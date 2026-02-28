import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import '../constants/app_theme.dart';
import '../constants/app_constants.dart';
import '../services/api_service.dart';

/// Screen for uploading PDFs / images so the AI model can scan them
/// and generate practice tests from the content.
class DocumentUploadScreen extends StatefulWidget {
  const DocumentUploadScreen({super.key});

  @override
  State<DocumentUploadScreen> createState() => _DocumentUploadScreenState();
}

class _DocumentUploadScreenState extends State<DocumentUploadScreen>
    with SingleTickerProviderStateMixin {
  // ── state ──────────────────────────────────────────────────────────────────
  bool _isUploading = false;
  bool _isGenerating = false;
  String _selectedExam = 'JEE Main';
  String? _selectedSubject;
  int _questionCount = 10;
  String _difficulty = 'Mixed';

  // uploaded document result
  Map<String, dynamic>? _uploadResult;
  // generated test result
  Map<String, dynamic>? _generatedTest;
  // previous uploads
  List<Map<String, dynamic>> _documents = [];
  bool _loadingDocs = true;

  String? _errorMsg;

  final ImagePicker _imagePicker = ImagePicker();
  late TabController _tabController;

  static const _subjects = [
    'Physics',
    'Chemistry',
    'Mathematics',
    'Biology',
    'General',
  ];

  static const _difficulties = ['Easy', 'Medium', 'Hard', 'Mixed'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadDocuments();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ── data loading ───────────────────────────────────────────────────────────

  Future<void> _loadDocuments() async {
    setState(() => _loadingDocs = true);
    try {
      final docs = await ApiService.getUploadedDocuments();
      if (mounted) setState(() => _documents = docs);
    } catch (_) {
      // offline or no docs yet
    }
    if (mounted) setState(() => _loadingDocs = false);
  }

  // ── pick & upload ─────────────────────────────────────────────────────────

  Future<void> _pickPdf() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      if (file.bytes == null && file.path == null) return;

      final bytes = file.bytes ?? await File(file.path!).readAsBytes();
      final filename = file.name;

      await _uploadDocument(bytes: bytes, filename: filename, isPdf: true);
    } catch (e) {
      _showError('Failed to pick PDF: $e');
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final file = await _imagePicker.pickImage(
        source: source,
        imageQuality: 90,
        maxWidth: 2400,
      );
      if (file == null) return;

      final bytes = await file.readAsBytes();
      await _uploadDocument(bytes: bytes, filename: file.name, isPdf: false);
    } catch (e) {
      _showError('Failed to pick image: $e');
    }
  }

  Future<void> _pickMultipleImages() async {
    try {
      final files = await _imagePicker.pickMultiImage(
        imageQuality: 90,
        maxWidth: 2400,
      );
      if (files.isEmpty) return;

      // Upload first image; backend supports batch in future
      final first = files.first;
      final bytes = await first.readAsBytes();
      await _uploadDocument(bytes: bytes, filename: first.name, isPdf: false);

      if (files.length > 1 && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${files.length - 1} more image(s) queued — upload one at a time for now.',
            ),
          ),
        );
      }
    } catch (e) {
      _showError('Failed to pick images: $e');
    }
  }

  Future<void> _uploadDocument({
    required List<int> bytes,
    required String filename,
    required bool isPdf,
  }) async {
    setState(() {
      _isUploading = true;
      _uploadResult = null;
      _generatedTest = null;
      _errorMsg = null;
    });

    try {
      Map<String, dynamic> result;
      if (isPdf) {
        result = await ApiService.uploadPdf(
          pdfBytes: bytes,
          filename: filename,
          examType: _selectedExam,
          subject: _selectedSubject,
        );
      } else {
        result = await ApiService.uploadDocumentImage(
          imageBytes: bytes,
          filename: filename,
          examType: _selectedExam,
          subject: _selectedSubject,
        );
      }

      if (mounted) {
        setState(() {
          _uploadResult = result;
          _isUploading = false;
        });
        _loadDocuments(); // refresh list
      }
    } on ApiException catch (_) {
      // Backend endpoint not available yet — use offline fallback
      if (mounted) {
        await Future.delayed(const Duration(seconds: 2)); // simulate processing
        final mockId = DateTime.now().millisecondsSinceEpoch.toString();
        setState(() {
          _uploadResult = {
            'document_id': mockId,
            'id': mockId,
            'filename': filename,
            'file_type': isPdf ? 'pdf' : 'image',
            'exam_type': _selectedExam,
            'subject': _selectedSubject ?? 'Auto-detected',
            'status': 'processed',
            'pages_extracted': isPdf ? 5 : 1,
            'text_length': bytes.length,
            'topics_detected': [
              'Kinematics',
              'Chemical Bonding',
              'Integration',
            ],
          };
          _isUploading = false;
          _errorMsg = null;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Offline mode: using mock scan result. Connect backend for real processing.',
              ),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMsg = 'Upload failed. Please try again.';
          _isUploading = false;
        });
      }
    }
  }

  // ── generate test ─────────────────────────────────────────────────────────

  Future<void> _generateTest() async {
    final docId =
        _uploadResult?['document_id']?.toString() ??
        _uploadResult?['id']?.toString();
    if (docId == null) {
      _showError('No document selected. Upload a file first.');
      return;
    }

    setState(() {
      _isGenerating = true;
      _generatedTest = null;
      _errorMsg = null;
    });

    try {
      final test = await ApiService.generateTestFromDocument(
        documentId: docId,
        questionCount: _questionCount,
        difficulty: _difficulty,
      );
      if (mounted) {
        setState(() {
          _generatedTest = test;
          _isGenerating = false;
        });
      }
    } on ApiException catch (_) {
      // Backend not available — mock a generated test for demo
      if (mounted) {
        await Future.delayed(const Duration(seconds: 2));
        setState(() {
          _generatedTest = {
            'test_id': 'mock_${DateTime.now().millisecondsSinceEpoch}',
            'id': 'mock_${DateTime.now().millisecondsSinceEpoch}',
            'title':
                'AI Test — ${_uploadResult?['filename'] ?? _selectedExam}',
            'question_count': _questionCount,
            'difficulty': _difficulty,
          };
          _isGenerating = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Offline mode: mock test generated. Connect backend for real AI questions.',
            ),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _errorMsg = 'Test generation failed. Try again.';
          _isGenerating = false;
        });
      }
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    setState(() => _errorMsg = msg);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ── build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload & Generate Test'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          tabs: const [
            Tab(icon: Icon(Icons.upload_file), text: 'Upload'),
            Tab(icon: Icon(Icons.history), text: 'My Documents'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildUploadTab(), _buildDocumentsTab()],
      ),
    );
  }

  // ── Upload Tab ─────────────────────────────────────────────────────────────

  Widget _buildUploadTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          const Text(
            'Upload Study Material 📄',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Upload a PDF or image — AI will scan it and generate a practice test from the content.',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),

          // Exam & subject selectors
          _buildSelectors(),
          const SizedBox(height: 20),

          // Upload area
          _buildUploadArea(),
          const SizedBox(height: 16),

          // Action buttons row
          _buildActionButtons(),
          const SizedBox(height: 20),

          // Error
          if (_errorMsg != null) _buildErrorBanner(),

          // Upload result
          if (_uploadResult != null) ...[
            _buildUploadResult(),
            const SizedBox(height: 20),
            _buildTestConfig(),
            const SizedBox(height: 16),
            _buildGenerateButton(),
          ],

          // Generated test result
          if (_generatedTest != null) ...[
            const SizedBox(height: 20),
            _buildGeneratedTestCard(),
          ],

          // Tips
          if (_uploadResult == null && !_isUploading) ...[
            const SizedBox(height: 28),
            _buildTips(),
          ],
        ],
      ),
    );
  }

  Widget _buildSelectors() {
    return Row(
      children: [
        // Exam type
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.divider),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                value: _selectedExam,
                icon: const Icon(
                  Icons.keyboard_arrow_down,
                  color: AppColors.primary,
                  size: 20,
                ),
                items: AppConstants.examTypes
                    .map(
                      (e) => DropdownMenuItem(
                        value: e,
                        child: Text(e, style: const TextStyle(fontSize: 13)),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _selectedExam = v!),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        // Subject (optional)
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.divider),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String?>(
                isExpanded: true,
                value: _selectedSubject,
                hint: const Text('Subject', style: TextStyle(fontSize: 13)),
                icon: const Icon(
                  Icons.keyboard_arrow_down,
                  color: AppColors.primary,
                  size: 20,
                ),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('Auto-detect', style: TextStyle(fontSize: 13)),
                  ),
                  ..._subjects.map(
                    (s) => DropdownMenuItem(
                      value: s,
                      child: Text(s, style: const TextStyle(fontSize: 13)),
                    ),
                  ),
                ],
                onChanged: (v) => setState(() => _selectedSubject = v),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUploadArea() {
    return GestureDetector(
      onTap: _isUploading ? null : _pickPdf,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 40),
        decoration: BoxDecoration(
          color: _isUploading ? AppColors.primary.withAlpha(10) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _isUploading ? AppColors.primary : AppColors.divider,
            width: _isUploading ? 2 : 1,
          ),
        ),
        child: _isUploading
            ? _buildProcessingIndicator()
            : _buildUploadPlaceholder(),
      ),
    );
  }

  Widget _buildUploadPlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primary.withAlpha(20),
                AppColors.accent.withAlpha(15),
              ],
            ),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.cloud_upload_outlined,
            size: 44,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 18),
        const Text(
          'Tap to upload PDF',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Supports PDF, JPG, PNG  •  Max 20 MB',
          style: TextStyle(fontSize: 12, color: AppColors.textLight),
        ),
      ],
    );
  }

  Widget _buildProcessingIndicator() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(
          width: 48,
          height: 48,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Uploading & scanning...',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'AI is extracting content from your $_selectedExam material',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: _actionBtn(
            icon: Icons.picture_as_pdf_rounded,
            label: 'PDF',
            color: Colors.redAccent,
            onTap: _pickPdf,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _actionBtn(
            icon: Icons.camera_alt_outlined,
            label: 'Camera',
            color: AppColors.primary,
            onTap: () => _pickImage(ImageSource.camera),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _actionBtn(
            icon: Icons.photo_library_outlined,
            label: 'Gallery',
            color: AppColors.accent,
            onTap: () => _pickImage(ImageSource.gallery),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _actionBtn(
            icon: Icons.collections_outlined,
            label: 'Multi',
            color: AppColors.maths,
            onTap: _pickMultipleImages,
          ),
        ),
      ],
    );
  }

  Widget _actionBtn({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: _isUploading ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withAlpha(15),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withAlpha(60)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.red.withAlpha(20),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.red.withAlpha(80)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _errorMsg!,
              style: const TextStyle(fontSize: 12, color: Colors.red),
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => _errorMsg = null),
            child: const Icon(Icons.close, color: Colors.red, size: 16),
          ),
        ],
      ),
    );
  }

  // ── Upload Result Card ────────────────────────────────────────────────────

  Widget _buildUploadResult() {
    final docId =
        _uploadResult?['document_id']?.toString() ??
        _uploadResult?['id']?.toString() ??
        '—';
    final pagesOrText =
        _uploadResult?['pages_extracted']?.toString() ??
        _uploadResult?['text_length']?.toString() ??
        '—';
    final status = _uploadResult?['status']?.toString() ?? 'completed';
    final topics =
        (_uploadResult?['topics_detected'] as List?)?.join(', ') ?? '—';
    final filename = _uploadResult?['filename']?.toString() ?? '—';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.success.withAlpha(80)),
        boxShadow: [
          BoxShadow(
            color: AppColors.success.withAlpha(15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.check_circle,
                color: AppColors.success,
                size: 22,
              ),
              const SizedBox(width: 8),
              const Text(
                'Upload Complete!',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.success,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => setState(() {
                  _uploadResult = null;
                  _generatedTest = null;
                }),
                child: const Text('Clear'),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _resultRow('File', filename),
          const Divider(height: 18),
          _resultRow('Document ID', docId),
          const Divider(height: 18),
          _resultRow('Pages / Chars', pagesOrText),
          const Divider(height: 18),
          _resultRow('Status', status),
          if (topics != '—') ...[
            const Divider(height: 18),
            _resultRow('Topics Found', topics),
          ],
        ],
      ),
    );
  }

  Widget _resultRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }

  // ── Test Configuration ────────────────────────────────────────────────────

  Widget _buildTestConfig() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.tune, color: AppColors.primary, size: 20),
              SizedBox(width: 8),
              Text(
                'Test Configuration',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Question count
          const Text(
            'Number of Questions',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          Row(
            children: [5, 10, 15, 20, 30].map((n) {
              final isSelected = _questionCount == n;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text('$n'),
                  selected: isSelected,
                  selectedColor: AppColors.primary.withAlpha(30),
                  labelStyle: TextStyle(
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.textSecondary,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    fontSize: 13,
                  ),
                  onSelected: (_) => setState(() => _questionCount = n),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // Difficulty
          const Text(
            'Difficulty Level',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          Row(
            children: _difficulties.map((d) {
              final isSelected = _difficulty == d;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(d),
                  selected: isSelected,
                  selectedColor: AppColors.primary.withAlpha(30),
                  labelStyle: TextStyle(
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.textSecondary,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    fontSize: 13,
                  ),
                  onSelected: (_) => setState(() => _difficulty = d),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildGenerateButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: _isGenerating ? null : _generateTest,
        icon: _isGenerating
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.auto_awesome),
        label: Text(
          _isGenerating ? 'Generating Test...' : 'Generate AI Test',
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  // ── Generated Test Card ───────────────────────────────────────────────────

  Widget _buildGeneratedTestCard() {
    final testId =
        _generatedTest?['test_id']?.toString() ??
        _generatedTest?['id']?.toString() ??
        '';
    final title = _generatedTest?['title']?.toString() ?? 'AI Generated Test';
    final qCount =
        _generatedTest?['question_count']?.toString() ?? '$_questionCount';
    final diff = _generatedTest?['difficulty']?.toString() ?? _difficulty;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withAlpha(15),
            AppColors.accent.withAlpha(10),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withAlpha(50)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(20),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.quiz,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Test Ready! 🎉',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _miniStat(Icons.help_outline, '$qCount Qs'),
              const SizedBox(width: 16),
              _miniStat(Icons.speed, diff),
              const SizedBox(width: 16),
              _miniStat(Icons.school, _selectedExam),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () {
                // Navigate to test screen with the generated test
                if (testId.isNotEmpty) {
                  Navigator.of(
                    context,
                  ).pop({'test_id': testId, 'title': title});
                }
              },
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text(
                'Start Test Now',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniStat(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // ── Tips ───────────────────────────────────────────────────────────────────

  Widget _buildTips() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'How it works',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        _tipCard(
          Icons.upload_file,
          'Upload Material',
          'Upload a PDF, textbook photo, or notes image',
          '1',
        ),
        _tipCard(
          Icons.psychology,
          'AI Scans Content',
          'Our AI extracts text, topics, and key concepts',
          '2',
        ),
        _tipCard(
          Icons.auto_awesome,
          'Generate Test',
          'Choose question count & difficulty, then generate',
          '3',
        ),
        _tipCard(
          Icons.quiz,
          'Practice & Learn',
          'Take the AI-generated test and track your score',
          '4',
        ),
      ],
    );
  }

  Widget _tipCard(IconData icon, String title, String sub, String step) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              step,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  sub,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Icon(icon, color: AppColors.primary.withAlpha(80), size: 24),
        ],
      ),
    );
  }

  // ── Documents Tab ──────────────────────────────────────────────────────────

  Widget _buildDocumentsTab() {
    if (_loadingDocs) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_documents.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.folder_open,
              size: 64,
              color: AppColors.textLight.withAlpha(100),
            ),
            const SizedBox(height: 16),
            const Text(
              'No documents yet',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Upload a PDF or image to get started',
              style: TextStyle(fontSize: 13, color: AppColors.textLight),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _tabController.animateTo(0),
              icon: const Icon(Icons.upload),
              label: const Text('Upload Now'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadDocuments,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _documents.length,
        itemBuilder: (_, i) => _buildDocCard(_documents[i]),
      ),
    );
  }

  Widget _buildDocCard(Map<String, dynamic> doc) {
    final filename = doc['filename']?.toString() ?? 'Untitled';
    final examType = doc['exam_type']?.toString() ?? '';
    final status = doc['status']?.toString() ?? 'processed';
    final createdAt = doc['created_at']?.toString() ?? '';
    final docId = doc['id']?.toString() ?? doc['document_id']?.toString() ?? '';
    final isPdf = filename.toLowerCase().endsWith('.pdf');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withAlpha(8),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: (isPdf ? Colors.redAccent : AppColors.primary).withAlpha(
                15,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isPdf ? Icons.picture_as_pdf : Icons.image,
              color: isPdf ? Colors.redAccent : AppColors.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  filename,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (examType.isNotEmpty) ...[
                      Text(
                        examType,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: status == 'processed' || status == 'completed'
                            ? AppColors.success.withAlpha(15)
                            : AppColors.maths.withAlpha(15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: status == 'processed' || status == 'completed'
                              ? AppColors.success
                              : AppColors.maths,
                        ),
                      ),
                    ),
                    if (createdAt.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Text(
                        createdAt.length >= 10
                            ? createdAt.substring(0, 10)
                            : createdAt,
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.textLight,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          // Generate test from this doc
          IconButton(
            tooltip: 'Generate test',
            icon: const Icon(Icons.auto_awesome, color: AppColors.primary),
            onPressed: () {
              setState(() {
                _uploadResult = {'document_id': docId, 'filename': filename};
                _generatedTest = null;
              });
              _tabController.animateTo(0);
            },
          ),
        ],
      ),
    );
  }
}
