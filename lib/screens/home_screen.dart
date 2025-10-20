import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_database/firebase_database.dart';
import '../providers/user_provider.dart';
import '../widgets/leaf_background.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin {
  final TextEditingController _transferTo = TextEditingController();
  final TextEditingController _transferAmount = TextEditingController();
  bool _loading = false;

  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnim;
  late final AnimationController _scaleController;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();


    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnim = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );

    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _scaleAnim = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeOutBack,
    );


    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) {
        _fadeController.forward();
        _scaleController.forward();
      }
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    _transferTo.dispose();
    _transferAmount.dispose();
    super.dispose();
  }

  Future<void> _transferMoney(BuildContext context) async {
    final userProv = Provider.of<UserProvider>(context, listen: false);
    final to = _transferTo.text.trim();
    final amt = double.tryParse(_transferAmount.text.replaceAll(',', '.')) ?? 0.0;

    if (to.isEmpty || amt <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Введите корректные данные'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      final ok = await userProv.transferMoney(to, amt);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ok ? 'Перевод выполнен ✅' : 'Ошибка перевода ❌'),
          backgroundColor: ok ? Colors.green : Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      if (ok) {
        _transferTo.clear();
        _transferAmount.clear();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProv = Provider.of<UserProvider>(context);
    final user = userProv.currentUser;
    final theme = Theme.of(context);

    final balance = (user?.balance ?? 0.0).toStringAsFixed(2);
    final score = (user?.score ?? 0.0).toStringAsFixed(1);

    return Scaffold(
      backgroundColor: Colors.green.shade50,
      body: LeafBackground(
        offsetFactor: 1.1,
        waveSpeed: 0.7,
        moveDuration: const Duration(seconds: 5),
        child: FadeTransition(
          opacity: _fadeAnim,
          child: ScaleTransition(
            scale: _scaleAnim,
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    Row(
                      children: [
                        Expanded(
                          child: _infoCard(
                            icon: Icons.star,
                            color: Colors.amber,
                            title: 'Баллы',
                            value: score,
                            unit: '',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _infoCard(
                            icon: Icons.account_balance_wallet_outlined,
                            color: Colors.green,
                            title: 'Счёт',
                            value: balance,
                            unit: '₽',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    Text(
                      'Перевести деньги другому пользователю',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),

                    _transferCard(),
                    const SizedBox(height: 24),

                    Text(
                      'Задания',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),

                    _taskList(user),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _transferCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black12.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          TextField(
            controller: _transferTo,
            decoration: InputDecoration(
              hintText: 'Email или UID получателя',
              prefixIcon: const Icon(Icons.email_outlined),
              filled: true,
              fillColor: Colors.grey.shade50,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _transferAmount,
            keyboardType:
            const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              hintText: 'Сумма перевода',
              prefixIcon: const Icon(Icons.attach_money_outlined),
              filled: true,
              fillColor: Colors.grey.shade50,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _loading ? null : () => _transferMoney(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.green,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: const BorderSide(color: Colors.green, width: 1.5),
                ),
                elevation: 0,
              ),
              child: _loading
                  ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.green,
                ),
              )
                  : const Text(
                'Перевести',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _taskList(user) {
    return StreamBuilder(
      stream: FirebaseDatabase.instance.ref('tasks/${user?.uid ?? "no"}').onValue,
      builder: (ctx, AsyncSnapshot<DatabaseEvent> snap) {
        if (!snap.hasData || snap.data!.snapshot.value == null) {
          return const Center(child: Text('Заданий пока нет 🌱'));
        }

        final map = Map<String, dynamic>.from(snap.data!.snapshot.value as Map);
        final keys = map.keys.toList();

        return Column(
          children: keys.map((k) {
            final item = Map<String, dynamic>.from(map[k]);
            final title = item['title'] ?? 'Без названия';
            final desc = item['desc'] ?? '';
            final points = (item['points'] ?? 0).toDouble();

            return GestureDetector(
              onTap: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (_) => Dialog(
                    backgroundColor: Colors.white.withOpacity(0.95),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.spa, color: Colors.green, size: 48),
                          const SizedBox(height: 10),
                          Text(
                            'Выполнить задание?',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Colors.green,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            title,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            desc,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.black54,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '+${points.toStringAsFixed(0)} баллов 🌿',
                            style: const TextStyle(
                              color: Colors.green,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text(
                                  'Отмена',
                                  style: TextStyle(color: Colors.redAccent),
                                ),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF63D471),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('Выполнено'),
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                  ),
                );

                if (confirm == true && user != null) {
                  final uid = user.uid;
                  final reward = points; // reward == points из задания
                  final parentUid = item['fromParent']; // UID родителя, если ты сохраняешь его при создании задания

                  // 1️⃣ Начисляем баллы
                  final scoreRef = FirebaseDatabase.instance.ref('users/$uid/score');
                  await scoreRef.runTransaction((data) {
                    double cur = (data as num?)?.toDouble() ?? 0;
                    return Transaction.success(cur + reward);
                  });

                  // 2️⃣ Начисляем деньги на баланс ребёнка
                  final balanceRef = FirebaseDatabase.instance.ref('users/$uid/balance');
                  await balanceRef.runTransaction((data) {
                    double cur = (data as num?)?.toDouble() ?? 0;
                    return Transaction.success(cur + reward);
                  });

                  // 3️⃣ Удаляем задание
                  await FirebaseDatabase.instance.ref('tasks/$uid/$k').remove();

                  // 4️⃣ Добавляем запись о транзакции
                  final timestamp = DateTime.now().toIso8601String();
                  await FirebaseDatabase.instance
                      .ref('transactions/$uid/$timestamp')
                      .set({
                    'from': parentUid ?? 'unknown',
                    'type': 'task_reward',
                    'amount': reward,
                    'task': title,
                    'time': timestamp,
                  });

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: Colors.green,
                        content: Text(
                          '🎉 Задание "$title" выполнено! +${reward.toStringAsFixed(0)} ₽ и баллов 🌿',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    );
                  }
                }

              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.task_alt, color: Colors.green),
                  ),
                  title: Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  subtitle: Text(
                    desc,
                    style: const TextStyle(color: Colors.black54),
                  ),
                  trailing: Text(
                    '+${points.toStringAsFixed(0)} ₽',
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }


  Widget _infoCard({
    required IconData icon,
    required Color color,
    required String title,
    required String value,
    required String unit,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black12.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 6),
          Text(title, style: const TextStyle(fontSize: 14, color: Colors.black54)),
          const SizedBox(height: 4),
          Text(
            '$value $unit',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}
