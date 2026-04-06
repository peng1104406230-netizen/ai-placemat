import '../../models/anonymous_user.dart';
import 'anonymous_user_repository.dart';
import 'key_value_store.dart';

class AnonymousUserStore {
  AnonymousUserStore({
    KeyValueStore? store,
  }) : _repository = AnonymousUserRepository(
         store: store ?? InMemoryKeyValueStore.instance,
       );

  final AnonymousUserRepository _repository;

  AnonymousUser loadOrCreate() {
    return _repository.loadOrCreate();
  }

  String describePersistencePlan() {
    return _repository.describePersistencePlan();
  }
}
