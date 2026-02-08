import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../db/db_helper.dart';
import '../../models/comunidad.dart';

class CrearComunidadPage extends StatefulWidget {
  const CrearComunidadPage({super.key});

  @override
  State<CrearComunidadPage> createState() => _CrearComunidadPageState();
}

class _CrearComunidadPageState extends State<CrearComunidadPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _numeroController = TextEditingController();
  final _fechaNacimientoController = TextEditingController();
  final _parroquiaController = TextEditingController();
  final _pasoController = TextEditingController();
  final _catequistaController = TextEditingController();
  final _fechaPasoController = TextEditingController();

  String _tipoParroquia = "Parroquia"; // valor por defecto
  bool _huboRito = false;

  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
  }

  void _seleccionarFecha(TextEditingController controller) async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );
    if (fecha != null) {
      controller.text = DateFormat('yyyy-MM-dd').format(fecha);
    }
  }

  void _guardarComunidad() async {
    if (_formKey.currentState!.validate()) {
      final comunidad = Comunidad(
        numero: _numeroController.text,
        fechaNacimiento: _fechaNacimientoController.text,
        parroquia: _parroquiaController.text,
        pasoActual: _pasoController.text,
        catequista: _catequistaController.text,
        tipoParroquia: _tipoParroquia,
        fechaPaso: _fechaPasoController.text,
        huboRito: _huboRito ? 1 : 0,
      );

      await DBHelper.insertarComunidad(comunidad);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Comunidad registrada correctamente')),
        );
        Navigator.pushReplacementNamed(context, 'main');
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.white, Color(0xFFFAFAFA)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Row(
                children: [
                  Hero(
                    tag: 'logo-virgen',
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(40),
                      child: Image.asset(
                        'assets/logos/logo-cnc.png',
                        height: 40,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Crear Comunidad',
                      style: TextStyle(
                        fontSize: 18,
                        fontFamily: 'Merriweather',
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(thickness: 1, color: Colors.redAccent),
              const SizedBox(height: 10),
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          _buildInput(_parroquiaController, 'Nombre de la Parroquia o Capilla'),
                          
                          _buildDropdownTipo(),

                          _buildInput(
                            _numeroController,
                            'Número de Comunidad',
                            isNumeric: true,
                          ),

                          _buildDateField(_fechaNacimientoController, 'Fecha de Nacimiento'),

                          _buildInput(_catequistaController, 'Catequista'),

                          _buildInput(_pasoController, 'Último paso'),

                          _buildDateField(_fechaPasoController, 'Fecha del paso'),

                          SwitchListTile(
                            title: const Text("¿Hubo rito?"),
                            activeColor: Colors.redAccent,
                            value: _huboRito,
                            onChanged: (value) {
                              setState(() {
                                _huboRito = value;
                              });
                            },
                          ),

                          const SizedBox(height: 18),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _guardarComunidad,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.redAccent,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              icon: const Icon(
                                Icons.save,
                                size: 18,
                                color: Colors.white,
                              ),
                              label: const Text(
                                'Guardar',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontFamily: 'Merriweather',
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInput(
    TextEditingController controller,
    String label, {
    bool isNumeric = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextFormField(
        controller: controller,
        style: const TextStyle(fontSize: 14),
        keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
        inputFormatters:
            isNumeric ? [FilteringTextInputFormatter.digitsOnly] : null,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(fontSize: 14),
          floatingLabelStyle: const TextStyle(
            color: Colors.redAccent,
            fontWeight: FontWeight.bold,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 10,
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
        validator:
            (value) =>
                value == null || value.isEmpty ? 'Campo obligatorio' : null,
      ),
    );
  }

  Widget _buildDateField(TextEditingController controller, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextFormField(
        controller: controller,
        style: const TextStyle(fontSize: 14),
        readOnly: true,
        onTap: () => _seleccionarFecha(controller),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(fontSize: 14),
          floatingLabelStyle: const TextStyle(
            color: Colors.redAccent,
            fontWeight: FontWeight.bold,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 10,
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          suffixIcon: const Icon(
            Icons.calendar_today,
            size: 18,
            color: Colors.redAccent,
          ),
        ),
        validator:
            (value) =>
                value == null || value.isEmpty ? 'Campo obligatorio' : null,
      ),
    );
  }

  Widget _buildDropdownTipo() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: DropdownButtonFormField<String>(
        value: _tipoParroquia,
        decoration: InputDecoration(
          labelText: 'Tipo (Parroquia o Capilla)',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
        items: const [
          DropdownMenuItem(value: "Parroquia", child: Text("Parroquia")),
          DropdownMenuItem(value: "Capilla", child: Text("Capilla")),
        ],
        onChanged: (value) {
          setState(() {
            _tipoParroquia = value!;
          });
        },
      ),
    );
  }
}
