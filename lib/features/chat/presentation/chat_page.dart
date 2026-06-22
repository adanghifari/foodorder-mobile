import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app/app_routes.dart';
import '../../../shared/config/api_config.dart';
import '../../../shared/widgets/app_notice.dart';
import '../../landing/data/order_type_session.dart';
import '../../scan/data/table_session.dart';
import '../../scan/presentation/scan_page.dart';
import '../../profile/data/profile_api_service.dart';
import '../data/chatbot_api_service.dart';
import '../data/chatbot_models.dart';
import '../../../shared/utils/status_localizer.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  static const String _chatHistoryKey = 'chat_history_entries_v1';
  static const String _chatHistorySavedAtKey = 'chat_history_saved_at_v1';
  static const Duration _chatTtl = Duration(days: 2);
  static const double _botBubbleTopOffset = 44;
  static const List<_GreetingShortcut> _greetingShortcuts = [
    _GreetingShortcut(
      label: 'Pesan Makanan',
      value: 'greeting_order',
    ),
    _GreetingShortcut(
      label: 'Tracking Pesanan',
      value: 'greeting_tracking',
    ),
    _GreetingShortcut(
      label: 'Rekomendasi Menu',
      value: 'greeting_recommendation',
    ),
    _GreetingShortcut(
      label: 'Lihat Keranjang',
      value: 'greeting_view_cart',
    ),
  ];

  final ChatbotApiService _chatbotApiService = ChatbotApiService();
  final ProfileApiService _profileApiService = ProfileApiService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<_ChatEntry> _entries = [];
  String _displayName = 'Pengguna';
  bool _sending = false;
  bool _requireLogin = false;
  String? _error;

  void _handleBack() {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
      return;
    }
    Navigator.pushReplacementNamed(context, AppRoutes.landing);
  }

  @override
  void initState() {
    super.initState();
    _restoreChatHistory();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendToBot({
    required String message,
    String action = '',
    bool includeUserBubble = true,
  }) async {
    final trimmed = message.trim();
    if (_sending) return;
    if (trimmed.isEmpty && action.isEmpty) return;
    if (_displayName == 'Pengguna') {
      await _resolveDisplayName();
    }

    var addedUserBubble = false;
    if (includeUserBubble && trimmed.isNotEmpty) {
      setState(() {
        _entries.add(
          _ChatEntry(
            isUser: true,
            text: trimmed,
            actions: const [],
            cards: const [],
          ),
        );
      });
      addedUserBubble = true;
      _persistChatHistory();
      _scrollToBottom();
    }

    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      final response = await _chatbotApiService.sendMessage(
        message: trimmed,
        action: action,
      );
      final fallbackReason = (response.data?['fallback_reason'] ?? '')
          .toString()
          .trim();
      final isGreetingRequest = trimmed.toLowerCase() == 'halo';
      final isGreetingIntent = response.intent.toLowerCase().contains(
        'greet',
      ) || response.intent.toLowerCase().contains('salam');
      final shouldPersonalizeGreeting = isGreetingRequest || isGreetingIntent;
      final reply = shouldPersonalizeGreeting
          ? _personalizeGreetingReply(response.reply)
          : response.reply;
      final displayReply =
          response.intent == 'unknown_or_ambiguous' && fallbackReason.isNotEmpty
          ? '$reply\n\n(alasan: $fallbackReason)'
          : reply;
      if (!mounted) return;
      setState(() {
        _requireLogin = false;
        _entries.add(
          _ChatEntry(
            isUser: false,
            text: displayReply,
            actions: response.actions,
            cards: response.cards,
          ),
        );
      });
      _persistChatHistory();
      _messageController.clear();
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      final message = AppNotice.humanizeMessage(e);
      final unauthorized = _isUnauthorizedMessage(message);
      if (unauthorized) {
        setState(() {
          _requireLogin = true;
          _error = 'Anda belum login. Silakan login terlebih dahulu untuk mengakses fitur chatbot.';
          if (addedUserBubble && _entries.isNotEmpty && _entries.last.isUser) {
            _entries.removeLast();
          }
        });
        return;
      }
      AppNotice.show(
        context,
        message,
        type: AppNoticeType.error,
      );
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }

  Future<void> _restoreChatHistory() async {
    await _resolveDisplayName();

    final prefs = await SharedPreferences.getInstance();
    final savedAtEpoch = prefs.getInt(_chatHistorySavedAtKey);
    final now = DateTime.now();

    if (savedAtEpoch != null) {
      final savedAt = DateTime.fromMillisecondsSinceEpoch(savedAtEpoch);
      if (now.difference(savedAt) > _chatTtl) {
        await prefs.remove(_chatHistoryKey);
        await prefs.remove(_chatHistorySavedAtKey);
      }
    }

    final raw = prefs.getString(_chatHistoryKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          final restored = decoded
              .whereType<Map>()
              .map(
                (item) => _ChatEntry.fromJson(Map<String, dynamic>.from(item)),
              )
              .toList(growable: false);
          if (mounted) {
            setState(() {
              _entries
                ..clear()
                ..addAll(restored);
            });
            _scrollToBottom();
            if (_entries.isNotEmpty) {
              return;
            }
          }
        }
      } catch (_) {
        // ignore broken local cache
      }
    }

    if (mounted && _entries.isEmpty) {
      await _sendToBot(message: 'halo', includeUserBubble: false);
    }
  }

  Future<void> _resolveDisplayName() async {
    try {
      final user = await _profileApiService.fetchMe();
      final username = user.username.trim();
      final name = user.name.trim();
      final candidate = username.isNotEmpty && username != '-'
          ? username
          : name;
      _displayName = candidate.isEmpty || candidate == '-' ? 'Pengguna' : candidate;
    } catch (_) {
      _displayName = 'Pengguna';
    }
  }

  String _personalizeGreetingReply(String reply) {
    final text = reply.trim();
    if (text.isEmpty || _displayName == 'Pengguna') {
      return text;
    }
    if (text.startsWith('Halo!')) {
      return text.replaceFirst('Halo!', 'Halo, $_displayName!');
    }
    if (text.startsWith('Halo')) {
      return text.replaceFirst('Halo', 'Halo, $_displayName');
    }
    return 'Halo, $_displayName!\n\n$text';
  }

  Future<void> _persistChatHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(
      _entries.map((entry) => entry.toJson()).toList(growable: false),
    );
    await prefs.setString(_chatHistoryKey, encoded);
    await prefs.setInt(
      _chatHistorySavedAtKey,
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.minScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFFFFF),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: _handleBack,
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: Colors.white,
              child: ClipOval(
                child: SizedBox.square(
                  dimension: 40,
                  child: Padding(
                    padding: const EdgeInsets.all(3),
                    child: Image.asset(
                      'assets/kedaibot.png',
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.person, color: Colors.grey),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'KedaiBot',
              style: TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: Colors.grey.withOpacity(0.2), height: 1.0),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _requireLogin
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.lock_outline,
                            color: Color(0xFF9C9C9C),
                            size: 40,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            _error ??
                                'Anda belum login. Silakan login terlebih dahulu untuk melihat riwayat.',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: () =>
                                Navigator.pushNamed(context, AppRoutes.login),
              child: const Text('Masuk'),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView(
                    controller: _scrollController,
                    reverse: true,
                    padding: const EdgeInsets.all(16.0),
                    children: [
                      if (_sending) ...[
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _botIdentityWidget(),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Padding(
                                padding: const EdgeInsets.only(
                                  top: _botBubbleTopOffset,
                                ),
                                child: _botChatBubble(
                                  text: 'Sedang memproses...',
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                      ],
                      ..._entries.reversed.map(_buildEntry),
                    ],
                  ),
          ),
          if (!_requireLogin) ...[
            if (_showGreetingShortcuts) _greetingShortcutPanel(),
            _chatInputWidget(),
          ],
        ],
      ),
    );
  }

  Widget _botAvatarWidget() {
    return CircleAvatar(
      radius: 20,
      backgroundColor: Colors.white,
      child: ClipOval(
        child: SizedBox.square(
          dimension: 40,
          child: Padding(
            padding: const EdgeInsets.all(3),
            child: Image.asset(
              'assets/kedaibot.png',
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.person, color: Colors.grey),
            ),
          ),
        ),
      ),
    );
  }

  Widget _botIdentityWidget() {
    return SizedBox(
      width: 52,
      child: Column(
        children: [
          _botAvatarWidget(),
          const SizedBox(height: 4),
          const Text(
            'KedaiBot',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.black54,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _botChatBubble({required String text}) {
    return Container(
      constraints: const BoxConstraints(maxWidth: double.infinity),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xFFF3F3F3),
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(16),
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.black, fontSize: 14, height: 1.4),
      ),
    );
  }

  Widget _userChatBubble({required String text}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: const BoxDecoration(
            color: Color(0xFFC6620C),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
              bottomLeft: Radius.circular(16),
            ),
          ),
          child: Text(
            text,
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
        ),
      ],
    );
  }

  Widget _chatInputWidget() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              enabled: !_sending,
              onSubmitted: (_) => _handleSendText(),
              decoration: InputDecoration(
                hintText: 'Ketik Pesan...',
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: const BorderSide(color: Colors.black),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: const BorderSide(color: Colors.black),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: _sending ? null : _handleSendText,
            child: CircleAvatar(
              backgroundColor: _sending
                  ? const Color(0xFFCFB294)
                  : const Color(0xFFC6620C),
              child: const Icon(Icons.send_rounded, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _handleSendText() {
    final text = _messageController.text.trim();
    if (text == '//clear') {
      _clearChatSession();
      return;
    }
    _sendToBot(message: text);
  }

  Future<void> _clearChatSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_chatHistoryKey);
    await prefs.remove(_chatHistorySavedAtKey);
    if (!mounted) return;
    setState(() {
      _entries.clear();
      _messageController.clear();
    });
    AppNotice.show(context, 'Riwayat chat berhasil dibersihkan.');
  }

  Widget _buildEntry(_ChatEntry entry) {
    if (entry.isUser) {
      return Column(
        children: [
          _userChatBubble(text: entry.text),
          const SizedBox(height: 12),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _botIdentityWidget(),
            const SizedBox(width: 8),
            Flexible(
              child: Padding(
                padding: const EdgeInsets.only(top: _botBubbleTopOffset),
                child: _botChatBubble(text: entry.text),
              ),
            ),
          ],
        ),
        if (entry.cards.isNotEmpty) ...[
          const SizedBox(height: 8),
          ...entry.cards.map(_buildCard),
        ],
        if (entry.actions.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: entry.actions
                .map(
                  (action) => _quickReplyButtonAction(
                    label: action.label,
                    onTap: () => _handleAction(action),
                  ),
                )
                .toList(growable: false),
          ),
        ],
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _quickReplyButtonAction({
    required String label,
    required VoidCallback onTap,
  }) {
    return OutlinedButton(
      onPressed: _sending ? null : onTap,
      style: OutlinedButton.styleFrom(
        backgroundColor: const Color(0xFFFFEEE1),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFFC6620C),
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildCard(ChatCard card) {
    if (card.isMenuCard) {
      final menuCard = card.asMenuCard;
      if (menuCard != null) {
        return _menuCardWidget(menuCard);
      }
    }

    if (card.isOrderSummaryCard) {
      final summary = card.asOrderSummaryCard;
      if (summary != null) {
        return _orderSummaryCardWidget(summary);
      }
    }

    if (card.isTrackingStatusCard) {
      final tracking = card.asTrackingStatusCard;
      if (tracking != null) {
        return _trackingCardWidget(tracking);
      }
    }

    return const SizedBox.shrink();
  }

  Future<void> _handleAction(ChatAction action) async {
    final value = action.value.trim();

    if (value == 'nav_scan_qr_dine_in' || value == 'nav_scan_qr_takeaway') {
      await Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (_) => const ScanPage(redirectToCart: true),
        ),
      );
      return;
    }

    if (value == 'nav_checkout_booking_dine_in') {
      await OrderTypeSession.set(OrderType.bookingDineIn);
      await TableSession.clear();
      if (!mounted) return;
      Navigator.pushNamed(context, AppRoutes.cart);
      return;
    }

    if (value == 'nav_checkout_pickup') {
      await OrderTypeSession.set(OrderType.pickup);
      await TableSession.clear();
      if (!mounted) return;
      Navigator.pushNamed(context, AppRoutes.cart);
      return;
    }

    if (value == 'greeting_view_cart') {
      await _sendToBot(message: action.label, action: value);
      return;
    }

    if (value == 'nav_cart_read_only') {
      if (!mounted) return;
      Navigator.pushNamed(
        context,
        AppRoutes.cart,
        arguments: const <String, dynamic>{'readOnly': true},
      );
      return;
    }

    await _sendToBot(message: action.label, action: value);
  }

  Widget _menuCardWidget(ChatMenuCard card) {
    final menu = card.menu;
    final imageUrl = _normalizeMenuImageUrl(menu.imageUrl);
    return Container(
      margin: const EdgeInsets.only(left: 44, bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEDEDED)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 72,
              height: 72,
              child: imageUrl.isEmpty
                  ? _menuImagePlaceholder()
                  : Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _menuImagePlaceholder(),
                    ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  menu.menuName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
                if (menu.description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    menu.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Rp${menu.price}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFC6620C),
                        ),
                      ),
                    ),
                    Text(
                      'Stok ${menu.stock}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _menuImagePlaceholder() {
    return Container(
      color: const Color(0xFFF1F1F1),
      child: const Icon(Icons.fastfood_rounded, color: Color(0xFFBDBDBD)),
    );
  }

  String _normalizeMenuImageUrl(String raw) {
    final value = raw.trim();
    if (value.isEmpty) {
      return '';
    }
    if (value.startsWith('http://') || value.startsWith('https://')) {
      return value;
    }
    if (value.startsWith('/storage/menu/')) {
      final filename = value.split('/').last;
      return '${ApiConfig.apiBaseUrl}/v1/menus/image/$filename';
    }
    if (value.startsWith('/')) {
      return '${ApiConfig.serverBaseUrl}$value';
    }
    return '${ApiConfig.serverBaseUrl}/$value';
  }

  Widget _orderSummaryCardWidget(ChatOrderSummaryCard card) {
    return Container(
      margin: const EdgeInsets.only(left: 44, bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE6E6E6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ringkasan Pesanan',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          ...card.items.take(3).map((item) {
            final name = (item['name'] ?? '-').toString();
            final qty = (item['quantity'] ?? 0).toString();
            final subtotal = (item['subtotal'] ?? 0).toString();
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text('$name x$qty - Rp$subtotal'),
            );
          }),
          const SizedBox(height: 6),
          Text(
            'Subtotal: Rp${card.total}',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _trackingCardWidget(ChatTrackingStatusCard card) {
    return Container(
      margin: const EdgeInsets.only(left: 44, bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE6E6E6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pesanan #${card.orderId.length > 6 ? card.orderId.substring(card.orderId.length - 6).toUpperCase() : card.orderId.toUpperCase()}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          if (card.trackingDateLabel.isNotEmpty)
            Text('Tanggal: ${card.trackingDateLabel}'),
          Text('Status: ${localizedOrderStatusLabel(card.statusLabel)}'),
          Text('Pembayaran: ${localizedPaymentStatusLabel(card.paymentStatus)}'),
          Text('Nomor antrean: ${card.queueNumber}'),
          Text('Total: Rp${card.totalPrice}'),
        ],
      ),
    );
  }

  bool _isUnauthorizedMessage(String message) {
    final raw = message.toLowerCase();
    return raw.contains('401') ||
        raw.contains('unauthorized') ||
        raw.contains('unauth') ||
        raw.contains('belum login');
  }

  bool get _showGreetingShortcuts => _entries.length > 1;

  Widget _greetingShortcutPanel() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey.withOpacity(0.12)),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: _greetingShortcuts
              .map(
                (shortcut) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: OutlinedButton(
                    onPressed: _sending
                        ? null
                        : () => _handleAction(
                            ChatAction(
                              uiBlockType: 'quick_reply',
                              type: 'quick_reply',
                              label: shortcut.label,
                              value: shortcut.value,
                              raw: const {},
                            ),
                          ),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFEEE1),
                      side: BorderSide.none,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                    ),
                    child: Text(
                      shortcut.label,
                      style: const TextStyle(
                        color: Color(0xFFC6620C),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              )
              .toList(growable: false),
        ),
      ),
    );
  }
}

class _ChatEntry {
  const _ChatEntry({
    required this.isUser,
    required this.text,
    required this.actions,
    required this.cards,
  });

  final bool isUser;
  final String text;
  final List<ChatAction> actions;
  final List<ChatCard> cards;

  Map<String, dynamic> toJson() {
    return {
      'is_user': isUser,
      'text': text,
      'actions': actions.map((action) => action.raw).toList(growable: false),
      'cards': cards.map((card) => card.raw).toList(growable: false),
    };
  }

  factory _ChatEntry.fromJson(Map<String, dynamic> json) {
    final actionList = (json['actions'] as List?) ?? const [];
    final cardList = (json['cards'] as List?) ?? const [];
    return _ChatEntry(
      isUser: (json['is_user'] as bool?) ?? false,
      text: (json['text'] ?? '').toString(),
      actions: actionList
          .whereType<Map>()
          .map((item) => ChatAction.fromJson(Map<String, dynamic>.from(item)))
          .toList(growable: false),
      cards: cardList
          .whereType<Map>()
          .map((item) => ChatCard.fromJson(Map<String, dynamic>.from(item)))
          .toList(growable: false),
    );
  }
}

class _GreetingShortcut {
  const _GreetingShortcut({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;
}
