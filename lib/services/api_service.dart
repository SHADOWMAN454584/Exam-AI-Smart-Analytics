import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  Exception
// ─────────────────────────────────────────────────────────────────────────────

class ApiException implements Exception {
  final int statusCode;
  final String rawBody;

  ApiException(this.statusCode, this.rawBody);

  String get message {
    try {
      final decoded = jsonDecode(rawBody);
      return decoded['detail']?.toString() ??
          'Request failed (HTTP $statusCode)';
    } catch (_) {
      return 'Request failed (HTTP $statusCode)';
    }
  }

  @override
  String toString() => 'ApiException($statusCode): $message';
}

// ─────────────────────────────────────────────────────────────────────────────
//  ApiService  (static singleton — no Provider needed)
// ─────────────────────────────────────────────────────────────────────────────

class ApiService {
  static const _tokenKey = 'auth_token';
  static const _userKey = 'user_data';

  static String? _token;
  static Map<String, dynamic>? _currentUser;

  // ── Public accessors ───────────────────────────────────────────────────────

  static String? get token => _token;
  static Map<String, dynamic>? get currentUser => _currentUser;
  static bool get isLoggedIn => _token != null;

  /// Must be called once in [main] before [runApp].
  static Future<bool> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_tokenKey);
    final raw = prefs.getString(_userKey);
    if (raw != null) _currentUser = jsonDecode(raw) as Map<String, dynamic>;
    return _token != null;
  }

  // ── Session helpers ────────────────────────────────────────────────────────

  static Future<void> _saveSession(
    String token,
    Map<String, dynamic> user,
  ) async {
    _token = token;
    _currentUser = user;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_userKey, jsonEncode(user));
  }

  static Future<void> logout() async {
    _token = null;
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
  }

  // ── HTTP helpers ───────────────────────────────────────────────────────────

  static Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (_token != null) 'Authorization': 'Bearer $_token',
  };

  static Future<dynamic> _get(String path) async {
    final res = await http
        .get(Uri.parse('${AppConstants.baseUrl}$path'), headers: _headers)
        .timeout(const Duration(seconds: 15));
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw ApiException(res.statusCode, res.body);
  }

  static Future<dynamic> _post(String path, Map<String, dynamic> body) async {
    final res = await http
        .post(
          Uri.parse('${AppConstants.baseUrl}$path'),
          headers: _headers,
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 15));
    if (res.statusCode == 200 || res.statusCode == 201) {
      return jsonDecode(res.body);
    }
    throw ApiException(res.statusCode, res.body);
  }

  static Future<dynamic> _put(String path, Map<String, dynamic> body) async {
    final res = await http
        .put(
          Uri.parse('${AppConstants.baseUrl}$path'),
          headers: _headers,
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 15));
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw ApiException(res.statusCode, res.body);
  }

  // ── Auth ───────────────────────────────────────────────────────────────────

  /// Login with email + password. Stores session on success.
  static Future<Map<String, dynamic>> login(
    String email,
    String password,
  ) async {
    final data =
        await _post('/api/auth/login', {'email': email, 'password': password})
            as Map<String, dynamic>;
    await _saveSession(
      data['access_token'] as String,
      data['user'] as Map<String, dynamic>,
    );
    return data;
  }

  /// Register a new account. Stores session on success.
  static Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String fullName,
    required String examTarget,
  }) async {
    final data =
        await _post('/api/auth/register', {
              'email': email,
              'password': password,
              'full_name': fullName,
              'exam_target': examTarget,
            })
            as Map<String, dynamic>;
    await _saveSession(
      data['access_token'] as String,
      data['user'] as Map<String, dynamic>,
    );
    return data;
  }

  /// Fetch the current user's profile and refresh local cache.
  static Future<Map<String, dynamic>> getProfile() async {
    final data = await _get('/api/auth/profile') as Map<String, dynamic>;
    _currentUser = data;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(data));
    return data;
  }

  /// Update profile fields (all optional).
  static Future<Map<String, dynamic>> updateProfile(
    Map<String, dynamic> fields,
  ) async {
    final data =
        await _put('/api/auth/profile', fields) as Map<String, dynamic>;
    _currentUser = data;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(data));
    return data;
  }

  // ── Tests ──────────────────────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getTests() async {
    final data = await _get('/api/tests/') as List;
    return data.cast<Map<String, dynamic>>();
  }

  static Future<List<Map<String, dynamic>>> getTestQuestions(
    String testId,
  ) async {
    final data = await _get('/api/tests/$testId/questions') as List;
    return data.cast<Map<String, dynamic>>();
  }

  static Future<Map<String, dynamic>> submitTest({
    required String testId,
    required List<Map<String, dynamic>> responses,
    required int timeTakenMinutes,
  }) async {
    return await _post('/api/tests/submit', {
          'test_id': testId,
          'responses': responses,
          'time_taken_minutes': timeTakenMinutes,
        })
        as Map<String, dynamic>;
  }

  static Future<List<Map<String, dynamic>>> getTestHistory() async {
    final data = await _get('/api/tests/attempts/history') as List;
    return data.cast<Map<String, dynamic>>();
  }

  static Future<Map<String, dynamic>> getAttemptDetail(String attemptId) async {
    return await _get('/api/tests/attempts/$attemptId/detail')
        as Map<String, dynamic>;
  }

  // ── Analytics ──────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> getAnalyticsOverview() async {
    return await _get('/api/analytics/overview') as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> getAnalyticsProgress() async {
    return await _get('/api/analytics/progress') as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> getAnalyticsPrediction() async {
    return await _get('/api/analytics/prediction') as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> getSubjectAnalytics(
    String subject,
  ) async {
    return await _get('/api/analytics/subject/$subject')
        as Map<String, dynamic>;
  }

  // ── Recommendations ────────────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getRecommendations() async {
    final data = await _get('/api/recommendations/') as List;
    return data.cast<Map<String, dynamic>>();
  }

  static Future<List<Map<String, dynamic>>> refreshRecommendations() async {
    final data = await _post('/api/recommendations/refresh', {}) as List;
    return data.cast<Map<String, dynamic>>();
  }

  static Future<void> markRecommendationComplete(String recId) async {
    await _put('/api/recommendations/$recId/complete', {});
  }

  // ── OCR ────────────────────────────────────────────────────────────────────

  /// Upload an image [bytes] for OCR processing.
  /// [filename] should include the extension (e.g. "scan.jpg").
  static Future<Map<String, dynamic>> scanPaper({
    required List<int> imageBytes,
    required String filename,
    required String examType,
    String? year,
  }) async {
    final uri = Uri.parse('${AppConstants.baseUrl}/api/ocr/scan');
    final request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer $_token'
      ..fields['exam_type'] = examType;
    if (year != null) request.fields['year'] = year;
    request.files.add(
      http.MultipartFile.fromBytes('file', imageBytes, filename: filename),
    );

    final streamed = await request.send().timeout(const Duration(seconds: 45));
    final res = await http.Response.fromStream(streamed);

    if (res.statusCode == 200 || res.statusCode == 201) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    throw ApiException(res.statusCode, res.body);
  }

  static Future<List<Map<String, dynamic>>> getScannedPapers() async {
    final data = await _get('/api/ocr/papers') as List;
    return data.cast<Map<String, dynamic>>();
  }

  static Future<Map<String, dynamic>> getScannedPaperDetail(
    String paperId,
  ) async {
    return await _get('/api/ocr/papers/$paperId') as Map<String, dynamic>;
  }

  // ── Document Upload & AI Test Generation ───────────────────────────────────

  /// Upload a PDF file for AI scanning and question extraction.
  /// Returns upload metadata including a [document_id].
  static Future<Map<String, dynamic>> uploadPdf({
    required List<int> pdfBytes,
    required String filename,
    required String examType,
    String? subject,
  }) async {
    final uri = Uri.parse('${AppConstants.baseUrl}/api/documents/upload');
    final request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer $_token'
      ..fields['exam_type'] = examType;
    if (subject != null) request.fields['subject'] = subject;
    request.files.add(
      http.MultipartFile.fromBytes('file', pdfBytes, filename: filename),
    );

    final streamed = await request.send().timeout(const Duration(seconds: 90));
    final res = await http.Response.fromStream(streamed);

    if (res.statusCode == 200 || res.statusCode == 201) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    throw ApiException(res.statusCode, res.body);
  }

  /// Upload an image (photo of notes/book/question paper) for AI scanning.
  /// Returns upload metadata including a [document_id].
  static Future<Map<String, dynamic>> uploadDocumentImage({
    required List<int> imageBytes,
    required String filename,
    required String examType,
    String? subject,
  }) async {
    final uri = Uri.parse('${AppConstants.baseUrl}/api/documents/upload');
    final request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer $_token'
      ..fields['exam_type'] = examType;
    if (subject != null) request.fields['subject'] = subject;
    request.files.add(
      http.MultipartFile.fromBytes('file', imageBytes, filename: filename),
    );

    final streamed = await request.send().timeout(const Duration(seconds: 60));
    final res = await http.Response.fromStream(streamed);

    if (res.statusCode == 200 || res.statusCode == 201) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    throw ApiException(res.statusCode, res.body);
  }

  /// Generate an AI test from a previously uploaded document.
  /// [documentId] is returned from uploadPdf / uploadDocumentImage.
  /// [questionCount] controls how many questions the AI should generate.
  static Future<Map<String, dynamic>> generateTestFromDocument({
    required String documentId,
    int questionCount = 10,
    String difficulty = 'Mixed',
    String examType = 'JEE Main',
    String? subject,
  }) async {
    return await _post('/api/documents/generate-test', {
          'document_id': documentId,
          'num_questions': questionCount,
          'difficulty': difficulty,
          'exam_type': examType,
          if (subject != null) 'subject': subject,
        })
        as Map<String, dynamic>;
  }

  /// Get all uploaded documents for the current user.
  static Future<List<Map<String, dynamic>>> getUploadedDocuments() async {
    final data = await _get('/api/documents/') as List;
    return data.cast<Map<String, dynamic>>();
  }

  /// Get details + extracted content of a single document.
  static Future<Map<String, dynamic>> getDocumentDetail(
    String documentId,
  ) async {
    return await _get('/api/documents/$documentId') as Map<String, dynamic>;
  }

  /// Get AI-generated tests linked to a specific document.
  static Future<List<Map<String, dynamic>>> getDocumentTests(
    String documentId,
  ) async {
    final data = await _get('/api/documents/$documentId/tests') as List;
    return data.cast<Map<String, dynamic>>();
  }
}
