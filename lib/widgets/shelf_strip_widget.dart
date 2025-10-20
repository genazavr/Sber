import 'package:flutter/material.dart';
import '../models/shelf_model.dart';

class ShelfStripWidget extends StatelessWidget {
  final ShelfModel shelf;
  const ShelfStripWidget({super.key, required this.shelf});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.green.shade50,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('ID: ${shelf.id}'),
          Text('Почва: ${shelf.soilHumidity} | Воздух: ${shelf.airHumidity}'),
          Icon(
            shelf.auto ? Icons.auto_awesome : Icons.flash_off,
            color: shelf.auto ? Colors.green : Colors.grey,
          )
        ],
      ),
    );
  }
}
