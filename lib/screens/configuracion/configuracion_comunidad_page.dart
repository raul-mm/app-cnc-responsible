import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../db/db_helper.dart';
import '../../models/comunidad.dart';

class ConfiguracionComunidadPage extends StatefulWidget {
  const ConfiguracionComunidadPage({super.key});

  @override
  State<ConfiguracionComunidadPage> createState() =>
      _ConfiguracionComunidadPageState();
}

class _ConfiguracionComunidadPageState extends State<ConfiguracionComunidadPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _numeroController = TextEditingController();
  final _fechaController = TextEditingController();
  final _parroquiaController = TextEditingController();
  final _pasoController = TextEditingController();
  final _catequistaController = TextEditingController();
  final _fechaPasoController = TextEditingController();

  String _tipoParroquia = "Parroquia";
  bool _huboRito = false;

  late final AnimationController _controller;
  Comunidad? comunidadActual;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();

    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    final comunidad = await DBHelper.obtenerComunidad();
    if (comunidad != null) {
      comunidadActual = comunidad;
      _numeroController.text = comunidad.numero;
      _fechaController.text = comunidad.fechaNacimiento;
      _parroquiaController.text = comunidad.parroquia;
      _pasoController.text = comunidad.pasoActual;
      _catequistaController.text = comunidad.catequista;
      _fechaPasoController.text = comunidad.fechaPaso;
      _tipoParroquia = comunidad.tipoParroquia;
      _huboRito = comunidad.huboRito == 1;
      setState(() {});
    }
  }

  void _seleccionarFecha(TextEditingController controller) async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse(controller.text) ?? DateTime(2000),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );
    if (fecha != null) {
      controller.text = DateFormat('yyyy-MM-dd').format(fecha);
    }
  }

  void _actualizarComunidad() async {
    if (_formKey.currentState!.validate()) {
      final comunidad = Comunidad(
        id: comunidadActual?.id ?? 1,
        numero: _numeroController.text,
        fechaNacimiento: _fechaController.text,
        parroquia: _parroquiaController.text,
        pasoActual: _pasoController.text,
        catequista: _catequistaController.text,
        tipoParroquia: _tipoParroquia,
        fechaPaso: _fechaPasoController.text,
        huboRito: _huboRito ? 1 : 0,
      );
      await DBHelper.actualizarComunidad(comunidad);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Datos actualizados correctamente')),
        );
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
      appBar: AppBar(
        title: const Text(
          'Configuración',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        backgroundColor: Color(0xFFC62828),
        foregroundColor: Colors.white,
        elevation: 4,
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Color(0xFFFAFAFA)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  _buildInput(_numeroController, 'Número de Comunidad'),
                  const SizedBox(height: 12),
                  _buildDateField(_fechaController, 'Fecha de Nacimiento'),
                  const SizedBox(height: 12),
                  _buildInput(_catequistaController, 'Catequista'),
                  const SizedBox(height: 12),
                  _buildInput(_parroquiaController, 'Parroquia'),
                  const SizedBox(height: 12),
                  _buildInput(_pasoController, 'Último paso'),
                  const SizedBox(height: 12),
                  _buildDateField(_fechaPasoController, 'Fecha del Paso'),
                  const SizedBox(height: 12),

                  // Tipo de parroquia o capilla
                  DropdownButtonFormField<String>(
                    initialValue: _tipoParroquia,
                    decoration: InputDecoration(
                      labelText: 'Tipo de Parroquia o Capilla',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    items: const [
                      DropdownMenuItem(value: "Parroquia", child: Text("Parroquia")),
                      DropdownMenuItem(value: "Capilla", child: Text("Capilla")),
                    ],
                    onChanged: (value) {
                      if (value != null) setState(() => _tipoParroquia = value);
                    },
                  ),
                  const SizedBox(height: 12),

                  // Hubo rito
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("¿Hubo rito?", style: TextStyle(fontSize: 14)),
                      Switch(
                        value: _huboRito,
                        activeThumbColor: Colors.redAccent,
                        onChanged: (value) {
                          setState(() => _huboRito = value);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _actualizarComunidad,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.save, color: Colors.white),
                      label: const Text(
                        'Actualizar',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          fontFamily: 'Merriweather',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInput(TextEditingController controller, String label) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      validator: (value) =>
          value == null || value.isEmpty ? 'Campo obligatorio' : null,
    );
  }

  Widget _buildDateField(TextEditingController controller, String label) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      onTap: () => _seleccionarFecha(controller),
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        suffixIcon: const Icon(Icons.calendar_today, color: Colors.redAccent),
      ),
      validator: (value) =>
          value == null || value.isEmpty ? 'Campo obligatorio' : null,
    );
  }
}
