import 'package:flutter/material.dart';

// используем псевдонимы, чтобы явно различать импорты
import 'parent_dashboard_screen.dart' as dashboard;
import 'parent_goals_screen.dart' as goals;
import 'parent_profile_screen.dart';

class ParentHomeScreen extends StatefulWidget {
  const ParentHomeScreen({super.key});

  @override
  State<ParentHomeScreen> createState() => _ParentHomeScreenState();
}

class _ParentHomeScreenState extends State<ParentHomeScreen> {
  int _index = 0;

  final List<Widget> _screens = [
    dashboard.ParentDashboardScreen(), // 👶 Главная
    goals.ParentGoalsScreen(),         // 🎯 Цели детей
    const ParentProfileScreen(),       // 👩‍👧 Профиль родителя
  ];

  @override
  Widget build(BuildContext context) {
    final items = [
      {'icon': Icons.home_rounded, 'label': 'Главная'},
      {'icon': Icons.flag_circle_rounded, 'label': 'Цели'},
      {'icon': Icons.account_circle_rounded, 'label': 'Профиль'},
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
                color: Colors.green.withOpacity(0.12),
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
                              size: 26,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            items[i]['label'] as String,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight:
                              isActive ? FontWeight.bold : FontWeight.w500,
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
