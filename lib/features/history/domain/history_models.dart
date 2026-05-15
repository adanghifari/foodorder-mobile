class HistoryOrderItem {
  const HistoryOrderItem({
    required this.orderId,
    required this.orderCode,
    required this.dateLabel,
    required this.orderTypeLabel,
    required this.customerName,
    required this.customerEmail,
    required this.tableLabel,
    required this.totalItems,
    required this.paymentMethodLabel,
    required this.paymentMethod,
    required this.vaNumber,
    required this.paymentExpiry,
    required this.qrisImageUrl,
    required this.paymentUrl,
    required this.midtransOrderId,
    required this.status,
    required this.totalPrice,
    required this.items,
  });

  final String orderId;
  final String orderCode;
  final String dateLabel;
  final String orderTypeLabel;
  final String customerName;
  final String customerEmail;
  final String tableLabel;
  final int totalItems;
  final String paymentMethodLabel;
  final String paymentMethod;
  final String vaNumber;
  final String paymentExpiry;
  final String qrisImageUrl;
  final String paymentUrl;
  final String midtransOrderId;
  final String status;
  final int totalPrice;
  final List<HistoryLineItem> items;
}

class HistoryLineItem {
  const HistoryLineItem({
    required this.name,
    required this.quantity,
    required this.unitPrice,
    required this.subtotal,
  });

  final String name;
  final int quantity;
  final int unitPrice;
  final int subtotal;
}

String idr(int value) {
  final number = value.toString().replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
    (match) => '${match[1]}.',
  );
  return 'Rp $number';
}
