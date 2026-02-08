import 'dart:async';
import 'package:app_movil_comunidad/db/db_helper.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:jumping_dot/jumping_dot.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with TickerProviderStateMixin {
  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;

  late final AnimationController _versionFadeController;
  late final Animation<double> _versionFadeAnimation;

  late PackageInfo _packageInfo;
  bool _isPackageInfoReady = false;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );

    _versionFadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _versionFadeAnimation = CurvedAnimation(
      parent: _versionFadeController,
      curve: Curves.easeIn,
    );

    _fadeController.forward();
    _initialize();
  }

  Future<void> _initialize() async {
    _packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      _isPackageInfoReady = true;
    });
    _versionFadeController.forward();

    await Future.delayed(const Duration(seconds: 5));
    _verificarComunidad();
  }

  Future<void> _verificarComunidad() async {
    final comunidad = await DBHelper.obtenerComunidad();
    if (comunidad != null) {
      Navigator.pushReplacementNamed(context, 'main');
    } else {
      Navigator.pushReplacementNamed(context, 'crearComunidad');
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _versionFadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Hero(
                  tag: 'logo-cnc',
                  child: Image.asset(
                    'assets/images/piccola.jpg',
                    width: 200,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Camino Neocatecumenal',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFC62828), // rojo fuerte
                    fontFamily: 'Merriweather',
                  ),
                ),
                const SizedBox(height: 18),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    '"Hay que hacer comunidades cristianas como la Sagrada Familia de Nazaret '
                    'que vivan en humildad, sencillez y alabanza.\n El otro es Cristo."',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                      fontStyle: FontStyle.italic,
                      fontFamily: 'Merriweather',
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                JumpingDots(
                  color: Color(0xFFC62828), // rojo
                  radius: 6,
                  numberOfDots: 3,
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton:
          _isPackageInfoReady
              ? FadeTransition(
                opacity: _versionFadeAnimation,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    'Versión ${_packageInfo.version}.${_packageInfo.buildNumber}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Merriweather',
                    ),
                  ),
                ),
              )
              : null,
    );
  }
}
