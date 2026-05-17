import 'package:shared_preferences/shared_preferences.dart';

class TableSession {
  static const _key = 'table_id';
  static int? _cached;

  static Future<void> set(int tableId) async {
    _cached = tableId;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_key, tableId);
  }

  static Future<int?> get() async {
    if (_cached != null) return _cached;
    final prefs = await SharedPreferences.getInstance();
    _cached = prefs.getInt(_key);
    return _cached;
  }

  static Future<void> clear() async {
    _cached = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
