import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/shelves_provider.dart';
import '../providers/user_provider.dart';
import '../widgets/leaf_background.dart';
import 'shelf_detail_screen.dart';

class ShelvesScreen extends StatefulWidget {
  const ShelvesScreen({super.key});

  @override
  State<ShelvesScreen> createState() => _ShelvesScreenState();
}

class _ShelvesScreenState extends State<ShelvesScreen> {
  final TextEditingController _codeCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final shelvesProv = Provider.of<ShelvesProvider>(context);
    final shelvesList = shelvesProv.shelves.values.toList();

    final userProv = Provider.of<UserProvider>(context);
    final user = userProv.currentUser;
    final userScore = (user?.score ?? 0.0).toStringAsFixed(0);

    return Scaffold(
      backgroundColor: Colors.green.shade50,
      body: LeafBackground(
        offsetFactor: 1.1,
        waveSpeed: 0.7,
        moveDuration: const Duration(seconds: 5),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 🔹 Заголовок
                const Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: Color(0xFFB9EAB1),
                      child: Icon(Icons.eco, color: Colors.white),
                    ),
                    SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Smart Garden",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1C1C1C),
                          ),
                        ),
                        Text(
                          "Мои стеллажи",
                          style: TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // 🔹 Верхняя панель статистики (реальные данные)
                _TopStats(
                  score: userScore,
                  shelvesCount: shelvesList.length,
                ),
                const SizedBox(height: 20),

                // 🔹 Список стеллажей
                Expanded(
                  child: shelvesList.isEmpty
                      ? const Center(
                    child: Text(
                      'Пока нет стеллажей 🌱',
                      style:
                      TextStyle(fontSize: 16, color: Colors.black54),
                    ),
                  )
                      : ListView.builder(
                    itemCount: shelvesList.length,
                    itemBuilder: (ctx, i) {
                      final s = shelvesList[i];
                      return _ShelfCard(
                        id: s.id,
                        soil: s.soilHumidity.toDouble(),
                        air: s.airHumidity.toDouble(),
                        onOpen: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                ShelfDetailScreen(shelfId: s.id),
                          ),
                        ),
                        onDelete: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: const Text('Удалить стеллаж?'),
                              content: const Text(
                                  'Вы уверены, что хотите удалить этот стеллаж?'),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: const Text('Отмена'),
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    foregroundColor: Colors.white,
                                  ),
                                  onPressed: () =>
                                      Navigator.pop(context, true),
                                  child: const Text('Удалить'),
                                ),
                              ],
                            ),
                          );

                          if (confirm == true) {
                            await shelvesProv.removeShelf(s.id);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(const SnackBar(
                                content:
                                Text('Стеллаж успешно удалён 🗑️'),
                                backgroundColor: Colors.green,
                              ));
                            }
                          }
                        },
                      );
                    },
                  ),
                ),

                const SizedBox(height: 12),
                _AddShelfButton(codeCtrl: _codeCtrl),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 🔹 Верхняя панель статистики
class _TopStats extends StatelessWidget {
  final String score;
  final int shelvesCount;

  const _TopStats({required this.score, required this.shelvesCount});

  @override
  Widget build(BuildContext context) {
    final random = Random();
    final colorOptions = [Colors.green, Colors.amber, Colors.red];
    final leafColor = colorOptions[random.nextInt(3)];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatItem(value: score, label: 'Баллов'),
          _StatItem(value: '$shelvesCount', label: 'Стеллажей'),
          Column(
            children: [
              Icon(Icons.eco, color: leafColor, size: 28),
              const SizedBox(height: 4),
              Text(
                leafColor == Colors.green
                    ? 'Отлично'
                    : leafColor == Colors.amber
                    ? 'Нормально'
                    : 'Плохо',
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 🔹 Элемент статистики
class _StatItem extends StatelessWidget {
  final String value;
  final String label;

  const _StatItem({
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF3DA56F),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 14, color: Colors.black54),
        ),
      ],
    );
  }
}

/// 🔹 Карточка стеллажа
class _ShelfCard extends StatelessWidget {
  final String id;
  final double soil;
  final double air;
  final VoidCallback onOpen;
  final VoidCallback onDelete;

  const _ShelfCard({
    required this.id,
    required this.soil,
    required this.air,
    required this.onOpen,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final random = Random();
    final colorOptions = [Colors.green, Colors.amber, Colors.red];
    final stateColor = colorOptions[random.nextInt(3)];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Заголовок и иконка состояния
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Стеллаж ${id.substring(0, 6)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                  ),
                ),
                Icon(Icons.eco, color: stateColor, size: 28),
              ],
            ),
            const SizedBox(height: 10),

            // Показатели
            Row(
              children: [
                const Icon(Icons.grass, color: Colors.green, size: 20),
                const SizedBox(width: 6),
                Text('Почва: ${soil.toStringAsFixed(1)}'),
                const SizedBox(width: 16),
                const Icon(Icons.air, color: Colors.blueAccent, size: 20),
                const SizedBox(width: 6),
                Text('Воздух: ${air.toStringAsFixed(1)}'),
              ],
            ),

            const SizedBox(height: 18),

            // Кнопки
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: onOpen,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF63D471),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    child: const Text('Открыть'),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 🔹 Кнопка добавления стеллажа с диалогом
class _AddShelfButton extends StatelessWidget {
  final TextEditingController codeCtrl;
  const _AddShelfButton({required this.codeCtrl});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        await showDialog(
          context: context,
          builder: (ctx) {
            return Dialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              backgroundColor: Colors.white,
              child: Padding(
                padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.storage_rounded,
                        size: 50, color: Colors.green),
                    const SizedBox(height: 10),
                    const Text(
                      'Добавить стеллаж',
                      style:
                      TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: codeCtrl,
                      decoration: InputDecoration(
                        labelText: 'Введите уникальный номер',
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () async {
                        final shelvesProv =
                        Provider.of<ShelvesProvider>(context, listen: false);
                        final id = await shelvesProv.createImprovShelf();
                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Стеллаж создан: $id'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            vertical: 14, horizontal: 24),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Создать'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.green, width: 1.6),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_circle_outline, color: Colors.green),
            SizedBox(width: 8),
            Text(
              'Добавить стеллаж',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
