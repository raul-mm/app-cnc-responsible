import 'package:shared_preferences/shared_preferences.dart';

class PreferenciasUsuario {
  static final PreferenciasUsuario _instancia = PreferenciasUsuario._internal();
  factory PreferenciasUsuario() => _instancia;
  PreferenciasUsuario._internal();

  SharedPreferences? _prefs;

  Future<void> initPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  bool get onboardingVisto => _prefs?.getBool('onboardingVisto') ?? false;
  set onboardingVisto(bool value) => _prefs?.setBool('onboardingVisto', value);
}
