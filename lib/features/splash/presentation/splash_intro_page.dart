import 'dart:async';

import 'package:flutter/material.dart';

import '../../../app/app_routes.dart';

class SplashIntroPage extends StatefulWidget {
  const SplashIntroPage({super.key});

  @override
  State<SplashIntroPage> createState() => _SplashIntroPageState();
}

class _SplashIntroPageState extends State<SplashIntroPage>
    with TickerProviderStateMixin {
  static const Duration _totalDuration = Duration(milliseconds: 2200);
  static const String _tagline = 'Rasa Juara, Pesan Cuma Pakai Klik!';

  late final AnimationController _introController;
  late final AnimationController _loopController;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _glowAnimation;
  late final Animation<double> _shineAnimation;
  Timer? _nextPageTimer;

  @override
  void initState() {
    super.initState();
    _introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..forward();
    _loopController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2100),
    )..repeat();

    _fadeAnimation = CurvedAnimation(
      parent: _introController,
      curve: Curves.easeOut,
    );
    _scaleAnimation = Tween<double>(begin: 0.92, end: 1).animate(
      CurvedAnimation(parent: _introController, curve: Curves.easeOutBack),
    );
    _glowAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.35, end: 1),
        weight: 45,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1, end: 0.5),
        weight: 55,
      ),
    ]).animate(
      CurvedAnimation(parent: _loopController, curve: Curves.easeInOut),
    );
    _shineAnimation = Tween<double>(begin: -1.4, end: 1.4).animate(
      CurvedAnimation(parent: _loopController, curve: Curves.easeInOutCubic),
    );

    _nextPageTimer = Timer(_totalDuration, _goToLanding);
  }

  @override
  void dispose() {
    _nextPageTimer?.cancel();
    _introController.dispose();
    _loopController.dispose();
    super.dispose();
  }

  void _goToLanding() {
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, AppRoutes.landing);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      body: Center(
        child: AnimatedBuilder(
          animation: Listenable.merge([_introController, _loopController]),
          builder: (context, child) {
            final glow = _glowAnimation.value;
            final visibleChars = (_tagline.length * _introController.value)
                .clamp(0, _tagline.length)
                .toInt();
            final typedText = _tagline.substring(0, visibleChars);
            return FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: SizedBox(
                  width: 390,
                  height: 390,
                  child: Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 520,
                        height: 520,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              const Color(
                                0xFFC6620C,
                              ).withValues(alpha: 0.34 * glow),
                              const Color(0xFFC6620C).withValues(alpha: 0),
                            ],
                          ),
                        ),
                      ),
                      Container(
                        width: 390,
                        height: 390,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              const Color(0xFFFFD9B8).withValues(
                                alpha: 0.30 * glow,
                              ),
                              const Color(0xFFFFD9B8).withValues(alpha: 0),
                            ],
                          ),
                        ),
                      ),
                      ClipRect(
                        child: SizedBox(
                          width: 390,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Image.asset(
                                'assets/logo.png',
                                width: 370,
                                fit: BoxFit.contain,
                              ),
                              Transform.translate(
                                offset: Offset(390 * _shineAnimation.value, 0),
                                child: Transform.rotate(
                                  angle: -0.35,
                                  child: Container(
                                    width: 42,
                                    height: 360,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          Colors.white.withValues(alpha: 0),
                                          Colors.white.withValues(alpha: 0.26),
                                          Colors.white.withValues(alpha: 0),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 42,
                        left: 25,
                        right: 25,
                        child: Text(
                          typedText,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF8A3D00),
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
