import 'package:app_movil_comunidad/screens/configuracion/configuracion_comunidad_page.dart';
import 'package:app_movil_comunidad/screens/dashboard/customNavigationBar.dart';
import 'package:app_movil_comunidad/screens/dashboard/dashboard_page.dart';
import 'package:app_movil_comunidad/screens/info/info_page.dart';
import 'package:app_movil_comunidad/screens/noticias/wp_cnc_noticias.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;
  DateTime? _ultimoAtras;

  final List<Widget> _pages = const [
    DashboardPage(),
    PostListPage(),
    ConfiguracionComunidadPage(),
    InfoPage(),
  ];

  /// Atrás: desde otra pestaña vuelve a Inicio; en Inicio hay que pulsar
  /// dos veces seguidas para salir.
  void _onBack(bool didPop, Object? result) {
    if (didPop) return;
    if (_currentIndex != 0) {
      setState(() => _currentIndex = 0);
      return;
    }
    final ahora = DateTime.now();
    if (_ultimoAtras != null &&
        ahora.difference(_ultimoAtras!) < const Duration(seconds: 2)) {
      SystemNavigator.pop();
      return;
    }
    _ultimoAtras = ahora;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        const SnackBar(
          content: Text('Presiona atrás otra vez para salir'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: _onBack,
      child: Scaffold(
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
      ),
    );
  }
}
