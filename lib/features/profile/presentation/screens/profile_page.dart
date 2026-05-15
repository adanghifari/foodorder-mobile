import 'package:flutter/material.dart';

import '../../../../app/app_routes.dart';
import '../../../../shared/widgets/app_back_button.dart';
import '../../../../shared/widgets/app_bottom_nav_bar.dart';
import '../../../auth/presentation/auth_session.dart';
import '../../../landing/presentation/order_type_session.dart';
import 'favorit_page.dart';
import 'pengaturan_page.dart';
import 'profile_api_service.dart';
import 'struk_page.dart';
import 'tentang_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final ProfileApiService _profileApiService = ProfileApiService();

  bool _isLoading = true;
  String? _error;
  ProfileUserDto? _user;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final user = await _profileApiService.fetchMe();
      if (!mounted) return;
      setState(() {
        _user = user;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      bottomNavigationBar: AppBottomNavBar(
        activeItem: AppBottomNavItem.account,
        onHomeTap: () => Navigator.pushNamed(context, AppRoutes.landing),
        onMenuTap: () => Navigator.pushNamed(context, AppRoutes.menu),
        onScanTap: () => ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Fitur scan akan segera tersedia.'),
            duration: Duration(seconds: 1),
          ),
        ),
        onHistoryTap: () => Navigator.pushNamed(context, AppRoutes.orderHistory),
        onAccountTap: () {},
      ),
      body: Stack(
        children: [
          Container(
            height: MediaQuery.of(context).size.height * 0.45,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFC6620C),
                  Color(0xFFFFFFFF),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 10,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const AppBackButton(
                        color: Colors.white,
                        size: 20,
                      ),
                      const Text(
                        'Profil',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.settings_outlined,
                          color: Colors.white,
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const PengaturanPage(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: _buildContent(context),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: Colors.redAccent),
          const SizedBox(height: 8),
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.redAccent, fontSize: 12),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: _loadProfile,
            child: const Text('Coba lagi'),
          ),
        ],
      );
    }

    final user = _user;
    if (user == null) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        Row(
          children: [
            const CircleAvatar(
              radius: 45,
              backgroundImage: AssetImage('assets/slices_ui/fotoprofile.jpg'),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  Text(
                    user.email,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.grey,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                  Text(
                    user.phone,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit, size: 20, color: Colors.black),
              onPressed: () {},
            ),
          ],
        ),
        const SizedBox(height: 25),
        const Divider(thickness: 1, color: Color(0xFFEEEEEE)),
        _buildMenuTile(
          context,
          icon: Icons.assignment_outlined,
          title: 'Pesanan saya',
          destination: null,
          namedRoute: AppRoutes.orderHistory,
        ),
        _buildMenuTile(
          context,
          icon: Icons.bookmark_border,
          title: 'Favorit',
          destination: const FavoritPage(),
        ),
        _buildMenuTile(
          context,
          icon: Icons.receipt_long_outlined,
          title: 'Struk',
          destination: const StrukPage(),
        ),
        _buildMenuTile(
          context,
          icon: Icons.info_outline,
          title: 'Tentang',
          destination: const TentangPage(),
        ),
        _buildMenuTile(
          context,
          icon: Icons.exit_to_app,
          title: 'Keluar',
          destination: null,
          isLast: true,
        ),
      ],
    );
  }

  Widget _buildMenuTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Widget? destination,
    String? namedRoute,
    bool isLast = false,
  }) {
    return Column(
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFC7985F).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xFFC7985F), size: 22),
          ),
          title: Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
          ),
          onTap: () async {
            if (title == 'Keluar') {
              await AuthSession.clear();
              await OrderTypeSession.clear();
              if (!context.mounted) return;
              Navigator.pushNamedAndRemoveUntil(
                context,
                AppRoutes.login,
                (route) => false,
              );
              return;
            }

            if (namedRoute != null) {
              Navigator.pushNamed(context, namedRoute);
            } else if (destination != null) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => destination),
              );
            }
          },
        ),
        if (!isLast)
          const Divider(thickness: 1, color: Color(0xFFEEEEEE), height: 1),
      ],
    );
  }
}
