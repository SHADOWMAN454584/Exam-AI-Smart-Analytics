import 'package:flutter/material.dart';
import '../constants/app_theme.dart';
import '../constants/sample_data.dart';
import '../services/api_service.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  bool _isLoading = true;
  bool _usingFallback = false;
  Map<String, dynamic>? _overview;
  Map<String, dynamic>? _progressData;
  final Map<String, Map<String, dynamic>> _subjectData = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        ApiService.getAnalyticsOverview(),
        ApiService.getAnalyticsProgress(),
        ApiService.getSubjectAnalytics('Physics'),
        ApiService.getSubjectAnalytics('Chemistry'),
        ApiService.getSubjectAnalytics('Maths'),
      ]);
      if (mounted) {
        setState(() {
          _overview = results[0] as Map<String, dynamic>?;
          _progressData = results[1] as Map<String, dynamic>?;
          _subjectData['Physics'] = (results[2] as Map<String, dynamic>?) ?? {};
          _subjectData['Chemistry'] =
              (results[3] as Map<String, dynamic>?) ?? {};
          _subjectData['Maths'] = (results[4] as Map<String, dynamic>?) ?? {};
          _usingFallback = false;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted)
        setState(() {
          _usingFallback = true;
          _isLoading = false;
        });
    }
  }

  double get _overallPct =>
      (_overview?['overall_percentage'] as num?)?.toDouble() ?? 76.4;

  List<Map<String, dynamic>> get _weeklyChartData {
    final weekly = (_progressData?['weekly_progress'] as List?)
        ?.cast<Map<String, dynamic>>();
    if (weekly != null && weekly.isNotEmpty) {
      return weekly
          .map(
            (w) => {
              'score': (w['avg_score'] as num?)?.toDouble() ?? 0.0,
              'week': (w['week_start'] as String?)?.substring(5) ?? '?',
            },
          )
          .toList();
    }
    return SampleData.weeklyProgress
        .map(
          (d) => {
            'score': (d['score'] as int).toDouble(),
            'week': d['week'] as String,
          },
        )
        .toList();
  }

  double _subjectScore(String subject) {
    final sp = _overview?['subject_performance'] as Map<String, dynamic>?;
    if (sp != null && sp.containsKey(subject)) {
      final e = sp[subject] as Map<String, dynamic>;
      return (e['avg_score'] as num?)?.toDouble() ??
          (e['percentage'] as num?)?.toDouble() ??
          0.0;
    }
    final sa = _subjectData[subject];
    if (sa != null) return (sa['avg_score'] as num?)?.toDouble() ?? 0.0;
    return subject == 'Physics'
        ? 74.5
        : subject == 'Chemistry'
        ? 78.2
        : 76.4;
  }

  List<_TopicScore> _topicsFor(String subject) {
    final sa = _subjectData[subject];
    final topics = (sa?['topic_breakdown'] as List?)
        ?.cast<Map<String, dynamic>>();
    if (topics != null && topics.isNotEmpty) {
      return topics
          .map(
            (t) => _TopicScore(
              t['topic'] as String? ?? '?',
              (t['avg_score'] as num?)?.toDouble() ??
                  (t['correct'] != null && t['total'] != null
                      ? (t['correct'] as num) / (t['total'] as num) * 100
                      : 0.0),
            ),
          )
          .toList();
    }
    if (subject == 'Physics') {
      return [
        _TopicScore('Mechanics', 82),
        _TopicScore('Electrostatics', 68),
        _TopicScore('Optics', 75),
        _TopicScore('Thermodynamics', 88),
        _TopicScore('Modern Physics', 60),
      ];
    } else if (subject == 'Chemistry') {
      return [
        _TopicScore('Organic', 72),
        _TopicScore('Inorganic', 85),
        _TopicScore('Physical', 78),
        _TopicScore('Coordination', 65),
      ];
    }
    return [
      _TopicScore('Calculus', 82),
      _TopicScore('Algebra', 78),
      _TopicScore('Coordinate Geo', 70),
      _TopicScore('Trigonometry', 85),
      _TopicScore('Probability', 67),
    ];
  }

  List<String> _strengthTopics() {
    final all =
        [
            'Physics',
            'Chemistry',
            'Maths',
          ].expand(_topicsFor).where((t) => t.score >= 80).toList()
          ..sort((a, b) => b.score.compareTo(a.score));
    return all.isEmpty
        ? ['Thermodynamics', 'Inorganic Chem', 'Trigonometry']
        : all.take(3).map((t) => t.name).toList();
  }

  List<String> _weakTopics() {
    final all =
        [
            'Physics',
            'Chemistry',
            'Maths',
          ].expand(_topicsFor).where((t) => t.score < 70).toList()
          ..sort((a, b) => a.score.compareTo(b.score));
    return all.isEmpty
        ? ['Modern Physics', 'Coordination', 'Probability']
        : all.take(3).map((t) => t.name).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_usingFallback)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.orange.withAlpha(25),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.orange.withAlpha(80)),
            ),
            child: const Row(
              children: [
                Icon(Icons.wifi_off, color: Colors.orange, size: 16),
                SizedBox(width: 8),
                Text(
                  'Offline mode — showing sample data',
                  style: TextStyle(fontSize: 12, color: Colors.orange),
                ),
              ],
            ),
          ),
        const Text(
          'Progress Analytics 📊',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Track your preparation journey',
          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 24),
        _buildOverallPerformance(),
        const SizedBox(height: 20),
        const Text(
          'Score Trend',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        _buildScoreTrend(),
        const SizedBox(height: 24),
        const Text(
          'Subject Performance',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        _buildSubjectCard(
          'Physics',
          _subjectScore('Physics'),
          AppColors.physics,
          _topicsFor('Physics'),
        ),
        const SizedBox(height: 12),
        _buildSubjectCard(
          'Chemistry',
          _subjectScore('Chemistry'),
          AppColors.chemistry,
          _topicsFor('Chemistry'),
        ),
        const SizedBox(height: 12),
        _buildSubjectCard(
          'Mathematics',
          _subjectScore('Maths'),
          AppColors.maths,
          _topicsFor('Maths'),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: _buildStrengthWeakCard(
                'Strengths 💪',
                AppColors.success,
                _strengthTopics(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStrengthWeakCard(
                'Weak Areas ⚡',
                AppColors.error,
                _weakTopics(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        const Text(
          'Test Statistics',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        _buildStatGrid(),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildOverallPerformance() {
    final overall = _overallPct;
    final color = AppColors.gradeColor(overall);
    final label = AppColors.gradeLabel(overall);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withAlpha(60),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Overall Performance',
                  style: TextStyle(
                    color: Colors.white.withAlpha(200),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      '76.4%',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 40,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          Icon(
                            Icons.trending_up,
                            color: AppColors.success,
                            size: 18,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '+${((_overview?['improvement'] as num?)?.toDouble() ?? 5.2).toStringAsFixed(1)}%',
                            style: TextStyle(
                              color: AppColors.success,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: color.withAlpha(50),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 80,
            height: 80,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 80,
                  height: 80,
                  child: CircularProgressIndicator(
                    value: overall / 100,
                    strokeWidth: 8,
                    backgroundColor: Colors.white.withAlpha(30),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                    strokeCap: StrokeCap.round,
                  ),
                ),
                Text(
                  '${overall.toInt()}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreTrend() {
    final data = _weeklyChartData;
    return Container(
      height: 200,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Last 7 Weeks',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.success.withAlpha(20),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.trending_up, color: AppColors.success, size: 14),
                    SizedBox(width: 4),
                    Text(
                      'Improving',
                      style: TextStyle(
                        color: AppColors.success,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: data.map((d) {
                final score = d['score'] as double;
                final height = (score / 100) * 100;
                final color = AppColors.gradeColor(score);
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          '${score.toInt()}',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: color,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          height: height,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [color.withAlpha(160), color],
                            ),
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          d['week'] as String,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectCard(
    String subject,
    double score,
    Color color,
    List<_TopicScore> topics,
  ) {
    final gradeColor = AppColors.gradeColor(score);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withAlpha(25),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    subject[0],
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subject,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${score.toStringAsFixed(1)}% average',
                      style: TextStyle(
                        fontSize: 12,
                        color: gradeColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: gradeColor.withAlpha(20),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  AppColors.gradeLabel(score),
                  style: TextStyle(
                    color: gradeColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...topics.map((t) => _topicProgressBar(t.name, t.score, color)),
        ],
      ),
    );
  }

  Widget _topicProgressBar(String topic, double score, Color subjectColor) {
    final color = AppColors.gradeColor(score);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(
              topic,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: score / 100,
                minHeight: 8,
                backgroundColor: AppColors.divider,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 38,
            child: Text(
              '${score.toInt()}%',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStrengthWeakCard(String title, Color color, List<String> items) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withAlpha(10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withAlpha(40)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 10),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Icon(
                    color == AppColors.success
                        ? Icons.check_circle_outline
                        : Icons.warning_amber_rounded,
                    size: 16,
                    color: color,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatGrid() {
    final accuracy = (_overview?['accuracy'] as num?)?.toDouble() ?? 72.0;
    final testsTaken = (_overview?['total_tests'] as num?)?.toInt() ?? 12;
    final avgTime = (_overview?['avg_time'] as num?)?.toDouble() ?? 2.1;
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _statTile(
          'Accuracy',
          '${accuracy.toInt()}%',
          Icons.gps_fixed,
          AppColors.physics,
        ),
        _statTile(
          'Avg Speed',
          '${avgTime.toStringAsFixed(1)} min/Q',
          Icons.speed,
          AppColors.chemistry,
        ),
        _statTile(
          'Tests Taken',
          '$testsTaken',
          Icons.assignment,
          AppColors.maths,
        ),
        _statTile(
          'Streak',
          '5 days',
          Icons.local_fire_department,
          AppColors.biology,
        ),
      ],
    );
  }

  Widget _statTile(String label, String value, IconData icon, Color color) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(16),
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
              color: color.withAlpha(20),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TopicScore {
  final String name;
  final double score;
  _TopicScore(this.name, this.score);
}
