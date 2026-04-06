class TrendSummary {
  const TrendSummary({
    required this.days,
    required this.avgSpeed,
    required this.fastMealCount,
    required this.improvementRate,
    required this.summaryText,
    this.aiTrendInsight,
  });

  final int days;
  final double avgSpeed;
  final int fastMealCount;
  final double improvementRate;
  final String summaryText;
  final String? aiTrendInsight;

  factory TrendSummary.placeholder() {
    return const TrendSummary(
      days: 7,
      avgSpeed: 0,
      fastMealCount: 0,
      improvementRate: 0,
      summaryText: '最近 7 天还没有真实本地餐次数据。完成真实用餐后，这里会自动生成趋势。',
      aiTrendInsight: null,
    );
  }

  TrendSummary copyWith({
    int? days,
    double? avgSpeed,
    int? fastMealCount,
    double? improvementRate,
    String? summaryText,
    String? aiTrendInsight,
  }) {
    return TrendSummary(
      days: days ?? this.days,
      avgSpeed: avgSpeed ?? this.avgSpeed,
      fastMealCount: fastMealCount ?? this.fastMealCount,
      improvementRate: improvementRate ?? this.improvementRate,
      summaryText: summaryText ?? this.summaryText,
      aiTrendInsight: aiTrendInsight ?? this.aiTrendInsight,
    );
  }
}
