/// Central configuration for the ExamAI app.
class AppConstants {
  /// Backend base URL.
  ///
  /// • Android emulator  → http://10.0.2.2:8000
  /// • iOS simulator     → http://localhost:8000
  /// • Physical device   → http://<your-machine-LAN-ip>:8000
  /// • Production        → https://your-deployed-api.com
  static const String baseUrl = 'http://10.0.2.2:8000';

  /// Available exam types for OCR scan selection.
  static const List<String> examTypes = [
    'JEE Main',
    'JEE Advanced',
    'NEET',
    'GATE',
    'CAT',
  ];
}
