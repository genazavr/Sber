import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../widgets/leaf_background.dart';


class QuizHistoryScreen extends StatelessWidget {
  final String quizId;
  final String title;
  const QuizHistoryScreen({
    super.key,
    required this.quizId,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    final userProv = Provider.of<UserProvider>(context);
    final uid = userProv.firebaseUser?.uid ?? userProv.currentUser?.uid;

    if (uid == null) {
      return const Scaffold(
        body: Center(child: Text('Неавторизовано')),
      );
    }

    final ref = FirebaseDatabase.instance
        .ref('users/$uid/quizHistory/$quizId')
        .orderByChild('timestamp');

    return Scaffold(
      backgroundColor: Colors.green.shade50,
      body: LeafBackground(
        offsetFactor: 1.1,
        waveSpeed: 0.7,
        moveDuration: const Duration(seconds: 5),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [

                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new,
                          color: Colors.green),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Expanded(
                      child: Text(
                        'История: $title',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1C1C1C),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),


                Expanded(
                  child: StreamBuilder(
                    stream: ref.onValue,
                    builder: (ctx, AsyncSnapshot<DatabaseEvent> snap) {
                      if (snap.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (!snap.hasData ||
                          snap.data!.snapshot.value == null) {
                        return const Center(
                          child: Text(
                            'Пока нет попыток 🌱',
                            style: TextStyle(
                                fontSize: 16, color: Colors.black54),
                          ),
                        );
                      }

                      final map = Map<String, dynamic>.from(
                          snap.data!.snapshot.value as Map);
                      final items = map.entries.map((e) {
                        final v = Map<String, dynamic>.from(e.value as Map);
                        return {
                          'id': e.key,
                          'timestamp': v['timestamp'] ?? '',
                          'correct': v['correct'] ?? 0,
                          'total': v['total'] ?? 0,
                          'percent': (v['percent'] ?? 0).toDouble(),
                        };
                      }).toList();

                      items.sort((a, b) =>
                          b['timestamp'].toString().compareTo(a['timestamp'].toString()));

                      return ListView.builder(
                        itemCount: items.length,
                        itemBuilder: (c, i) {
                          final it = items[i];
                          final percent = it['percent'] as double;
                          final color = percent >= 100
                              ? const Color(0xFF63D471)
                              : percent >= 70
                              ? Colors.orangeAccent
                              : Colors.redAccent;

                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                            margin: const EdgeInsets.only(bottom: 14),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.95),
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                              border: Border.all(
                                color: color.withOpacity(0.6),
                                width: 1.2,
                              ),
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: color.withOpacity(0.15),
                                child: Icon(
                                  percent >= 100
                                      ? Icons.eco
                                      : Icons.history_rounded,
                                  color: color,
                                ),
                              ),
                              title: Text(
                                'Попытка ${items.length - i}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              subtitle: Text(
                                'Правильно: ${it['correct']} из ${it['total']}\n'
                                    'Результат: ${percent.toStringAsFixed(1)}%\n'
                                    '${it['timestamp']}',
                                style: const TextStyle(fontSize: 14),
                              ),
                              trailing: Text(
                                '${percent.toStringAsFixed(0)}%',
                                style: TextStyle(
                                  color: color,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                          );
                        },
                      );
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
