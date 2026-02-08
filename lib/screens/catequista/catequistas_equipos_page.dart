import 'package:flutter/material.dart';
import 'package:app_movil_comunidad/db/db_helper.dart';
import 'package:app_movil_comunidad/models/persona.dart';

class EquiposCatequistasPage extends StatefulWidget {
  const EquiposCatequistasPage({super.key});

  @override
  State<EquiposCatequistasPage> createState() => _EquiposCatequistasPageState();
}

class _EquiposCatequistasPageState extends State<EquiposCatequistasPage> {
  int? selectedEquipoId;

  List<Map<String, dynamic>> equipos = [];
  List<Persona> personas = [];
  List<Map<String, dynamic>> miembros = [];

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    await _loadEquipos();
    await _loadPersonas();
  }

  // ======================
  // DATA
  // ======================
  Future<void> _loadEquipos() async {
    equipos = await DBHelper.getEquiposCatequistas();
    setState(() {});
  }

  Future<void> _loadPersonas() async {
    personas = await DBHelper.getPersonas();
    setState(() {});
  }

  Future<void> _loadMiembros() async {
    if (selectedEquipoId == null) {
      miembros = [];
    } else {
      miembros = await DBHelper.getMiembrosEquipoCatequista(selectedEquipoId!);
    }
    setState(() {});
  }

  // ======================
  // CREAR EQUIPO
  // ======================
  Future<void> _agregarEquipo() async {
    final controller = TextEditingController();
    String? errorText;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Indicador superior
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Icono + título
                  Row(
                    children: const [
                      CircleAvatar(
                        backgroundColor: Color(0xFFFFEBEE),
                        child: Icon(
                          Icons.group_add_rounded,
                          color: Color(0xFFC62828),
                        ),
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Crear equipo de catequistas',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Campo
                  TextField(
                    controller: controller,
                    autofocus: true,
                    decoration: InputDecoration(
                      labelText: 'Nombre del equipo',
                      hintText: 'Ej: Equipo San Pablo',
                      errorText: errorText,
                      prefixIcon: const Icon(Icons.group),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Botones
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(45),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Cancelar'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            final nombre = controller.text.trim();

                            if (nombre.isEmpty) {
                              setModalState(() {
                                errorText = 'Ingrese el nombre del equipo';
                              });
                              return;
                            }

                            final id = await DBHelper.insertEquipoCatequista(
                              nombre,
                            );

                            selectedEquipoId = id;
                            await _loadEquipos();
                            await _loadMiembros();

                            if (mounted) Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFC62828),
                            foregroundColor: Colors.white,
                            minimumSize: const Size.fromHeight(45),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Guardar'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ======================
  // PERSONAS DISPONIBLES
  // ======================
  void _mostrarPersonasDisponibles() {
    if (selectedEquipoId == null) return;

    final miembrosIds = miembros.map((e) => e['persona_id'] as int).toSet();

    final disponibles = personas
        .where((p) => !miembrosIds.contains(p.id))
        .toList();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        if (disponibles.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: Text('No hay personas disponibles')),
          );
        }

        return ListView(
          children: disponibles.map((p) {
            return ListTile(
              leading: const Icon(Icons.person_outline),
              title: Text('${p.nombres} ${p.apellidos}'),
              onTap: () => _asignarPersona(p),
            );
          }).toList(),
        );
      },
    );
  }

  // ======================
  // ASIGNAR PERSONA
  // ======================
  void _asignarPersona(Persona persona) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.person_add_alt_1, size: 36, color: Colors.brown),
              const SizedBox(height: 10),
              Text(
                '${persona.nombres} ${persona.apellidos}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.group, color: Colors.brown),
                title: const Text('Catequista'),
                onTap: () => _asignarRol(persona, 'Catequista'),
              ),
              ListTile(
                leading: const Icon(Icons.star, color: Colors.deepOrange),
                title: const Text('Responsable'),
                onTap: () => _asignarRol(persona, 'Responsable'),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _asignarRol(Persona persona, String rol) async {
    if (selectedEquipoId == null) return;

    try {
      await DBHelper.insertMiembroEquipoCatequista({
        'equipo_id': selectedEquipoId,
        'persona_id': persona.id,
        'rol': rol,
      });

      await _loadMiembros();

      if (mounted) {
        Navigator.pop(context);
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('Error: $e');
    }
  }

  Future<void> _eliminarMiembro(int personaId) async {
    if (selectedEquipoId == null) return;

    await DBHelper.deleteMiembroEquipoCatequista(personaId, selectedEquipoId!);

    await _loadMiembros();
  }

  // ======================
  // UI
  // ======================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Equipos de catequistas'),
        backgroundColor: const Color(0xFFC62828),
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Column(
        children: [
          const SizedBox(height: 12),

          // ======================
          // CARDS SUPERIORES
          // ======================
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: _ActionCard(
                    icon: Icons.group_add,
                    title: 'Crear equipo',
                    subtitle: 'Nuevo grupo',
                    color: Colors.brown,
                    onTap: _agregarEquipo,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ActionCard(
                    icon: Icons.person_add_alt_1,
                    title: 'Agregar',
                    subtitle: 'Asignar personas',
                    color: selectedEquipoId == null
                        ? Colors.grey
                        : Colors.deepOrange,
                    enabled: selectedEquipoId != null,
                    onTap: _mostrarPersonasDisponibles,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ======================
          // DROPDOWN
          // ======================
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: DropdownButtonFormField<int>(
              value: selectedEquipoId,
              hint: const Text('Selecciona un equipo'),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              items: equipos.map((e) {
                return DropdownMenuItem<int>(
                  value: e['id'],
                  child: Text(e['nombre'] ?? ''),
                );
              }).toList(),
              onChanged: (value) async {
                setState(() => selectedEquipoId = value);
                await _loadMiembros();
              },
            ),
          ),

          const SizedBox(height: 10),

          // ======================
          // LISTA
          // ======================
          Expanded(
            child: selectedEquipoId == null
                ? const Center(
                    child: Text(
                      'Selecciona un equipo',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    itemCount: miembros.length,
                    itemBuilder: (_, index) {
                      final m = miembros[index];

                      final nombre = m['nombres'] ?? '';
                      final apellidos = m['apellidos'] ?? '';
                      final rol = m['rol'] ?? '';
                      final inicial = nombre.isNotEmpty ? nombre[0] : '?';

                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: const Color(0xFFD7CCC8),
                            child: Text(inicial),
                          ),
                          title: Text(
                            '$nombre $apellidos',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            rol,
                            style: TextStyle(
                              fontSize: 12,
                              color: rol == 'Responsable'
                                  ? Colors.deepOrange
                                  : Colors.brown,
                            ),
                          ),
                          trailing: IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.red,
                            ),
                            onPressed: () => _eliminarMiembro(m['persona_id']),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ======================
// ACTION CARD
// ======================
class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  final bool enabled;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Opacity(
        opacity: enabled ? 1 : 0.4,
        child: Card(
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: color.withOpacity(0.15),
                  child: Icon(icon, color: color),
                ),
                const SizedBox(height: 10),
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
