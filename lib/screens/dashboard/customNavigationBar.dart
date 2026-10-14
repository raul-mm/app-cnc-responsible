import 'package:flutter/material.dart';

class CustomNavigationBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onItemSelected;

  const CustomNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      height: 70,
      selectedIndex: currentIndex,
      onDestinationSelected: onItemSelected,
      backgroundColor: Colors.white,
      indicatorColor: Colors.redAccent.withValues(alpha: 0.2),
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      elevation: 4,
      animationDuration: const Duration(milliseconds: 400),
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home_rounded),
          label: 'Inicio',
        ),
        NavigationDestination(
          icon: Icon(Icons.newspaper_outlined),
          selectedIcon: Icon(Icons.newspaper_rounded),
          label: 'Noticias',
        ),
        NavigationDestination(
          icon: Icon(Icons.church_outlined),
          selectedIcon: Icon(Icons.church_rounded),
          label: 'Comunidad',
        ),
        NavigationDestination(
          icon: Icon(Icons.info_outline),
          selectedIcon: Icon(Icons.info_rounded),
          label: 'Info',
        ),
      ],
    );
  }
}
