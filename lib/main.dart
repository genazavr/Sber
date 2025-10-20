import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

import 'providers/auth_provider.dart' as local_auth;
import 'providers/user_provider.dart';
import 'providers/shelves_provider.dart';

import 'screens/auth_screen.dart';
import 'screens/parent_home_screen.dart';
import 'widgets/bottom_nav.dart';
import 'splash_screen.dart';
import 'widgets/leaf_background.dart';
import 'package:untitled17/MainShell.dart'; // 🌿 добавим контейнер

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => local_auth.AuthProvider()),
        ChangeNotifierProxyProvider<local_auth.AuthProvider, UserProvider>(
          create: (_) => UserProvider(null),
          update: (_, auth, __) => UserProvider(auth.user),
        ),
        ChangeNotifierProxyProvider<local_auth.AuthProvider, ShelvesProvider>(
          create: (_) => ShelvesProvider(null),
          update: (_, auth, __) => ShelvesProvider(auth.user),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'PlantKids',
        theme: ThemeData(primarySwatch: Colors.green),
        home: const SplashScreenWrapper(),
      ),
    );
  }
}

class SplashScreenWrapper extends StatefulWidget {
  const SplashScreenWrapper({super.key});

  @override
  State<SplashScreenWrapper> createState() => _SplashScreenWrapperState();
}

class _SplashScreenWrapperState extends State<SplashScreenWrapper> {
  bool _showSplash = true;
  bool _checkingRole = false;
  String? _fallbackRole;

  @override
  void initState() {
    super.initState();
    // Splash показываем 2 секунды
    Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _showSplash = false);
    });
  }

  Future<String?> _fetchRole(String uid) async {
    try {
      final snap = await FirebaseDatabase.instance.ref('users/$uid/role').get();
      if (snap.exists) return snap.value.toString();
    } catch (_) {}
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return MainShell(
      // 🌿 общий фон — листья не пересоздаются
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 700),
        switchInCurve: Curves.easeInOut,
        switchOutCurve: Curves.easeInOut,
        child: _showSplash
            ? const AnimatedSplash()
            : StreamBuilder<User?>(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, snapshot) {
            final firebaseUser = snapshot.data;

            // 🧩 Если не вошёл
            if (firebaseUser == null) {
              return const AuthScreen();
            }

            // 🔹 Если вошёл, проверяем роль
            return Consumer<UserProvider>(
              builder: (context, userProvider, _) {
                final user = userProvider.currentUser;

                // Пока пользователь не подгрузился
                if (user == null) {
                  if (!_checkingRole) {
                    _checkingRole = true;
                    _fetchRole(firebaseUser.uid).then((role) {
                      if (mounted) {
                        setState(() {
                          _fallbackRole = role ?? 'child';
                          _checkingRole = false;
                        });
                      }
                    });
                  }
                  return const AnimatedSplash();
                }

                final role = user.role ?? _fallbackRole ?? 'child';

                return AnimatedSwitcher(
                  duration: const Duration(milliseconds: 600),
                  child: role == 'parent'
                      ? const ParentHomeScreen()
                      : const BottomNav(),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
