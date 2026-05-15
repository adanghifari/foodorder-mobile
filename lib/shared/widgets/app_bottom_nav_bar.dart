import 'package:flutter/material.dart';

enum AppBottomNavItem {
  home,
  menu,
  history,
  account,
}

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

  final AppBottomNavItem activeItem;
  final VoidCallback onHomeTap;
  final VoidCallback onMenuTap;
  final VoidCallback onScanTap;
  final VoidCallback onHistoryTap;
  final VoidCallback onAccountTap;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: SizedBox(
        height: 98,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: Color(0xFFE8E8E8)),
                ),
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
                  const SizedBox(width: 92),
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
            Positioned(
              left: 0,
              right: 0,
              top: -28,
              child: Center(
                child: GestureDetector(
                  onTap: onScanTap,
                  child: Container(
                    width: 84,
                    height: 84,
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
                        Icon(Icons.qr_code_scanner_rounded,
                            color: Colors.white, size: 28),
                        SizedBox(height: 2),
                        Text(
                          'Scan',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
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
        padding: const EdgeInsets.only(top: 14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: active ? _accent : _navText,
              size: 24,
            ),
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
}
