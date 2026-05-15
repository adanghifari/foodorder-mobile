import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

import '../../../app/app_routes.dart';
import 'order_type_picker_page.dart';
import 'order_type_session.dart';
import 'landing_top_menu_service.dart';
import '../../../shared/widgets/app_bottom_nav_bar.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  final LandingTopMenuService _topMenuService = LandingTopMenuService();
  late List<_LandingMenuCardData> _menuCards;
  bool _isFromBackend = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _menuCards = _fallbackMenus;
    _loadTopMenus();
  }

  static const Color _bg = Color(0xFFF2F2F2);
  static const Color _textDark = Color(0xFF343434);
  static const Color _accent = Color(0xFFD45A00);
  static const Color _accentDark = Color(0xFF7E3511);
  static const bool _isLoggedIn = bool.fromEnvironment(
    'IS_LOGGED_IN',
    defaultValue: false,
  );

  static const List<_LandingMenuCardData> _fallbackMenus = [
    _LandingMenuCardData(
      name: 'Gudeg Juara',
      imageUrl: '',
      description:
          'Manis-gurih autentik, dimasak perlahan dengan santan kental dan rempah pilihan.',
    ),
    _LandingMenuCardData(
      name: 'Ayam Bakar',
      imageUrl: '',
      description:
          'Ayam ungkep bumbu tradisional, dibakar sempurna dengan aroma smokey menggugah selera',
    ),
    _LandingMenuCardData(
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      bottomNavigationBar: AppBottomNavBar(
        activeItem: AppBottomNavItem.home,
        onHomeTap: () {},
        onMenuTap: () => Navigator.pushNamed(context, AppRoutes.menu),
        onScanTap: () => ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Fitur scan akan segera tersedia.'),
            duration: Duration(seconds: 1),
          ),
        ),
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
                  padding: const EdgeInsets.fromLTRB(22, 20, 22, 30),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTopOptionRow(context),
                      const SizedBox(height: 22),
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
      height: 312,
      child: Stack(
        children: [
          Container(color: const Color(0xFFEAEAEA)),
          Positioned(
            left: 24,
            bottom: 132,
            child: SizedBox(
              width: 175,
              child: Image.asset(
                'assets/foto katalog/logobaru.png',
                fit: BoxFit.contain,
              ),
            ),
          ),
          const Positioned(
            left: 24,
            bottom: 92,
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
            bottom: 72,
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
            bottom: -5,
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
            bottom: 0,
            child: CustomPaint(
              size: const Size(double.infinity, 64),
              painter: _HeroWavePainter(),
            ),
          ),
          if (!_isLoggedIn)
            Positioned(
              top: 16,
              right: 16,
              child: Material(
                elevation: 5,
                borderRadius: BorderRadius.circular(10),
                child: OutlinedButton(
                  onPressed: () =>
                      Navigator.pushNamed(context, AppRoutes.login),
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
          (menu) => _menuCard(
            context,
            name: menu.name,
            imageUrl: menu.imageUrl,
            description: menu.description,
          ),
        ),
        _othersCard(context),
      ],
    );
  }

  Widget _menuCard(
    BuildContext context, {
    required String name,
    required String imageUrl,
    required String description,
  }) {
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
              child: imageUrl.isNotEmpty
                  ? Image.network(
                      imageUrl,
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
            name,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: _textDark,
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Text(
              description,
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
              onPressed: () => _openOrderTypePicker(context),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF4D554D), width: 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: EdgeInsets.zero,
              ),
              child: const Text(
                'Pesan',
                style: TextStyle(
                  color: Color(0xFF4D554D),
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
    required this.name,
    required this.imageUrl,
    required this.description,
  });

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
