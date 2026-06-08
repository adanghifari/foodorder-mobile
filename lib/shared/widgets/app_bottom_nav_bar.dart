import 'package:flutter/material.dart';

enum AppBottomNavItem { home, menu, history, account }

class AppBottomNavBar extends StatefulWidget {
  const AppBottomNavBar({
    super.key,
    required this.activeItem,
    required this.onHomeTap,
    required this.onMenuTap,
    required this.onScanTap,
    required this.onHistoryTap,
    required this.onAccountTap,
    this.enableEntranceAnimation = false,
    this.enableScanPulse = false,
  });

  final AppBottomNavItem activeItem;
  final VoidCallback onHomeTap;
  final VoidCallback onMenuTap;
  final VoidCallback onScanTap;
  final VoidCallback onHistoryTap;
  final VoidCallback onAccountTap;
  final bool enableEntranceAnimation;
  final bool enableScanPulse;

  @override
  State<AppBottomNavBar> createState() => _AppBottomNavBarState();
}

class _AppBottomNavBarState extends State<AppBottomNavBar>
    with SingleTickerProviderStateMixin {
  static const Color _accent = Color(0xFFD45A00);
  static const Color _navText = Color(0xFF6A6A6A);
  static const double _scanButtonSize = 82;

  late final AnimationController _pulseController;
  bool _entered = false;
  bool _scanPressed = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _entered = true);
      if (widget.enableScanPulse) {
        _pulseController.repeat(reverse: true);
      }
    });
  }

  @override
  void didUpdateWidget(covariant AppBottomNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.enableScanPulse && !_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
    }
    if (!widget.enableScanPulse && _pulseController.isAnimating) {
      _pulseController.stop();
      _pulseController.value = 0;
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    const navHeight = 65.0;
    final safeBottomPadding = (bottomInset - 30).clamp(0.0, double.infinity);

    final nav = SizedBox(
      height: navHeight + bottomInset,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: Container(
              padding: EdgeInsets.only(bottom: safeBottomPadding),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Color(0xFFE8E8E8))),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x14000000),
                    blurRadius: 14,
                    offset: Offset(0, -4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _navItem(
                      label: 'Beranda',
                      icon: Icons.home_rounded,
                      active: widget.activeItem == AppBottomNavItem.home,
                      onTap: widget.onHomeTap,
                    ),
                  ),
                  Expanded(
                    child: _navItem(
                      label: 'Menu',
                      icon: Icons.menu_book_rounded,
                      active: widget.activeItem == AppBottomNavItem.menu,
                      onTap: widget.onMenuTap,
                    ),
                  ),
                  Expanded(child: _scanLabel(onTap: widget.onScanTap)),
                  Expanded(
                    child: _navItem(
                      label: 'Riwayat',
                      icon: Icons.receipt_long_rounded,
                      active: widget.activeItem == AppBottomNavItem.history,
                      onTap: widget.onHistoryTap,
                    ),
                  ),
                  Expanded(
                    child: _navItem(
                      label: 'Akun',
                      icon: Icons.person_outline_rounded,
                      active: widget.activeItem == AppBottomNavItem.account,
                      onTap: widget.onAccountTap,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: -24,
            child: Center(
              child: GestureDetector(
                onTapDown: (_) => setState(() => _scanPressed = true),
                onTapCancel: () => setState(() => _scanPressed = false),
                onTapUp: (_) => setState(() => _scanPressed = false),
                onTap: widget.onScanTap,
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 1, end: 1),
                  duration: const Duration(milliseconds: 120),
                  builder: (context, _, child) {
                    return AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        final pulse = widget.enableScanPulse
                            ? (0.96 + (_pulseController.value * 0.04))
                            : 1.0;
                        final pressedScale = _scanPressed ? 0.95 : 1.0;
                        return Transform.scale(
                          scale: pulse * pressedScale,
                          child: child,
                        );
                      },
                      child: child,
                    );
                  },
                  child: Container(
                    width: _scanButtonSize,
                    height: _scanButtonSize,
                    decoration: const BoxDecoration(
                      color: _accent,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x30000000),
                          blurRadius: 16,
                          offset: Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.qr_code_scanner_rounded,
                          color: Colors.white,
                          size: 30,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    if (!widget.enableEntranceAnimation) {
      return nav;
    }

    return AnimatedSlide(
      offset: _entered ? Offset.zero : const Offset(0, 0.15),
      duration: const Duration(milliseconds: 520),
      curve: Curves.easeOutCubic,
      child: AnimatedOpacity(
        opacity: _entered ? 1 : 0,
        duration: const Duration(milliseconds: 520),
        curve: Curves.easeOutCubic,
        child: nav,
      ),
    );
  }

  Widget _navItem({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    bool active = false,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: active ? _accent : _navText, size: 24),
            const SizedBox(height: 5),
            Text(
              label,
              style: TextStyle(
                color: active ? _accent : _navText,
                fontSize: 12,
                fontWeight: active ? FontWeight.w700 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _scanLabel({required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: const Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: EdgeInsets.only(bottom: 6),
          child: Text(
            'Scan',
            style: TextStyle(
              color: _navText,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
