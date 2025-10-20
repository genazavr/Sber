import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../widgets/leaf_background.dart';

class ShopScreen extends StatelessWidget {
  const ShopScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userProv = Provider.of<UserProvider>(context);
    final user = userProv.currentUser;

    // 🎁 Твои реальные картинки
    final List<Map<String, dynamic>> prizes = [
      {'id': 'p1', 'img': 'assets/cards/cards11.png', 'cost': 100, 'name': 'Шопер'},
      {'id': 'p2', 'img': 'assets/cards/cards2.png', 'cost': 80, 'name': 'Блокнот'},
      {'id': 'p3', 'img': 'assets/cards/cards3.png', 'cost': 120, 'name': 'Футболка'},
      {'id': 'p4', 'img': 'assets/cards/cards4.png', 'cost': 90, 'name': 'Дневник'},
    ];

    return Scaffold(
      backgroundColor: Colors.green.shade50,
      body: LeafBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 🔙 Кнопка "Назад" + заголовок
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new, color: Colors.green),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 3),
                    const CircleAvatar(
                      radius: 22,
                      backgroundColor: Color(0xFFB9EAB1),
                      child: Icon(Icons.storefront, color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Магазин наград",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1C1C1C),
                          ),
                        ),
                        Text(
                          "Обменивай баллы 🌿",
                          style: TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // 🌟 Баллы пользователя
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Ваши баллы:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2F4F2F),
                        ),
                      ),
                      Row(
                        children: [
                          Icon(Icons.star, color: Colors.amber.shade600),
                          const SizedBox(width: 4),
                          Text(
                            '${(user?.score ?? 0.0).toStringAsFixed(1)}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // 🎁 Сетка призов
                Expanded(
                  child: GridView.builder(
                    itemCount: prizes.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.7, // 📐 Сделали чуть уже, чтобы картинки не растягивались
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemBuilder: (context, i) {
                      final p = prizes[i];
                      return _PrizeCard(prize: p, userId: user?.uid, context: context);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PrizeCard extends StatelessWidget {
  final Map<String, dynamic> prize;
  final String? userId;
  final BuildContext context;

  const _PrizeCard({
    required this.prize,
    required this.userId,
    required this.context,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: userId == null
          ? null
          : () async {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text(
              'Покупка награды',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            content: Text(
              'Купить "${prize['name']}" за ${prize['cost']} баллов?',
              style: const TextStyle(fontSize: 16),
            ),
            actions: [
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: Colors.green.shade700,
                ),
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Отмена'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFA5D6A7),
                  foregroundColor: Colors.white,
                ),
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Купить'),
              ),
            ],
          ),
        );

        if (confirm == true && userId != null) {
          await _handlePurchase(context, userId!);
        }
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: Colors.white.withOpacity(0.95),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    prize['img'],
                    fit: BoxFit.contain, // ✅ чтобы вся картинка помещалась
                    width: double.infinity,
                  ),
                ),
              ),
            ),
            Text(
              prize['name'],
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${prize['cost']} баллов',
              style: const TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Future<void> _handlePurchase(BuildContext context, String uid) async {
    final ref = FirebaseDatabase.instance.ref('users/$uid/score');
    bool success = false;

    await ref.runTransaction((data) {
      double current = 0.0;
      if (data is num) current = data.toDouble();
      if (current >= prize['cost']) {
        success = true;
        return Transaction.success(current - prize['cost']);
      } else {
        return Transaction.abort();
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? '🎉 Вы купили ${prize['name']} за ${prize['cost']} баллов!'
              : 'Недостаточно баллов 😔',
        ),
        backgroundColor: success ? Colors.green.shade400 : Colors.redAccent,
      ),
    );
  }
}
