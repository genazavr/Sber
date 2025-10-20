import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/user_model.dart';

class UserProvider with ChangeNotifier {
  final User? firebaseUser;
  AppUser? currentUser;
  DatabaseReference? _ref;
  StreamSubscription<DatabaseEvent>? _sub;
  bool _loading = false;

  bool get isLoading => _loading;

  UserProvider(this.firebaseUser) {
    if (firebaseUser != null) {
      _initUser();
    }
  }

  Future<void> _initUser() async {
    _loading = true;
    notifyListeners();

    try {
      await Future.delayed(const Duration(milliseconds: 300));

      _ref = FirebaseDatabase.instance.ref('users/${firebaseUser!.uid}');
      _sub = _ref!.onValue.listen((event) {
        if (event.snapshot.value != null) {
          final data = Map<String, dynamic>.from(event.snapshot.value as Map);
          currentUser = AppUser.fromMap(firebaseUser!.uid, data);
          _loading = false;
          notifyListeners();
        } else {
          // если данных нет — создаём базовую запись
          currentUser = AppUser(
            uid: firebaseUser!.uid,
            email: firebaseUser!.email ?? '',
            name: firebaseUser!.displayName ?? '',
            score: 0.0,
            balance: 0.0,
            shelves: [],
            role: 'child',
          );
          _ref!.set(currentUser!.toMap());
          _loading = false;
          notifyListeners();
        }
      });
    } catch (e) {
      debugPrint('Ошибка загрузки пользователя: $e');
      _loading = false;
      notifyListeners();
    }
  }

  /// Очистка данных при выходе
  void clearUser() {
    currentUser = null;
    _sub?.cancel();
    notifyListeners();
  }

  /// Добавить очки пользователю
  Future<void> addScore(double delta) async {
    if (firebaseUser == null) return;
    final ref =
    FirebaseDatabase.instance.ref('users/${firebaseUser!.uid}/score');
    await ref.runTransaction((Object? currentData) {
      double currentValue = 0.0;
      if (currentData is num) currentValue = currentData.toDouble();
      return Transaction.success(currentValue + delta);
    });
  }

  /// 💰 Перевести деньги другому пользователю (по UID или email)
  Future<bool> transferMoney(String receiverUidOrEmail, double amount) async {
    if (firebaseUser == null) return false;
    String? receiverUid = receiverUidOrEmail;

    // Если введён email — ищем UID
    if (receiverUidOrEmail.contains('@')) {
      final snap = await FirebaseDatabase.instance.ref('users').get();
      if (snap.exists && snap.value != null) {
        final usersMap = Map<String, dynamic>.from(snap.value as Map);
        usersMap.forEach((key, value) {
          if (value['email'] == receiverUidOrEmail) receiverUid = key;
        });
      }
    }

    if (receiverUid == null || receiverUid == firebaseUser!.uid) return false;

    final senderRef =
    FirebaseDatabase.instance.ref('users/${firebaseUser!.uid}/balance');
    final receiverRef =
    FirebaseDatabase.instance.ref('users/$receiverUid/balance');

    bool success = false;

    // Сначала вычитаем деньги у отправителя
    await senderRef.runTransaction((Object? data) {
      double current = (data is num) ? data.toDouble() : 0.0;
      if (current >= amount) {
        success = true;
        return Transaction.success(current - amount);
      } else {
        return Transaction.abort();
      }
    });

    if (!success) return false;

    // Затем добавляем деньги получателю
    await receiverRef.runTransaction((Object? data) {
      double current = (data is num) ? data.toDouble() : 0.0;
      return Transaction.success(current + amount);
    });

    // Записываем историю перевода (опционально)
    final timestamp = DateTime.now().toIso8601String();
    await FirebaseDatabase.instance
        .ref('transactions/${firebaseUser!.uid}/$timestamp')
        .set({
      'to': receiverUid,
      'amount': amount,
      'type': 'sent',
      'time': timestamp,
    });

    await FirebaseDatabase.instance
        .ref('transactions/$receiverUid/$timestamp')
        .set({
      'from': firebaseUser!.uid,
      'amount': amount,
      'type': 'received',
      'time': timestamp,
    });

    return true;
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
