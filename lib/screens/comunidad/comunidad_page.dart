// comunidad_page.dart
import 'package:flutter/material.dart';
import 'package:app_movil_comunidad/db/db_helper.dart';
import 'package:app_movil_comunidad/models/persona.dart';

class ComunidadPage extends StatefulWidget {
  const ComunidadPage({super.key});

  @override
  State<ComunidadPage> createState() => _ComunidadPageState();
}

class _ComunidadPageState extends State<ComunidadPage> {
  List<Persona> personas = [];

  @override
  void initState() {
    super.initState();
    _loadPersonas();
  }

  Future<void> _loadPersonas() async {
    final data = await DBHelper.getPersonas();
    setState(() => personas = data);
  }

  void _showForm({Persona? persona}) {
    final formKey = GlobalKey<FormState>();
    final nombresController = TextEditingController(text: persona?.nombres);
    final apellidosController = TextEditingController(text: persona?.apellidos);
    final fechaController = TextEditingController(
      text: persona?.fechaNacimiento,
    );
    final docController = TextEditingController(text: persona?.documento);
    final telController = TextEditingController(text: persona?.telefono);
    final direccionController = TextEditingController(text: persona?.direccion);
    final correoController = TextEditingController(text: persona?.correo);
    final aniversarioController = TextEditingController(
      text: persona?.fechaAniversario,
    );

    String estadoCivil = persona?.estadoCivil ?? 'Soltero';
    int? conyugeId = persona?.conyugeId;
    int? numeroHijos = persona?.numeroHijos;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          top: 20,
          left: 16,
          right: 16,
        ),
        child: StatefulBuilder(
          builder: (context, setModalState) {
            return Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 50,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      persona == null ? 'Agregar Persona' : 'Editar Persona',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Merriweather',
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildTextField('Nombres', nombresController),
                    _buildTextField('Apellidos', apellidosController),
                    _buildDatePickerField(context, fechaController),
                    _buildTextField('Nro. Documento', docController),
                    _buildTextField('Nro. Celular', telController),
                    _buildTextField('Dirección', direccionController),
                    _buildTextField('Correo', correoController),
                    const SizedBox(height: 5),
                    DropdownButtonFormField<String>(
                      initialValue: estadoCivil,
                      items: ['Soltero', 'Casado', 'Viudo', 'Divorciado']
                          .map(
                            (e) => DropdownMenuItem(value: e, child: Text(e)),
                          )
                          .toList(),
                      decoration: _inputDecoration('Estado civil'),
                      onChanged: (value) =>
                          setModalState(() => estadoCivil = value!),
                    ),
                    if (estadoCivil == 'Casado') ...[
                      const SizedBox(height: 5),
                      DropdownButtonFormField<int>(
                        initialValue: conyugeId,
                        hint: const Text("Selecciona cónyuge"),
                        decoration: _inputDecoration('Cónyuge'),
                        items: personas
                            .where((p) => persona?.id != p.id)
                            .map(
                              (p) => DropdownMenuItem(
                                value: p.id,
                                child: Text('${p.nombres} ${p.apellidos}'),
                              ),
                            )
                            .toList(),
                        onChanged: (value) =>
                            setModalState(() => conyugeId = value),
                      ),
                      _buildDatePickerField(
                        context,
                        aniversarioController,
                        label: 'Aniversario',
                        required: false,
                      ),
                    ],
                    const SizedBox(height: 5),
                    TextFormField(
                      initialValue: numeroHijos?.toString(),
                      keyboardType: TextInputType.number,
                      decoration: _inputDecoration('Cantidad de hijos'),
                      onChanged: (value) => numeroHijos = int.tryParse(value),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                      icon: const Icon(Icons.save),
                      label: const Text('Guardar'),
                      onPressed: () async {
                        if (!formKey.currentState!.validate()) return;

                        final nuevaPersona = Persona(
                          id: persona?.id,
                          nombres: nombresController.text,
                          apellidos: apellidosController.text,
                          fechaNacimiento: fechaController.text,
                          documento: docController.text,
                          telefono: telController.text,
                          direccion: direccionController.text,
                          correo: correoController.text,
                          estadoCivil: estadoCivil,
                          conyugeId: conyugeId,
                          fechaAniversario: aniversarioController.text,
                          numeroHijos: numeroHijos
                        );

                        if (persona == null) {
                          await DBHelper.insertPersona(nuevaPersona);
                        } else {
                          await DBHelper.updatePersona(nuevaPersona);
                        }

                        if (mounted) Navigator.pop(context);
                        _loadPersonas();
                      },
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) => InputDecoration(
    labelText: label,
    filled: true,
    fillColor: Colors.grey.shade100,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide.none,
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
  );

  Widget _buildTextField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextFormField(
        controller: controller,
        decoration: _inputDecoration(label),
        validator: (value) =>
            value == null || value.isEmpty ? 'Campo requerido' : null,
      ),
    );
  }

  Widget _buildDatePickerField(
    BuildContext context,
    TextEditingController controller, {
    String label = 'Fecha de nacimiento',
    bool required = true,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: GestureDetector(
        onTap: () async {
          FocusScope.of(context).unfocus();
          final picked = await showDatePicker(
            context: context,
            initialDate: DateTime.now(),
            firstDate: DateTime(1900),
            lastDate: DateTime.now(),
          );
          if (picked != null) {
            controller.text =
                '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
          }
        },
        child: AbsorbPointer(
          child: TextFormField(
            controller: controller,
            decoration: _inputDecoration(
              label,
            ).copyWith(suffixIcon: const Icon(Icons.calendar_today, size: 18)),
            validator: required
                ? (value) => value == null || value.isEmpty
                      ? 'Campo obligatorio'
                      : null
                : null,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Mi comunidad',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFFC62828),
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 4,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showForm(),
        backgroundColor: Colors.black,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: personas.isEmpty
          ? const Center(child: Text('No hay personas registradas.'))
          : ListView.separated(
              itemCount: personas.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (_, index) {
                final p = personas[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    title: Text(
                      '${p.nombres} ${p.apellidos}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('DNI: ${p.documento}'),
                        Text('Tel: ${p.telefono}'),
                        Text('Dir: ${p.direccion}'),
                        if (p.estadoCivil != null)
                          Text('Estado civil: ${p.estadoCivil}'),
                        if (p.numeroHijos != null)
                          Text('Nro Hijos: ${p.numeroHijos}'),
                      ],
                    ),
                    trailing: Wrap(
                      spacing: 8,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.orange),
                          onPressed: () => _showForm(persona: p),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () async {
                            await DBHelper.deletePersona(p.id!);
                            _loadPersonas();
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
