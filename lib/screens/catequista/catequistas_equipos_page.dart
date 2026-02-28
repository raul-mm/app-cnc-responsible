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

  bool loading = true;

  @override
  void initState() {
    super.initState();
    _refreshAll();
  }

  // ======================
  // REUTILIZABLES
  // ======================

  Future<void> _refreshAll() async {
    loading = true;
    setState(() {});

    equipos = await DBHelper.getEquiposCatequistas();
    personas = await DBHelper.getPersonas();

    if (selectedEquipoId != null) {
      await _refreshMiembros();
    }

    loading = false;
    setState(() {});
  }

  Future<void> _refreshMiembros() async {
    if (selectedEquipoId == null) {
      miembros = [];
    } else {
      miembros = await DBHelper.getMiembrosEquipoCatequista(selectedEquipoId!);
    }
    setState(() {});
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text), behavior: SnackBarBehavior.floating),
    );
  }

  Future<bool> _confirmAction(String title, String message) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            child: const Text('Cancelar'),
            onPressed: () => Navigator.pop(context, false),
          ),
          ElevatedButton(
            child: const Text('Aceptar'),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  void _showBottomSheet(Widget child) {
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
        ),
        child: child,
      ),
    );
  }

  List<Persona> _getPersonasDisponibles() {
    final ids = miembros.map((e) => e['persona_id']).toSet();
    return personas.where((p) => !ids.contains(p.id)).toList();
  }

  // ======================
  // CREAR EQUIPO
  // ======================

  void _crearEquipo() {
    final controller = TextEditingController();
    String? error;

    _showBottomSheet(
      StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _sheetHandle(),
                const SizedBox(height: 10),
                const Text(
                  'Nuevo equipo',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    labelText: 'Nombre del equipo',
                    errorText: error,
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () async {
                    final nombre = controller.text.trim();
                    if (nombre.isEmpty) {
                      setModalState(() => error = 'Ingrese un nombre');
                      return;
                    }

                    final id = await DBHelper.insertEquipoCatequista(nombre);

                    selectedEquipoId = id;
                    await _refreshAll();

                    if (mounted) Navigator.pop(context);
                    _showMessage('Equipo creado');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFC62828),
                    minimumSize: const Size.fromHeight(45),
                  ),
                  child: const Text('Guardar'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ======================
  // AGREGAR PERSONA
  // ======================

  void _mostrarDisponibles() {
    final disponibles = _getPersonasDisponibles();

    _showBottomSheet(
      disponibles.isEmpty
          ? _emptyState('No hay personas disponibles')
          : ListView(
              shrinkWrap: true,
              children: disponibles.map((p) {
                return ListTile(
                  leading: const Icon(Icons.person_outline),
                  title: Text('${p.nombres} ${p.apellidos}'),
                  onTap: () => _seleccionarRol(p),
                );
              }).toList(),
            ),
    );
  }

  void _seleccionarRol(Persona p) {
    _showBottomSheet(
      Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _sheetHandle(),
          ListTile(
            leading: const Icon(Icons.group),
            title: const Text('Catequista'),
            onTap: () => _asignarRol(p, 'Catequista'),
          ),
          ListTile(
            leading: const Icon(Icons.star, color: Colors.deepOrange),
            title: const Text('Responsable'),
            onTap: () => _asignarRol(p, 'Responsable'),
          ),
        ],
      ),
    );
  }

  Future<void> _asignarRol(Persona p, String rol) async {
    await DBHelper.insertMiembroEquipoCatequista({
      'equipo_id': selectedEquipoId,
      'persona_id': p.id,
      'rol': rol,
    });

    await _refreshMiembros();

    if (mounted) {
      Navigator.pop(context);
      Navigator.pop(context);
      _showMessage('Persona agregada');
    }
  }

  Future<void> _eliminarMiembro(int personaId) async {
    final ok = await _confirmAction(
      'Eliminar',
      '¿Desea quitar esta persona del equipo?',
    );

    if (!ok) return;

    await DBHelper.deleteMiembroEquipoCatequista(personaId, selectedEquipoId!);

    await _refreshMiembros();
    _showMessage('Miembro eliminado');
  }

  // ======================
  // WIDGETS REUTILIZABLES
  // ======================

  Widget _sheetHandle() => Container(
    width: 40,
    height: 4,
    margin: const EdgeInsets.only(bottom: 10),
    decoration: BoxDecoration(
      color: Colors.grey.shade300,
      borderRadius: BorderRadius.circular(10),
    ),
  );

  Widget _emptyState(String text) {
    return Padding(
      padding: const EdgeInsets.all(30),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.group_off, size: 60, color: Colors.grey),
          const SizedBox(height: 10),
          Text(text, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _equipoDropdown() {
    return DropdownButtonFormField<int>(
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
      items: equipos
          .map(
            (e) =>
                DropdownMenuItem<int>(value: e['id'], child: Text(e['nombre'])),
          )
          .toList(),
      onChanged: (value) async {
        selectedEquipoId = value;
        await _refreshMiembros();
      },
    );
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
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                const SizedBox(height: 12),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: _ActionCard(
                          icon: Icons.group_add,
                          title: 'Crear equipo',
                          subtitle: 'Nuevo',
                          color: Colors.brown,
                          onTap: _crearEquipo,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _ActionCard(
                          icon: Icons.person_add,
                          title: 'Agregar',
                          subtitle: 'Personas',
                          color: selectedEquipoId == null
                              ? Colors.grey
                              : Colors.deepOrange,
                          enabled: selectedEquipoId != null,
                          onTap: _mostrarDisponibles,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _equipoDropdown(),
                ),
                const SizedBox(height: 10),

                Expanded(
                  child: selectedEquipoId == null
                      ? _emptyState('Selecciona un equipo')
                      : miembros.isEmpty
                      ? _emptyState('Este equipo no tiene miembros')
                      : ListView.builder(
                          itemCount: miembros.length,
                          itemBuilder: (_, i) {
                            final m = miembros[i];
                            return Card(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 6,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: ListTile(
                                title: Text(
                                  '${m['nombres']} ${m['apellidos']}',
                                ),
                                subtitle: Text(m['rol']),
                                trailing: IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
                                  onPressed: () =>
                                      _eliminarMiembro(m['persona_id']),
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
