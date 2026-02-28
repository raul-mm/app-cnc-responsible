import 'package:flutter/material.dart';
import 'package:app_movil_comunidad/models/persona.dart';

class PersonaForm extends StatefulWidget {
  final Persona? persona;
  final List<Persona> personas;
  final ScrollController scrollController;
  final Function(Persona, bool) onSave;

  const PersonaForm({
    super.key,
    this.persona,
    required this.personas,
    required this.scrollController,
    required this.onSave,
  });

  @override
  State<PersonaForm> createState() => _PersonaFormState();
}

class _PersonaFormState extends State<PersonaForm> {
  final formKey = GlobalKey<FormState>();

  late TextEditingController nombres;
  late TextEditingController apellidos;
  late TextEditingController fecha;
  late TextEditingController documento;
  late TextEditingController telefono;

  String estadoCivil = 'Soltero';
  int? conyugeId;

  @override
  void initState() {
    super.initState();

    nombres = TextEditingController(text: widget.persona?.nombres);
    apellidos = TextEditingController(text: widget.persona?.apellidos);
    fecha = TextEditingController(text: widget.persona?.fechaNacimiento);
    documento = TextEditingController(text: widget.persona?.documento);
    telefono = TextEditingController(text: widget.persona?.telefono);

    estadoCivil = widget.persona?.estadoCivil ?? 'Soltero';
    conyugeId = widget.persona?.conyugeId;
  }

  InputDecoration _dec(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.grey.shade100,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
    );
  }

  Widget _text(String label, TextEditingController c) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextFormField(
        controller: c,
        decoration: _dec(label),
        validator: (v) =>
            v == null || v.isEmpty ? 'Campo obligatorio' : null,
      ),
    );
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: DateTime(1990),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (d != null) {
      fecha.text =
          '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    }
  }

  void _save() {
    if (!formKey.currentState!.validate()) return;

    final persona = Persona(
      id: widget.persona?.id,
      nombres: nombres.text,
      apellidos: apellidos.text,
      fechaNacimiento: fecha.text,
      documento: documento.text,
      telefono: telefono.text,
      estadoCivil: estadoCivil,
      conyugeId: conyugeId,
    );

    widget.onSave(persona, widget.persona != null);
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: ListView(
        controller: widget.scrollController,
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            widget.persona == null ? 'Nueva persona' : 'Editar persona',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _text('Nombres', nombres),
          _text('Apellidos', apellidos),

          GestureDetector(
            onTap: _pickDate,
            child: AbsorbPointer(
              child: _text('Fecha nacimiento', fecha),
            ),
          ),

          _text('Documento', documento),
          _text('Teléfono', telefono),

          const SizedBox(height: 6),

          DropdownButtonFormField<String>(
            value: estadoCivil,
            decoration: _dec('Estado civil'),
            items: ['Soltero', 'Casado', 'Viudo', 'Divorciado']
                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                .toList(),
            onChanged: (v) => setState(() => estadoCivil = v!),
          ),

          if (estadoCivil == 'Casado')
            DropdownButtonFormField<int>(
              value: conyugeId,
              decoration: _dec('Cónyuge'),
              items: widget.personas
                  .where((p) => p.id != widget.persona?.id)
                  .map((p) => DropdownMenuItem(
                        value: p.id,
                        child: Text('${p.nombres} ${p.apellidos}'),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => conyugeId = v),
            ),

          const SizedBox(height: 20),

          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFC62828),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.save),
            label: const Text('Guardar'),
            onPressed: _save,
          ),

          const SizedBox(height: 30),
        ],
      ),
    );
  }
}
