import 'package:app_movil_comunidad/routes/routes.dart';
import 'package:app_movil_comunidad/screens/preferencias_usuario.dart';
import 'package:app_movil_comunidad/utils/constants/constants.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = PreferenciasUsuario();
  await prefs.initPrefs();
  runApp(MyApp(showOnboarding: !prefs.onboardingVisto));
}

class MyApp extends StatelessWidget {
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  final bool showOnboarding;
  MyApp({super.key, required this.showOnboarding});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Comunidad CNC',
      navigatorKey: navigatorKey,
      theme: ThemeData(
        primaryColor: kPrimaryColor,
        fontFamily: 'Poppins',
        scaffoldBackgroundColor: const Color.fromRGBO(251, 252, 255, 1),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 0,
            backgroundColor: kPrimaryColor,
            shape: const StadiumBorder(),
            maximumSize: const Size(double.infinity, 56),
            minimumSize: const Size(double.infinity, 56),
          ),
        ),
        inputDecorationTheme: const InputDecorationTheme(
          filled: true,
          fillColor: kPrimaryLightColor,
          iconColor: kPrimaryColor,
          prefixIconColor: kPrimaryColor,
          contentPadding: EdgeInsets.symmetric(
            horizontal: defaultPadding,
            vertical: defaultPadding,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(30)),
            borderSide: BorderSide.none,
          ),
        ),
      ),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('es'), Locale('ES')],
      initialRoute: showOnboarding ? 'onboarding' : 'splash',
      routes: getAplicationRoutes(),
      builder: (context, child) {
        return SafeArea(
          top: false,
          bottom: true,
          left: false,
          right: false,
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
