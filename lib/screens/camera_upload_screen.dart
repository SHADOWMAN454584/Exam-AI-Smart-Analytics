import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../constants/app_theme.dart';
import '../constants/app_constants.dart';
import '../services/api_service.dart';
import 'document_upload_screen.dart';

class CameraUploadScreen extends StatefulWidget {
  const CameraUploadScreen({super.key});

  @override
  State<CameraUploadScreen> createState() => _CameraUploadScreenState();
}

class _CameraUploadScreenState extends State<CameraUploadScreen> {
  bool _isProcessing = false;
  bool _hasResult = false;
  String _selectedExam = 'JEE Main';
  Map<String, dynamic>? _scanResult;
  String? _errorMsg;

  final ImagePicker _picker = ImagePicker();

  Future<void> _pickAndUpload(ImageSource source) async {
    try {
      final file = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1920,
      );
      if (file == null) return;

      setState(() {
        _isProcessing = true;
        _hasResult = false;
        _scanResult = null;
        _errorMsg = null;
      });

      final bytes = await file.readAsBytes();
      final result = await ApiService.scanPaper(
        imageBytes: bytes,
        filename: file.name,
        examType: _selectedExam,
      );

      if (mounted) {
        setState(() {
          _scanResult = result as Map<String, dynamic>?;
          _isProcessing = false;
          _hasResult = true;
        });
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _errorMsg = e.message;
          _isProcessing = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMsg = 'Upload failed. Please try again.';
          _isProcessing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Upload failed. Please try again.')),
        );
      }
    }
  }

  // Legacy tap-to-upload (gallery)
  void _simulateUpload() => _pickAndUpload(ImageSource.gallery);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          const Text(
            'PYQ Scanner 📷',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Scan previous year questions and get AI-powered analysis',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),

          // Exam selector
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
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
                ),
                items: AppConstants.examTypes.map((e) {
                  return DropdownMenuItem(value: e, child: Text(e));
                }).toList(),
                onChanged: (v) => setState(() => _selectedExam = v!),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Upload area
          GestureDetector(
            onTap: _isProcessing ? null : _simulateUpload,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: double.infinity,
              height: 220,
              decoration: BoxDecoration(
                color: _isProcessing
                    ? AppColors.primary.withAlpha(10)
                    : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _isProcessing ? AppColors.primary : AppColors.divider,
                  width: _isProcessing ? 2 : 1,
                  strokeAlign: BorderSide.strokeAlignInside,
                ),
              ),
              child: _isProcessing
                  ? _buildProcessingState()
                  : _buildUploadState(),
            ),
          ),
          const SizedBox(height: 16),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: _actionButton(
                  icon: Icons.camera_alt_outlined,
                  label: 'Camera',
                  color: AppColors.primary,
                  onTap: () => _pickAndUpload(ImageSource.camera),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _actionButton(
                  icon: Icons.photo_library_outlined,
                  label: 'Gallery',
                  color: AppColors.accent,
                  onTap: () => _pickAndUpload(ImageSource.gallery),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _actionButton(
                  icon: Icons.picture_as_pdf_outlined,
                  label: 'PDF',
                  color: AppColors.maths,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const DocumentUploadScreen(),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),

          // Error banner
          if (_errorMsg != null)
            Container(
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
                ],
              ),
            ),

          // Result area
          if (_hasResult) _buildMockResult(),

          // Tips section
          if (!_hasResult) ...[
            const Text(
              'Tips for best results',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            _tipCard(
              Icons.light_mode_outlined,
              'Good lighting',
              'Ensure the paper is well-lit without shadows',
            ),
            _tipCard(
              Icons.crop_free,
              'Flat surface',
              'Place the question paper on a flat surface',
            ),
            _tipCard(
              Icons.center_focus_strong_outlined,
              'Clear focus',
              'Hold steady and ensure text is readable',
            ),
            _tipCard(
              Icons.filter_frames_outlined,
              'Full page',
              'Capture the entire question in the frame',
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildUploadState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.primary.withAlpha(15),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.cloud_upload_outlined,
            size: 40,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Tap to scan question paper',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Supports images and PDF files',
          style: TextStyle(fontSize: 13, color: AppColors.textLight),
        ),
      ],
    );
  }

  Widget _buildProcessingState() {
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
          'Processing your scan...',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'AI is extracting questions from $_selectedExam paper',
          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildMockResult() {
    final questionsExtracted =
        (_scanResult?['questions_extracted'] as num?)?.toInt() ?? 0;
    final extractedText = (_scanResult?['extracted_text'] as String?) ?? '';
    final status = (_scanResult?['status'] as String?) ?? 'completed';
    final subjects = (_scanResult?['subjects'] as String?) ?? _selectedExam;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.check_circle, color: AppColors.success, size: 22),
            const SizedBox(width: 8),
            const Text(
              'Scan Complete!',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.success,
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: () => setState(() => _hasResult = false),
              child: const Text('Clear'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.divider),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _resultRow('Exam', _selectedExam),
              const Divider(height: 20),
              _resultRow('Questions Found', '$questionsExtracted'),
              const Divider(height: 20),
              _resultRow('Subjects', subjects),
              const Divider(height: 20),
              _resultRow('Status', status),
              if (extractedText.isNotEmpty) ...[
                const Divider(height: 20),
                const Text(
                  'Extracted Text Preview',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  extractedText.length > 200
                      ? '${extractedText.substring(0, 200)}...'
                      : extractedText,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textPrimary,
                    height: 1.5,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Text('Start Practice with Scanned Questions'),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.analytics_outlined),
            label: const Text('View AI Analysis'),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _resultRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: _isProcessing ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withAlpha(15),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withAlpha(60)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tipCard(IconData icon, String title, String subtitle) {
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
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.accent.withAlpha(20),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.accent, size: 20),
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
                  subtitle,
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
    );
  }
}
