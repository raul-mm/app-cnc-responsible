import 'package:app_movil_comunidad/db/db_helper.dart';
import 'package:app_movil_comunidad/models/persona.dart';
import 'package:app_movil_comunidad/widgets/ui.dart';
import 'package:flutter/material.dart';

/// Servicio de la comunidad (Salmistas, Didáscalos):
/// un responsable y varias personas.
class ServicioPage extends StatefulWidget {
  final String tipo;

  const ServicioPage({super.key, required this.tipo});

  @override
  State<ServicioPage> createState() => _ServicioPageState();
}

class _ServicioPageState extends State<ServicioPage> {
  List<Persona> personas = [];
  List<Map<String, dynamic>> miembros = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    final p = await DBHelper.getPersonas();
    final m = await DBHelper.getServicio(widget.tipo);
    if (!mounted) return;
    setState(() {
      personas = p;
      miembros = m;
      loading = false;
    });
  }

  bool _esResponsable(Map<String, dynamic> m) => m['es_responsable'] == 1;

  Future<void> _agregar() async {
    final ya = {for (final m in miembros) m['persona_id'] as int: 'Ya está'};
    final sel = await seleccionarPersonas(
      context,
      titulo: 'Agregar a ${widget.tipo}',
      personas: personas,
      bloqueadas: ya,
    );
    if (sel == null || sel.isEmpty) return;
    final sinResponsable = !miembros.any(_esResponsable);
    await DBHelper.agregarAServicio(
      widget.tipo,
      sel.map((p) => p.id!).toList(),
    );
    // El primero que se agrega queda como responsable si no hay ninguno.
    if (sinResponsable && sel.length == 1 && miembros.isEmpty) {
      await DBHelper.setResponsableServicio(widget.tipo, sel.first.id);
    }
    await _cargar();
  }

  Future<void> _opciones(Map<String, dynamic> m) async {
    final esResp = _esResponsable(m);
    final accion = await showAppSheet<String>(
      context,
      titulo: m['nombre_completo'],
      icon: Icons.person_outline,
      builder: (ctx, _) => Column(
        children: [
          ListTile(
            leading: Icon(
              esResp ? Icons.star_border : Icons.star,
              color: kRojo,
            ),
            title: Text(
              esResp ? 'Quitar como responsable' : 'Hacer responsable',
            ),
            onTap: () => Navigator.pop(ctx, 'responsable'),
          ),
          ListTile(
            leading: const Icon(Icons.remove_circle_outline, color: kRojo),
            title: Text('Quitar de ${widget.tipo}'),
            onTap: () => Navigator.pop(ctx, 'quitar'),
          ),
        ],
      ),
    );
    if (accion == 'responsable') {
      await DBHelper.setResponsableServicio(
        widget.tipo,
        esResp ? null : m['persona_id'] as int,
      );
      await _cargar();
    } else if (accion == 'quitar' && mounted) {
      final ok = await confirmar(
        context,
        titulo: 'Quitar de ${widget.tipo}',
        mensaje: '¿Quitar a ${m['nombre_completo']}?',
        accion: 'Quitar',
      );
      if (!ok) return;
      await DBHelper.quitarDeServicio(m['id']);
      await _cargar();
    }
  }

  Widget _tile(Map<String, dynamic> m) => ListTile(
    contentPadding: EdgeInsets.zero,
    leading: Avatar(m['nombre_completo']),
    title: Text(m['nombre_completo']),
    subtitle: m['telefono'] == null ? null : Text(m['telefono']),
    trailing: const Icon(Icons.more_vert),
    onTap: () => _opciones(m),
  );

  @override
  Widget build(BuildContext context) {
    final responsable = miembros.where(_esResponsable).toList();
    final resto = miembros.where((m) => !_esResponsable(m)).toList();

    return AppPage(
      title: widget.tipo,
      fab: AppFab(label: 'Agregar', icon: Icons.group_add, onPressed: _agregar),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : miembros.isEmpty
          ? EmptyState(
              icon: Icons.groups_2_outlined,
              text: 'No hay ${widget.tipo.toLowerCase()}',
              hint: 'Agrega personas registradas y elige a un responsable.',
            )
          : ListView(
              padding: const EdgeInsets.only(top: 10, bottom: 90),
              children: [
                SectionCard(
                  title: 'Responsable',
                  padding: const EdgeInsets.fromLTRB(16, 14, 8, 6),
                  child: responsable.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            'Sin responsable. Toca una persona para asignarlo.',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        )
                      : _tile(responsable.first),
                ),
                if (resto.isNotEmpty)
                  SectionCard(
                    title: 'Personas (${resto.length})',
                    padding: const EdgeInsets.fromLTRB(16, 14, 8, 6),
                    child: Column(children: resto.map(_tile).toList()),
                  ),
              ],
            ),
    );
  }
}
