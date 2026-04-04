import 'key_value_store.dart';

class MemoryKeyValueStore implements KeyValueStore {
  final Map<String, Object> _store = {};

  @override
  String? getString(String key) => _store[key] as String?;

  @override
  Future<void> setString(String key, String value) async {
    _store[key] = value;
  }

  @override
  List<String>? getStringList(String key) =>
      (_store[key] as List?)?.cast<String>();

  @override
  Future<void> setStringList(String key, List<String> value) async {
    _store[key] = List<String>.from(value);
  }

  @override
  Future<void> remove(String key) async {
    _store.remove(key);
  }
}
