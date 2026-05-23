import 'package:flutter/material.dart';

import '../../../app/app_routes.dart';
import '../../../shared/widgets/app_notice.dart';
import '../../landing/data/order_type_session.dart';
import '../../scan/data/table_session.dart';
import '../../scan/presentation/scan_page.dart';
import '../data/chatbot_api_service.dart';
import '../data/chatbot_models.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final ChatbotApiService _chatbotApiService = ChatbotApiService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<_ChatEntry> _entries = [];
  bool _sending = false;

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
    _sendToBot(message: 'halo', includeUserBubble: false);
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
    }

    setState(() => _sending = true);
    try {
      final response = await _chatbotApiService.sendMessage(
        message: trimmed,
        action: action,
      );
      final fallbackReason = (response.data?['fallback_reason'] ?? '')
          .toString()
          .trim();
      final displayReply =
          response.intent == 'unknown_or_ambiguous' && fallbackReason.isNotEmpty
          ? '${response.reply}\n\n(reason: $fallbackReason)'
          : response.reply;
      if (!mounted) return;
      setState(() {
        _entries.add(
          _ChatEntry(
            isUser: false,
            text: displayReply,
            actions: response.actions,
            cards: response.cards,
          ),
        );
      });
      _messageController.clear();
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      AppNotice.show(
        context,
        AppNotice.humanizeMessage(e),
        type: AppNoticeType.error,
      );
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
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
              radius: 18,
              backgroundColor: Colors.white,
              child: ClipOval(
                child: Image.asset(
                  'assets/slices_ui/logokedaiklik.jpg',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.person, color: Colors.grey),
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
            child: ListView(
              controller: _scrollController,
              padding: const EdgeInsets.all(16.0),
              children: [
                ..._entries.map(_buildEntry),
                if (_sending) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _botAvatarWidget(),
                      const SizedBox(width: 8),
                      _botChatBubble(text: 'Sedang memproses...'),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
              ],
            ),
          ),
          _chatInputWidget(),
        ],
      ),
    );
  }

  Widget _botAvatarWidget() {
    return CircleAvatar(
      radius: 18,
      backgroundColor: Colors.white,
      child: ClipOval(
        child: Image.asset(
          'assets/slices_ui/logokedaiklik.jpg',
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              const Icon(Icons.person, color: Colors.grey),
        ),
      ),
    );
  }

  Widget _botChatBubble({required String text}) {
    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.75,
      ),
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
    _sendToBot(message: _messageController.text);
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
            _botAvatarWidget(),
            const SizedBox(width: 8),
            _botChatBubble(text: entry.text),
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

    await _sendToBot(message: action.label, action: value);
  }

  Widget _menuCardWidget(ChatMenuCard card) {
    final menu = card.menu;
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
            menu.menuName,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          if (menu.description.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(menu.description, style: const TextStyle(fontSize: 12)),
          ],
          const SizedBox(height: 6),
          Text('Harga: Rp${menu.price}'),
          Text('Stok: ${menu.stock}'),
        ],
      ),
    );
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
            'Total: Rp${card.total}',
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
            'Order #${card.orderId.length > 6 ? card.orderId.substring(card.orderId.length - 6).toUpperCase() : card.orderId.toUpperCase()}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          if (card.trackingDateLabel.isNotEmpty)
            Text('Tanggal: ${card.trackingDateLabel}'),
          Text('Status: ${card.statusLabel}'),
          Text('Pembayaran: ${card.paymentStatus}'),
          Text('Nomor antrean: ${card.queueNumber}'),
          Text('Total: Rp${card.totalPrice}'),
        ],
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
}
