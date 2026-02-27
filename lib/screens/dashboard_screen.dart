import 'package:flutter/material.dart';
import '../constants/app_theme.dart';
import '../constants/sample_data.dart';
import '../services/api_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _overview;
  List<Map<String, dynamic>> _attempts = [];
  List<Map<String, dynamic>> _progressData = [];
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMsg = null;
    });
    try {
      final results = await Future.wait([
        ApiService.getAnalyticsOverview(),
        ApiService.getTestHistory(),
        ApiService.getAnalyticsProgress(),
      ]);
      final overview = results[0] as Map<String, dynamic>;
      final attempts = (results[1] as List).cast<Map<String, dynamic>>();
      final progressRaw = results[2] as Map<String, dynamic>;
      final progressList = (progressRaw['weekly_progress'] as List? ?? [])
          .cast<Map<String, dynamic>>();
      if (mounted) {
        setState(() {
          _overview = overview;
          _attempts = attempts;
          _progressData = progressList;
          _isLoading = false;
        });
      }
    } catch (_) {
      // Fallback to sample data
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMsg = 'Using offline data';
        });
      }
    }
  }

  // ── helpers ──────────────────────────────────────────────────────────────

  String get _displayName {
    final user = ApiService.currentUser;
    if (user != null) {
      final name = user['full_name']?.toString() ?? SampleData.sampleName;
      return name.split(' ').first;
    }
    return SampleData.sampleName.split(' ').first;
  }

  String get _avatarInitials {
    final user = ApiService.currentUser;
    if (user != null) {
      final name = user['full_name']?.toString() ?? SampleData.sampleAvatar;
      final parts = name.trim().split(' ');
      if (parts.length >= 2)
        return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
    }
    return SampleData.sampleAvatar;
  }

  double get _latestScore {
    if (_attempts.isNotEmpty) {
      final pct = _attempts.first['percentage'];
      if (pct != null) return (pct as num).toDouble();
    }
    if (_overview != null) {
      final avg = _overview!['average_score'];
      if (avg != null) return (avg as num).toDouble();
    }
    return (SampleData.mockTestHistory.first['score'] as int).toDouble();
  }

  int get _testsTaken =>
      _overview?['total_tests_taken'] as int? ??
      SampleData.mockTestHistory.length;

  String get _avgScore {
    if (_overview != null) {
      final avg = _overview!['average_score'];
      if (avg != null) return '${(avg as num).toStringAsFixed(0)}%';
    }
    final scores = SampleData.mockTestHistory.map((t) => t['score'] as int);
    final sum = scores.reduce((a, b) => a + b);
    return '${(sum / scores.length).toStringAsFixed(0)}%';
  }

  String get _totalTime {
    if (_overview != null) {
      final mins = _overview!['total_time_spent_minutes'];
      if (mins != null) {
        final m = (mins as num).toInt();
        return m >= 60 ? '${m ~/ 60}h ${m % 60}m' : '${m}m';
      }
    }
    return '8h 55m';
  }

  List<Map<String, dynamic>> get _chartData {
    if (_progressData.isNotEmpty) return _progressData;
    return SampleData.weeklyProgress;
  }

  List<Map<String, dynamic>> get _recentTests {
    if (_attempts.isNotEmpty) return _attempts.take(5).toList();
    return SampleData.mockTestHistory;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_errorMsg != null)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.maths.withAlpha(25),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.wifi_off_rounded,
                      size: 16,
                      color: AppColors.maths,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _errorMsg!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.maths,
                      ),
                    ),
                  ],
                ),
              ),
            _buildGreeting(),
            const SizedBox(height: 24),
            _buildOverallScoreCard(_latestScore),
            const SizedBox(height: 20),
            _buildQuickStats(),
            const SizedBox(height: 24),
            const Text(
              'Weekly Progress',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            _buildProgressChart(),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent Tests',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                TextButton(onPressed: () {}, child: const Text('See All')),
              ],
            ),
            const SizedBox(height: 8),
            ..._recentTests.map((t) => _buildAttemptCard(t)),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildGreeting() {
    return Row(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.accent],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: Text(
              _avatarInitials,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hello, $_displayName! 👋',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            const Text(
              'Ready to ace your next exam?',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOverallScoreCard(double score) {
    final color = AppColors.gradeColor(score);
    final label = AppColors.gradeLabel(score);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withAlpha(80),
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
                const Text(
                  'Latest Score',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${score.toInt()}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 48,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.only(bottom: 8),
                      child: Text(
                        ' /100',
                        style: TextStyle(color: Colors.white60, fontSize: 18),
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
                    border: Border.all(color: color.withAlpha(100)),
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
          // Circular progress
          SizedBox(
            width: 90,
            height: 90,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 90,
                  height: 90,
                  child: CircularProgressIndicator(
                    value: score / 100,
                    strokeWidth: 8,
                    backgroundColor: Colors.white.withAlpha(30),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                    strokeCap: StrokeCap.round,
                  ),
                ),
                Text(
                  '${score.toInt()}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    return Row(
      children: [
        _statCard(
          Icons.quiz_outlined,
          '$_testsTaken',
          'Tests Taken',
          AppColors.physics,
        ),
        const SizedBox(width: 12),
        _statCard(
          Icons.trending_up,
          _avgScore,
          'Avg Score',
          AppColors.chemistry,
        ),
        const SizedBox(width: 12),
        _statCard(
          Icons.timer_outlined,
          _totalTime,
          'Total Time',
          AppColors.maths,
        ),
      ],
    );
  }

  Widget _statCard(IconData icon, String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withAlpha(20),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withAlpha(25),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressChart() {
    final data = _chartData;
    final maxScore = 100.0;

    return Container(
      height: 180,
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: data.map((d) {
          // API format: avg_score + week_start; sample: score + week
          final rawScore = d['avg_score'] ?? d['score'] ?? 0;
          final score = (rawScore as num).toDouble();
          final height = (score / maxScore) * 120;
          final color = AppColors.gradeColor(score);
          // Label: use week_start (trim to 'W1' style) or 'week'
          String label = d['week'] as String? ?? '';
          if (label.isEmpty) {
            final ws = d['week_start']?.toString() ?? '';
            label = ws.length >= 10 ? ws.substring(5, 10) : ws;
          }
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
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
                        colors: [color.withAlpha(180), color],
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textLight,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  /// Renders a card for both API TestAttemptOut and sample-data format.
  Widget _buildAttemptCard(Map<String, dynamic> item) {
    // API format uses 'percentage'; sample uses 'score' (0-100 int)
    final rawScore = item['percentage'] ?? item['score'] ?? 0;
    final score = (rawScore as num).toDouble();
    final color = AppColors.gradeColor(score);
    final label = AppColors.gradeLabel(score);
    // Title
    final title =
        item['name']?.toString() ?? item['test_id']?.toString() ?? 'Test';
    // Date
    final date =
        item['created_at']?.toString().split('T').first ??
        item['date']?.toString() ??
        '';
    // Duration
    final dur = item['time_taken_minutes'] != null
        ? '${item['time_taken_minutes']} min'
        : item['duration']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withAlpha(25),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                '${score.toInt()}',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
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
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$date${dur.isNotEmpty ? '  •  $dur' : ''}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textLight,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color.withAlpha(25),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
