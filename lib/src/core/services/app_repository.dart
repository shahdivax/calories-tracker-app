import '../data/models.dart';
import 'drift_store_service.dart';

class AppRepository {
  const AppRepository(this._store);

  final DriftStoreService _store;

  Future<AppStateData> load() => _store.load();

  Future<void> save(AppStateData data) => _store.save(data);
}
