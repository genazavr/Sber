import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';

import '../widgets/leaf_background.dart';

class ParentGoalsScreen extends StatefulWidget {
  const ParentGoalsScreen({super.key});

  @override
  State<ParentGoalsScreen> createState() => _ParentGoalsScreenState();
}

class _ParentGoalsScreenState extends State<ParentGoalsScreen>
    with TickerProviderStateMixin {
  String? _selectedChildUid;
  String? _selectedChildName;
  bool _showFallingLeaves = false;
  late AnimationController _leafController;
  final _random = Random();

  @override
  void initState() {
    super.initState();
    _leafController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
  }

  @override
  void dispose() {
    _leafController.dispose();
    super.dispose();
  }

  /// ✅ Списание с родителя и пополнение цели
  Future<void> _topUpGoal(String childUid, String goalId, double amount) async {
    final parentUid = FirebaseAuth.instance.currentUser!.uid;
    final parentBalanceRef =
    FirebaseDatabase.instance.ref('users/$parentUid/balance');
    final goalRef =
    FirebaseDatabase.instance.ref('users/$childUid/goals/$goalId');

    final parentSnap = await parentBalanceRef.get();
    double parentBalance = (parentSnap.exists && parentSnap.value is num)
        ? (parentSnap.value as num).toDouble()
        : 0;

    if (parentBalance < amount) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Недостаточно средств 💸'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    // списываем с родителя
    await parentBalanceRef.set(parentBalance - amount);

    // увеличиваем накопление у ребёнка
    final goalSnap = await goalRef.get();
    if (!goalSnap.exists || goalSnap.value == null) return;
    final goal = Map<String, dynamic>.from(goalSnap.value as Map);
    double saved = (goal['savedAmount'] ?? 0).toDouble();
    double target = (goal['targetAmount'] ?? 0).toDouble();

    saved += amount;
    await goalRef.update({'savedAmount': saved});

    // проверка достижения цели
    if (saved >= target && target > 0) {
      setState(() => _showFallingLeaves = true);
      _leafController.forward(from: 0);

      final childBalanceRef =
      FirebaseDatabase.instance.ref('users/$childUid/balance');
      await childBalanceRef.runTransaction((val) {
        double current = (val is num) ? val.toDouble() : 0.0;
        return Transaction.success(current + target);
      });

      await goalRef.remove();

      Future.delayed(const Duration(seconds: 4), () {
        if (mounted) setState(() => _showFallingLeaves = false);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.green.shade700,
            content: Text(
              '🎉 Цель достигнута! ${_selectedChildName ?? "Ребёнок"} получил $target ₽ 🌿',
            ),
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Цель пополнена на $amount ₽ 💰'),
          backgroundColor: Colors.green.shade600,
        ),
      );
    }
  }

  Future<String> _fetchChildName(String uid, [String? existingName]) async {
    if (existingName != null && existingName.isNotEmpty) return existingName;
    final snap = await FirebaseDatabase.instance.ref('users/$uid/name').get();
    if (snap.exists && snap.value is String) return snap.value as String;
    return 'Без имени';
  }

  @override
  Widget build(BuildContext context) {
    final parent = FirebaseAuth.instance.currentUser!;
    return Scaffold(
      backgroundColor: Colors.green.shade50,
      body: Stack(
        children: [
          LeafBackground(
            child: SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  _buildChildDropdown(parent),
                  const SizedBox(height: 20),
                  Expanded(
                    child: _selectedChildUid == null
                        ? const Center(
                      child: Text(
                        '👆 Выбери ребёнка, чтобы увидеть цели!',
                        style: TextStyle(color: Colors.black54),
                      ),
                    )
                        : _buildGoalsList(),
                  ),
                ],
              ),
            ),
          ),

          // 🍃 Пасхалка: падающие листья при достижении цели
          if (_showFallingLeaves)
            AnimatedBuilder(
              animation: _leafController,
              builder: (context, _) {
                return IgnorePointer(
                  child: CustomPaint(
                    painter: _FallingLeavesPainter(
                      _leafController.value,
                      _random,
                    ),
                    size: MediaQuery.of(context).size,
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildChildDropdown(User parent) {
    return StreamBuilder(
      stream:
      FirebaseDatabase.instance.ref('parents/${parent.uid}/children').onValue,
      builder: (context, snap) {
        if (!snap.hasData || snap.data!.snapshot.value == null) {
          return const Padding(
            padding: EdgeInsets.all(20),
            child: Text('😿 Нет добавленных детей'),
          );
        }

        final kids = Map<String, dynamic>.from(snap.data!.snapshot.value as Map);
        final entries = kids.entries.toList();

        return FutureBuilder<List<MapEntry<String, String>>>(
          future: Future.wait(
            entries.map((e) async {
              final uid = e.key;
              final data = Map<String, dynamic>.from(e.value);
              final name = await _fetchChildName(uid, data['name']);
              return MapEntry(uid, name);
            }),
          ),
          builder: (context, nameSnap) {
            if (!nameSnap.hasData) {
              return const CircularProgressIndicator();
            }
            final childList = nameSnap.data!;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(bottom: 6),
                    child: Text(
                      'Выбери ребёнка 🌿',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    dropdownColor: Colors.white,
                    value: _selectedChildUid,
                    items: childList
                        .map((entry) => DropdownMenuItem(
                      value: entry.key,
                      child: Text(
                        entry.value,
                        style: const TextStyle(color: Colors.black),
                      ),
                    ))
                        .toList(),
                    onChanged: (uid) {
                      setState(() {
                        _selectedChildUid = uid;
                        _selectedChildName =
                            childList.firstWhere((e) => e.key == uid).value;
                      });
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildGoalsList() {
    return StreamBuilder(
      stream: FirebaseDatabase.instance
          .ref('users/$_selectedChildUid/goals')
          .onValue,
      builder: (context, goalSnap) {
        if (!goalSnap.hasData || goalSnap.data!.snapshot.value == null) {
          return Center(
            child: Text('😅 У ${_selectedChildName ?? "ребёнка"} нет целей'),
          );
        }

        final goals =
        Map<String, dynamic>.from(goalSnap.data!.snapshot.value as Map);

        return ListView(
          padding: const EdgeInsets.all(16),
          children: goals.entries.map((entry) {
            final goal = Map<String, dynamic>.from(entry.value);
            final title = goal['title'] ?? 'Цель';
            final saved = (goal['savedAmount'] ?? 0).toDouble();
            final target = (goal['targetAmount'] ?? 1).toDouble();
            final progress = (saved / target).clamp(0.0, 1.0);

            return Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.greenAccent.shade100,
                    Colors.green.shade300,
                    Colors.lightGreen.shade400,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.spa, color: Colors.white, size: 22),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              shadows: [
                                Shadow(
                                  offset: Offset(0, 1),
                                  blurRadius: 2,
                                  color: Colors.black26,
                                )
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: progress,
                        color: Colors.white,
                        backgroundColor: Colors.white.withOpacity(0.3),
                        minHeight: 8,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '💰 ${saved.toStringAsFixed(0)} / ${target.toStringAsFixed(0)} ₽',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '${(progress * 100).toStringAsFixed(0)}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.9),
                          foregroundColor: Colors.green.shade700,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Пополнить',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        onPressed: () async {
                          final amount = await _showTopUpDialog(context);
                          if (amount != null && amount > 0) {
                            await _topUpGoal(
                                _selectedChildUid!, entry.key, amount);
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }


  Future<double?> _showTopUpDialog(BuildContext context) async {
    final controller = TextEditingController();
    return showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('💸 Пополнить цель'),
        content: TextField(
          controller: controller,
          keyboardType:
          const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Введите сумму',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.green),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF63D471),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              final amount =
                  double.tryParse(controller.text.replaceAll(',', '.')) ?? 0;
              Navigator.pop(ctx, amount);
            },
            child: const Text('✅ Пополнить'),
          ),
        ],
      ),
    );
  }
}

/// 🍃 Кастомный painter для анимации падающих листьев
class _FallingLeavesPainter extends CustomPainter {
  final double progress;
  final Random random;
  _FallingLeavesPainter(this.progress, this.random);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.green.withOpacity(0.7);
    for (int i = 0; i < 20; i++) {
      final x = random.nextDouble() * size.width;
      final y = size.height * progress + i * 20 * sin(progress * pi * i);
      final leafSize = 6 + random.nextDouble() * 8;
      canvas.drawOval(
        Rect.fromLTWH(x, y % size.height, leafSize, leafSize / 2),
        paint..color = Colors.greenAccent.withOpacity(1 - progress),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _FallingLeavesPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
