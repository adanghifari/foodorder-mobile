import 'package:flutter/material.dart';

enum AppBottomNavItem { home, menu, history, account }

class AppBottomNavBar extends StatelessWidget {
  const AppBottomNavBar({
    super.key,
    required this.activeItem,
    required this.onHomeTap,
    required this.onMenuTap,
    required this.onScanTap,
    required this.onHistoryTap,
    required this.onAccountTap,
  });

  static const Color _accent = Color(0xFFD45A00);
  static const Color _navText = Color(0xFF6A6A6A);
  static const double _scanButtonSize = 82;

  final AppBottomNavItem activeItem;
  final VoidCallback onHomeTap;
  final VoidCallback onMenuTap;
  final VoidCallback onScanTap;
  final VoidCallback onHistoryTap;
  final VoidCallback onAccountTap;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    const navHeight =65.0;

    return SizedBox(
      height: navHeight + bottomInset,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: Container(
              padding: EdgeInsets.only(bottom: bottomInset - 30),
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
                      active: activeItem == AppBottomNavItem.home,
                      onTap: onHomeTap,
                    ),
                  ),
                  Expanded(
                    child: _navItem(
                      label: 'Menu',
                      icon: Icons.menu_book_rounded,
                      active: activeItem == AppBottomNavItem.menu,
                      onTap: onMenuTap,
                    ),
                  ),
                  Expanded(child: _scanLabel(onTap: onScanTap)),
                  Expanded(
                    child: _navItem(
                      label: 'Riwayat',
                      icon: Icons.receipt_long_rounded,
                      active: activeItem == AppBottomNavItem.history,
                      onTap: onHistoryTap,
                    ),
                  ),
                  Expanded(
                    child: _navItem(
                      label: 'Akun',
                      icon: Icons.person_outline_rounded,
                      active: activeItem == AppBottomNavItem.account,
                      onTap: onAccountTap,
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
                onTap: onScanTap,
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
        ],
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
      child: const Padding(
        padding: EdgeInsets.only(top: 52),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Scan',
              style: TextStyle(
                color: _navText,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
