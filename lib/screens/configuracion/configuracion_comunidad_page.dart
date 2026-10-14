import 'package:app_movil_comunidad/db/db_helper.dart';
import 'package:app_movil_comunidad/models/comunidad.dart';
import 'package:app_movil_comunidad/screens/configuracion/comunidad_form.dart';
import 'package:app_movil_comunidad/widgets/ui.dart';
import 'package:flutter/material.dart';

class ConfiguracionComunidadPage extends StatefulWidget {
  const ConfiguracionComunidadPage({super.key});

  @override
  State<ConfiguracionComunidadPage> createState() =>
      _ConfiguracionComunidadPageState();
}

class _ConfiguracionComunidadPageState
    extends State<ConfiguracionComunidadPage> {
  Comunidad? _comunidad;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    DBHelper.obtenerComunidad().then((c) {
      if (mounted) {
        setState(() {
          _comunidad = c;
          _loading = false;
        });
      }
    });
  }

  Future<void> _guardar(Comunidad comunidad) async {
    if (_comunidad == null) {
      final id = await DBHelper.insertarComunidad(comunidad);
      _comunidad = Comunidad.fromMap({...comunidad.toMap(), 'id': id});
    } else {
      await DBHelper.actualizarComunidad(comunidad);
      _comunidad = comunidad;
    }
    if (mounted) toast(context, 'Datos de la comunidad actualizados');
  }

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: 'Configuración de la comunidad',
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.only(top: 10),
              child: ComunidadForm(
                inicial: _comunidad,
                textoBoton: 'Guardar cambios',
                onSave: _guardar,
              ),
            ),
    );
  }
}
