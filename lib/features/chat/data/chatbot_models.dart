class ChatbotEnvelope {
  const ChatbotEnvelope({
    required this.status,
    required this.message,
    required this.data,
  });

  final String status;
  final String message;
  final ChatbotResponse data;

  factory ChatbotEnvelope.fromJson(Map<String, dynamic> json) {
    final dataMap = _asMap(json['data']);
    return ChatbotEnvelope(
      status: _asString(json['status']),
      message: _asString(json['message']),
      data: ChatbotResponse.fromJson(dataMap),
    );
  }
}

class ChatbotResponse {
  const ChatbotResponse({
    required this.responseVersion,
    required this.reply,
    required this.intent,
    required this.data,
    required this.actions,
    required this.cards,
  });

  final String responseVersion;
  final String reply;
  final String intent;
  final Map<String, dynamic>? data;
  final List<ChatAction> actions;
  final List<ChatCard> cards;

  factory ChatbotResponse.fromJson(Map<String, dynamic> json) {
    final rawActions = _asList(json['actions']);
    final rawCards = _asList(json['cards']);

    return ChatbotResponse(
      responseVersion: _asString(json['response_version']),
      reply: _asString(json['reply']),
      intent: _asString(json['intent']),
      data: _asNullableMap(json['data']),
      actions: rawActions
          .map((e) => ChatAction.fromJson(_asMap(e)))
          .toList(growable: false),
      cards: rawCards
          .map((e) => ChatCard.fromJson(_asMap(e)))
          .toList(growable: false),
    );
  }
}

class ChatAction {
  const ChatAction({
    required this.uiBlockType,
    required this.type,
    required this.label,
    required this.value,
    required this.raw,
  });

  final String uiBlockType;
  final String type;
  final String label;
  final String value;
  final Map<String, dynamic> raw;

  factory ChatAction.fromJson(Map<String, dynamic> json) {
    return ChatAction(
      uiBlockType: _asString(json['ui_block_type']),
      type: _asString(json['type']),
      label: _asString(json['label']),
      value: _asString(json['value']),
      raw: json,
    );
  }
}

class ChatCard {
  const ChatCard({
    required this.uiBlockType,
    required this.type,
    required this.raw,
  });

  final String uiBlockType;
  final String type;
  final Map<String, dynamic> raw;

  bool get isMenuCard => type == 'menu_card';
  bool get isOrderSummaryCard => type == 'order_summary_card';
  bool get isTrackingStatusCard => type == 'tracking_status_card';

  ChatMenuCard? get asMenuCard {
    if (!isMenuCard) return null;
    return ChatMenuCard.fromJson(raw);
  }

  ChatOrderSummaryCard? get asOrderSummaryCard {
    if (!isOrderSummaryCard) return null;
    return ChatOrderSummaryCard.fromJson(raw);
  }

  ChatTrackingStatusCard? get asTrackingStatusCard {
    if (!isTrackingStatusCard) return null;
    return ChatTrackingStatusCard.fromJson(raw);
  }

  factory ChatCard.fromJson(Map<String, dynamic> json) {
    return ChatCard(
      uiBlockType: _asString(json['ui_block_type']),
      type: _asString(json['type']),
      raw: json,
    );
  }
}

class ChatMenuCard {
  const ChatMenuCard({required this.menu});

  final ChatMenu menu;

  factory ChatMenuCard.fromJson(Map<String, dynamic> json) {
    return ChatMenuCard(menu: ChatMenu.fromJson(_asMap(json['menu'])));
  }
}

class ChatMenu {
  const ChatMenu({
    required this.menuId,
    required this.menuName,
    required this.description,
    required this.price,
    required this.stock,
    required this.category,
    required this.imageUrl,
  });

  final String menuId;
  final String menuName;
  final String description;
  final int price;
  final int stock;
  final String category;
  final String imageUrl;

  factory ChatMenu.fromJson(Map<String, dynamic> json) {
    return ChatMenu(
      menuId: _asString(json['menu_id']),
      menuName: _asString(json['menu_name']),
      description: _asString(json['description']),
      price: _asInt(json['price']),
      stock: _asInt(json['stock']),
      category: _asString(json['category']),
      imageUrl: _asString(json['image_url']),
    );
  }
}

class ChatOrderSummaryCard {
  const ChatOrderSummaryCard({required this.items, required this.total});

  final List<Map<String, dynamic>> items;
  final int total;

  factory ChatOrderSummaryCard.fromJson(Map<String, dynamic> json) {
    return ChatOrderSummaryCard(
      items: _asList(
        json['items'],
      ).map((e) => _asMap(e)).toList(growable: false),
      total: _asInt(json['total']),
    );
  }
}

class ChatTrackingStatusCard {
  const ChatTrackingStatusCard({
    required this.orderId,
    required this.status,
    required this.statusLabel,
    required this.trackingDateLabel,
    required this.paymentStatus,
    required this.queueNumber,
    required this.totalPrice,
    required this.createdAt,
  });

  final String orderId;
  final String status;
  final String statusLabel;
  final String trackingDateLabel;
  final String paymentStatus;
  final int queueNumber;
  final int totalPrice;
  final String createdAt;

  factory ChatTrackingStatusCard.fromJson(Map<String, dynamic> json) {
    return ChatTrackingStatusCard(
      orderId: _asString(json['order_id']),
      status: _asString(json['status']),
      statusLabel: _asString(json['status_label']),
      trackingDateLabel: _asString(json['tracking_date_label']),
      paymentStatus: _asString(json['payment_status']),
      queueNumber: _asInt(json['queue_number']),
      totalPrice: _asInt(json['total_price']),
      createdAt: _asString(json['created_at']),
    );
  }
}

Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return value.map((key, val) => MapEntry(key.toString(), val));
  }
  return const <String, dynamic>{};
}

Map<String, dynamic>? _asNullableMap(dynamic value) {
  if (value == null) return null;
  final map = _asMap(value);
  if (map.isEmpty) return null;
  return map;
}

List<dynamic> _asList(dynamic value) {
  if (value is List) return value;
  return const [];
}

String _asString(dynamic value) {
  if (value == null) return '';
  return value.toString();
}

int _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}
