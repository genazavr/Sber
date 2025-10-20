import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:provider/provider.dart';
import '../providers/shelves_provider.dart';
import '../widgets/leaf_background.dart';
import '../models/shelf_model.dart';

class ShelfDetailScreen extends StatefulWidget {
  final String shelfId;
  const ShelfDetailScreen({super.key, required this.shelfId});

  @override
  State<ShelfDetailScreen> createState() => _ShelfDetailScreenState();
}

class _ShelfDetailScreenState extends State<ShelfDetailScreen> {
  int uploadedThisWeek = 0;

  @override
  void initState() {
    super.initState();
    _checkUploads();
  }

  Future<void> _checkUploads() async {
    final ref = FirebaseDatabase.instance.ref('shelves/${widget.shelfId}/uploads');
    final snapshot = await ref.get();
    if (snapshot.exists) {
      final data = Map<String, dynamic>.from(snapshot.value as Map);
      final now = DateTime.now();
      final recent = data.values.where((e) {
        final ts = DateTime.fromMillisecondsSinceEpoch(e);
        return now.difference(ts).inDays < 7;
      }).length;
      setState(() => uploadedThisWeek = recent);
    }
  }

  Future<void> _uploadPhoto(BuildContext context, ShelfModel shelf, int index) async {
    if (uploadedThisWeek >= 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Вы уже загрузили 3 фото на этой неделе ❌')),
      );
      return;
    }

    final picker = ImagePicker();
    final img = await picker.pickImage(source: ImageSource.gallery);
    if (img == null) return;

    final dir = await getApplicationDocumentsDirectory();
    final saved = await File(img.path).copy(
      '${dir.path}/${widget.shelfId}_p${index + 1}_${DateTime.now().millisecondsSinceEpoch}.jpg',
    );

    await FirebaseDatabase.instance
        .ref('shelves/${widget.shelfId}/shelvesMeta/p${index + 1}')
        .update({
      'imagePath': saved.path,
      'name': shelf.shelvesMeta['p${index + 1}']?['name'] ?? 'Crop ${index + 1}',
    });

    await FirebaseDatabase.instance
        .ref('shelves/${widget.shelfId}/uploads')
        .push()
        .set(DateTime.now().millisecondsSinceEpoch);

    await FirebaseDatabase.instance
        .ref('users/${shelf.owner}/score')
        .runTransaction((data) {
      double cur = 0.0;
      if (data is num) cur = data.toDouble();
      return Transaction.success(cur + 100.0);
    });

    setState(() => uploadedThisWeek++);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Фото добавлено 🌿 +100 баллов')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final shelvesProv = Provider.of<ShelvesProvider>(context);
    final shelf = shelvesProv.shelves[widget.shelfId];

    if (shelf == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.green.shade50,
      body: LeafBackground(
        offsetFactor: 1.1,
        waveSpeed: 0.7,
        moveDuration: const Duration(seconds: 5),
        child: SafeArea(
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                child: ListView(
                  children: [
                    const SizedBox(height: 70),

                    // 🔹 Заголовок
                    Row(
                      children: [
                        const Icon(Icons.eco, color: Colors.green, size: 30),
                        const SizedBox(width: 8),
                        Text(
                          'Стеллаж ${shelf.id.substring(0, 6)}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2E472E),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // 🔹 Показатели
                    _InfoRow(
                      icon: Icons.grass,
                      label: 'Почва',
                      value: '${shelf.soilHumidity.toStringAsFixed(1)}%',
                    ),
                    const SizedBox(height: 10),
                    _InfoRow(
                      icon: Icons.air,
                      label: 'Воздух',
                      value: '${shelf.airHumidity.toStringAsFixed(1)}%',
                    ),

                    const SizedBox(height: 30),
                    _SectionTitle('💡 Освещение'),
                    const SizedBox(height: 8),
                    ...List.generate(3, (i) {
                      return _StylishCard(
                        child: SwitchListTile(
                          activeColor: Colors.green,
                          title: Text('Источник света ${i + 1}',
                              style: const TextStyle(fontWeight: FontWeight.w500)),
                          value: shelf.lights[i] == 1,
                          onChanged: (v) => shelvesProv.toggleLight(shelf.id, i, v),
                        ),
                      );
                    }),

                    const SizedBox(height: 25),
                    _SectionTitle('💧 Полив'),
                    const SizedBox(height: 8),
                    ...List.generate(3, (i) {
                      return _StylishCard(
                        child: ListTile(
                          leading: Icon(Icons.water_drop,
                              color: shelf.pumps[i] == 1
                                  ? Colors.blue
                                  : Colors.grey),
                          title: Text('Полка ${i + 1}'),
                          subtitle: Text(
                            shelf.pumps[i] == 1 ? 'Поливается...' : 'Ожидает',
                            style: TextStyle(
                                color: shelf.pumps[i] == 1
                                    ? Colors.blueAccent
                                    : Colors.grey),
                          ),
                          trailing: ElevatedButton(
                            onPressed: () => shelvesProv.togglePump(
                              shelf.id,
                              i,
                              shelf.pumps[i] == 0,
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: shelf.pumps[i] == 1
                                  ? Colors.redAccent
                                  : Colors.green,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: const EdgeInsets.symmetric(
                                  vertical: 8, horizontal: 14),
                            ),
                            child: Text(
                              shelf.pumps[i] == 1 ? 'Остановить' : 'Полить',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),

                    const SizedBox(height: 25),
                    _SectionTitle('⚙️ Настройки'),
                    const SizedBox(height: 8),
                    _StylishCard(
                      child: SwitchListTile(
                        activeColor: Colors.green,
                        title: const Text('Автополив при низких значениях'),
                        value: shelf.auto,
                        onChanged: (v) =>
                            shelvesProv.enableAutoIrrigation(shelf.id, v),
                      ),
                    ),

                    const SizedBox(height: 30),
                    _SectionTitle('📸 Фото урожая (${3 - uploadedThisWeek} осталось)'),
                    const SizedBox(height: 8),
                    ...List.generate(3, (i) {
                      final meta = shelf.shelvesMeta['p${i + 1}'];
                      final path = meta?['imagePath'] ?? '';
                      final name = meta?['name'] ?? 'Полка ${i + 1}';

                      return _StylishCard(
                        child: ListTile(
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: path.isNotEmpty
                                ? Image.file(
                              File(path),
                              width: 56,
                              height: 56,
                              fit: BoxFit.cover,
                            )
                                : Container(
                              width: 56,
                              height: 56,
                              color: Colors.green.withOpacity(0.1),
                              child: const Icon(Icons.image_outlined,
                                  color: Colors.green),
                            ),
                          ),
                          title: Text(name),
                          trailing: IconButton(
                            icon: const Icon(Icons.add_a_photo_outlined,
                                color: Colors.green),
                            onPressed: () => _uploadPhoto(context, shelf, i),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),


              Positioned(
                top: 10,
                left: 8,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.85),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new,
                        color: Colors.green),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.green),
        const SizedBox(width: 10),
        Text(
          '$label: ',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        Text(
          value,
          style: const TextStyle(
              fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
        ),
      ],
    );
  }
}


class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 18,
        color: Color(0xFF2F4F2F),
      ),
    );
  }
}


class _StylishCard extends StatelessWidget {
  final Widget child;
  const _StylishCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }
}
