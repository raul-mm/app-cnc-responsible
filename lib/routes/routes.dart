import 'package:app_movil_comunidad/screens/carismas/CarismasPage.dart';
import 'package:app_movil_comunidad/screens/catequista/catequistas_equipos_page.dart';
import 'package:app_movil_comunidad/screens/comunidad/comunidad_page.dart';
import 'package:app_movil_comunidad/screens/configuracion/configuracion_comunidad_page.dart';
import 'package:app_movil_comunidad/screens/configuracion/crear_comunidad_page.dart';
import 'package:app_movil_comunidad/screens/dashboard/dashboard_page.dart';
import 'package:app_movil_comunidad/screens/dashboard/main_navigation.dart';
import 'package:app_movil_comunidad/screens/equipo/equipo_page.dart';
import 'package:app_movil_comunidad/screens/grupos/grupos_page.dart';
import 'package:app_movil_comunidad/screens/onboarding/onboarding_page.dart';
import 'package:app_movil_comunidad/screens/servicio/servicio_page.dart';
import 'package:app_movil_comunidad/screens/signo/signos_page.dart';
import 'package:app_movil_comunidad/screens/splash/splash_page.dart';
import 'package:flutter/cupertino.dart';

Map<String, WidgetBuilder> getAplicationRoutes() {
  return <String, WidgetBuilder>{
    'splash': (BuildContext context) => SplashPage(),
    'dashboard': (BuildContext context) => DashboardPage(),
    'comunidad': (BuildContext context) => ComunidadPage(),
    'equipo': (BuildContext context) => EquipoPage(),
    'catequista': (BuildContext context) => EquiposCatequistasPage(),
    'main': (BuildContext context) => MainNavigation(),
    'crearComunidad': (BuildContext context) => CrearComunidadPage(),
    'configuracionComunidad': (BuildContext context) =>
        ConfiguracionComunidadPage(),
    'signos': (BuildContext context) => SignosPage(),
    'onboarding': (BuildContext context) => OnboardingPage(),
    'grupos': (BuildContext context) => GruposPage(),
    'carismas': (BuildContext context) => CarismasPage(),
    'salmistas': (BuildContext context) =>
        const ServicioPage(tipo: 'Salmistas'),
    'lectores': (BuildContext context) => const ServicioPage(tipo: 'Lectores'),
    'ostiarios': (BuildContext context) =>
        const ServicioPage(tipo: 'Ostiarios'),
    'didascalos': (BuildContext context) =>
        const ServicioPage(tipo: 'Didáscalos'),
  };
}
