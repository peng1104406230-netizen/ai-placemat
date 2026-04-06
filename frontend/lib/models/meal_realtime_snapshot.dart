class MealRealtimeSnapshot {
  const MealRealtimeSnapshot({
    required this.status,
    required this.weightGram,
    required this.rawWeightGram,
    required this.avgSpeed,
    required this.peakSpeed,
    required this.isTooFast,
    required this.reminderCount,
    required this.lastUpdatedAt,
    required this.statusNote,
    required this.pickCountLast60s,
    required this.avgPickGrams,
    required this.peakPickFrequency,
  });

  final String status;
  final double weightGram;
  final double rawWeightGram;
  final double avgSpeed;
  final double peakSpeed;
  final bool isTooFast;
  final int reminderCount;
  final DateTime lastUpdatedAt;
  final String statusNote;
  final int pickCountLast60s;
  final double avgPickGrams;
  final double peakPickFrequency;

  factory MealRealtimeSnapshot.initial() {
    return MealRealtimeSnapshot(
      status: 'idle',
      weightGram: 0,
      rawWeightGram: 0,
      avgSpeed: 0,
      peakSpeed: 0,
      isTooFast: false,
      reminderCount: 0,
      lastUpdatedAt: DateTime.fromMillisecondsSinceEpoch(0),
      statusNote: '等待重量流输入。',
      pickCountLast60s: 0,
      avgPickGrams: 0,
      peakPickFrequency: 0,
    );
  }

  MealRealtimeSnapshot copyWith({
    String? status,
    double? weightGram,
    double? rawWeightGram,
    double? avgSpeed,
    double? peakSpeed,
    bool? isTooFast,
    int? reminderCount,
    DateTime? lastUpdatedAt,
    String? statusNote,
    int? pickCountLast60s,
    double? avgPickGrams,
    double? peakPickFrequency,
  }) {
    return MealRealtimeSnapshot(
      status: status ?? this.status,
      weightGram: weightGram ?? this.weightGram,
      rawWeightGram: rawWeightGram ?? this.rawWeightGram,
      avgSpeed: avgSpeed ?? this.avgSpeed,
      peakSpeed: peakSpeed ?? this.peakSpeed,
      isTooFast: isTooFast ?? this.isTooFast,
      reminderCount: reminderCount ?? this.reminderCount,
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
      statusNote: statusNote ?? this.statusNote,
      pickCountLast60s: pickCountLast60s ?? this.pickCountLast60s,
      avgPickGrams: avgPickGrams ?? this.avgPickGrams,
      peakPickFrequency: peakPickFrequency ?? this.peakPickFrequency,
    );
  }
}
