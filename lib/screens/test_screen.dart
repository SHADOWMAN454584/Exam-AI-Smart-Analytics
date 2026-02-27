import 'package:flutter/material.dart';
import '../constants/app_theme.dart';
import '../constants/sample_data.dart';
import '../services/api_service.dart';

class TestScreen extends StatefulWidget {
  const TestScreen({super.key});

  @override
  State<TestScreen> createState() => _TestScreenState();
}

enum _TestPhase { loading, selectTest, takingTest, viewingResults }

class _TestScreenState extends State<TestScreen> {
  _TestPhase _phase = _TestPhase.loading;

  // Test selection
  List<Map<String, dynamic>> _availableTests = [];

  // Active test
  String? _activeTestId;
  String _activeTestTitle = 'Practice Test';
  List<Map<String, dynamic>> _questions = [];
  int _currentIndex = 0;
  final Map<int, int?> _selectedAnswers = {};
  final Map<int, int> _timeSpent = {}; // seconds per question
  DateTime? _questionStartTime;
  DateTime? _testStartTime;

  // Results
  Map<String, dynamic>? _apiResult; // from POST /api/tests/submit

  @override
  void initState() {
    super.initState();
    _loadTests();
  }

  // ── Data loading ──────────────────────────────────────────────────────────

  Future<void> _loadTests() async {
    setState(() => _phase = _TestPhase.loading);
    try {
      final tests = await ApiService.getTests();
      if (mounted) {
        setState(() {
          _availableTests = tests;
          _phase = _TestPhase.selectTest;
        });
      }
    } catch (_) {
      // No tests on server – go straight into sample questions
      if (mounted) {
        setState(() {
          _availableTests = [];
          _phase = _TestPhase.selectTest;
        });
      }
    }
  }

  Future<void> _startTest(Map<String, dynamic>? test) async {
    setState(() => _phase = _TestPhase.loading);
    List<Map<String, dynamic>> questions;
    String testId = '';
    String testTitle = 'Practice Test';

    if (test != null) {
      testId = test['id']?.toString() ?? '';
      testTitle = test['title']?.toString() ?? 'Practice Test';
      try {
        questions = await ApiService.getTestQuestions(testId);
      } catch (_) {
        questions = SampleData.mockQuestions;
        testId = '';
      }
    } else {
      questions = SampleData.mockQuestions;
    }

    if (mounted) {
      setState(() {
        _activeTestId = testId.isEmpty ? null : testId;
        _activeTestTitle = testTitle;
        _questions = questions;
        _currentIndex = 0;
        _selectedAnswers.clear();
        _timeSpent.clear();
        _testStartTime = DateTime.now();
        _questionStartTime = DateTime.now();
        _apiResult = null;
        _phase = _TestPhase.takingTest;
      });
    }
  }

  // ── Actions ───────────────────────────────────────────────────────────────

  Map<String, dynamic> get _currentQ => _questions[_currentIndex];

  void _selectOption(int optionIndex) {
    setState(() => _selectedAnswers[_currentIndex] = optionIndex);
  }

  void _nextQuestion() {
    _recordTimeSpent();
    if (_currentIndex < _questions.length - 1) {
      setState(() {
        _currentIndex++;
        _questionStartTime = DateTime.now();
      });
    }
  }

  void _prevQuestion() {
    _recordTimeSpent();
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
        _questionStartTime = DateTime.now();
      });
    }
  }

  void _recordTimeSpent() {
    if (_questionStartTime != null) {
      _timeSpent[_currentIndex] = DateTime.now()
          .difference(_questionStartTime!)
          .inSeconds;
    }
  }

  void _submitTest() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Submit Test?'),
        content: Text(
          'You have answered ${_selectedAnswers.length}/${_questions.length} questions. '
          'Are you sure you want to submit?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _doSubmit();
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  Future<void> _doSubmit() async {
    _recordTimeSpent();
    setState(() => _phase = _TestPhase.loading);

    final timeTaken = _testStartTime != null
        ? DateTime.now().difference(_testStartTime!).inMinutes
        : 0;

    if (_activeTestId != null) {
      try {
        final responses = List.generate(_questions.length, (i) {
          final q = _questions[i];
          // API field: selected_option uses 0-based index or null
          return {
            'question_id': q['id']?.toString() ?? '$i',
            'selected_option': _selectedAnswers[i],
            'time_spent_seconds': _timeSpent[i] ?? 30,
          };
        });

        final result = await ApiService.submitTest(
          testId: _activeTestId!,
          responses: responses,
          timeTakenMinutes: timeTaken,
        );
        if (mounted) {
          setState(() {
            _apiResult = result;
            _phase = _TestPhase.viewingResults;
          });
        }
        return;
      } catch (_) {
        // Fall through to local calculation
      }
    }

    // Local calculation fallback
    if (mounted) setState(() => _phase = _TestPhase.viewingResults);
  }

  // ── Local scoring (fallback) ─────────────────────────────────────────────

  int get _localScore {
    int correct = 0;
    for (int i = 0; i < _questions.length; i++) {
      final correctOpt =
          _questions[i]['correct'] ?? _questions[i]['correct_option'];
      if (correctOpt != null && _selectedAnswers[i] == (correctOpt as int)) {
        correct++;
      }
    }
    return correct;
  }

  @override
  Widget build(BuildContext context) {
    switch (_phase) {
      case _TestPhase.loading:
        return const Center(child: CircularProgressIndicator());
      case _TestPhase.selectTest:
        return _buildSelectTestView();
      case _TestPhase.takingTest:
        return _buildTakingTestView();
      case _TestPhase.viewingResults:
        return _buildResultView();
    }
  }

  // ── Select Test ───────────────────────────────────────────────────────────

  Widget _buildSelectTestView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Available Tests 📝',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Choose a test to start or try the practice set',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),
          if (_availableTests.isEmpty) ...[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(10),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primary.withAlpha(40)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: AppColors.primary),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'No tests found on the server. '
                      'Using the built-in practice set.',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
          // Server tests
          ..._availableTests.map((t) => _buildTestListCard(t)),
          // Always show sample practice set
          _buildPracticeCard(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildTestListCard(Map<String, dynamic> test) {
    final subject = test['subject']?.toString() ?? 'Mixed';
    final difficulty = test['difficulty']?.toString() ?? '';
    final total = test['total_questions'] ?? 0;
    final duration = test['duration_minutes'] != null
        ? '${test['duration_minutes']} min'
        : '';

    final subjectColors = {
      'Physics': AppColors.physics,
      'Chemistry': AppColors.chemistry,
      'Maths': AppColors.maths,
    };
    final color = subjectColors[subject] ?? AppColors.primary;

    return GestureDetector(
      onTap: () => _startTest(test),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: color.withAlpha(20),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  subject.isNotEmpty ? subject[0] : 'T',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    test['title']?.toString() ?? 'Test',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$total Qs${duration.isNotEmpty ? '  •  $duration' : ''}${difficulty.isNotEmpty ? '  •  $difficulty' : ''}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: AppColors.textLight,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPracticeCard() {
    return GestureDetector(
      onTap: () => _startTest(null),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primary.withAlpha(20),
              AppColors.accent.withAlpha(20),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primary.withAlpha(50)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(25),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.edit_note_rounded,
                color: AppColors.primary,
                size: 26,
              ),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Quick Practice Set',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '5 Mixed Questions  •  JEE / NEET Style',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: AppColors.textLight,
            ),
          ],
        ),
      ),
    );
  }

  // ── Taking Test ───────────────────────────────────────────────────────────

  Widget _buildTakingTestView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTestHeader(),
          const SizedBox(height: 20),
          _buildQuestionNavigator(),
          const SizedBox(height: 24),
          _buildQuestionCard(),
          const SizedBox(height: 20),
          ..._buildOptions(),
          const SizedBox(height: 28),
          _buildNavButtons(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildTestHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _activeTestTitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Question ${_currentIndex + 1} of ${_questions.length}',
                  style: TextStyle(
                    color: Colors.white.withAlpha(180),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(30),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.timer_outlined, color: Colors.white, size: 18),
                const SizedBox(width: 6),
                Text(
                  '${_selectedAnswers.length}/${_questions.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionNavigator() {
    return SizedBox(
      height: 42,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _questions.length,
        itemBuilder: (_, i) {
          final isActive = i == _currentIndex;
          final isAnswered = _selectedAnswers.containsKey(i);
          return GestureDetector(
            onTap: () {
              _recordTimeSpent();
              setState(() {
                _currentIndex = i;
                _questionStartTime = DateTime.now();
              });
            },
            child: Container(
              width: 42,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: isActive
                    ? AppColors.primary
                    : isAnswered
                    ? AppColors.primary.withAlpha(25)
                    : AppColors.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isActive
                      ? AppColors.primary
                      : isAnswered
                      ? AppColors.primary.withAlpha(80)
                      : AppColors.divider,
                ),
              ),
              child: Center(
                child: Text(
                  '${i + 1}',
                  style: TextStyle(
                    color: isActive
                        ? Colors.white
                        : isAnswered
                        ? AppColors.primary
                        : AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildQuestionCard() {
    final subjectColors = {
      'Physics': AppColors.physics,
      'Chemistry': AppColors.chemistry,
      'Maths': AppColors.maths,
    };
    final subjectColor =
        subjectColors[_currentQ['subject']] ?? AppColors.primary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
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
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: subjectColor.withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _currentQ['subject'] as String,
                  style: TextStyle(
                    color: subjectColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _currentQ['difficulty'] as String,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                _currentQ['topic'] as String,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _currentQ['question'] as String,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildOptions() {
    final options = _currentQ['options'] as List<String>;
    final labels = ['A', 'B', 'C', 'D'];
    return List.generate(options.length, (i) {
      final isSelected = _selectedAnswers[_currentIndex] == i;
      return GestureDetector(
        onTap: () => _selectOption(i),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary.withAlpha(15) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.divider,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : AppColors.background,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    labels[i],
                    style: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  options[i],
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              if (isSelected)
                const Icon(
                  Icons.check_circle,
                  color: AppColors.primary,
                  size: 22,
                ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildNavButtons() {
    return Row(
      children: [
        if (_currentIndex > 0)
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _prevQuestion,
              icon: const Icon(Icons.arrow_back_rounded, size: 18),
              label: const Text('Previous'),
            ),
          ),
        if (_currentIndex > 0) const SizedBox(width: 12),
        Expanded(
          child: _currentIndex < _questions.length - 1
              ? ElevatedButton.icon(
                  onPressed: _nextQuestion,
                  icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                  label: const Text('Next'),
                )
              : ElevatedButton.icon(
                  onPressed: _submitTest,
                  icon: const Icon(Icons.check_circle_outline, size: 18),
                  label: const Text('Submit'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildResultView() {
    // Use API result if available, otherwise fall back to local calculation
    final double percentage;
    final int scoreInt;
    final int totalInt = _questions.length;
    List<dynamic>? apiResponses;
    Map<String, dynamic>? subjectBreakdown;

    if (_apiResult != null) {
      percentage = ((_apiResult!['percentage'] as num?)?.toDouble() ?? 0.0);
      scoreInt = (_apiResult!['score'] as num?)?.toInt() ?? _localScore;
      apiResponses = _apiResult!['responses'] as List<dynamic>?;
      subjectBreakdown =
          _apiResult!['subject_breakdown'] as Map<String, dynamic>?;
    } else {
      scoreInt = _localScore;
      percentage = totalInt > 0 ? (scoreInt / totalInt) * 100 : 0;
    }

    final color = AppColors.gradeColor(percentage);
    final label = AppColors.gradeLabel(percentage);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 20),
          // Score summary card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [color.withAlpha(20), color.withAlpha(10)],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: color.withAlpha(60)),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.emoji_events,
                  size: 56,
                  color: AppColors.maths,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Test Completed!',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: 120,
                  height: 120,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 120,
                        height: 120,
                        child: CircularProgressIndicator(
                          value: percentage / 100,
                          strokeWidth: 10,
                          backgroundColor: AppColors.divider,
                          valueColor: AlwaysStoppedAnimation<Color>(color),
                          strokeCap: StrokeCap.round,
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${percentage.toStringAsFixed(0)}%',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: color,
                            ),
                          ),
                          Text(
                            label,
                            style: TextStyle(
                              fontSize: 12,
                              color: color,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'You scored $scoreInt out of $totalInt',
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          // Subject breakdown (API only)
          if (subjectBreakdown != null && subjectBreakdown.isNotEmpty) ...[
            const SizedBox(height: 20),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Subject Breakdown',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 12),
            ...subjectBreakdown.entries.map((e) {
              final subjectColors = {
                'Physics': AppColors.physics,
                'Chemistry': AppColors.chemistry,
                'Maths': AppColors.maths,
              };
              final sc = subjectColors[e.key] ?? AppColors.primary;
              final vals = e.value as Map<String, dynamic>;
              final pct = (vals['percentage'] as num?)?.toDouble() ?? 0.0;
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.shadow,
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: sc.withAlpha(25),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        e.key,
                        style: TextStyle(
                          color: sc,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: LinearProgressIndicator(
                        value: pct / 100,
                        backgroundColor: AppColors.divider,
                        valueColor: AlwaysStoppedAnimation<Color>(sc),
                        minHeight: 8,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${pct.toStringAsFixed(0)}%',
                      style: TextStyle(fontWeight: FontWeight.w700, color: sc),
                    ),
                  ],
                ),
              );
            }),
          ],
          const SizedBox(height: 24),
          // Answer review
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Answer Review',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 12),
          ...List.generate(_questions.length, (i) {
            final q = _questions[i];
            final selected = _selectedAnswers[i];
            final options =
                (q['options'] as List?)?.cast<String>() ?? <String>[];

            // Determine correct option: from API response or from question data
            int? correct;
            String? explanation;
            if (apiResponses != null && i < apiResponses.length) {
              final resp = apiResponses[i] as Map<String, dynamic>;
              correct = resp['correct_option'] as int?;
              explanation = resp['explanation'] as String?;
            }
            correct ??= (q['correct'] ?? q['correct_option']) as int?;

            final isCorrect = correct != null && selected == correct;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isCorrect
                      ? AppColors.success.withAlpha(80)
                      : AppColors.error.withAlpha(80),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        isCorrect ? Icons.check_circle : Icons.cancel,
                        color: isCorrect ? AppColors.success : AppColors.error,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Q${i + 1}: ${q['question']}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (selected != null && options.length > selected)
                    Text(
                      'Your answer: ${options[selected]}',
                      style: TextStyle(
                        fontSize: 12,
                        color: isCorrect ? AppColors.success : AppColors.error,
                      ),
                    ),
                  if (!isCorrect && correct != null && options.length > correct)
                    Text(
                      'Correct answer: ${options[correct]}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.success,
                      ),
                    ),
                  if (explanation != null && explanation.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      explanation,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            );
          }),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      _phase = _TestPhase.selectTest;
                      _currentIndex = 0;
                      _selectedAnswers.clear();
                      _timeSpent.clear();
                      _apiResult = null;
                    });
                    _loadTests();
                  },
                  icon: const Icon(Icons.list_alt_rounded, size: 18),
                  label: const Text('All Tests'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    final testToRetake = _availableTests.firstWhere(
                      (t) => t['id'] == _activeTestId,
                      orElse: () => <String, dynamic>{},
                    );
                    setState(() {
                      _currentIndex = 0;
                      _selectedAnswers.clear();
                      _timeSpent.clear();
                      _apiResult = null;
                      _phase = _TestPhase.takingTest;
                      _testStartTime = DateTime.now();
                      _questionStartTime = DateTime.now();
                    });
                    if (testToRetake.isNotEmpty) {
                      _startTest(testToRetake);
                    }
                  },
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Retake'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
