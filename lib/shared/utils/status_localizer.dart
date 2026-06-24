String localizedPaymentStatusLabel(String status) {
  final value = status.trim().toUpperCase();
  return switch (value) {
    'PAID' || 'SUCCESS' || 'SETTLEMENT' => 'Lunas',
    'PENDING' || 'UNPAID' => 'Menunggu pembayaran',
    'FAILED' => 'Gagal',
    'CANCELED' || 'CANCELLED' => 'Dibatalkan',
    'EXPIRED' => 'Kedaluwarsa',
    'PROCESSING' => 'Sedang diproses',
    'CONFIRMED' => 'Terkonfirmasi',
    _ => _humanizeLabel(status),
  };
}

String localizedOrderStatusLabel(String status) {
  final value = status.trim().toUpperCase();
  return switch (value) {
    'PENDING_PAYMENT' => 'Menunggu pembayaran',
    'PAYMENT_FAILED' => 'Pembayaran gagal',
    'CONFIRMED' => 'Terkonfirmasi',
    'IN_QUEUE' => 'Dalam antrean',
    'IN_PROGRESS' => 'Sedang diproses',
    'READY' => 'Siap disajikan',
    'DELIVERED' || 'SUCCESS' => 'Selesai',
    'CANCELED' || 'CANCELLED' => 'Dibatalkan',
    'EXPIRED' => 'Kedaluwarsa',
    _ => _humanizeLabel(status),
  };
}

String localizedOrderTypeLabel(
  String orderTypeKey, {
  int? tableNumber,
  String bookingScheduleLabel = '',
}) {
  final tablePart = tableNumber != null ? ' • Meja $tableNumber' : '';
  final schedulePart = bookingScheduleLabel.isNotEmpty ? ' • $bookingScheduleLabel' : '';
  final value = orderTypeKey.trim().toLowerCase();

  return switch (value) {
    'booking' || 'booking_dine_in' => 'Booking meja$tablePart$schedulePart',
    'dine_in' || 'dineindirect' => 'Makan di tempat$tablePart',
    'pickup' => 'Ambil sendiri',
    'take_away' => 'Bawa pulang',
    _ => _humanizeLabel(orderTypeKey),
  };
}

String localizedOrderTypePickerLabel(String raw) {
  final value = raw.trim().toLowerCase();
  return switch (value) {
    'booking dine-in' || 'booking_dine_in' => 'Booking meja',
    'dine-in' || 'dine in' || 'dine_in' => 'Makan di tempat',
    'pickup' => 'Ambil sendiri',
    'take away (qr)' || 'take_away' => 'Bawa pulang (QR)',
    _ => _humanizeLabel(raw),
  };
}

String _humanizeLabel(String raw) {
  final cleaned = raw.trim().replaceAll('_', ' ').replaceAll(RegExp(r'\s+'), ' ');
  if (cleaned.isEmpty) return '-';
  final lower = cleaned.toLowerCase();
  return lower
      .split(' ')
      .map((word) {
        if (word.isEmpty) return word;
        return word[0].toUpperCase() + word.substring(1);
      })
      .join(' ');
}
