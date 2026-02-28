import 'package:app_movil_comunidad/db/db_helper.dart';
import 'package:app_movil_comunidad/models/persona.dart';
import 'package:flutter/material.dart';

class EquipoPage extends StatefulWidget {
  const EquipoPage({super.key});

  @override
  State<EquipoPage> createState() => _EquipoPageState();
}

class _EquipoPageState extends State<EquipoPage> {
  List<Persona> personas = [];
  final List<Map<String, dynamic>> equipo = [];

  @override
  void initState() {
    super.initState();
    _cargarPersonas();
    _cargarEquipo();
  }

  Future<void> _cargarPersonas() async {
    final data = await DBHelper.getPersonas();
    setState(() {
      personas = data;
    });
  }

  Future<void> _cargarEquipo() async {
    final data = await DBHelper.getEquipo();
    setState(() {
      equipo.clear();
      equipo.addAll(data);
    });
  }

  Future<void> _eliminarMiembro(int miembroId) async {
    await DBHelper.deleteMiembroEquipo(miembroId);
    await _cargarEquipo();
  }

  void _mostrarFormularioModal({Map<String, dynamic>? miembro}) {
    final isEditando = miembro != null;
    Persona? persona = isEditando
        ? personas.firstWhere((p) => p.id == miembro['persona_id'])
        : null;
    String cargo = isEditando ? miembro['cargo'] : 'Responsable';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (_) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 24,
          ),
          child: StatefulBuilder(
            builder: (context, setModalState) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 50,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: const [
                        Icon(Icons.group_add_rounded, color: Colors.redAccent),
                        SizedBox(width: 8),
                        Text(
                          'Registrar Miembro',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    DropdownButtonFormField<Persona>(
                      initialValue: persona,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: 'Seleccionar Persona',
                        prefixIcon: const Icon(Icons.person_outline),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: personas.map((p) {
                        final deshabilitado = _personaEnEquipo(
                          p.id!,
                          miembroEditandoId: isEditando ? miembro['id'] : null,
                        );
                        return DropdownMenuItem<Persona>(
                          value: deshabilitado ? null : p,
                          enabled: !deshabilitado,
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '${p.nombres} ${p.apellidos}',
                                  style: TextStyle(
                                    color: deshabilitado
                                        ? Colors.grey
                                        : Colors.black,
                                    fontStyle: deshabilitado
                                        ? FontStyle.italic
                                        : FontStyle.normal,
                                  ),
                                ),
                              ),
                              if (deshabilitado)
                                const Icon(
                                  Icons.lock_outline,
                                  size: 16,
                                  color: Colors.grey,
                                ),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setModalState(() => persona = value);
                      },
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Seleccionar Cargo',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          ...[
                            'Responsable',
                            'Viceresponsable',
                            'Corresponsable',
                          ].map(
                            (cargoTexto) => RadioListTile<String>(
                              title: Text(cargoTexto),
                              value: cargoTexto,
                              groupValue: cargo,
                              activeColor: Colors.redAccent,
                              onChanged: (value) =>
                                  setModalState(() => cargo = value!),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      icon: Icon(isEditando ? Icons.edit : Icons.save),
                      label: Text(
                        isEditando ? 'Actualizar' : 'Guardar Miembro',
                      ),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () async {
                        if (persona == null) return;
                        final nuevoMiembro = {
                          'persona_id': persona!.id,
                          'cargo': cargo,
                        };
                        await DBHelper.insertOrUpdateEquipo(nuevoMiembro);
                        await _cargarEquipo();
                        Navigator.pop(context);
                      },
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  bool _personaEnEquipo(int personaId, {int? miembroEditandoId}) {
    return equipo.any((m) {
      final mismaPersona = m['persona_id'] == personaId;
      final noEsElMismoRegistro = miembroEditandoId == null
          ? true
          : m['id'] != miembroEditandoId;

      return mismaPersona && noEsElMismoRegistro;
    });
  }

  void _confirmarEliminar(BuildContext context, Map<String, dynamic> miembro) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar miembro'),
        content: Text(
          '¿Deseas quitar a ${miembro['nombre_completo']} del equipo?',
        ),
        actions: [
          TextButton(
            child: const Text('Cancelar'),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
            onPressed: () {
              Navigator.pop(context);
              _eliminarMiembro(int.parse(miembro['id'].toString()));
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Equipo de corresponsables',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        backgroundColor: Color(0xFFC62828),
        foregroundColor: Colors.white,
        elevation: 4,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: equipo.isEmpty
                  ? const Center(child: Text('No hay miembros registrados.'))
                  : ListView.builder(
                      itemCount: equipo.length,
                      itemBuilder: (context, index) {
                        final miembro = equipo[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          child: ListTile(
                            leading: const Icon(Icons.person),
                            title: Text(miembro['nombre_completo']),
                            subtitle: Text(miembro['cargo']),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.edit,
                                    color: Colors.orange,
                                  ),
                                  onPressed: () =>
                                      _mostrarFormularioModal(miembro: miembro),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
                                  onPressed: () =>
                                      _confirmarEliminar(context, miembro),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _mostrarFormularioModal(),
        backgroundColor: Colors.black,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
