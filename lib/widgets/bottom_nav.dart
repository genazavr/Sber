import 'package:flutter/material.dart';
import 'package:untitled17/screens/chat_screen.dart';
import '../screens/home_screen.dart';
import '../screens/shelves_screen.dart';
import '../screens/courses_screen.dart';
import '../screens/savings_goals_screen.dart';
import '../screens/map_screen.dart';

class BottomNav extends StatefulWidget {
  const BottomNav({super.key});

  @override
  State<BottomNav> createState() => _BottomNavState();
}

class _BottomNavState extends State<BottomNav> {
  int _index = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    ShelvesScreen(),
    const CoursesScreen(),
    const FirebaseGoalsScreen(),
    const ChatPage(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final items = [
      {'icon': Icons.home_rounded, 'label': 'Главная'},
      {'icon': Icons.local_florist_rounded, 'label': 'Цветочек'},
      {'icon': Icons.menu_book_rounded, 'label': 'Курсы'},
      {'icon': Icons.savings_rounded, 'label': 'Копилка'},
      {'icon': Icons.chat_bubble_rounded, 'label': 'Чат'},
      {'icon': Icons.credit_card_rounded, 'label': 'Карта'},
    ];

    return Scaffold(
      extendBody: true,
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: SafeArea(
        child: Container(
          margin: const EdgeInsets.only(left: 16, right: 16, bottom: 6),
          height: 72,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white.withOpacity(0.93),
                Colors.green.shade50.withOpacity(0.88),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(26),
            boxShadow: [
              BoxShadow(
                color: Colors.green.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(items.length, (i) {
                final isActive = _index == i;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _index = i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 280),
                      curve: Curves.easeOut,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(
                        color: isActive
                            ? Colors.green.shade100.withOpacity(0.4)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnimatedScale(
                            scale: isActive ? 1.2 : 1.0,
                            duration: const Duration(milliseconds: 250),
                            child: Icon(
                              items[i]['icon'] as IconData,
                              color: isActive
                                  ? Colors.green.shade700
                                  : Colors.grey.shade600,
                              size: 24,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            items[i]['label'] as String,
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: isActive
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                              color: isActive
                                  ? Colors.green.shade700
                                  : Colors.grey.shade600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}
