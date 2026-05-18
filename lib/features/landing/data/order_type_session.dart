import 'package:shared_preferences/shared_preferences.dart';

enum OrderType { bookingDineIn, onSpotDineIn, pickup }

class OrderTypeSession {
  static const _key = 'order_type';
  static OrderType? _cached;

  static String toApiValue(OrderType type) {
    return switch (type) {
      OrderType.bookingDineIn => 'booking_dine_in',
      OrderType.onSpotDineIn => 'dine_in',
      OrderType.pickup => 'pickup',
    };
  }

  static String toLabel(OrderType type) {
    return switch (type) {
      OrderType.bookingDineIn => 'Booking dine-in',
      OrderType.onSpotDineIn => 'Dine-in',
      OrderType.pickup => 'Take away',
    };
  }

  static Future<void> set(OrderType type) async {
    _cached = type;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, toApiValue(type));
  }

  static Future<OrderType?> get() async {
    if (_cached != null) return _cached;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    _cached = _fromApiValue(raw);
    return _cached;
  }

  static Future<void> clear() async {
    _cached = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }

  static OrderType? _fromApiValue(String? raw) {
    if (raw == 'booking_dine_in') return OrderType.bookingDineIn;
    if (raw == 'dine_in') return OrderType.onSpotDineIn;
    if (raw == 'pickup') return OrderType.pickup;
    return null;
  }
}
