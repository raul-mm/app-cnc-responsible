import 'dart:math';

import 'package:app_movil_comunidad/db/db_helper.dart';
import 'package:app_movil_comunidad/models/persona.dart';
import 'package:app_movil_comunidad/utils/catalogos.dart';
import 'package:app_movil_comunidad/widgets/ui.dart';
import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

/// Grupos de Palabra, Eucaristía, Artículo y Domésticas.
class GruposPage extends StatelessWidget {
  const GruposPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: tiposGrupo.length,
      child: AppPage(
        title: 'Grupos',
        bottom: TabBar(
          isScrollable: true,
          tabAlignment: TabAlignment.center,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: [for (final t in tiposGrupo) Tab(text: t)],
        ),
        body: TabBarView(
          children: [for (final t in tiposGrupo) _GruposTipoView(tipo: t)],
        ),
      ),
    );
  }
}

class _GruposTipoView extends StatefulWidget {
  final String tipo;
  const _GruposTipoView({required this.tipo});

  @override
  State<_GruposTipoView> createState() => _GruposTipoViewState();
}

class _GruposTipoViewState extends State<_GruposTipoView>
    with AutomaticKeepAliveClientMixin {
  List<Map<String, dynamic>> grupos = [];
  List<Persona> personas = [];

  /// persona_id -> grupo_id
  Map<int, int> asignacion = {};
  bool loading = true;

  String get tipo => widget.tipo;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    final g = await DBHelper.getGrupos(tipo);
    final p = await DBHelper.getPersonas();
    final m = await DBHelper.getMiembrosGrupos(tipo);
    if (!mounted) return;
    setState(() {
      grupos = g;
      personas = p;
      asignacion = {
        for (final r in m) r['persona_id'] as int: r['grupo_id'] as int,
      };
      loading = false;
    });
  }

  List<Persona> _miembros(int grupoId) =>
      personas.where((p) => asignacion[p.id] == grupoId).toList();

  List<Persona> get _sinGrupo =>
      personas.where((p) => !asignacion.containsKey(p.id)).toList();

  String _nombreGrupo(int id) => grupos.firstWhere(
    (g) => g['id'] == id,
    orElse: () => {'nombre': '?'},
  )['nombre'];

  // ---------------------------------------------------------------
  // Acciones
  // ---------------------------------------------------------------

  Future<void> _crearGrupos() async {
    final txt = await pedirTexto(
      context,
      titulo: 'Crear grupos de $tipo',
      label: '¿Cuántos grupos?',
      inicial: grupos.isEmpty ? '4' : '1',
      teclado: TextInputType.number,
    );
    final n = int.tryParse(txt ?? '');
    if (n == null || n <= 0) return;
    await DBHelper.crearGrupos(tipo, n);
    await _cargar();
  }

  /// Reparto equilibrado: los matrimonios van juntos y se reparte primero
  /// lo más grande en el grupo con menos personas.
  Future<void> _repartir() async {
    if (grupos.isEmpty) {
      toast(context, 'Primero crea los grupos');
      return;
    }
    if (personas.isEmpty) {
      toast(context, 'No hay personas registradas');
      return;
    }
    if (asignacion.isNotEmpty) {
      final ok = await confirmar(
        context,
        titulo: 'Repartir de nuevo',
        mensaje: 'Se reemplazará la distribución actual de $tipo. ¿Continuar?',
        accion: 'Repartir',
      );
      if (!ok) return;
    }

    final ids = personas.map((p) => p.id!).toSet();
    final vistos = <int>{};
    final unidades = <List<int>>[];
    for (final p in personas) {
      if (vistos.contains(p.id)) continue;
      final unidad = [p.id!];
      vistos.add(p.id!);
      if (p.conyugeId != null &&
          ids.contains(p.conyugeId) &&
          !vistos.contains(p.conyugeId)) {
        unidad.add(p.conyugeId!);
        vistos.add(p.conyugeId!);
      }
      unidades.add(unidad);
    }
    unidades.shuffle(Random());
    unidades.sort((a, b) => b.length.compareTo(a.length));

    final dist = {for (final g in grupos) g['id'] as int: <int>[]};
    for (final u in unidades) {
      final destino = dist.entries.reduce(
        (a, b) => a.value.length <= b.value.length ? a : b,
      );
      destino.value.addAll(u);
    }

    await DBHelper.guardarDistribucion(tipo, dist);
    await _cargar();
    if (mounted)
      toast(context, 'Personas repartidas en ${grupos.length} grupos');
  }

  Future<void> _editarMiembros(Map<String, dynamic> g) async {
    final id = g['id'] as int;
    final actuales = _miembros(id).map((p) => p.id!).toSet();
    final bloqueadas = {
      for (final e in asignacion.entries)
        if (e.value != id) e.key: 'En ${_nombreGrupo(e.value)}',
    };
    final sel = await seleccionarPersonas(
      context,
      titulo: '${g['nombre']} · $tipo',
      personas: personas,
      seleccionadas: actuales,
      bloqueadas: bloqueadas,
    );
    if (sel == null) return;
    final nuevos = sel.map((p) => p.id!).toSet();
    for (final pid in actuales.difference(nuevos)) {
      await DBHelper.quitarDeGrupo(tipo, pid);
    }
    await DBHelper.asignarAGrupo(
      id,
      tipo,
      nuevos.difference(actuales).toList(),
    );
    await _cargar();
  }

  Future<void> _opcionesPersona(Persona p) async {
    final actual = asignacion[p.id];
    final destino = await showAppSheet<int>(
      context,
      titulo: p.nombreCompleto,
      icon: Icons.swap_horiz,
      builder: (ctx, _) => Column(
        children: [
          for (final g in grupos)
            ListTile(
              enabled: g['id'] != actual,
              leading: Icon(
                g['id'] == actual ? Icons.check_circle : Icons.arrow_forward,
                color: kRojo,
              ),
              title: Text(
                g['id'] == actual
                    ? '${g['nombre']} (actual)'
                    : 'Mover a ${g['nombre']}',
              ),
              onTap: () => Navigator.pop(ctx, g['id'] as int),
            ),
          if (actual != null)
            ListTile(
              leading: const Icon(Icons.remove_circle_outline, color: kRojo),
              title: const Text('Quitar del grupo'),
              onTap: () => Navigator.pop(ctx, -1),
            ),
        ],
      ),
    );
    if (destino == null) return;
    if (destino == -1) {
      await DBHelper.quitarDeGrupo(tipo, p.id!);
    } else {
      await DBHelper.asignarAGrupo(destino, tipo, [p.id!]);
    }
    await _cargar();
  }

  Future<void> _menuGrupo(String accion, Map<String, dynamic> g) async {
    switch (accion) {
      case 'miembros':
        await _editarMiembros(g);
      case 'renombrar':
        final nombre = await pedirTexto(
          context,
          titulo: 'Renombrar grupo',
          label: 'Nombre',
          inicial: g['nombre'],
        );
        if (nombre == null || nombre.isEmpty) return;
        await DBHelper.renombrarGrupo(g['id'], nombre);
        await _cargar();
      case 'eliminar':
        final ok = await confirmar(
          context,
          titulo: 'Eliminar grupo',
          mensaje: '¿Eliminar ${g['nombre']}? Sus miembros quedarán sin grupo.',
        );
        if (!ok) return;
        await DBHelper.eliminarGrupo(g['id']);
        await _cargar();
    }
  }

  Future<void> _menuGeneral(String accion) async {
    switch (accion) {
      case 'pdf':
        await _exportarPDF();
      case 'borrar':
        final ok = await confirmar(
          context,
          titulo: 'Eliminar todos',
          mensaje: '¿Eliminar todos los grupos de $tipo?',
        );
        if (!ok) return;
        await DBHelper.eliminarGruposTipo(tipo);
        await _cargar();
    }
  }

  Future<void> _exportarPDF() async {
    if (grupos.isEmpty) {
      toast(context, 'No hay grupos para exportar');
      return;
    }
    final comunidad = await DBHelper.obtenerComunidad();
    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        build: (_) => [
          pw.Header(
            level: 0,
            child: pw.Text(
              'Grupos de $tipo'
              '${comunidad == null ? '' : ' · Comunidad ${comunidad.numero} · ${comunidad.parroquia}'}',
            ),
          ),
          for (final g in grupos) ...[
            pw.Text(
              '${g['nombre']} (${_miembros(g['id']).length})',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 4),
            ..._miembros(g['id']).map((p) => pw.Bullet(text: p.nombreCompleto)),
            pw.SizedBox(height: 12),
          ],
        ],
      ),
    );
    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'grupos_${tipo.toLowerCase()}.pdf',
    );
  }

  // ---------------------------------------------------------------
  // UI
  // ---------------------------------------------------------------

  Widget _barra() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${grupos.length} grupos · ${asignacion.length}/${personas.length} asignados',
              style: TextStyle(color: Colors.grey.shade700),
            ),
          ),
          PopupMenuButton<String>(
            onSelected: _menuGeneral,
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'pdf', child: Text('Exportar PDF')),
              PopupMenuItem(
                value: 'borrar',
                child: Text('Eliminar todos los grupos'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _acciones() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: kRojo,
                side: const BorderSide(color: kRojo),
                minimumSize: const Size.fromHeight(44),
              ),
              icon: const Icon(Icons.add),
              label: const Text('Crear grupos'),
              onPressed: _crearGrupos,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ElevatedButton.icon(
              style: primaryButton().copyWith(
                minimumSize: const WidgetStatePropertyAll(Size.fromHeight(44)),
              ),
              icon: const Icon(Icons.shuffle),
              label: const Text('Repartir'),
              onPressed: _repartir,
            ),
          ),
        ],
      ),
    );
  }

  Widget _grupoCard(Map<String, dynamic> g) {
    final lista = _miembros(g['id']);
    return SectionCard(
      title: '${g['nombre']}  (${lista.length})',
      actions: [
        PopupMenuButton<String>(
          onSelected: (a) => _menuGrupo(a, g),
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'miembros', child: Text('Editar miembros')),
            PopupMenuItem(value: 'renombrar', child: Text('Renombrar')),
            PopupMenuItem(value: 'eliminar', child: Text('Eliminar grupo')),
          ],
        ),
      ],
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          for (final p in lista)
            PersonaChip(
              nombre: p.nombreCompleto,
              onTap: () => _opcionesPersona(p),
            ),
          ActionChip(
            avatar: const Icon(Icons.add, size: 18, color: kRojo),
            label: const Text('Agregar'),
            side: const BorderSide(color: kRojo),
            backgroundColor: Colors.white,
            onPressed: () => _editarMiembros(g),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (loading) return const Center(child: CircularProgressIndicator());

    final sinGrupo = _sinGrupo;
    return RefreshIndicator(
      onRefresh: _cargar,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 30),
        children: [
          _barra(),
          _acciones(),
          const SizedBox(height: 6),
          if (grupos.isEmpty)
            EmptyState(
              icon: Icons.diversity_3_outlined,
              text: 'No hay grupos de $tipo',
              hint:
                  'Crea los grupos y luego repártelos automáticamente '
                  '(los matrimonios quedan juntos) o agrega personas a mano.',
            ),
          ...grupos.map(_grupoCard),
          if (grupos.isNotEmpty && sinGrupo.isNotEmpty)
            SectionCard(
              title: 'Sin grupo (${sinGrupo.length})',
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: sinGrupo
                    .map(
                      (p) => PersonaChip(
                        nombre: p.nombreCompleto,
                        onTap: () => _opcionesPersona(p),
                      ),
                    )
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }
}
