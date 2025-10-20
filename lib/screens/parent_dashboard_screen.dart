import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/leaf_background.dart';

class ParentDashboardScreen extends StatefulWidget {
  const ParentDashboardScreen({super.key});

  @override
  State<ParentDashboardScreen> createState() => _ParentDashboardScreenState();
}

class _ParentDashboardScreenState extends State<ParentDashboardScreen>
    with TickerProviderStateMixin {
  final _taskTitle = TextEditingController();
  final _taskDesc = TextEditingController();
  final _taskReward = TextEditingController();
  final _transferTo = TextEditingController();
  final _transferAmount = TextEditingController();

  String? _selectedChildUid;
  String? _selectedChildName;
  String? _selectedChildEmail;

  final Map<String, Map<String, String>> _childrenCache = {};

  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeController =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut);
    _fadeController.forward();
    _loadChildren();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _taskTitle.dispose();
    _taskDesc.dispose();
    _taskReward.dispose();
    _transferTo.dispose();
    _transferAmount.dispose();
    super.dispose();
  }

  void _loadChildren() {
    final parent = FirebaseAuth.instance.currentUser!;
    final ref = FirebaseDatabase.instance.ref('parents/${parent.uid}/children');

    ref.onValue.listen((event) async {
      final data = event.snapshot.value;
      if (data == null) {
        if (mounted) setState(() => _childrenCache.clear());
        return;
      }

      final kids = Map<String, dynamic>.from(data as Map);
      final newCache = <String, Map<String, String>>{};

      for (var entry in kids.entries) {
        final uid = entry.key;
        final val = Map<String, dynamic>.from(entry.value);
        String? name = val['name'];
        String? email = val['email'];


        if (name == null || name == "Без имени") {
          final userSnap = await FirebaseDatabase.instance.ref('users/$uid').get();
          if (userSnap.exists && userSnap.value != null) {
            final userData = Map<String, dynamic>.from(userSnap.value as Map);
            name = userData['name'] ?? name;
            email = userData['email'] ?? email;
          }
        }

        newCache[uid] = {
          'name': name ?? 'Без имени',
          'email': email ?? 'Без email',
        };
      }

      if (mounted) {
        setState(() {
          _childrenCache
            ..clear()
            ..addAll(newCache);
        });
      }
    });
  }



  Future<void> _transferMoney() async {
    final parent = FirebaseAuth.instance.currentUser!;
    final input = _transferTo.text.trim();
    final amount = double.tryParse(_transferAmount.text.replaceAll(',', '.')) ?? 0.0;

    if (input.isEmpty || amount <= 0) {
      _showSnack('Введите получателя и сумму');
      return;
    }

    String? receiverUid = input;
    if (input.contains('@')) {
      final snap = await FirebaseDatabase.instance.ref('users').get();
      if (snap.exists && snap.value != null) {
        final usersMap = Map<String, dynamic>.from(snap.value as Map);
        for (var entry in usersMap.entries) {
          final user = Map<String, dynamic>.from(entry.value);
          if (user['email'] == input) {
            receiverUid = entry.key;
            break;
          }
        }
      }
    }

    if (receiverUid == null || receiverUid == parent.uid) {
      _showSnack('Неверный получатель');
      return;
    }

    final parentRef = FirebaseDatabase.instance.ref('users/${parent.uid}/balance');
    final receiverRef = FirebaseDatabase.instance.ref('users/$receiverUid/balance');

    final parentSnap = await parentRef.get();
    double parentBalance = (parentSnap.exists && parentSnap.value is num)
        ? (parentSnap.value as num).toDouble()
        : 0.0;

    if (parentBalance < amount) {
      _showSnack('Недостаточно средств');
      return;
    }

    await parentRef.runTransaction((val) {
      double current = (val is num) ? val.toDouble() : 0.0;
      return Transaction.success(current - amount);
    });

    await receiverRef.runTransaction((val) {
      double current = (val is num) ? val.toDouble() : 0.0;
      return Transaction.success(current + amount);
    });

    _showSnack('Перевод успешно выполнен ✅');
    _transferTo.clear();
    _transferAmount.clear();
  }


  Future<void> _createTask() async {
    if (_selectedChildUid == null) {
      _showSnack('Выберите ребёнка');
      return;
    }

    final title = _taskTitle.text.trim();
    final desc = _taskDesc.text.trim();
    final reward = double.tryParse(_taskReward.text.replaceAll(',', '.')) ?? 0;

    if (title.isEmpty || reward <= 0) {
      _showSnack('Введите название и вознаграждение');
      return;
    }

    final parent = FirebaseAuth.instance.currentUser!;
    final parentRef = FirebaseDatabase.instance.ref('users/${parent.uid}/balance');

    final parentSnap = await parentRef.get();
    double parentBalance = (parentSnap.exists && parentSnap.value is num)
        ? (parentSnap.value as num).toDouble()
        : 0.0;

    if (parentBalance < reward) {
      _showSnack('Недостаточно средств для создания задания');
      return;
    }


    await parentRef.runTransaction((val) {
      double current = (val is num) ? val.toDouble() : 0.0;
      if (current >= reward) {
        return Transaction.success(current - reward);
      } else {
        return Transaction.abort();
      }
    });


    await FirebaseDatabase.instance.ref('tasks/${_selectedChildUid!}').push().set({
      'title': title,
      'desc': desc,
      'points': reward,
      'createdAt': DateTime.now().toIso8601String(),
      'childName': _selectedChildName ?? 'Без имени',
      'childEmail': _selectedChildEmail ?? 'Без email',
      'status': 'pending',
      'fromParent': parent.uid,
    });

    _showSnack('Задание добавлено и $reward₽ списано с вашего счёта');
    _taskTitle.clear();
    _taskDesc.clear();
    _taskReward.clear();
  }

  void _showSnack(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(text),
      backgroundColor: Colors.green.shade600,
      behavior: SnackBarBehavior.floating,
    ));
  }


  @override
  Widget build(BuildContext context) {
    final parent = FirebaseAuth.instance.currentUser!;

    return Scaffold(
      backgroundColor: Colors.green.shade50,
      body: LeafBackground(
        offsetFactor: 1.1,
        waveSpeed: 0.5,
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _balanceCard(parent),
                  const SizedBox(height: 20),
                  _sectionTitle('💸 Перевод средств'),
                  _transferCard(),
                  const SizedBox(height: 24),
                  _sectionTitle('📝 Создание задания'),
                  _taskCard(),
                  const SizedBox(height: 24),
                  _sectionTitle('📋 Мои дети'),
                  ..._childrenCards(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }


  Widget _balanceCard(User parent) {
    return StreamBuilder(
      stream: FirebaseDatabase.instance.ref('users/${parent.uid}/balance').onValue,
      builder: (context, snap) {
        double balance = 0;
        if (snap.hasData && snap.data!.snapshot.value != null) {
          balance = (snap.data!.snapshot.value as num).toDouble();
        }

        return Container(
          width: double.infinity,
          height: 200,
          margin: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              colors: [Color(0xFF63D471), Color(0xFFA8E063)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.green.withOpacity(0.25),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                top: 16,
                right: 20,
                child: Text(
                  'Green Challenge',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.95),
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              Positioned(
                left: 20,
                bottom: 60,
                child: Text(
                  'PARENT CARD',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: 14,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              Positioned(
                left: 20,
                bottom: 28,
                child: Text(
                  '${balance.toStringAsFixed(2)} ₽',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _sectionTitle(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.green.shade800,
      ),
    ),
  );

  Widget _transferCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _boxStyle(),
      child: Column(
        children: [
          TextField(
            controller: _transferTo,
            decoration: _inputStyle('UID или Email получателя', Icons.person),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _transferAmount,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: _inputStyle('Сумма (₽)', Icons.currency_ruble),
          ),
          const SizedBox(height: 16),
          _greenButton(Icons.send, 'Перевести', _transferMoney),
        ],
      ),
    );
  }

  Widget _taskCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _boxStyle(),
      child: Column(
        children: [
          DropdownButtonFormField<String>(
            decoration: InputDecoration(
              labelText: 'Выберите ребёнка',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Colors.white,
            ),
            value: _selectedChildUid,
            items: _childrenCache.entries.map((e) {
              final uid = e.key;
              final name = e.value['name'] ?? 'Без имени';
              final email = e.value['email'] ?? '';
              return DropdownMenuItem(
                value: uid,
                child: Text('$name (${email.isNotEmpty ? email : uid})'),
              );
            }).toList(),
            onChanged: (uid) {
              if (uid == null) return;
              setState(() {
                _selectedChildUid = uid;
                _selectedChildName = _childrenCache[uid]?['name'];
                _selectedChildEmail = _childrenCache[uid]?['email'];
              });
            },
          ),
          const SizedBox(height: 8),
          if (_selectedChildName != null)
            Text('👶 $_selectedChildName выбрана',
                style: const TextStyle(color: Colors.black54)),
          const SizedBox(height: 8),
          TextField(controller: _taskTitle, decoration: _inputStyle('Название', Icons.edit)),
          const SizedBox(height: 8),
          TextField(controller: _taskDesc, decoration: _inputStyle('Описание', Icons.text_snippet)),
          const SizedBox(height: 8),
          TextField(
            controller: _taskReward,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: _inputStyle('Вознаграждение ₽', Icons.star),
          ),
          const SizedBox(height: 16),
          _greenButton(Icons.add_task, 'Создать задание', _createTask),
        ],
      ),
    );
  }

  Widget _greenButton(IconData icon, String label, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton.icon(
        icon: Icon(icon),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF63D471),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        onPressed: onTap,
      ),
    );
  }

  InputDecoration _inputStyle(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: Colors.green),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.green, width: 0.4),
      ),
    );
  }

  BoxDecoration _boxStyle() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black12.withOpacity(0.05),
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  List<Widget> _childrenCards() {
    if (_childrenCache.isEmpty) {
      return [
        const Padding(
          padding: EdgeInsets.all(12),
          child: Text('Пока нет добавленных детей 🌱',
              style: TextStyle(color: Colors.black54)),
        ),
      ];
    }

    return _childrenCache.entries.map((e) {
      final name = e.value['name'] ?? 'Без имени';
      final email = e.value['email'] ?? 'Без email';
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: _boxStyle(),
        child: ListTile(
          leading: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.child_care, color: Colors.green),
          ),
          title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text(email, style: const TextStyle(color: Colors.black54)),
        ),
      );
    }).toList();
  }
}
