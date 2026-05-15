import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';

import '../../../app/app_routes.dart';
import '../../auth/data/auth_session.dart';
import '../../cart/data/cart_api_service.dart';
import 'order_type_picker_page.dart';
import '../data/order_type_session.dart';
import '../data/landing_top_menu_service.dart';
import '../../../shared/widgets/app_bottom_nav_bar.dart';
import '../../../shared/widgets/app_notice.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage>
    with WidgetsBindingObserver {
  final LandingTopMenuService _topMenuService = LandingTopMenuService();
  final CartApiService _cartApiService = CartApiService();
  late List<_LandingMenuCardData> _menuCards;
  bool _isFromBackend = false;
  String? _loadError;
  bool _isLoggedIn = false;
  String _username = 'Pengguna';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _menuCards = _fallbackMenus;
    _loadTopMenus();
    _loadAuthState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadAuthState();
    }
  }

  static const Color _bg = Color(0xFFF2F2F2);
  static const Color _textDark = Color(0xFF343434);
  static const Color _accent = Color(0xFFD45A00);
  static const Color _accentDark = Color(0xFF7E3511);
  static const List<_LandingMenuCardData> _fallbackMenus = [
    _LandingMenuCardData(
      id: '',
      stock: 0,
      name: 'Gudeg Juara',
      imageUrl: '',
      description:
          'Manis-gurih autentik, dimasak perlahan dengan santan kental dan rempah pilihan.',
    ),
    _LandingMenuCardData(
      id: '',
      stock: 0,
      name: 'Ayam Bakar',
      imageUrl: '',
      description:
          'Ayam ungkep bumbu tradisional, dibakar sempurna dengan aroma smokey menggugah selera',
    ),
    _LandingMenuCardData(
      id: '',
      stock: 0,
      name: 'Ayam Geprek',
      imageUrl: '',
      description:
          'Ayam crispy pilihan, disajikan dengan sambal ulek segar yang pedasnya nampol.',
    ),
  ];

  Future<void> _loadTopMenus() async {
    try {
      final topMenus = await _topMenuService.fetchTopMenusByCategory();
      if (!mounted || topMenus.isEmpty) {
        return;
      }

      final mapped = topMenus
          .map(
            (item) => _LandingMenuCardData(
              id: item.id,
              stock: item.stock,
              name: item.name,
              description: item.description,
              imageUrl: item.imageUrl,
            ),
          )
          .take(3)
          .toList();

      if (mapped.isNotEmpty) {
        setState(() {
          _menuCards = mapped;
          _isFromBackend = true;
          _loadError = null;
        });
      }
    } catch (e) {
      debugPrint('Failed to load top menus from backend: $e');
      if (mounted) {
        setState(() {
          _isFromBackend = false;
          _loadError = e.toString();
        });
      }
      // Keep fallback static menus if API is unavailable.
    }
  }

  Future<void> _loadAuthState() async {
    final token = await AuthSession.getToken();
    if (!mounted) return;

    if (token == null || token.isEmpty) {
      setState(() {
        _isLoggedIn = false;
        _username = 'Pengguna';
      });
      return;
    }

    setState(() => _isLoggedIn = true);

    try {
      const apiFromEnv = String.fromEnvironment('API_BASE_URL', defaultValue: '');
      final baseUrl = apiFromEnv.isNotEmpty
          ? apiFromEnv
          : (kIsWeb ? 'http://127.0.0.1:8000/api' : 'http://192.168.1.5:8000/api');
      final dio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 15),
          headers: const {'Accept': 'application/json'},
        ),
      );
      final response = await dio.get<Map<String, dynamic>>(
        '$baseUrl/v1/auth/me',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      if (!mounted) return;
      final data = response.data?['data'] as Map<String, dynamic>? ?? const {};
      final username = (data['username'] ?? data['name'] ?? 'Pengguna').toString();
      setState(() {
        _username = username;
      });
    } catch (_) {
      // Keep landing usable even if profile fetch fails.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      bottomNavigationBar: AppBottomNavBar(
        activeItem: AppBottomNavItem.home,
        onHomeTap: () {},
        onMenuTap: () => Navigator.pushNamed(context, AppRoutes.menu),
        onScanTap: () => Navigator.pushNamed(context, AppRoutes.scan),
        onHistoryTap: () =>
            Navigator.pushNamed(context, AppRoutes.orderHistory),
        onAccountTap: () => Navigator.pushNamed(context, AppRoutes.profile),
      ),
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark,
        child: SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            child: Column(
              children: [
                _buildHero(context),
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 0, 22, 30),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                    Transform.translate(
                     offset: const Offset(0, -30), // coba -12, -16, atau -20
                     child: _buildTopOptionRow(context),
                      ),
                      const SizedBox(height: 0),
                      _buildSectionTitle(),
                      const SizedBox(height: 18),
                      _buildMenuGrid(context),
                      const SizedBox(height: 26),
                      _buildBottomInfo(),
                      const SizedBox(height: 22),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHero(BuildContext context) {
    return SizedBox(
      height: 362,
      child: Stack(
        children: [
          Container(color: const Color(0xFFEAEAEA)),
          Positioned(
            left: -10,
            bottom: 165,
            child: SizedBox(
              width: 240,
              child: Image.asset(
                'assets/foto katalog/logobaru.png',
                fit: BoxFit.contain,
              ),
            ),
          ),
          const Positioned(
            left: 24,
            bottom: 140,
            child: Text(
              '100% Tasty',
              style: TextStyle(
                color: _textDark,
                fontSize: 24,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
              ),
            ),
          ),
          const Positioned(
            left: 24,
            bottom: 120,
            child: Text(
              'Rasa Juara, Pesan Cuma Pakai Klik!',
              style: TextStyle(
                color: Color(0xFF575757),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Positioned(
            right: -40,
            bottom: 30,
            child: Transform.rotate(
              angle: -0.42,
              child: Image.asset(
                'assets/foto katalog/hidangan.png',
                width: 248,
                fit: BoxFit.cover,
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 50,
            child: CustomPaint(
              size: const Size(double.infinity, 64),
              painter: _HeroWavePainter(),
            ),
          ),
          Positioned(
            top: 16,
            left: 16,
            child: _isLoggedIn
                ? Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x22000000),
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircleAvatar(
                          radius: 14,
                          backgroundImage: AssetImage('assets/slices_ui/fotoprofile.jpg'),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Hai! $_username',
                          style: const TextStyle(
                            color: _textDark,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  )
                : Material(
                    elevation: 5,
                    borderRadius: BorderRadius.circular(10),
                    child: OutlinedButton(
                      onPressed: () async {
                        await Navigator.pushNamed(context, AppRoutes.login);
                        if (!mounted) return;
                        await _loadAuthState();
                      },
                      style: OutlinedButton.styleFrom(
                        backgroundColor: _accent,
                        foregroundColor: Colors.white,
                        side: BorderSide.none,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        textStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      child: const Text('Sign In'),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle() {
    return Center(
      child: Column(
        children: [
          const Text(
            'Menu Terbaik',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: _textDark,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 8),
          Container(width: 126, height: 5, color: _accentDark),
          const SizedBox(height: 8),
          Text(
            _isFromBackend ? 'Sumber: Backend' : 'Sumber: Fallback',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF6C6C6C),
            ),
          ),
          if (_loadError != null) ...[
            const SizedBox(height: 4),
            Text(
              _loadError!,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 10, color: Colors.redAccent),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMenuGrid(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 0.64,
      children: [
        ..._menuCards.map(
          (menu) => _menuCard(context, menu: menu),
        ),
        _othersCard(context),
      ],
    );
  }

  Widget _menuCard(BuildContext context, {required _LandingMenuCardData menu}) {
    final isOutOfStock = menu.stock < 1;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Color(0x18000000),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: AspectRatio(
              aspectRatio: 1.28,
              child: menu.imageUrl.isNotEmpty
                  ? Image.network(
                      menu.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Image.asset(
                        'assets/foto katalog/Gudeg.jpg',
                        fit: BoxFit.cover,
                      ),
                    )
                  : Image.asset(
                      'assets/foto katalog/Gudeg.jpg',
                      fit: BoxFit.cover,
                    ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            menu.name,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: _textDark,
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Text(
              menu.description,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF6C6C6C),
                fontSize: 10.5,
                height: 1.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: 92,
            height: 34,
            child: OutlinedButton(
              onPressed: () => _handleTopMenuOrder(context, menu),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF4D554D), width: 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: EdgeInsets.zero,
              ),
              child: Text(
                isOutOfStock ? 'Habis' : 'Pesan',
                style: TextStyle(
                  color: isOutOfStock
                      ? const Color(0xFF9CA3AF)
                      : const Color(0xFF4D554D),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _othersCard(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => _openOrderTypePicker(context),
      child: Stack(
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFFCC6A08),
              borderRadius: BorderRadius.circular(14),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x18000000),
                  blurRadius: 16,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              children: [
                const Spacer(),
                const Text(
                  'Lainnya',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 25,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 22),
                Container(
                  height: 42,
                  width: 134,
                  decoration: BoxDecoration(
                    color: const Color(0xFF8F3E0E),
                    border: Border.all(color: Colors.white, width: 2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Center(
                    child: Text(
                      'Lihat menu',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const Spacer(),
              ],
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(painter: _OthersPatternPainter()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopOptionRow(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _whyTile(
            context,
            icon: Icons.restaurant,
            label: 'Makan\nditempat',
            orderType: OrderType.dineIn,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _whyTile(
            context,
            icon: Icons.storefront,
            label: 'Ambil ke\nresto',
            orderType: OrderType.pickup,
          ),
        ),
      ],
    );
  }

  Widget _whyTile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required OrderType orderType,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => _selectOrderTypeAndGo(context, orderType),
      child: Container(
        height: 86,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F8F8),
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [
            BoxShadow(
              color: Color(0x10000000),
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              height: 44,
              width: 44,
              decoration: const BoxDecoration(
                color: _accent,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: _textDark,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectOrderTypeAndGo(
    BuildContext context,
    OrderType orderType,
  ) async {
    await OrderTypeSession.set(orderType);
    if (!context.mounted) return;
    Navigator.pushNamed(context, AppRoutes.menu);
  }

  Future<OrderType?> _pickOrderType(BuildContext context) async {
    return showModalBottomSheet<OrderType>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Pilih Tipe Pesanan',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: _textDark,
                  ),
                ),
                const SizedBox(height: 12),
                ListTile(
                  leading: const Icon(Icons.restaurant, color: _accent),
                  title: const Text('Makan di tempat'),
                  onTap: () => Navigator.pop(sheetContext, OrderType.dineIn),
                ),
                ListTile(
                  leading: const Icon(Icons.storefront, color: _accent),
                  title: const Text('Ambil ke resto'),
                  onTap: () => Navigator.pop(sheetContext, OrderType.pickup),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleTopMenuOrder(
    BuildContext context,
    _LandingMenuCardData menu,
  ) async {
    if (menu.stock < 1) {
      AppNotice.show(
        context,
        'Stok ${menu.name} sedang habis.',
        type: AppNoticeType.error,
      );
      return;
    }
    if (menu.id.trim().isEmpty) {
      AppNotice.show(
        context,
        'Menu ini belum tersedia untuk pesan cepat.',
        type: AppNoticeType.info,
      );
      return;
    }

    final token = await AuthSession.getToken();
    if (token == null || token.isEmpty) {
      if (!mounted) return;
      final loginSuccess = await Navigator.pushNamed(
        context,
        AppRoutes.login,
        arguments: const {'returnToPrevious': true},
      );
      if (!mounted || loginSuccess != true) return;
    }

    if (!mounted) return;
    final orderType = await _pickOrderType(context);
    if (orderType == null) return;
    await OrderTypeSession.set(orderType);

    try {
      final currentItems = await _cartApiService.getCartItems();
      final existingQty = currentItems
          .where((e) => e.menuId == menu.id)
          .fold<int>(0, (sum, e) => sum + e.quantity);
      await _cartApiService.setItemQuantity(
        menuItemId: menu.id,
        quantity: existingQty + 1,
      );
      if (!mounted) return;
      AppNotice.show(
        context,
        '${menu.name} masuk ke keranjang.',
        type: AppNoticeType.success,
      );
      Navigator.pushNamed(context, AppRoutes.cart);
    } catch (e) {
      if (!mounted) return;
      final raw = e.toString().toLowerCase();
      final isUnauthorized = raw.contains('401') ||
          raw.contains('unauth') ||
          raw.contains('belum login') ||
          raw.contains('unauthorized');
      if (isUnauthorized) {
        await _showLoginRequiredPopup(context);
      } else {
        AppNotice.show(context, '$e', type: AppNoticeType.error);
      }
    }
  }

  Future<void> _showLoginRequiredPopup(BuildContext context) async {
    final shouldLogin = await AppNotice.confirm(
      context,
      type: AppNoticeType.info,
      bodyTitle: 'Login Diperlukan',
      message:
          'Anda belum login. Silakan login terlebih dahulu untuk melanjutkan pesanan.',
      confirmLabel: 'Login',
    );

    if (!mounted || shouldLogin != true) return;
    Navigator.pushNamed(context, AppRoutes.login);
  }

  Widget _buildBottomInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text.rich(
          TextSpan(
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: _textDark,
            ),
            children: [
              TextSpan(text: 'Mengapa '),
              TextSpan(
                text: 'KedaiKlik',
                style: TextStyle(color: _accent),
              ),
              TextSpan(text: '?'),
            ],
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'Nikmati kenyamanan memesan masakan tradisional favorit Anda dalam satu aplikasi. Kualitas rasa terjaga, proses pemesanan cepat, dan langsung diantar ke tempat Anda.',
          style: TextStyle(
            fontSize: 10.5,
            height: 1.7,
            color: Color(0xFF4D4D4D),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 14),
      ],
    );
  }

  void _openOrderTypePicker(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (_) => const OrderTypePickerPage()),
    );
  }
}

class _LandingMenuCardData {
  const _LandingMenuCardData({
    required this.id,
    required this.stock,
    required this.name,
    required this.imageUrl,
    required this.description,
  });

  final String id;
  final int stock;
  final String name;
  final String imageUrl;
  final String description;
}

class _SocialChip extends StatelessWidget {
  const _SocialChip({required this.icon, required this.label});

  static const Color _accent = Color(0xFFD45A00);
  static const Color _textDark = Color(0xFF343434);

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE4E4E4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: _accent),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: _textDark,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroWavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final dark = Paint()..color = const Color(0xFFB85A05);
    final light = Paint()..color = const Color(0xFFD87411);

    final bottom = Path()
      ..moveTo(0, size.height)
      ..lineTo(0, size.height * 0.42)
      ..quadraticBezierTo(
        size.width * 0.35,
        size.height * 0.04,
        size.width * 0.66,
        size.height * 0.56,
      )
      ..quadraticBezierTo(
        size.width * 0.84,
        size.height * 0.86,
        size.width,
        size.height * 0.2,
      )
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(bottom, dark);

    final top = Path()
      ..moveTo(0, size.height)
      ..lineTo(0, size.height * 0.66)
      ..quadraticBezierTo(
        size.width * 0.26,
        size.height * 0.16,
        size.width * 0.53,
        size.height * 0.72,
      )
      ..quadraticBezierTo(
        size.width * 0.77,
        size.height * 1.05,
        size.width,
        size.height * 0.31,
      )
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(top, light);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _OthersPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = Colors.white.withValues(alpha: 0.82)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final topRight = Path()
      ..moveTo(size.width * 0.76, 12)
      ..cubicTo(size.width * 0.80, 0, size.width * 0.93, 4, size.width, 20)
      ..moveTo(size.width * 0.70, 22)
      ..cubicTo(size.width * 0.77, 4, size.width * 0.93, 10, size.width, 30)
      ..moveTo(size.width * 0.66, 34)
      ..cubicTo(size.width * 0.74, 13, size.width * 0.92, 18, size.width, 42);
    canvas.drawPath(topRight, stroke);

    final leftMid = Path()
      ..moveTo(0, size.height * 0.34)
      ..quadraticBezierTo(
        size.width * 0.10,
        size.height * 0.30,
        size.width * 0.14,
        size.height * 0.40,
      )
      ..moveTo(0, size.height * 0.42)
      ..quadraticBezierTo(
        size.width * 0.08,
        size.height * 0.37,
        size.width * 0.12,
        size.height * 0.47,
      );
    canvas.drawPath(leftMid, stroke);

    final bottomLeft = Path()
      ..moveTo(14, size.height)
      ..quadraticBezierTo(32, size.height - 26, 66, size.height - 20)
      ..quadraticBezierTo(84, size.height - 18, 96, size.height)
      ..moveTo(24, size.height)
      ..quadraticBezierTo(40, size.height - 16, 66, size.height - 12)
      ..quadraticBezierTo(84, size.height - 10, 92, size.height);
    canvas.drawPath(bottomLeft, stroke);

    final bottomRight = Path()
      ..moveTo(size.width - 8, size.height * 0.74)
      ..quadraticBezierTo(
        size.width - 18,
        size.height * 0.70,
        size.width - 6,
        size.height * 0.66,
      )
      ..moveTo(size.width - 20, size.height * 0.78)
      ..quadraticBezierTo(
        size.width - 34,
        size.height * 0.73,
        size.width - 16,
        size.height * 0.68,
      );
    canvas.drawPath(bottomRight, stroke);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
