class AppUser {
  final String uid;
  final String email;
  String name;
  double score;
  double balance;
  List<String> shelves;
  String role;

  AppUser({
    required this.uid,
    required this.email,
    this.name = '',
    this.score = 0.0,
    this.balance = 0.0,
    this.shelves = const [],
    this.role = 'child',
  });

  factory AppUser.fromMap(String uid, Map<dynamic, dynamic> map) {
    return AppUser(
      uid: uid,
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      score: (map['score'] is num) ? (map['score'] as num).toDouble() : 0.0,
      balance: (map['balance'] is num) ? (map['balance'] as num).toDouble() : 0.0,
      shelves: map['shelves'] != null
          ? List<String>.from((map['shelves'] as Map).keys)
          : [],
      role: map['role'] ?? 'child',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'name': name,
      'score': score,
      'balance': balance,
      'shelves': {for (var s in shelves) s: true},
      'role': role,
    };
  }
}
