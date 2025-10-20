import 'dart:math';
import 'package:flutter/material.dart';
import 'widgets/leaf_background.dart';
import 'screens/auth_screen.dart';

class AnimatedSplash extends StatefulWidget {
  const AnimatedSplash({super.key});

  @override
  State<AnimatedSplash> createState() => _AnimatedSplashState();
}

class _AnimatedSplashState extends State<AnimatedSplash>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _exitLeafController;

  bool _exiting = false;

  @override
  void initState() {
    super.initState();

    // Анимация появления
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..forward();

    // Анимация "разлета" листьев
    _exitLeafController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    // Запуск выхода после показа
    Future.delayed(const Duration(seconds: 3), _startExitAnimation);
  }

  void _startExitAnimation() {
    if (_exiting) return;
    _exiting = true;

    _exitLeafController.forward();

    // Переход к AuthScreen после анимации
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 1200),
            pageBuilder: (_, __, ___) => const AuthScreen(),
            transitionsBuilder: (_, animation, __, child) => FadeTransition(
              opacity: CurvedAnimation(
                parent: animation,
                curve: Curves.easeInOut,
              ),
              child: child,
            ),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _exitLeafController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _exitLeafController,
      builder: (context, _) {
        // чем ближе к 1 — тем дальше листья “разлетаются”
        final progress = Curves.easeInOut.transform(_exitLeafController.value);

        return Scaffold(
          backgroundColor: Colors.green.shade50,
          body: LeafBackground(
            offsetFactor: 1 + progress * 0.5, // лёгкий разлёт
            waveSpeed: 0.6 + progress * 0.4,
            child: FadeTransition(
              opacity: _fadeController,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Transform.scale(
                      scale: 1 - progress * 0.2, // плавное “удаление” иконки
                      child: const Icon(
                        Icons.eco,
                        color: Colors.green,
                        size: 100,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Opacity(
                      opacity: 1 - progress * 0.8,
                      child: Text(
                        'Green challenge',
                        style: TextStyle(
                          fontSize: 32,
                          color: Colors.green.shade800,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
