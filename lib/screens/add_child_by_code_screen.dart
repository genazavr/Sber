import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class AddChildByCodeScreen extends StatefulWidget {
  const AddChildByCodeScreen({super.key});

  @override
  State<AddChildByCodeScreen> createState() => _AddChildByCodeScreenState();
}

class _AddChildByCodeScreenState extends State<AddChildByCodeScreen> {
  final _controller = TextEditingController();
  bool _loading = false;
  final _db = FirebaseDatabase.instance.ref();

  Future<void> _addChild() async {
    final code = _controller.text.trim().toUpperCase();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Введите код')),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final snap = await _db.child('link_codes/$code').get();

      if (!snap.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Код не найден')),
        );
        setState(() => _loading = false);
        return;
      }

      final data = Map<String, dynamic>.from(snap.value as Map);

      final expiresAt = DateTime.tryParse(data['expiresAt'] ?? '');
      if (expiresAt == null || DateTime.now().isAfter(expiresAt)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Код истёк')),
        );
        await _db.child('link_codes/$code').remove();
        setState(() => _loading = false);
        return;
      }

      final parentUid = FirebaseAuth.instance.currentUser?.uid;
      if (parentUid == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ошибка авторизации родителя')),
        );
        setState(() => _loading = false);
        return;
      }


      await _db.child('parents/$parentUid/children/${data['childUid']}').set({
        'email': data['childEmail'],
        'linkedAt': DateTime.now().toIso8601String(),
      });


      await _db.child('link_codes/$code').remove();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ребёнок успешно добавлен 👶')),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: $e')),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Добавить ребёнка по коду'),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              'Введите 6-значный код, который показал ребёнок:',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _controller,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: 'Код (например: A7G4P2)',
                border: OutlineInputBorder(),
              ),
              maxLength: 6,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.link),
                label: _loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Добавить ребёнка'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                onPressed: _loading ? null : _addChild,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
