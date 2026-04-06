import '../../models/reminder_settings.dart';
import 'key_value_store.dart';
import 'storage_keys.dart';

class ReminderSettingsRepository {
  ReminderSettingsRepository({
    required KeyValueStore store,
  }) : _store = store;

  final KeyValueStore _store;

  ReminderSettings loadLocalOrDefault() {
    final bool reminderEnabled =
        _store.readBool(StorageKeys.reminderEnabled) ?? true;
    final int reminderFrequency =
        _store.readInt(StorageKeys.reminderFrequency) ?? 180;
    final int maxPicksPerMinute =
        _store.readInt(StorageKeys.maxPicksPerMinute) ??
        _store.readInt(StorageKeys.speedThresholdGramPerMin) ??
        8;
    final String reminderText =
        _store.readString(StorageKeys.reminderText) ?? '请放慢进食速度';
    final bool vibrationEnabled =
        _store.readBool(StorageKeys.vibrationEnabled) ?? true;
    final bool popupEnabled =
        _store.readBool(StorageKeys.popupEnabled) ?? true;
    final bool voiceEnabled =
        _store.readBool(StorageKeys.voiceEnabled) ?? false;
    final bool quietHoursEnabled =
        _store.readBool(StorageKeys.quietHoursEnabled) ?? true;
    final String quietHoursStart =
        _store.readString(StorageKeys.quietHoursStart) ?? '22:00';
    final String quietHoursEnd =
        _store.readString(StorageKeys.quietHoursEnd) ?? '07:00';

    return ReminderSettings(
      reminderEnabled: reminderEnabled,
      reminderFrequency: reminderFrequency,
      maxPicksPerMinute: maxPicksPerMinute.clamp(3, 20),
      reminderText: reminderText,
      vibrationEnabled: vibrationEnabled,
      popupEnabled: popupEnabled,
      voiceEnabled: voiceEnabled,
      quietHours: QuietHours(
        enabled: quietHoursEnabled,
        start: quietHoursStart,
        end: quietHoursEnd,
      ),
      syncState: 'localOnly',
    );
  }

  ReminderSettings saveLocal(ReminderSettings settings) {
    _store.writeBool(StorageKeys.reminderEnabled, settings.reminderEnabled);
    _store.writeInt(StorageKeys.reminderFrequency, settings.reminderFrequency);
    _store.writeInt(
      StorageKeys.maxPicksPerMinute,
      settings.maxPicksPerMinute,
    );
    _store.writeString(StorageKeys.reminderText, settings.reminderText);
    _store.writeBool(StorageKeys.vibrationEnabled, settings.vibrationEnabled);
    _store.writeBool(StorageKeys.popupEnabled, settings.popupEnabled);
    _store.writeBool(StorageKeys.voiceEnabled, settings.voiceEnabled);
    _store.writeBool(
      StorageKeys.quietHoursEnabled,
      settings.quietHours.enabled,
    );
    _store.writeString(StorageKeys.quietHoursStart, settings.quietHours.start);
    _store.writeString(StorageKeys.quietHoursEnd, settings.quietHours.end);

    return ReminderSettings(
      reminderEnabled: settings.reminderEnabled,
      reminderFrequency: settings.reminderFrequency,
      maxPicksPerMinute: settings.maxPicksPerMinute,
      reminderText: settings.reminderText,
      vibrationEnabled: settings.vibrationEnabled,
      popupEnabled: settings.popupEnabled,
      voiceEnabled: settings.voiceEnabled,
      quietHours: settings.quietHours,
      syncState: 'localOnly',
    );
  }

  String describeLocalFirstStrategy() {
    return 'load local cache first, use it for reminders immediately, and keep remote sync as a future TODO.';
  }
}
