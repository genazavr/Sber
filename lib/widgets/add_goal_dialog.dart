import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../models/saving_goal.dart';

class AddGoalDialog extends StatefulWidget {
  final Function(SavingGoal) onSave;
  const AddGoalDialog({super.key, required this.onSave});

  @override
  State<AddGoalDialog> createState() => _AddGoalDialogState();
}

class _AddGoalDialogState extends State<AddGoalDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  File? _image;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      final dir = await getApplicationDocumentsDirectory();
      final fileName = '${const Uuid().v4()}.jpg';
      final saved = await File(picked.path).copy('${dir.path}/$fileName');
      setState(() => _image = saved);
    }
  }

  void _saveGoal() {
    if (!_formKey.currentState!.validate() || _image == null) return;
    final goal = SavingGoal(
      id: const Uuid().v4(),
      title: _titleCtrl.text.trim(),
      targetAmount: double.parse(_amountCtrl.text),
      savedAmount: 0,
      imagePath: _image!.path,
    );
    widget.onSave(goal);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Новая цель'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _titleCtrl,
                decoration: const InputDecoration(labelText: 'Название цели'),
                validator: (v) =>
                v == null || v.isEmpty ? 'Введите название' : null,
              ),
              TextFormField(
                controller: _amountCtrl,
                decoration:
                const InputDecoration(labelText: 'Сколько нужно накопить'),
                keyboardType: TextInputType.number,
                validator: (v) =>
                v == null || double.tryParse(v) == null ? 'Введите сумму' : null,
              ),
              const SizedBox(height: 12),
              _image != null
                  ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(_image!, height: 120, fit: BoxFit.cover),
              )
                  : TextButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.image),
                label: const Text('Выбрать картинку'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
        ElevatedButton(onPressed: _saveGoal, child: const Text('Создать')),
      ],
    );
  }
}
