import 'package:app_movil_comunidad/db/db_helper.dart';
import 'package:app_movil_comunidad/models/persona.dart';
import 'package:app_movil_comunidad/utils/catalogos.dart';
import 'package:app_movil_comunidad/widgets/ui.dart';
import 'package:flutter/material.dart';

/// Equipo de responsables de la comunidad.
class EquipoPage extends StatefulWidget {
  const EquipoPage({super.key});

  @override
  State<EquipoPage> createState() => _EquipoPageState();
}

class _EquipoPageState extends State<EquipoPage> {
  List<Persona> personas = [];
  List<Map<String, dynamic>> equipo = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    final p = await DBHelper.getPersonas();
    final e = await DBHelper.getEquipo();
    if (!mounted) return;
    setState(() {
      personas = p;
      equipo = e;
      loading = false;
    });
  }

  Future<String?> _elegirCargo(String nombre, String actual) {
    return showAppSheet<String>(
      context,
      titulo: 'Cargo de $nombre',
      icon: Icons.workspace_premium_outlined,
      builder: (ctx, _) => Column(
        children: cargosEquipo
            .map(
              (c) => ListTile(
                leading: Icon(
                  c == actual ? Icons.radio_button_checked : Icons.radio_button_off,
                  color: kRojo,
                ),
                title: Text(c),
                onTap: () => Navigator.pop(ctx, c),
              ),
            )
            .toList(),
      ),
    );
  }

  /// Guarda el cargo garantizando un único Responsable.
  Future<void> _guardar({int? id, required int personaId, required String cargo}) async {
    if (cargo == 'Responsable') {
      final actual = equipo.where(
        (m) => m['cargo'] == 'Responsable' && m['persona_id'] != personaId,
      );
      if (actual.isNotEmpty) {
        final otro = actual.first;
        final ok = await confirmar(
          context,
          titulo: 'Cambiar responsable',
          mensaje:
              '${otro['nombre_completo']} es el responsable actual. '
              '¿Pasarlo a Corresponsable?',
          accion: 'Cambiar',
        );
        if (!ok) return;
        await DBHelper.guardarMiembroEquipo(
          id: otro['id'],
          personaId: otro['persona_id'],
          cargo: 'Corresponsable',
        );
      }
    }
    await DBHelper.guardarMiembroEquipo(id: id, personaId: personaId, cargo: cargo);
    await _cargar();
  }

  Future<void> _agregar() async {
    final enEquipo = {for (final m in equipo) m['persona_id'] as int: 'Ya es ${m['cargo']}'};
    final sel = await seleccionarPersonas(
      context,
      titulo: 'Agregar al equipo',
      personas: personas,
      bloqueadas: enEquipo,
      multiple: false,
    );
    if (sel == null || sel.isEmpty || !mounted) return;
    final p = sel.first;
    final yaHayResponsable = equipo.any((m) => m['cargo'] == 'Responsable');
    final cargo = await _elegirCargo(
      p.nombreCompleto,
      yaHayResponsable ? 'Corresponsable' : 'Responsable',
    );
    if (cargo == null) return;
    await _guardar(personaId: p.id!, cargo: cargo);
  }

  Future<void> _editar(Map<String, dynamic> m) async {
    final cargo = await _elegirCargo(m['nombre_completo'], m['cargo']);
    if (cargo == null || cargo == m['cargo']) return;
    await _guardar(id: m['id'], personaId: m['persona_id'], cargo: cargo);
  }

  Future<void> _eliminar(Map<String, dynamic> m) async {
    final ok = await confirmar(
      context,
      titulo: 'Quitar del equipo',
      mensaje: '¿Quitar a ${m['nombre_completo']} del equipo?',
      accion: 'Quitar',
    );
    if (!ok) return;
    await DBHelper.deleteMiembroEquipo(m['id']);
    await _cargar();
  }

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: 'Equipo de responsables',
      fab: AppFab(label: 'Agregar', icon: Icons.group_add, onPressed: _agregar),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : equipo.isEmpty
          ? const EmptyState(
              icon: Icons.groups_2_outlined,
              text: 'El equipo está vacío',
              hint: 'Elige entre las personas registradas al responsable, '
                  'viceresponsable y corresponsables.',
            )
          : ListView(
              padding: const EdgeInsets.only(top: 10, bottom: 90),
              children: [
                for (final cargo in cargosEquipo)
                  if (equipo.any((m) => m['cargo'] == cargo))
                    SectionCard(
                      title: cargo,
                      padding: const EdgeInsets.fromLTRB(16, 14, 8, 6),
                      child: Column(
                        children: equipo
                            .where((m) => m['cargo'] == cargo)
                            .map(
                              (m) => ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: Avatar(m['nombre_completo']),
                                title: Text(m['nombre_completo']),
                                subtitle: m['telefono'] == null
                                    ? null
                                    : Text(m['telefono']),
                                onTap: () => _editar(m),
                                trailing: IconButton(
                                  icon: Icon(
                                    Icons.remove_circle_outline,
                                    color: Colors.grey.shade600,
                                  ),
                                  onPressed: () => _eliminar(m),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Toca una persona para cambiar su cargo.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                ),
              ],
            ),
    );
  }
}
