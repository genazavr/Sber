import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import '../providers/user_provider.dart';
import '../widgets/leaf_background.dart';
import 'shop_screen.dart';
import 'package:image_picker/image_picker.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  bool _showUid = false;
  String? _selectedDesign;
  String? _linkCode;
  DateTime? _expiresAt;

  late AnimationController _leafController;

  final List<Map<String, String>> _cardDesigns = [
    {'name': 'Классическая', 'image': 'assets/cards/1.png'},
    {'name': 'Весёлая', 'image': 'assets/cards/2.png'},
    {'name': 'Командная', 'image': 'assets/cards/3.png'},

  ];

  Map<String, String> _generateCardDetails() => {'expiry': '07/29', 'cvv': '512'};

  @override
  void initState() {
    super.initState();
    _leafController =
        AnimationController(vsync: this, duration: const Duration(seconds: 2));
    _loadSelectedDesign();
  }

  Future<void> _loadSelectedDesign() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final snap = await FirebaseDatabase.instance.ref('users/$uid/cardDesign').get();
    if (snap.exists) {
      setState(() => _selectedDesign = snap.value.toString());
    } else {
      setState(() => _selectedDesign = _cardDesigns.first['name']);
    }
  }

  Future<void> _saveSelectedDesign(String designName) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    await FirebaseDatabase.instance.ref('users/$uid').update({'cardDesign': designName});
    setState(() => _selectedDesign = designName);
  }

  // Выбор дизайна карты
  void _chooseCardDesign() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Выбери дизайн карты 🌈',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              alignment: WrapAlignment.center,
              children: _cardDesigns.map((design) {
                final isSelected = _selectedDesign == design['name'];
                return GestureDetector(
                  onTap: () async {
                    await _saveSelectedDesign(design['name']!);
                    if (mounted) Navigator.pop(context);
                  },
                  child: Stack(
                    children: [
                      Container(
                        width: 160,
                        height: 100,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected ? Colors.green : Colors.transparent,
                            width: 3,
                          ),
                          image: DecorationImage(
                            image: AssetImage(design['image']!),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      if (isSelected)
                        const Positioned(
                          top: 8,
                          right: 8,
                          child: Icon(Icons.check_circle, color: Colors.green, size: 24),
                        ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Выход из аккаунта'),
        content: const Text('Ты уверен, что хочешь выйти? 🌿'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            style: TextButton.styleFrom(foregroundColor: Colors.green),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            child: const Text('Выйти'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      _leafController.forward(from: 0);
      await Future.delayed(const Duration(milliseconds: 1500));

      await FirebaseAuth.instance.signOut();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Вы вышли из аккаунта 🌱')),
      );
      Navigator.of(context).pushNamedAndRemoveUntil('/', (_) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProv = Provider.of<UserProvider>(context);
    final user = userProv.currentUser;
    final details = _generateCardDetails();

    return Scaffold(
      backgroundColor: Colors.green.shade50,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const SizedBox(height: 10),
              GestureDetector(
                onTap: _chooseCardDesign,
                child: _buildCard(user, details),
              ),
              const SizedBox(height: 24),
              _infoPanel(user),
              const SizedBox(height: 24),
              _squareButton(
                icon: Icons.logout,
                label: 'Выход',
                onTap: _logout,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard(user, details) {
    final design = _cardDesigns.firstWhere(
          (e) => e['name'] == _selectedDesign,
      orElse: () => _cardDesigns.first,
    );

    return Container(
      width: 340,
      height: 210,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        image: DecorationImage(
          image: AssetImage(design['image']!),
          fit: BoxFit.cover,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: 20,
            top: 16,
            child: Text(
              'Green Challenge',
              style: TextStyle(
                color: Colors.green.shade900,
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
                    color: Colors.black87,
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
                  color: Colors.black54,
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
                color: Colors.green,
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
              user?.name ?? 'CARD HOLDER',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          Positioned(
            right: 20,
            bottom: 20,
            child: Text(
              'VALID: ${details['expiry']}   CVV: ${details['cvv']}',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.black45,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _squareButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 10),
        height: 70,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF63D471), Color(0xFF41B66E)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.green.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 28, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoPanel(user) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black12.withOpacity(0.05),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _infoRow(Icons.email, 'Email', user?.email ?? '---'),
          _infoRow(Icons.account_balance_wallet, 'Баланс',
              '${(user?.balance ?? 0).toStringAsFixed(0)} ₽'),
          _infoRow(Icons.star, 'Баллы',
              '${(user?.score ?? 0).toStringAsFixed(0)}'),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: Colors.green.shade600),
          const SizedBox(width: 12),
          Text('$title: ',
              style:
              const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
          Expanded(
            child: Text(value, style: const TextStyle(color: Colors.black54)),
          ),
        ],
      ),
    );
  }
}
