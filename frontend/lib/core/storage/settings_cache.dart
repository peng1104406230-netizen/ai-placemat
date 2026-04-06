import '../../models/reminder_settings.dart';
import 'key_value_store.dart';
import 'reminder_settings_repository.dart';

class SettingsCache {
  SettingsCache({
    KeyValueStore? store,
  }) : _repository = ReminderSettingsRepository(
         store: store ?? InMemoryKeyValueStore.instance,
       );

  final ReminderSettingsRepository _repository;

  ReminderSettings load() {
    return _repository.loadLocalOrDefault();
  }

  ReminderSettings save(ReminderSettings settings) {
    return _repository.saveLocal(settings);
  }

  String describeLocalFirstStrategy() {
    return _repository.describeLocalFirstStrategy();
  }
}
