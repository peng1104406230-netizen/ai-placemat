abstract class KeyValueStore {
  String? readString(String key);

  bool? readBool(String key);

  int? readInt(String key);

  void writeString(String key, String value);

  void writeBool(String key, bool value);

  void writeInt(String key, int value);
}

class InMemoryKeyValueStore implements KeyValueStore {
  InMemoryKeyValueStore._();

  static final InMemoryKeyValueStore instance = InMemoryKeyValueStore._();

  final Map<String, Object?> _storage = <String, Object?>{};

  @override
  bool? readBool(String key) => _storage[key] as bool?;

  @override
  int? readInt(String key) => _storage[key] as int?;

  @override
  String? readString(String key) => _storage[key] as String?;

  @override
  void writeBool(String key, bool value) {
    _storage[key] = value;
  }

  @override
  void writeInt(String key, int value) {
    _storage[key] = value;
  }

  @override
  void writeString(String key, String value) {
    _storage[key] = value;
  }
}
