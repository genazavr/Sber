import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class AuthProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get user => _auth.currentUser;
  bool get isAuthenticated => user != null;

  AuthProvider() {
    _auth.authStateChanges().listen((_) => notifyListeners());
  }


  Future<UserCredential> signUp(
      String email, String password, String name, {required String role}) async {

    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final uid = cred.user!.uid;


    final userRef = FirebaseDatabase.instance.ref('users/$uid');

    final Map<String, dynamic> baseData = {
      'email': email,
      'name': name,
      'role': role,
      'score': 0.0,
      'balance': 0.0,
    };

    await userRef.set(baseData);


    if (role == 'parent') {
      await FirebaseDatabase.instance.ref('parents/$uid').set({
        'email': email,
        'name': name,
        'createdAt': DateTime.now().toIso8601String(),
        'children': {},
      });
    }

    return cred;
  }

  /// 🔹 Вход
  Future<UserCredential> signIn(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(
        email: email, password: password);
  }

  /// 🔹 Выход
  Future<void> signOut() async {
    await _auth.signOut();
    notifyListeners();
  }
}
