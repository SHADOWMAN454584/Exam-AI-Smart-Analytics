/// Sample account credentials for demo login.
class SampleData {
  static const String sampleEmail = 'student@exam.ai';
  static const String samplePassword = 'test1234';
  static const String sampleName = 'Arjun Sharma';
  static const String sampleAvatar = 'AS';

  /// Mock test history data
  static List<Map<String, dynamic>> get mockTestHistory => [
    {
      'id': '1',
      'name': 'JEE Main Mock Test 1',
      'date': '2026-02-15',
      'score': 82,
      'total': 100,
      'duration': '2h 45m',
      'subjects': {
        'Physics': {'score': 28, 'total': 33, 'percentage': 84.8},
        'Chemistry': {'score': 25, 'total': 33, 'percentage': 75.8},
        'Maths': {'score': 29, 'total': 34, 'percentage': 85.3},
      },
    },
    {
      'id': '2',
      'name': 'NEET Mock Test 3',
      'date': '2026-02-10',
      'score': 65,
      'total': 100,
      'duration': '3h 10m',
      'subjects': {
        'Physics': {'score': 18, 'total': 25, 'percentage': 72.0},
        'Chemistry': {'score': 20, 'total': 25, 'percentage': 80.0},
        'Biology': {'score': 27, 'total': 50, 'percentage': 54.0},
      },
    },
    {
      'id': '3',
      'name': 'JEE Advanced Practice',
      'date': '2026-02-05',
      'score': 71,
      'total': 100,
      'duration': '3h 0m',
      'subjects': {
        'Physics': {'score': 22, 'total': 33, 'percentage': 66.7},
        'Chemistry': {'score': 26, 'total': 33, 'percentage': 78.8},
        'Maths': {'score': 23, 'total': 34, 'percentage': 67.6},
      },
    },
  ];

  /// Mock questions for test interface
  static List<Map<String, dynamic>> get mockQuestions => [
    {
      'id': 1,
      'subject': 'Physics',
      'question':
          'A ball is thrown vertically upward with a velocity of 20 m/s. What is the maximum height reached?',
      'options': ['10 m', '20 m', '30 m', '40 m'],
      'correct': 1,
      'topic': 'Kinematics',
      'difficulty': 'Medium',
    },
    {
      'id': 2,
      'subject': 'Chemistry',
      'question': 'Which of the following is the strongest acid?',
      'options': ['HF', 'HCl', 'HBr', 'HI'],
      'correct': 3,
      'topic': 'Chemical Bonding',
      'difficulty': 'Easy',
    },
    {
      'id': 3,
      'subject': 'Maths',
      'question': 'The value of ∫₀¹ x²dx is:',
      'options': ['1/2', '1/3', '1/4', '1'],
      'correct': 1,
      'topic': 'Integration',
      'difficulty': 'Easy',
    },
    {
      'id': 4,
      'subject': 'Physics',
      'question': 'The SI unit of electric field intensity is:',
      'options': ['N/C', 'V/m', 'Both N/C and V/m', 'J/C'],
      'correct': 2,
      'topic': 'Electrostatics',
      'difficulty': 'Easy',
    },
    {
      'id': 5,
      'subject': 'Chemistry',
      'question': 'The number of sigma bonds in ethene (C₂H₄) is:',
      'options': ['3', '4', '5', '6'],
      'correct': 2,
      'topic': 'Organic Chemistry',
      'difficulty': 'Medium',
    },
  ];

  /// Mock recommendations
  static List<Map<String, dynamic>> get mockRecommendations => [
    {
      'title': 'Focus on Kinematics',
      'description':
          'Your accuracy in projectile motion questions dropped 15% in the last test. Practice 2D projectile problems.',
      'priority': 'High',
      'subject': 'Physics',
      'estimatedTime': '45 min',
      'type': 'practice',
    },
    {
      'title': 'Review Organic Reactions',
      'description':
          'Named reactions accuracy is at 55%. Revise key mechanisms: SN1, SN2, E1, E2.',
      'priority': 'High',
      'subject': 'Chemistry',
      'estimatedTime': '1 hour',
      'type': 'revision',
    },
    {
      'title': 'Integration Techniques',
      'description':
          'Good progress! Attempt 10 more integration-by-parts questions to solidify your understanding.',
      'priority': 'Medium',
      'subject': 'Maths',
      'estimatedTime': '30 min',
      'type': 'practice',
    },
    {
      'title': 'Take a Full Mock Test',
      'description':
          'It\'s been 5 days since your last full-length mock. Schedule one to maintain test stamina.',
      'priority': 'Medium',
      'subject': 'General',
      'estimatedTime': '3 hours',
      'type': 'test',
    },
    {
      'title': 'Revise Thermodynamics',
      'description':
          'Strong topic for you (88% accuracy). A quick revision will keep it fresh.',
      'priority': 'Low',
      'subject': 'Physics',
      'estimatedTime': '20 min',
      'type': 'revision',
    },
  ];

  // Weekly progress data (for chart)
  static List<Map<String, dynamic>> get weeklyProgress => [
    {'week': 'W1', 'score': 58},
    {'week': 'W2', 'score': 62},
    {'week': 'W3', 'score': 65},
    {'week': 'W4', 'score': 71},
    {'week': 'W5', 'score': 68},
    {'week': 'W6', 'score': 76},
    {'week': 'W7', 'score': 82},
  ];
}
