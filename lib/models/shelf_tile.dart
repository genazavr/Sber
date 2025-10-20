import 'package:flutter/material.dart';
import '../models/shelf_model.dart';

class ShelfTile extends StatelessWidget {
  final ShelfModel shelf;
  final VoidCallback onTap;

  const ShelfTile({super.key, required this.shelf, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text('Стеллаж ${shelf.id}'),
        subtitle: Text(
          'Почва: ${shelf.soilHumidity} | Воздух: ${shelf.airHumidity} | Свет: ${shelf.lights.join(",")}',
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
