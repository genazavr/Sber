import 'dart:convert';

class SavingGoal {
  String id;
  String title;
  double targetAmount;
  double savedAmount;
  String imagePath;

  SavingGoal({
    required this.id,
    required this.title,
    required this.targetAmount,
    required this.savedAmount,
    required this.imagePath,
  });

  double get progress => (savedAmount / targetAmount).clamp(0, 1);

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'targetAmount': targetAmount,
    'savedAmount': savedAmount,
    'imagePath': imagePath,
  };

  factory SavingGoal.fromMap(Map<String, dynamic> map) => SavingGoal(
    id: map['id'],
    title: map['title'],
    targetAmount: (map['targetAmount'] ?? 0).toDouble(),
    savedAmount: (map['savedAmount'] ?? 0).toDouble(),
    imagePath: map['imagePath'] ?? '',
  );

  String toJson() => jsonEncode(toMap());
  factory SavingGoal.fromJson(String src) =>
      SavingGoal.fromMap(jsonDecode(src));
}
