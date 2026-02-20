import 'package:flutter/material.dart';
import '../constants/app_theme.dart';
import '../constants/sample_data.dart';

class TestScreen extends StatefulWidget {
  const TestScreen({super.key});

  @override
  State<TestScreen> createState() => _TestScreenState();
}

class _TestScreenState extends State<TestScreen> {
  final questions = SampleData.mockQuestions;
  int _currentIndex = 0;
  final Map<int, int?> _selectedAnswers = {};
  bool _submitted = false;

  Map<String, dynamic> get _currentQ => questions[_currentIndex];

  void _selectOption(int optionIndex) {
    if (_submitted) return;
    setState(() {
      _selectedAnswers[_currentIndex] = optionIndex;
    });
  }

  void _nextQuestion() {
    if (_currentIndex < questions.length - 1) {
      setState(() => _currentIndex++);
    }
  }

  void _prevQuestion() {
    if (_currentIndex > 0) {
      setState(() => _currentIndex--);
    }
  }

  void _submitTest() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Submit Test?'),
        content: Text(
          'You have answered ${_selectedAnswers.length}/${questions.length} questions. Are you sure you want to submit?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() => _submitted = true);
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  int get _score {
    int correct = 0;
    for (int i = 0; i < questions.length; i++) {
      if (_selectedAnswers[i] == questions[i]['correct']) correct++;
    }
    return correct;
  }

  @override
  Widget build(BuildContext context) {
    if (_submitted) return _buildResultView();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Test header
          _buildTestHeader(),
          const SizedBox(height: 20),
          // Question navigator pills
          _buildQuestionNavigator(),
          const SizedBox(height: 24),
          // Question card
          _buildQuestionCard(),
          const SizedBox(height: 20),
          // Options
          ..._buildOptions(),
          const SizedBox(height: 28),
          // Navigation buttons
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
                const Text(
                  'Practice Test',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Question ${_currentIndex + 1} of ${questions.length}',
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
                  '${_selectedAnswers.length}/${questions.length}',
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
        itemCount: questions.length,
        itemBuilder: (_, i) {
          final isActive = i == _currentIndex;
          final isAnswered = _selectedAnswers.containsKey(i);
          return GestureDetector(
            onTap: () => setState(() => _currentIndex = i),
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
          child: _currentIndex < questions.length - 1
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
    final percentage = (_score / questions.length) * 100;
    final color = AppColors.gradeColor(percentage);
    final label = AppColors.gradeLabel(percentage);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 20),
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
                            '${percentage.toInt()}%',
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
                  'You scored $_score out of ${questions.length}',
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
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
          ...List.generate(questions.length, (i) {
            final q = questions[i];
            final selected = _selectedAnswers[i];
            final correct = q['correct'] as int;
            final isCorrect = selected == correct;
            final options = q['options'] as List<String>;

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
                  if (selected != null)
                    Text(
                      'Your answer: ${options[selected]}',
                      style: TextStyle(
                        fontSize: 12,
                        color: isCorrect ? AppColors.success : AppColors.error,
                      ),
                    ),
                  if (!isCorrect)
                    Text(
                      'Correct answer: ${options[correct]}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.success,
                      ),
                    ),
                ],
              ),
            );
          }),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                setState(() {
                  _currentIndex = 0;
                  _selectedAnswers.clear();
                  _submitted = false;
                });
              },
              child: const Text('Retake Test'),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
