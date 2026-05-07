import 'package:flutter/material.dart';

import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/register_screen.dart';
import '../features/cart/presentation/cart_page.dart';
import '../features/chat/presentation/chat_screen.dart';
import '../features/landing/presentation/landing_page.dart';
import '../features/menu/presentation/menu_page.dart';
import '../features/payment/presentation/payment_page.dart';
import '../features/profile/presentation/screens/profile_page.dart';
import 'app_routes.dart';

class KedaiKlikApp extends StatelessWidget {
  const KedaiKlikApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'KedaiKlik',
      initialRoute: AppRoutes.login,
      routes: {
        AppRoutes.login: (_) => const LoginScreen(),
        AppRoutes.register: (_) => const RegisterScreen(),
        AppRoutes.landing: (_) => const LandingPage(),
        AppRoutes.menu: (_) => const MenuPage(),
        AppRoutes.cart: (_) => const CartPage(),
        AppRoutes.payment: (_) => const PaymentPage(),
        AppRoutes.profile: (_) => const ProfilePage(),
        AppRoutes.chat: (_) => const ChatScreen(),
      },
    );
  }
}
