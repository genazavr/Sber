import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import 'package:percent_indicator/percent_indicator.dart';
import '../providers/user_provider.dart';
import '../widgets/leaf_background.dart';

class FirebaseGoalsScreen extends StatefulWidget {
  const FirebaseGoalsScreen({super.key});

  @override
  State<FirebaseGoalsScreen> createState() => _FirebaseGoalsScreenState();
}

class _FirebaseGoalsScreenState extends State<FirebaseGoalsScreen> {
  final DatabaseReference db = FirebaseDatabase.instance.ref();
  List<Map<String, dynamic>> goals = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadGoals();
  }

  Future<void> _loadGoals() async {
    final userProv = Provider.of<UserProvider>(context, listen: false);
    final uid = userProv.firebaseUser?.uid ?? userProv.currentUser?.uid;
    if (uid == null) return;

    final ref = db.child('users/$uid/goals');
    final snap = await ref.get();
    goals = [];

    if (snap.exists) {
      final data = Map<String, dynamic>.from(snap.value as Map);
      goals = data.entries.map((e) {
        final val = Map<String, dynamic>.from(e.value);
        val['id'] = e.key;
        return val;
      }).toList();
    }

    setState(() => loading = false);
  }

  Future<void> _saveGoal(Map<String, dynamic> goal) async {
    final userProv = Provider.of<UserProvider>(context, listen: false);
    final uid = userProv.firebaseUser?.uid ?? userProv.currentUser?.uid;
    if (uid == null) return;
    await db.child('users/$uid/goals/${goal['id']}').set(goal);
    await _loadGoals();
  }

  Future<void> _addMoney(Map<String, dynamic> goal) async {
    final userProv = Provider.of<UserProvider>(context, listen: false);
    final uid = userProv.firebaseUser?.uid ?? userProv.currentUser?.uid;
    if (uid == null) return;
    final balanceRef = db.child('users/$uid/balance');
    final controller = TextEditingController();

    await showDialog(
      context: context,
      builder: (_) =>
          Dialog(
            backgroundColor: Colors.white.withOpacity(0.95),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.eco, color: Colors.green, size: 48),
                  const SizedBox(height: 12),
                  Text('Пополнить "${goal['title']}"',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: Colors.green, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  TextField(
                    controller: controller,
                    style: const TextStyle(color: Colors.black),
                    decoration: InputDecoration(
                      labelText: 'Введите сумму',
                      labelStyle: const TextStyle(color: Colors.black54),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Отмена',
                            style: TextStyle(color: Colors.redAccent)),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFA5D6A7),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () async {
                          final value = double.tryParse(controller.text) ?? 0;
                          if (value <= 0) return;

                          final balSnap = await balanceRef.get();
                          double balance = (balSnap.value is num)
                              ? (balSnap.value as num).toDouble()
                              : 0.0;

                          if (balance < value) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Недостаточно средств'),
                                backgroundColor: Colors.redAccent,
                              ),
                            );
                            return;
                          }

                          await balanceRef.set(balance - value);
                          goal['savedAmount'] =
                              (goal['savedAmount'] ?? 0) + value;
                          await db
                              .child('users/$uid/goals/${goal['id']}')
                              .update({'savedAmount': goal['savedAmount']});

                          final double target =
                          (goal['targetAmount'] ?? 0).toDouble();
                          final double saved =
                          (goal['savedAmount'] ?? 0).toDouble();

                          if (saved >= target && target > 0) {

                            await balanceRef.runTransaction((data) {
                              double cur = (data as num?)?.toDouble() ?? 0;
                              return Transaction.success(cur + saved);
                            });


                            await db.child('users/$uid/goals/${goal['id']}').remove();


                            try {
                              final file = File(goal['imagePath']);
                              if (await file.exists()) await file.delete();
                            } catch (_) {}


                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    '🎉 Цель "${goal['title']}" достигнута! Деньги возвращены на счёт 💰',
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          }


                          await _loadGoals();
                          if (context.mounted) Navigator.pop(context);
                        },
                        child: const Text('Добавить'),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
    );
  }

  Future<void> _deleteGoal(Map<String, dynamic> goal) async {
    final userProv = Provider.of<UserProvider>(context, listen: false);
    final uid = userProv.firebaseUser?.uid ?? userProv.currentUser?.uid;
    if (uid == null) return;

    final balanceRef = db.child('users/$uid/balance');
    if ((goal['savedAmount'] ?? 0) > 0) {
      await balanceRef.runTransaction((data) {
        double cur = (data as num?)?.toDouble() ?? 0;
        return Transaction.success(cur + (goal['savedAmount'] ?? 0));
      });
    }

    await db.child('users/$uid/goals/${goal['id']}').remove();

    try {
      final file = File(goal['imagePath']);
      if (await file.exists()) await file.delete();
    } catch (_) {}

    await _loadGoals();
  }

  Future<void> _createGoal() async {
    final titleCtrl = TextEditingController();
    final targetCtrl = TextEditingController();
    final dateCtrl = TextEditingController();
    File? image;

    Future<void> pickImage() async {
      final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (picked == null) return;
      final dir = await getApplicationDocumentsDirectory();
      final saved =
      await File(picked.path).copy('${dir.path}/${const Uuid().v4()}.jpg');
      setState(() => image = saved);
    }

    await showDialog(
      context: context,
      builder: (_) =>
          Dialog(
            backgroundColor: Colors.white.withOpacity(0.95),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.spa, color: Colors.green, size: 48),
                    const SizedBox(height: 10),
                    const Text('Новая цель 🌱',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Colors.green)),
                    const SizedBox(height: 16),
                    TextField(
                      controller: titleCtrl,
                      decoration: _inputDecoration('Название цели'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: targetCtrl,
                      keyboardType: TextInputType.number,
                      decoration: _inputDecoration('Сколько нужно накопить'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: dateCtrl,
                      readOnly: true,
                      decoration: _inputDecoration('Дата окончания',
                          icon: const Icon(
                              Icons.calendar_today, color: Colors.green)),
                      onTap: () async {
                        final now = DateTime.now();
                        final date = await showDatePicker(
                          context: context,
                          initialDate: now,
                          firstDate: now,
                          lastDate: DateTime(now.year + 3),
                        );
                        if (date != null) {
                          dateCtrl.text = DateFormat('dd.MM.yyyy').format(date);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    image != null
                        ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(image!,
                            height: 120, fit: BoxFit.cover))
                        : TextButton.icon(
                        onPressed: pickImage,
                        icon: const Icon(Icons.image, color: Colors.green),
                        label: const Text('Выбрать фото',
                            style: TextStyle(color: Colors.green))),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFA5D6A7),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () async {
                        if (titleCtrl.text.isEmpty ||
                            targetCtrl.text.isEmpty ||
                            image == null) return;
                        final goal = {
                          'id': const Uuid().v4(),
                          'title': titleCtrl.text.trim(),
                          'targetAmount': double.parse(targetCtrl.text),
                          'savedAmount': 0.0,
                          'imagePath': image!.path,
                          'endDate': dateCtrl.text,
                        };
                        await _saveGoal(goal);
                        if (context.mounted) Navigator.pop(context);
                      },
                      child: const Text('Создать'),
                    ),
                  ],
                ),
              ),
            ),
          ),
    );
  }

  InputDecoration _inputDecoration(String label, {Widget? icon}) {
    return InputDecoration(
      labelText: label,
      prefixIcon: icon,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 80.0),

        child: FloatingActionButton.extended(
          backgroundColor: const Color(0xFF63D471),
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text(
            'Новая цель',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          onPressed: _createGoal,
        ),
      ),
      body: LeafBackground(
        child: SafeArea(
          child: loading
              ? const Center(
              child: CircularProgressIndicator(color: Colors.green))
              : goals.isEmpty
              ? const Center(
            child: Text(
              'Пока нет целей 🌱',
              style: TextStyle(color: Colors.black54, fontSize: 16),
            ),
          )
              : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: goals.length,
            itemBuilder: (context, i) {
              final g = goals[i];
              final double target = (g['targetAmount'] ?? 0).toDouble();
              final double saved = (g['savedAmount'] ?? 0).toDouble();
              final double progress =
              target == 0 ? 0 : (saved / target).clamp(0, 1);

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    CircularPercentIndicator(
                      radius: 75,
                      lineWidth: 12,
                      animation: true,
                      percent: progress,
                      progressColor: Colors.green.shade400,
                      backgroundColor: Colors.grey.shade200,
                      circularStrokeCap: CircularStrokeCap.round,
                      center: ClipRRect(
                        borderRadius: BorderRadius.circular(80),
                        child: Image.file(
                          File(g['imagePath']),
                          width: 110,
                          height: 110,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      g['title'],
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.green,
                      ),
                    ),
                    Text(
                      'Накоплено: ${saved.toStringAsFixed(0)} / ${target
                          .toStringAsFixed(0)}',
                      style: const TextStyle(color: Colors.black87),
                    ),
                    if (g['endDate'] != null && g['endDate'] != '')
                      Text(
                        'До: ${g['endDate']}',
                        style: const TextStyle(color: Colors.black54),
                      ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () => _addMoney(g),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF63D471),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(Icons.add),
                          label: const Text('Пополнить'),
                        ),
                        ElevatedButton.icon(
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (_) =>
                                  AlertDialog(
                                    title: const Text('Удалить цель?'),
                                    content: const Text(
                                      'Накопленные средства вернутся на счёт.',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, false),
                                        child: const Text('Отмена'),
                                      ),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                          Colors.redAccent,
                                        ),
                                        onPressed: () =>
                                            Navigator.pop(context, true),
                                        child: const Text('Удалить'),
                                      ),
                                    ],
                                  ),
                            );
                            if (confirm == true) {
                              await _deleteGoal(g);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF63D471),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(Icons.delete_outline),
                          label: const Text('Удалить'),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
