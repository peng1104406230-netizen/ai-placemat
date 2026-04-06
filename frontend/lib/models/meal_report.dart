class MealReport {
  const MealReport({
    required this.mealId,
    required this.durationSeconds,
    required this.intakeGrams,
    required this.avgSpeed,
    required this.peakSpeed,
    required this.reminderCount,
    required this.summaryText,
    this.aiSuggestion,
    this.reportSource = 'localDb',
  });

  final String mealId;
  final int durationSeconds;
  final double intakeGrams;
  final double avgSpeed;
  final double peakSpeed;
  final int reminderCount;
  final String summaryText;
  final String? aiSuggestion;
  final String reportSource;

  factory MealReport.placeholder() {
    return const MealReport(
      mealId: 'no_meal',
      durationSeconds: 0,
      intakeGrams: 0,
      avgSpeed: 0,
      peakSpeed: 0,
      reminderCount: 0,
      summaryText: '还没有真实本地餐次记录。先去实时页开始一次真实用餐，报告页就会显示出来。',
      aiSuggestion: null,
      reportSource: 'noRealMeal',
    );
  }

  MealReport copyWith({
    String? mealId,
    int? durationSeconds,
    double? intakeGrams,
    double? avgSpeed,
    double? peakSpeed,
    int? reminderCount,
    String? summaryText,
    String? aiSuggestion,
    String? reportSource,
  }) {
    return MealReport(
      mealId: mealId ?? this.mealId,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      intakeGrams: intakeGrams ?? this.intakeGrams,
      avgSpeed: avgSpeed ?? this.avgSpeed,
      peakSpeed: peakSpeed ?? this.peakSpeed,
      reminderCount: reminderCount ?? this.reminderCount,
      summaryText: summaryText ?? this.summaryText,
      aiSuggestion: aiSuggestion ?? this.aiSuggestion,
      reportSource: reportSource ?? this.reportSource,
    );
  }
}
