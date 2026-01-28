import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:laundriin/features/home/home_screen.dart';
import 'package:laundriin/features/orders/orders_screen.dart';
import 'package:laundriin/features/reports/reports_screen.dart';
import 'package:laundriin/features/settings/setting_screen.dart';
import 'package:laundriin/ui/color.dart';
import 'package:laundriin/ui/typography.dart';

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
    const OrdersScreen(),
    const ReportsScreen(),
    const SettingScreen(),
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
              iconSvg: "assets/svg/Home.svg",
              label: "Home",
            ),
            _navItem(
              index: 1,
              iconSvg: "assets/svg/Document.svg",
              label: "Orders",
            ),
            _navItem(
              index: 2,
              iconSvg: "assets/svg/Chart.svg",
              label: "Reports",
            ),
            _navItem(
              index: 3,
              iconSvg: "assets/svg/Setting.svg",
              label: "Settings",
            ),
          ],
        ),
      ),
    );
  }

  Widget _navItem({
    required int index,
    required String iconSvg,
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
            SvgPicture.asset(
              iconSvg,
              width: 24,
              height: 24,
              color: isActive ? _activeColor : _inactiveColor,
            ),
            const SizedBox(height: 4),
            Text(label,
                style: xsRegular.copyWith(
                  color: isActive ? _activeColor : _inactiveColor,
                )),
          ],
        ),
      ),
    );
  }
}
