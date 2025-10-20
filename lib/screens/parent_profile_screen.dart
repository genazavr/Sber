import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_database/firebase_database.dart';
import '../providers/user_provider.dart';
import '../providers/auth_provider.dart' as local_auth;
import '../widgets/leaf_background.dart';

class ParentProfileScreen extends StatefulWidget {
  const ParentProfileScreen({super.key});

  @override
  State<ParentProfileScreen> createState() => _ParentProfileScreenState();
}

class _ParentProfileScreenState extends State<ParentProfileScreen> {
  final _codeController = TextEditingController();
  bool _loading = false;
  bool _showUid = false;
  String? _status;

  // 💳 Фиксированные данные карты
  final String _expiry = '07/29';
  final String _cvv = '312';

  // 📚 Загрузка истории тестов ребёнка из quizHistory/agro/...
  Future<List<Map<String, dynamic>>> _loadTests(String childUid) async {
    final ref = FirebaseDatabase.instance.ref('users/$childUid/quizHistory');
    final snap = await ref.get();

    if (!snap.exists || snap.value == null) return [];

    final Map<String, dynamic> data = Map<String, dynamic>.from(snap.value as Map);
    final List<Map<String, dynamic>> results = [];

    for (var subjectEntry in data.entries) {
      final subject = subjectEntry.key;
      final Map<String, dynamic> tests = Map<String, dynamic>.from(subjectEntry.value);
      for (var testEntry in tests.entries) {
        final t = Map<String, dynamic>.from(testEntry.value);
        results.add({
          'subject': subject,
          'correct': t['correct'] ?? 0,
          'total': t['total'] ?? 0,
          'percent': t['percent'] ?? 0,
          'date': t['timestamp'] ?? '',
        });
      }
    }

    results.sort((a, b) => b['date'].compareTo(a['date']));
    return results;
  }

  // 🧩 Привязка ребёнка
  Future<void> _linkChild(String parentUid) async {
    final code = _codeController.text.trim().toUpperCase();
    if (code.isEmpty) {
      setState(() => _status = "Введите код ребёнка");
      return;
    }

    setState(() {
      _loading = true;
      _status = null;
    });

    try {
      final ref = FirebaseDatabase.instance.ref('link_codes/$code');
      final snapshot = await ref.get();

      if (!snapshot.exists) {
        setState(() => _status = "Код не найден ❌");
      } else {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        final expiresAt = DateTime.tryParse(data['expiresAt'] ?? '');
        final childUid = data['childUid'];
        final childEmail = data['childEmail'];
        final createdAt = data['createdAt'];

        if (expiresAt == null || DateTime.now().isAfter(expiresAt)) {
          setState(() => _status = "Код истёк ⏰");
          await ref.remove();
        } else {
          final userSnap =
          await FirebaseDatabase.instance.ref('users/$childUid').get();
          final userData = userSnap.exists
              ? Map<String, dynamic>.from(userSnap.value as Map)
              : {'name': 'Без имени', 'email': childEmail};

          final parentRef =
          FirebaseDatabase.instance.ref('parents/$parentUid/children/$childUid');
          await parentRef.set({
            'email': userData['email'],
            'name': userData['name'],
            'linkedAt': createdAt,
          });

          await FirebaseDatabase.instance
              .ref('children/$childUid/parentUid')
              .set(parentUid);

          await ref.remove();
          setState(() => _status = "✅ Ребёнок успешно добавлен!");
        }
      }
    } catch (e) {
      setState(() => _status = "Ошибка: $e");
    } finally {
      setState(() => _loading = false);
    }
  }

  // 👶 Получение списка детей
  Future<List<Map<String, dynamic>>> _fetchAllChildren(String parentUid) async {
    final snap =
    await FirebaseDatabase.instance.ref('parents/$parentUid/children').get();
    if (!snap.exists || snap.value == null) return [];

    final children = Map<String, dynamic>.from(snap.value as Map);
    List<Map<String, dynamic>> results = [];

    for (var entry in children.entries) {
      final uid = entry.key;
      final childSnap = await FirebaseDatabase.instance.ref('users/$uid').get();
      final childData =
      childSnap.exists ? Map<String, dynamic>.from(childSnap.value as Map) : {};
      results.add({
        'uid': uid,
        'name': childData['name'] ?? entry.value['name'] ?? 'Без имени',
        'email': childData['email'] ?? entry.value['email'] ?? 'Без email',
        'balance': (childData['balance'] ?? 0).toDouble(),
        'score': (childData['score'] ?? 0),
      });
    }
    return results;
  }

  @override
  Widget build(BuildContext context) {
    final userProv = Provider.of<UserProvider>(context);
    final authProv = Provider.of<local_auth.AuthProvider>(context, listen: false);
    final user = userProv.currentUser;

    return Scaffold(
      backgroundColor: Colors.green.shade50,
      body: LeafBackground(
        offsetFactor: 1.1,
        waveSpeed: 0.7,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const SizedBox(height: 10),

                // 💳 Карта родителя (в твоём стиле)
                Container(
                  width: 340,
                  height: 210,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: const LinearGradient(
                      colors: [Color(0xFFA8E063), Color(0xFF56AB2F)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 10,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        top: 16,
                        right: 16,
                        child: Text(
                          'Green Parent',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Positioned(
                        left: 20,
                        bottom: 50,
                        right: 60,
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 400),
                          child: _showUid
                              ? FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            key: const ValueKey('visibleUid'),
                            child: Text(
                              user?.uid ?? '0000-0000-0000',
                              style: const TextStyle(
                                fontSize: 16,
                                letterSpacing: 2,
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          )
                              : const Text(
                            '••••  ••••  ••••',
                            key: ValueKey('hiddenUid'),
                            style: TextStyle(
                              fontSize: 18,
                              letterSpacing: 3,
                              color: Colors.white70,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        right: 20,
                        bottom: 78,
                        child: IconButton(
                          icon: Icon(
                            _showUid ? Icons.visibility_off : Icons.visibility,
                            color: Colors.white,
                            size: 22,
                          ),
                          onPressed: () {
                            setState(() => _showUid = !_showUid);
                            if (user?.uid != null) {
                              Clipboard.setData(ClipboardData(text: user!.uid));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('UID скопирован 📋'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            }
                          },
                        ),
                      ),
                      Positioned(
                        left: 20,
                        bottom: 20,
                        child: Text(
                          user?.name ?? 'PARENT HOLDER',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      Positioned(
                        right: 20,
                        bottom: 20,
                        child: Text(
                          'VALID: $_expiry   CVV: $_cvv',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white70,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // 🔹 Привязка ребёнка
                TextField(
                  controller: _codeController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    hintText: "Введите 6-значный код ребёнка",
                    prefixIcon: const Icon(Icons.qr_code_2, color: Colors.green),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: _loading
                      ? null
                      : () async {
                    if (user?.uid != null) await _linkChild(user!.uid);
                  },
                  icon: _loading
                      ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                      : const Icon(Icons.link),
                  label: const Text("Привязать ребёнка"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF63D471),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                  ),
                ),
                const SizedBox(height: 10),
                if (_status != null)
                  Text(
                    _status!,
                    style: TextStyle(
                      color:
                      _status!.contains("✅") ? Colors.green : Colors.redAccent,
                    ),
                  ),

                const Divider(height: 40, thickness: 0.8),

                // 👶 Список детей
                const Text(
                  "Мои дети 🌱",
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87),
                ),
                const SizedBox(height: 10),

                FutureBuilder<List<Map<String, dynamic>>>(
                  future: user?.uid != null ? _fetchAllChildren(user!.uid) : null,
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.all(20),
                        child: CircularProgressIndicator(color: Colors.green),
                      );
                    }
                    if (!snap.hasData || snap.data!.isEmpty) {
                      return const Text("Пока нет добавленных детей");
                    }

                    final kids = snap.data!;
                    return Column(
                      children: kids.map((child) {
                        return Container(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
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
                            leading: const Icon(Icons.child_care,
                                color: Colors.green),
                            title: Text(
                              child['name'],
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Email: ${child['email']}"),
                                Text("Баланс: ${child['balance']} ₽"),
                                Text("Очки: ${child['score']}"),
                              ],
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.school, color: Colors.green),
                              tooltip: "Посмотреть историю тестов",
                              onPressed: () async {
                                final tests = await _loadTests(child['uid']);
                                if (!mounted) return;
                                showDialog(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16)),
                                    title: Text("📚 Тесты ${child['name']}"),
                                    content: tests.isEmpty
                                        ? const Text("Пока нет результатов тестов 😅")
                                        : SizedBox(
                                      width: double.maxFinite,
                                      child: ListView.builder(
                                        shrinkWrap: true,
                                        itemCount: tests.length,
                                        itemBuilder: (context, i) {
                                          final t = tests[i];
                                          return ListTile(
                                            leading: const Icon(
                                                Icons.quiz,
                                                color: Colors.green),
                                            title: Text(
                                                "${t['subject']} (${t['percent']}%)"),
                                            subtitle: Text(
                                                "✅ ${t['correct']} из ${t['total']} | ${t['date']}"),
                                          );
                                        },
                                      ),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(ctx),
                                        child: const Text('Закрыть',
                                            style:
                                            TextStyle(color: Colors.green)),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),

                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () async {
                    await authProv.signOut();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Вы вышли из аккаунта 🌿')),
                      );
                      Navigator.of(context)
                          .pushNamedAndRemoveUntil('/', (_) => false);
                    }
                  },
                  icon: const Icon(Icons.logout),
                  label: const Text("Выйти из аккаунта"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                    padding:
                    const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
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
