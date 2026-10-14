import 'package:app_movil_comunidad/db/db_helper.dart';
import 'package:app_movil_comunidad/models/comunidad.dart';
import 'package:app_movil_comunidad/models/persona.dart';
import 'package:app_movil_comunidad/widgets/ui.dart';
import 'package:flutter/material.dart';

class EquiposCatequistasPage extends StatefulWidget {
  const EquiposCatequistasPage({super.key});

  @override
  State<EquiposCatequistasPage> createState() => _EquiposCatequistasPageState();
}

class _EquiposCatequistasPageState extends State<EquiposCatequistasPage> {
  List<Map<String, dynamic>> equipos = [];
  Map<int, List<Map<String, dynamic>>> miembros = {};
  List<Persona> personas = [];
  int? equipoComunidadId;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    final e = await DBHelper.getEquiposCatequistas();
    final p = await DBHelper.getPersonas();
    final c = await DBHelper.obtenerComunidad();
    final m = <int, List<Map<String, dynamic>>>{};
    for (final eq in e) {
      m[eq['id'] as int] = await DBHelper.getMiembrosEquipoCatequista(eq['id']);
    }
    if (!mounted) return;
    setState(() {
      equipos = e;
      personas = p;
      miembros = m;
      equipoComunidadId = c?.equipoCatequistaId;
      loading = false;
    });
  }

  Future<void> _crearEquipo() async {
    final nombre = await pedirTexto(
      context,
      titulo: 'Nuevo equipo de catequistas',
      label: 'Nombre del equipo',
      inicial: 'Equipo ${equipos.length + 1}',
    );
    if (nombre == null || nombre.isEmpty) return;
    final id = await DBHelper.insertEquipoCatequista(nombre);
    await _cargar();
    if (!mounted) return;
    toast(context, 'Equipo creado. Ahora agrega a sus miembros.');
    await _agregarMiembros(id);
  }

  Future<void> _renombrar(Map<String, dynamic> eq) async {
    final nombre = await pedirTexto(
      context,
      titulo: 'Renombrar equipo',
      label: 'Nombre',
      inicial: eq['nombre'],
    );
    if (nombre == null || nombre.isEmpty) return;
    await DBHelper.renombrarEquipoCatequista(eq['id'], nombre);
    await _cargar();
  }

  Future<void> _eliminarEquipo(Map<String, dynamic> eq) async {
    final ok = await confirmar(
      context,
      titulo: 'Eliminar equipo',
      mensaje: '¿Eliminar "${eq['nombre']}" y sus ${eq['total']} miembros?',
    );
    if (!ok) return;
    await DBHelper.deleteEquipoCatequista(eq['id']);
    await _cargar();
  }

  Future<void> _asignarAComunidad(Map<String, dynamic> eq) async {
    final c = await DBHelper.obtenerComunidad();
    if (c == null) return;
    await DBHelper.actualizarComunidad(
      Comunidad.fromMap({...c.toMap(), 'equipo_catequista_id': eq['id']}),
    );
    await _cargar();
    if (mounted) toast(context, '"${eq['nombre']}" asignado a la comunidad');
  }

  Future<void> _agregarMiembros(int equipoId) async {
    final actuales = {
      for (final m in miembros[equipoId] ?? const []) m['persona_id'] as int,
    };
    final sel = await seleccionarPersonas(
      context,
      titulo: 'Miembros del equipo',
      personas: personas,
      seleccionadas: actuales,
    );
    if (sel == null) return;
    final nuevos = sel.map((p) => p.id!).toSet();
    for (final id in actuales.difference(nuevos)) {
      await DBHelper.deleteMiembroEquipoCatequista(id, equipoId);
    }
    final hayResponsable = (miembros[equipoId] ?? const []).any(
      (m) => m['rol'] == 'Responsable' && nuevos.contains(m['persona_id']),
    );
    var primero = !hayResponsable;
    for (final id in nuevos.difference(actuales)) {
      await DBHelper.insertMiembroEquipoCatequista(
        equipoId: equipoId,
        personaId: id,
        rol: primero ? 'Responsable' : 'Catequista',
      );
      primero = false;
    }
    await _cargar();
  }

  Future<void> _opcionesMiembro(int equipoId, Map<String, dynamic> m) async {
    final accion = await showAppSheet<String>(
      context,
      titulo: m['nombre_completo'],
      icon: Icons.person_outline,
      builder: (ctx, _) => Column(
        children: [
          ListTile(
            leading: const Icon(Icons.star_outline, color: kRojo),
            title: Text(
              m['rol'] == 'Responsable'
                  ? 'Cambiar a Catequista'
                  : 'Hacer Responsable del equipo',
            ),
            onTap: () => Navigator.pop(ctx, 'rol'),
          ),
          ListTile(
            leading: const Icon(Icons.remove_circle_outline, color: kRojo),
            title: const Text('Quitar del equipo'),
            onTap: () => Navigator.pop(ctx, 'quitar'),
          ),
        ],
      ),
    );
    if (accion == 'rol') {
      await DBHelper.insertMiembroEquipoCatequista(
        equipoId: equipoId,
        personaId: m['persona_id'],
        rol: m['rol'] == 'Responsable' ? 'Catequista' : 'Responsable',
      );
    } else if (accion == 'quitar') {
      await DBHelper.deleteMiembroEquipoCatequista(m['persona_id'], equipoId);
    } else {
      return;
    }
    await _cargar();
  }

  Widget _equipoCard(Map<String, dynamic> eq) {
    final id = eq['id'] as int;
    final lista = miembros[id] ?? const [];
    final esDeComunidad = id == equipoComunidadId;

    return SectionCard(
      title: eq['nombre'],
      actions: [
        if (esDeComunidad)
          const Chip(
            label: Text('Comunidad', style: TextStyle(fontSize: 11)),
            visualDensity: VisualDensity.compact,
            backgroundColor: Color(0xFFFFEBEE),
            side: BorderSide.none,
          ),
        PopupMenuButton<String>(
          onSelected: (v) {
            switch (v) {
              case 'miembros':
                _agregarMiembros(id);
              case 'comunidad':
                _asignarAComunidad(eq);
              case 'renombrar':
                _renombrar(eq);
              case 'eliminar':
                _eliminarEquipo(eq);
            }
          },
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'miembros', child: Text('Editar miembros')),
            if (!esDeComunidad)
              const PopupMenuItem(
                value: 'comunidad',
                child: Text('Asignar a la comunidad'),
              ),
            const PopupMenuItem(value: 'renombrar', child: Text('Renombrar')),
            const PopupMenuItem(value: 'eliminar', child: Text('Eliminar')),
          ],
        ),
      ],
      child: lista.isEmpty
          ? TextButton.icon(
              onPressed: () => _agregarMiembros(id),
              icon: const Icon(Icons.person_add_alt, color: kRojo),
              label: const Text('Agregar miembros', style: TextStyle(color: kRojo)),
            )
          : Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final m in lista)
                  PersonaChip(
                    nombre: m['nombre_completo'],
                    etiqueta: m['rol'] == 'Responsable' ? '★ Resp.' : null,
                    onTap: () => _opcionesMiembro(id, m),
                  ),
                ActionChip(
                  avatar: const Icon(Icons.add, size: 18, color: kRojo),
                  label: const Text('Agregar'),
                  side: const BorderSide(color: kRojo),
                  backgroundColor: Colors.white,
                  onPressed: () => _agregarMiembros(id),
                ),
              ],
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: 'Equipos de catequistas',
      fab: AppFab(label: 'Equipo', icon: Icons.add, onPressed: _crearEquipo),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : equipos.isEmpty
          ? const EmptyState(
              icon: Icons.school_outlined,
              text: 'No hay equipos de catequistas',
              hint: 'Crea un equipo y elige a sus miembros entre las personas.',
            )
          : ListView(
              padding: const EdgeInsets.only(top: 10, bottom: 90),
              children: equipos.map(_equipoCard).toList(),
            ),
    );
  }
}
