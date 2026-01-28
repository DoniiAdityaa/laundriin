import 'package:flutter/material.dart';
import 'package:laundriin/features/home/home_screen.dart';
import 'package:laundriin/ui/color.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;

  final Color _activeColor = blue500;
  final Color _inactiveColor = textSecondary;

  final List<Widget> _screens = [
    const HomeScreen(),
    // const OrdersScreen(),
    // const ReportsScreen(),
    // const ProfileScreen(),
  ];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: _screens[_selectedIndex],
      bottomNavigationBar: _buildbottomNav(),
    );
  }

  Widget _buildbottomNav() {
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(0, 0, 0, 0),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: bgCard,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(22),
            topRight: Radius.circular(22),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 24,
              offset: const Offset(0, -8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _navItem(
              index: 0,
              icon: Icons.home_rounded,
              label: "Home",
            ),
            _navItem(
              index: 1,
              icon: Icons.receipt_long_rounded,
              label: "Orders",
            ),
            _navItem(
              index: 2,
              icon: Icons.bar_chart_rounded,
              label: "Reports",
            ),
            _navItem(
              index: 3,
              icon: Icons.settings_rounded,
              label: "Settings",
            ),
          ],
        ),
      ),
    );
  }

  Widget _navItem({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final bool isActive = _selectedIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() => _selectedIndex = index);
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 26,
              color: isActive ? _activeColor : _inactiveColor,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isActive ? _activeColor : _inactiveColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
