import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:dio/dio.dart';

import '../../../app/app_routes.dart';
import '../../auth/data/auth_session.dart';

import 'order_type_picker_page.dart';
import '../data/order_type_session.dart';
import '../data/landing_top_menu_service.dart';
import '../../../shared/widgets/app_bottom_nav_bar.dart';
import '../../../shared/widgets/app_notice.dart';
import '../../../shared/config/api_config.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  final LandingTopMenuService _topMenuService = LandingTopMenuService();
  static const double _chatShortcutWidth = 148;
  static const double _chatShortcutHeight = 50;
  static const double _chatShortcutEdgePadding = 12;
  static const double _chatShortcutTopSafePadding = 10;
  static const double _chatShortcutBottomSafePadding = 10;
  static const Duration _welcomeDuration = Duration(milliseconds: 640);
  static const Duration _welcomeTimeline = Duration(milliseconds: 2100);
  static const Duration _loopTimeline = Duration(milliseconds: 4200);
  static const double _chatBottomClearance = 92;

  late List<_LandingMenuCardData> _menuCards;
  final ScrollController _scrollController = ScrollController();
  late final AnimationController _welcomeController;
  late final AnimationController _loopController;
  bool _isFromBackend = false;
  String? _loadError;
  bool _isLoggedIn = false;
  String _username = 'Pengguna';
  String _name = 'Pengguna';
  String? _avatarUrl;
  Offset? _chatShortcutPosition;
  bool _menuSectionRevealed = false;
  bool _menuGridRevealed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _welcomeController = AnimationController(
      vsync: this,
      duration: _welcomeTimeline,
    );
    _loopController = AnimationController(
      vsync: this,
      duration: _loopTimeline,
    );
    _menuCards = _fallbackMenus;
    _loadTopMenus();
    _loadAuthState();
    _scrollController.addListener(_handleScrollReveal);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _welcomeController.forward(from: 0);
      if (!_reducedMotion) {
        _loopController.repeat(reverse: true);
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.removeListener(_handleScrollReveal);
    _scrollController.dispose();
    _welcomeController.dispose();
    _loopController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadAuthState();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_reducedMotion) {
      _loopController.stop();
      _loopController.value = 0;
    } else if (!_loopController.isAnimating) {
      _loopController.repeat(reverse: true);
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
          _loadError = AppNotice.humanizeMessage(e);
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
        _name = 'Pengguna';
        _avatarUrl = null;
      });
      return;
    }

    try {
      final baseUrl = ApiConfig.apiBaseUrl;
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
      final name = (data['name'] ?? data['username'] ?? 'Pengguna').toString();
      final avatarVal = data['avatar_url'] ?? data['photo'] ?? data['profile_picture'];
      setState(() {
        _isLoggedIn = true;
        _username = username;
        _name = name;
        _avatarUrl = (avatarVal == null || avatarVal.toString() == 'null') ? null : avatarVal.toString();
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoggedIn = false;
        _username = 'Pengguna';
        _name = 'Pengguna';
        _avatarUrl = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: _bg,
      bottomNavigationBar: _staggeredEntrance(
        delayMs: 1080,
        offsetY: 24,
        child: AppBottomNavBar(
          activeItem: AppBottomNavItem.home,
          onHomeTap: () {},
          onMenuTap: () => Navigator.pushNamed(context, AppRoutes.menu),
          onScanTap: () => Navigator.pushNamed(context, AppRoutes.scan),
          onHistoryTap: () =>
              Navigator.pushNamed(context, AppRoutes.orderHistory),
          onAccountTap: () => Navigator.pushNamed(context, AppRoutes.profile),
          enableEntranceAnimation: true,
          enableScanPulse: !_reducedMotion,
        ),
      ),
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final viewportSize = Size(
              constraints.maxWidth,
              constraints.maxHeight,
            );
            final defaultPosition = Offset(
              viewportSize.width -
                  _chatShortcutWidth -
                  _chatShortcutEdgePadding,
              viewportSize.height -
                  _chatShortcutHeight -
                  _chatShortcutBottomSafePadding -
                  bottomInset,
            );
            final currentPosition = _clampChatShortcutPosition(
              _chatShortcutPosition ?? defaultPosition,
              viewportSize: viewportSize,
              topInset: topInset,
              bottomInset: bottomInset,
            );

            return Stack(
              children: [
                SafeArea(
                  bottom: false,
                  child: NotificationListener<ScrollNotification>(
                    onNotification: (notification) {
                      if (notification is ScrollUpdateNotification) {
                        _handleScrollReveal();
                      }
                      return false;
                    },
                    child: SingleChildScrollView(
                      controller: _scrollController,
                    child: Column(
                      children: [
                        _buildHero(context),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(22, 0, 22, 30),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _staggeredEntrance(
                                delayMs: 80,
                                offsetY: 22,
                                child: Transform.translate(
                                  offset: const Offset(0, -30),
                                  child: _buildTopOptionRow(context),
                                ),
                              ),
                              const SizedBox(height: 0),
                              _staggeredEntrance(
                                delayMs: 150,
                                offsetY: 18,
                                child: _buildSectionTitle(),
                              ),
                              const SizedBox(height: 18),
                              _staggeredEntrance(
                                delayMs: 230,
                                offsetY: 16,
                                child: _buildMenuGrid(context),
                              ),
                              const SizedBox(height: 26),
                              _scrollReveal(
                                revealed: _menuGridRevealed,
                                delayMs: 180,
                                offsetY: 18,
                                child: _buildBottomInfo(),
                              ),
                              const SizedBox(height: 22),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  ),
                ),
                Positioned(
                  left: currentPosition.dx,
                  top: currentPosition.dy,
                  child: AnimatedBuilder(
                    animation: _loopController,
                    builder: (context, child) {
                      final loopY = _reducedMotion
                          ? 0.0
                          : (4 * (1 - _loopController.value));
                      return Transform.translate(
                        offset: Offset(0, loopY),
                        child: child,
                      );
                    },
                    child: _springEntrance(
                      delayMs: 1240,
                      child: _buildChatShortcut(
                        context,
                        viewportSize: viewportSize,
                        topInset: topInset,
                        bottomInset: bottomInset,
                        currentPosition: currentPosition,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _staggeredEntrance({
    required Widget child,
    required int delayMs,
    double offsetY = 16,
  }) {
    return AnimatedBuilder(
      animation: _welcomeController,
      builder: (context, child) {
        final value = _entranceProgress(delayMs);
        return Transform.translate(
          offset: Offset(0, (1 - value) * offsetY),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: child,
    );
  }

  Widget _springEntrance({required Widget child, required int delayMs}) {
    return AnimatedBuilder(
      animation: _welcomeController,
      builder: (context, _) {
        final timelineMs = _welcomeTimeline.inMilliseconds;
        final begin = (delayMs / timelineMs).clamp(0.0, 1.0);
        final end = ((delayMs + 680) / timelineMs).clamp(begin + 0.01, 1.0);
        final curve = Interval(begin, end, curve: Curves.elasticOut);
        final value = curve.transform(_welcomeController.value.clamp(0.0, 1.0));
        return Opacity(
          opacity: value.clamp(0.0, 1.0),
          child: Transform.scale(
            scale: 0.8 + (0.2 * value),
            child: child,
          ),
        );
      },
    );
  }

  Widget _scrollReveal({
    required bool revealed,
    required Widget child,
    int delayMs = 0,
    double offsetY = 16,
  }) {
    return AnimatedOpacity(
      opacity: revealed ? 1 : 0,
      duration: Duration(milliseconds: _reducedMotion ? 180 : 520),
      curve: Curves.easeOutCubic,
      child: AnimatedSlide(
        offset: revealed ? Offset.zero : Offset(0, offsetY / 100),
        duration: Duration(milliseconds: _reducedMotion ? 180 : 520),
        curve: Curves.easeOutCubic,
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: revealed ? 1 : 0),
          duration: Duration(milliseconds: _reducedMotion ? 120 : 420),
          curve: Interval(
            (delayMs / 600).clamp(0.0, 0.95),
            1.0,
            curve: Curves.easeOut,
          ),
          builder: (context, value, inner) => Opacity(opacity: value, child: inner),
          child: child,
        ),
      ),
    );
  }

  double _entranceProgress(int delayMs) {
    final timelineMs = (_welcomeController.duration ?? _welcomeTimeline)
        .inMilliseconds;
    final begin = delayMs / timelineMs;
    final end = (delayMs + _welcomeDuration.inMilliseconds) /
        timelineMs;
    final safeBegin = begin.clamp(0.0, 1.0);
    final safeEnd = end.clamp(safeBegin + 0.01, 1.0);
    final curve = Interval(safeBegin, safeEnd, curve: Curves.easeInOutCubic);
    return curve.transform(_welcomeController.value.clamp(0.0, 1.0));
  }

  double _intervalProgress(int startMs, int endMs) {
    final timelineMs = (_welcomeController.duration ?? _welcomeTimeline)
        .inMilliseconds;
    final begin = (startMs / timelineMs).clamp(0.0, 1.0);
    final end = (endMs / timelineMs).clamp(begin + 0.01, 1.0);
    final curve = Interval(begin, end, curve: Curves.easeOutCubic);
    return curve.transform(_welcomeController.value.clamp(0.0, 1.0));
  }

  bool get _reducedMotion {
    final media = MediaQuery.maybeOf(context);
    return media?.disableAnimations == true ||
        media?.accessibleNavigation == true;
  }

  void _handleScrollReveal() {
    if (!_scrollController.hasClients || !mounted) return;
    final offset = _scrollController.offset;
    var changed = false;
    if (!_menuSectionRevealed && offset > 90) {
      _menuSectionRevealed = true;
      changed = true;
    }
    if (!_menuGridRevealed && offset > 160) {
      _menuGridRevealed = true;
      changed = true;
    }
    if (changed) {
      setState(() {});
    }
  }

  Offset _clampChatShortcutPosition(
    Offset position, {
    required Size viewportSize,
    required double topInset,
    required double bottomInset,
  }) {
    final minX = _chatShortcutEdgePadding;
    final maxX =
        viewportSize.width - _chatShortcutWidth - _chatShortcutEdgePadding;
    final minY = topInset + _chatShortcutTopSafePadding;
    final maxY =
        viewportSize.height -
        _chatShortcutHeight -
        _chatShortcutBottomSafePadding -
        bottomInset -
        _chatBottomClearance;

    return Offset(position.dx.clamp(minX, maxX), position.dy.clamp(minY, maxY));
  }

  Widget _buildChatShortcut(
    BuildContext context, {
    required Size viewportSize,
    required double topInset,
    required double bottomInset,
    required Offset currentPosition,
  }) {
    return GestureDetector(
      dragStartBehavior: DragStartBehavior.down,
      behavior: HitTestBehavior.opaque,
      onPanUpdate: (details) {
        final basePosition = _chatShortcutPosition ?? currentPosition;
        final nextPosition = Offset(
          basePosition.dx + details.delta.dx,
          basePosition.dy + details.delta.dy,
        );
        setState(() {
          _chatShortcutPosition = _clampChatShortcutPosition(
            nextPosition,
            viewportSize: viewportSize,
            topInset: topInset,
            bottomInset: bottomInset,
          );
        });
      },
      onPanEnd: (_) {
        final position = _chatShortcutPosition ?? currentPosition;
        final leftSnap = _chatShortcutEdgePadding;
        final rightSnap =
            viewportSize.width - _chatShortcutWidth - _chatShortcutEdgePadding;
        final midpoint = viewportSize.width / 2;
        final snapX = (position.dx + (_chatShortcutWidth / 2) < midpoint)
            ? leftSnap
            : rightSnap;

        setState(() {
          _chatShortcutPosition = Offset(snapX, position.dy);
        });
      },
      child: Material(
        color: Colors.transparent,
        child: FloatingAssistiveButton(
          width: _chatShortcutWidth,
          height: _chatShortcutHeight,
          imageAsset: 'assets/kedaibot.png',
          badgePulse: _reducedMotion ? 1.0 : (0.9 + (_loopController.value * 0.14)),
          onTap: () => Navigator.pushNamed(context, AppRoutes.chat),
        ),
      ),
    );
  }

  Widget _buildHero(BuildContext context) {
    final foodFloatOffset = _reducedMotion ? 0.0 : 6 * (1 - _loopController.value);
    final waveOffset = _reducedMotion ? 0.0 : (_loopController.value - 0.5) * 14;

    return SizedBox(
      height: 362,
      child: Stack(
        children: [
          Container(color: const Color(0xFFEAEAEA)),
          Positioned(
            left: -10,
            bottom: 165,
            child: _staggeredEntrance(
              delayMs: 20,
              offsetY: 16,
              child: SizedBox(
                width: 240,
                child: Image.asset(
                  'assets/logo.png',
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          Positioned(
            left: 24,
            bottom: 140,
            child: _staggeredEntrance(
              delayMs: 120,
              offsetY: 14,
              child: const Text(
                '100% Tasty',
                style: TextStyle(
                  color: _textDark,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                ),
              ),
            ),
          ),
          Positioned(
            left: 24,
            bottom: 118,
            child: _staggeredEntrance(
              delayMs: 220,
              offsetY: 12,
              child: const Text(
                'Rasa Juara, Pesan Cuma Pakai Klik!',
                style: TextStyle(
                  color: Color(0xFF575757),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          AnimatedBuilder(
            animation: _welcomeController,
            builder: (context, child) {
              final progress = Curves.easeOutCubic.transform(
                _intervalProgress(160, 760),
              );
              return Positioned(
                right: -40 + (1 - progress) * 24,
                bottom: 30 + foodFloatOffset,
                child: Opacity(
                  opacity: progress,
                  child: Transform.scale(
                    scale: 0.95 + (0.05 * progress),
                    child: child,
                  ),
                ),
              );
            },
            child: Transform.rotate(
              angle: -0.42,
              child: Image.asset(
                'assets/foto katalog/hidangan.png',
                width: 248,
                fit: BoxFit.cover,
              ),
            ),
          ),
          AnimatedBuilder(
            animation: _loopController,
            builder: (context, child) {
              return Positioned(
                left: 0,
                right: 0,
                bottom: 50,
                child: Transform.translate(
                  offset: Offset(waveOffset, 0),
                  child: child,
                ),
              );
            },
            child: CustomPaint(
              size: const Size(double.infinity, 64),
              painter: _HeroWavePainter(),
            ),
          ),
          AnimatedBuilder(
            animation: _welcomeController,
            builder: (context, child) {
              final value = Curves.easeOut.transform(_intervalProgress(30, 420));
              return Positioned(
                top: 16 - (1 - value) * 10,
                left: 16,
                child: Opacity(opacity: value, child: child),
              );
            },
            child: _isLoggedIn
                ? Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
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
                        _avatarUrl != null && _avatarUrl!.isNotEmpty
                            ? CircleAvatar(
                                radius: 14,
                                backgroundImage: NetworkImage(_avatarUrl!),
                              )
                            : Container(
                                width: 28,
                                height: 28,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFC7985F),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    _getInitials(_name),
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
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
                    child: _PressableScale(
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
                        child: const Text('Login'),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle() {
    final lineProgress = _reducedMotion
        ? 1.0
        : Curves.easeOutCubic.transform(_intervalProgress(360, 820));
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
          Container(width: 126 * lineProgress, height: 5, color: _accentDark),
          const SizedBox(height: 8),
          AnimatedOpacity(
            opacity: _menuSectionRevealed ? 1 : 0.72,
            duration: const Duration(milliseconds: 280),
            child: Text(
              _isFromBackend ? 'Sumber: Backend' : 'Sumber: Fallback',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF6C6C6C),
              ),
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
    final cards = <Widget>[
      ..._menuCards.map((menu) => _menuCard(context, menu: menu)),
      _othersCard(context),
    ];
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 0.64,
      children: List.generate(cards.length, (index) {
        return _staggeredEntrance(
          delayMs: 260 + (index * 110),
          offsetY: 24,
          child: cards[index],
        );
      }),
    );
  }

  Widget _menuCard(BuildContext context, {required _LandingMenuCardData menu}) {
    final isOutOfStock = menu.stock < 1;
    return _PressableScale(
      scale: 0.98,
      child: Container(
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
    ),
    );
  }

  Widget _othersCard(BuildContext context) {
    return _PressableScale(
      scale: 0.98,
      child: InkWell(
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
    ),
    );
  }

  Widget _buildTopOptionRow(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _staggeredEntrance(
            delayMs: 440,
            offsetY: 20,
            child: _whyTile(
              context,
              icon: Icons.restaurant,
              label: 'Booking\nmeja',
              orderType: OrderType.bookingDineIn,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _staggeredEntrance(
            delayMs: 560,
            offsetY: 20,
            child: _whyTile(
              context,
              icon: Icons.storefront,
              label: 'Pesan &\nambil',
              orderType: OrderType.pickup,
            ),
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
    return _PressableScale(
      scale: 0.97,
      child: InkWell(
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
    // Using a special sentinel value to detect "Scan QR" selection.
    // We return null for cancel, an OrderType for normal selection,
    // and handle scan QR via a flag.
    var isScanQr = false;
    final result = await showModalBottomSheet<OrderType?>(
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
                  title: const Text('Booking meja'),
                  onTap: () =>
                      Navigator.pop(sheetContext, OrderType.bookingDineIn),
                ),
                ListTile(
                  leading: const Icon(Icons.storefront, color: _accent),
                  title: const Text('Pesan & ambil'),
                  onTap: () => Navigator.pop(sheetContext, OrderType.pickup),
                ),
                ListTile(
                  leading: const Icon(Icons.qr_code_scanner, color: _accent),
                  title: const Text('Scan QR'),
                  onTap: () {
                    isScanQr = true;
                    Navigator.pop(sheetContext, null);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );

    if (isScanQr) {
      if (!mounted) return null;
      Navigator.pushNamed(context, AppRoutes.scan);
      return null;
    }
    return result;
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

    if (!mounted) return;
    final orderType = await _pickOrderType(context);
    if (orderType == null) return;
    await OrderTypeSession.set(orderType);

    if (!mounted) return;
    Navigator.pushNamed(context, AppRoutes.menu);
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

  String _getInitials(String name) {
    if (name.isEmpty || name == '-') return 'U';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length > 1) {
      final first = parts[0].isNotEmpty ? parts[0][0] : '';
      final second = parts[1].isNotEmpty ? parts[1][0] : '';
      return (first + second).toUpperCase();
    }
    return parts[0].isNotEmpty ? parts[0][0].toUpperCase() : 'U';
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

class _PressableScale extends StatefulWidget {
  const _PressableScale({
    required this.child,
    this.scale = 0.97,
  });

  final Widget child;
  final double scale;

  @override
  State<_PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<_PressableScale> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => setState(() => _pressed = true),
      onPointerUp: (_) => setState(() => _pressed = false),
      onPointerCancel: (_) => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? widget.scale : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

class FloatingAssistiveButton extends StatelessWidget {
  const FloatingAssistiveButton({
    super.key,
    required this.imageAsset,
    required this.onTap,
    this.badgePulse = 1,
    this.width = 148,
    this.height = 50,
  });

  final String imageAsset;
  final VoidCallback onTap;
  final double badgePulse;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final avatarSize = height - 6;
    final radius = height / 2;

    return Semantics(
      button: true,
      label: 'Assistive chat button',
      child: GestureDetector(
        onTap: onTap,
        child: SizedBox(
          width: width,
          height: height,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: width,
                height: height,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(radius),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: avatarSize,
                      height: avatarSize,
                      decoration: BoxDecoration(
                        color: Color(0xFFEAEAEA),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.all(2),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        clipBehavior: Clip.antiAliasWithSaveLayer,
                        child: Image.asset(
                          imageAsset,
                          fit: BoxFit.cover,
                          filterQuality: FilterQuality.high,
                          isAntiAlias: true,
                          gaplessPlayback: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'KedaiBot',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                right: -8,
                top: -14,
                child: IgnorePointer(
                  child: Transform.scale(
                    scale: badgePulse,
                    child: Image.asset(
                      'assets/chat.png',
                      width: 35,
                      height: 35,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.high,
                      isAntiAlias: true,
                      errorBuilder: (_, __, ___) => const SizedBox(
                        width: 35,
                        height: 35,
                        child: Icon(
                          Icons.chat_bubble_outline_rounded,
                          size: 20,
                          color: Color(0xFFC6620C),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
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
