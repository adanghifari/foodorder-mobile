import 'package:flutter/material.dart';

import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/register_screen.dart';
import '../features/cart/presentation/cart_page.dart';
import '../features/chat/presentation/chat_screen.dart';
import '../features/landing/presentation/landing_page.dart';
import '../features/menu/presentation/menu_page.dart';
import '../features/history/presentation/history_page.dart';
import '../features/payment/presentation/payment_page.dart';
import '../features/profile/presentation/screens/profile_page.dart';
import 'app_routes.dart';

class KedaiKlikApp extends StatelessWidget {
  const KedaiKlikApp({super.key});
  static const String _defaultInitialRoute = String.fromEnvironment(
    'INITIAL_ROUTE',
    defaultValue: AppRoutes.landing,
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'KedaiKlik',
      initialRoute: _defaultInitialRoute,
      routes: {
        AppRoutes.login: (_) => const LoginScreen(),
        AppRoutes.register: (_) => const RegisterScreen(),
        AppRoutes.landing: (_) => LandingPage(),
        AppRoutes.menu: (_) => const MenuPage(),
        AppRoutes.cart: (_) => const CartPage(),
        AppRoutes.payment: (_) => const PaymentPage(),
        AppRoutes.profile: (_) => const ProfilePage(),
        AppRoutes.chat: (_) => const ChatScreen(),
        AppRoutes.orderHistory: (_) => const HistoryPage(),
      },
    );
  }
}
