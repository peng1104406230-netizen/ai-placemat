class QuietHours {
  const QuietHours({
    required this.enabled,
    required this.start,
    required this.end,
  });

  final bool enabled;
  final String start;
  final String end;

  QuietHours copyWith({
    bool? enabled,
    String? start,
    String? end,
  }) {
    return QuietHours(
      enabled: enabled ?? this.enabled,
      start: start ?? this.start,
      end: end ?? this.end,
    );
  }
}

class ReminderSettings {
  const ReminderSettings({
    required this.reminderEnabled,
    required this.reminderFrequency,
    required this.maxPicksPerMinute,
    required this.reminderText,
    required this.vibrationEnabled,
    required this.popupEnabled,
    required this.voiceEnabled,
    required this.quietHours,
    required this.syncState,
  });

  final bool reminderEnabled;
  final int reminderFrequency;
  final int maxPicksPerMinute;
  final String reminderText;
  final bool vibrationEnabled;
  final bool popupEnabled;
  final bool voiceEnabled;
  final QuietHours quietHours;
  final String syncState;

  bool get hasAnyDeliveryMethod =>
      vibrationEnabled || popupEnabled || voiceEnabled;

  ReminderSettings copyWith({
    bool? reminderEnabled,
    int? reminderFrequency,
    int? maxPicksPerMinute,
    String? reminderText,
    bool? vibrationEnabled,
    bool? popupEnabled,
    bool? voiceEnabled,
    QuietHours? quietHours,
    String? syncState,
  }) {
    return ReminderSettings(
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      reminderFrequency: reminderFrequency ?? this.reminderFrequency,
      maxPicksPerMinute: maxPicksPerMinute ?? this.maxPicksPerMinute,
      reminderText: reminderText ?? this.reminderText,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      popupEnabled: popupEnabled ?? this.popupEnabled,
      voiceEnabled: voiceEnabled ?? this.voiceEnabled,
      quietHours: quietHours ?? this.quietHours,
      syncState: syncState ?? this.syncState,
    );
  }
}
