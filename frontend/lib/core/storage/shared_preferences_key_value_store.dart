import 'package:shared_preferences/shared_preferences.dart';

import 'key_value_store.dart';

class SharedPreferencesKeyValueStore implements KeyValueStore {
  SharedPreferencesKeyValueStore._(this._preferences);

  final SharedPreferences _preferences;

  static Future<SharedPreferencesKeyValueStore> create() async {
    final preferences = await SharedPreferences.getInstance();
    return SharedPreferencesKeyValueStore._(preferences);
  }

  @override
  bool? readBool(String key) => _preferences.getBool(key);

  @override
  int? readInt(String key) => _preferences.getInt(key);

  @override
  String? readString(String key) => _preferences.getString(key);

  @override
  void writeBool(String key, bool value) {
    _preferences.setBool(key, value);
  }

  @override
  void writeInt(String key, int value) {
    _preferences.setInt(key, value);
  }

  @override
  void writeString(String key, String value) {
    _preferences.setString(key, value);
  }
}
