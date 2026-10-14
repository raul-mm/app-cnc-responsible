import 'package:app_movil_comunidad/db/db_helper.dart';
import 'package:app_movil_comunidad/screens/configuracion/comunidad_form.dart';
import 'package:app_movil_comunidad/widgets/ui.dart';
import 'package:flutter/material.dart';

class CrearComunidadPage extends StatelessWidget {
  const CrearComunidadPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kFondo,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                child: Row(
                  children: [
                    Hero(
                      tag: 'logo-virgen',
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(40),
                        child: Image.asset(
                          'assets/logos/logo-cnc.png',
                          height: 48,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Crear comunidad',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Completa los datos para empezar',
                            style: TextStyle(color: Colors.black54),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              ComunidadForm(
                textoBoton: 'Crear comunidad',
                onSave: (comunidad) async {
                  await DBHelper.insertarComunidad(comunidad);
                  if (!context.mounted) return;
                  toast(context, 'Comunidad registrada');
                  Navigator.pushReplacementNamed(context, 'main');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
