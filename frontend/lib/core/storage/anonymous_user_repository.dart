import '../../models/anonymous_user.dart';
import 'package:uuid/uuid.dart';

import 'key_value_store.dart';
import 'storage_keys.dart';

class AnonymousUserRepository {
  AnonymousUserRepository({
    required KeyValueStore store,
  }) : _store = store;

  final KeyValueStore _store;
  static const Uuid _uuid = Uuid();

  AnonymousUser loadOrCreate() {
    final String? savedId = _store.readString(StorageKeys.anonymousUserId);
    final String? savedCreatedAt =
        _store.readString(StorageKeys.anonymousUserCreatedAt);

    if (savedId != null && savedCreatedAt != null) {
      return AnonymousUser(
        anonymousUserId: savedId,
        createdAt: DateTime.tryParse(savedCreatedAt) ?? DateTime.now(),
        source: 'restored',
      );
    }

    final AnonymousUser user = AnonymousUser(
      anonymousUserId: _generateAnonymousUserId(),
      createdAt: DateTime.now(),
      source: 'local',
    );
    persist(user);
    return user;
  }

  void persist(AnonymousUser user) {
    _store.writeString(StorageKeys.anonymousUserId, user.anonymousUserId);
    _store.writeString(
      StorageKeys.anonymousUserCreatedAt,
      user.createdAt.toIso8601String(),
    );
  }

  String describePersistencePlan() {
    return 'shared_preferences-backed anonymousUserId persistence is active.';
  }

  String _generateAnonymousUserId() {
    return _uuid.v4();
  }
}
