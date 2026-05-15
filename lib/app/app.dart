import 'package:flutter/material.dart';

import '../features/auth/presentation/login_page.dart';
import '../features/auth/presentation/register_page.dart';
import '../features/cart/presentation/cart_page.dart';
import '../features/chat/presentation/chat_page.dart';
import '../features/landing/presentation/landing_page.dart';
import '../features/menu/presentation/menu_page.dart';
import '../features/history/presentation/history_page.dart';
import '../features/payment/presentation/payment_page.dart';
import '../features/profile/presentation/profile_page.dart';
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
      theme: ThemeData(
        splashFactory: NoSplash.splashFactory,
        highlightColor: Colors.transparent,
        splashColor: Colors.transparent,
        hoverColor: Colors.transparent,
        focusColor: Colors.transparent,
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ButtonStyle(
            overlayColor: WidgetStatePropertyAll<Color>(Colors.transparent),
            animationDuration: Duration.zero,
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: ButtonStyle(
            overlayColor: WidgetStatePropertyAll<Color>(Colors.transparent),
            animationDuration: Duration.zero,
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: ButtonStyle(
            overlayColor: WidgetStatePropertyAll<Color>(Colors.transparent),
            animationDuration: Duration.zero,
          ),
        ),
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: _NoPushTransitionKeepPopBuilder(
              reverseBuilder: ZoomPageTransitionsBuilder(),
            ),
            TargetPlatform.iOS: _NoPushTransitionKeepPopBuilder(
              reverseBuilder: CupertinoPageTransitionsBuilder(),
            ),
            TargetPlatform.macOS: _NoPushTransitionKeepPopBuilder(
              reverseBuilder: CupertinoPageTransitionsBuilder(),
            ),
            TargetPlatform.linux: _NoPushTransitionKeepPopBuilder(
              reverseBuilder: FadeUpwardsPageTransitionsBuilder(),
            ),
            TargetPlatform.windows: _NoPushTransitionKeepPopBuilder(
              reverseBuilder: FadeUpwardsPageTransitionsBuilder(),
            ),
          },
        ),
      ),
      initialRoute: _defaultInitialRoute,
      routes: {
        AppRoutes.login: (_) => const LoginPage(),
        AppRoutes.register: (_) => const RegisterPage(),
        AppRoutes.landing: (_) => LandingPage(),
        AppRoutes.menu: (_) => const MenuPage(),
        AppRoutes.cart: (_) => const CartPage(),
        AppRoutes.payment: (_) => const PaymentPage(),
        AppRoutes.profile: (_) => const ProfilePage(),
        AppRoutes.chat: (_) => const ChatPage(),
        AppRoutes.orderHistory: (_) => const HistoryPage(),
      },
    );
  }
}

class _NoPushTransitionKeepPopBuilder extends PageTransitionsBuilder {
  const _NoPushTransitionKeepPopBuilder({required this.reverseBuilder});

  final PageTransitionsBuilder reverseBuilder;

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (animation.status == AnimationStatus.forward) {
      return child;
    }
    return reverseBuilder.buildTransitions(
      route,
      context,
      animation,
      secondaryAnimation,
      child,
    );
  }
}
