class LocalMealRecord {
  const LocalMealRecord({
    required this.mealId,
    required this.anonymousUserId,
    required this.startedAt,
    required this.endedAt,
    required this.intakeGrams,
    required this.avgSpeed,
    required this.peakSpeed,
    required this.reminderCount,
  });

  final String mealId;
  final String anonymousUserId;
  final DateTime startedAt;
  final DateTime endedAt;
  final double intakeGrams;
  final double avgSpeed;
  final double peakSpeed;
  final int reminderCount;
}

class LocalWeightSample {
  const LocalWeightSample({
    required this.mealId,
    required this.weightGram,
    required this.recordedAt,
  });

  final String mealId;
  final double weightGram;
  final DateTime recordedAt;
}

class LocalReminderEvent {
  const LocalReminderEvent({
    required this.mealId,
    required this.reminderText,
    required this.vibrationEnabled,
    required this.popupEnabled,
    required this.voiceEnabled,
    required this.triggeredAt,
  });

  final String mealId;
  final String reminderText;
  final bool vibrationEnabled;
  final bool popupEnabled;
  final bool voiceEnabled;
  final DateTime triggeredAt;
}

abstract class MealRecordStore {
  Future<void> saveMeal(LocalMealRecord meal);

  Future<List<LocalMealRecord>> listMeals();
}

abstract class WeightSampleStore {
  Future<void> saveWeightSample(LocalWeightSample sample);

  Future<List<LocalWeightSample>> listSamplesForMeal(String mealId);
}

abstract class ReminderEventStore {
  Future<void> saveReminderEvent(LocalReminderEvent event);

  Future<List<LocalReminderEvent>> listReminderEventsForMeal(String mealId);
}
