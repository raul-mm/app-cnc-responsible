import 'package:app_movil_comunidad/screens/configuracion/configuracion_comunidad_page.dart';
import 'package:app_movil_comunidad/screens/dashboard/customNavigationBar.dart';
import 'package:app_movil_comunidad/screens/dashboard/dashboard_page.dart';
import 'package:app_movil_comunidad/screens/info/info_page.dart';
import 'package:app_movil_comunidad/screens/noticias/wp_cnc_noticias.dart';
import 'package:flutter/material.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    DashboardPage(),
    PostListPage(),
    ConfiguracionComunidadPage(),
    InfoPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _pages[_currentIndex],
      ),
      bottomNavigationBar: CustomNavigationBar(
        currentIndex: _currentIndex,
        onItemSelected: (index) {
          setState(() => _currentIndex = index);
        },
      ),
    );
  }
}
