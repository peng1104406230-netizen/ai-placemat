import '../core/ble/ble_gatt_debug_service.dart';
import '../core/ble/ble_scan_service.dart';
import '../core/engine/meal_engine.dart';
import '../core/engine/weight_processor.dart';
import '../core/parser/manufacturer_data_parser.dart';
import '../core/reminder/reminder_service.dart';
import '../core/storage/anonymous_user_store.dart';
import '../core/storage/key_value_store.dart';
import '../core/storage/local_db.dart';
import '../core/storage/settings_cache.dart';
import '../core/storage/shared_preferences_key_value_store.dart';
import '../providers/app_controller.dart';

class BootstrapService {
  Future<AppController> createController() async {
    final KeyValueStore keyValueStore =
        await SharedPreferencesKeyValueStore.create();
    final AppController controller = AppController(
      anonymousUserStore: AnonymousUserStore(store: keyValueStore),
      settingsCache: SettingsCache(store: keyValueStore),
      localDb: LocalDb(),
      bleScanService: const BleScanService(),
      bleGattDebugService: BleGattDebugService(),
      parser: ManufacturerDataParser.bh(),
      weightProcessor: WeightProcessor.basic(),
      mealEngine: MealEngine.basic(),
      reminderService: ReminderService.basic(),
    );
    await controller.initialize();
    return controller;
  }
}
