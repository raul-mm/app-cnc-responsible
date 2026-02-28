import 'package:flutter/material.dart';
import 'package:app_movil_comunidad/db/db_helper.dart';
import 'package:app_movil_comunidad/models/persona.dart';

class CarismasPage extends StatefulWidget {
  const CarismasPage({super.key});

  @override
  State<CarismasPage> createState() => _CarismasPageState();
}

class _CarismasPageState extends State<CarismasPage> {
  List<Persona> personas = [];
  final List<Map<String, dynamic>> carismas = [];

  final List<String> tiposCarisma = [
    'Seminarista',
    'Sacerdote',
    'Ostiario',
    'Responsable de Salmos',
    'Familia en misión',
    'Itinerante',
  ];

  @override
  void initState() {
    super.initState();
    _cargarPersonas();
    _cargarCarismas();
  }

  Future<void> _cargarPersonas() async {
    personas = await DBHelper.getPersonas();
    setState(() {});
  }

  Future<void> _cargarCarismas() async {
    final data = await DBHelper.getCarismas();
    setState(() {
      carismas.clear();
      carismas.addAll(data);
    });
  }

  bool _personaTieneCarisma(int personaId, {int? editandoId}) {
    return carismas.any((c) {
      final mismaPersona = c['persona_id'] == personaId;
      final noEsElMismo = editandoId == null ? true : c['id'] != editandoId;
      return mismaPersona && noEsElMismo;
    });
  }

  // =====================
  // MODAL
  // =====================
  void _mostrarModal({Map<String, dynamic>? carisma}) {
    final isEdit = carisma != null;

    Persona? persona = isEdit
        ? personas.firstWhere((p) => p.id == carisma['persona_id'])
        : null;

    String tipo = isEdit ? carisma['tipo'] : tiposCarisma.first;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 20,
                right: 20,
                top: 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: const [
                        Icon(Icons.volunteer_activism,
                            color: Colors.redAccent),
                        SizedBox(width: 8),
                        Text(
                          'Registrar Carisma',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // PERSONA
                    DropdownButtonFormField<Persona>(
                      initialValue: persona,
                      isExpanded: true,
                      decoration: _inputDecoration('Persona'),
                      items: personas.map((p) {
                        final bloqueado = _personaTieneCarisma(
                          p.id!,
                          editandoId: isEdit ? carisma['id'] : null,
                        );

                        return DropdownMenuItem(
                          value: bloqueado ? null : p,
                          enabled: !bloqueado,
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '${p.nombres} ${p.apellidos}',
                                  style: TextStyle(
                                    color: bloqueado
                                        ? Colors.grey
                                        : Colors.black,
                                  ),
                                ),
                              ),
                              if (bloqueado)
                                const Icon(Icons.lock,
                                    size: 16, color: Colors.grey),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (value) =>
                          setModalState(() => persona = value),
                    ),

                    const SizedBox(height: 16),

                    // TIPO
                    DropdownButtonFormField<String>(
                      initialValue: tipo,
                      decoration: _inputDecoration('Tipo de carisma'),
                      items: tiposCarisma
                          .map((t) =>
                              DropdownMenuItem(value: t, child: Text(t)))
                          .toList(),
                      onChanged: (value) =>
                          setModalState(() => tipo = value!),
                    ),

                    const SizedBox(height: 24),

                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () async {
                        if (persona == null) return;

                        await DBHelper.insertOrUpdateCarisma({
                          'id': isEdit ? carisma['id'] : null,
                          'persona_id': persona!.id,
                          'tipo': tipo,
                        });

                        await _cargarCarismas();
                        Navigator.pop(context);
                      },
                      child: Text(isEdit ? 'Actualizar' : 'Guardar'),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // =====================
  // UI
  // =====================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Carismas',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        backgroundColor: const Color(0xFFC62828),
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: carismas.isEmpty
            ? const Center(child: Text('No hay carismas registrados'))
            : ListView.builder(
                itemCount: carismas.length,
                itemBuilder: (_, i) {
                  final c = carismas[i];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: ListTile(
                      leading: const Icon(Icons.person),
                      title: Text(c['nombre_completo']),
                      subtitle: Text(c['tipo']),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit,
                                color: Colors.orange),
                            onPressed: () => _mostrarModal(carisma: c),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete,
                                color: Colors.red),
                            onPressed: () async {
                              await DBHelper.deleteCarisma(c['id']);
                              _cargarCarismas();
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.black,
        child: const Icon(Icons.add),
        onPressed: () => _mostrarModal(),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.grey.shade100,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}
