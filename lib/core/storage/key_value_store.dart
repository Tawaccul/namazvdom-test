abstract class KeyValueStore {
  String? getString(String key);
  Future<void> setString(String key, String value);

  List<String>? getStringList(String key);
  Future<void> setStringList(String key, List<String> value);

  Future<void> remove(String key);
}
