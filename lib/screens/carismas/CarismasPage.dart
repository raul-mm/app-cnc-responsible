import 'package:app_movil_comunidad/db/db_helper.dart';
import 'package:app_movil_comunidad/models/persona.dart';
import 'package:app_movil_comunidad/services/reportes.dart';
import 'package:app_movil_comunidad/utils/catalogos.dart';
import 'package:app_movil_comunidad/widgets/ui.dart';
import 'package:flutter/material.dart';

/// Carismas de la comunidad. Una persona puede tener varios.
class CarismasPage extends StatefulWidget {
  const CarismasPage({super.key});

  @override
  State<CarismasPage> createState() => _CarismasPageState();
}

class _CarismasPageState extends State<CarismasPage> {
  List<Persona> personas = [];
  List<Map<String, dynamic>> carismas = [];
  List<Map<String, dynamic>> catequistas = [];
  Map<String, List<Map<String, dynamic>>> servicios = {};
  bool soloConPersonas = false;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    final p = await DBHelper.getPersonas();
    final c = await DBHelper.getCarismas();
    final cat = await DBHelper.getCatequistas();
    final serv = {
      for (final tipo in DBHelper.tiposServicio)
        tipo: await DBHelper.getServicio(tipo),
    };
    if (!mounted) return;
    setState(() {
      personas = p;
      carismas = c;
      catequistas = cat;
      servicios = serv;
      loading = false;
    });
  }

  /// Incluye tipos antiguos que no estén en el catálogo actual,
  /// salvo los retirados.
  List<String> get _tipos => [
    ...tiposCarisma,
    ...carismas
        .map((c) => c['tipo'] as String)
        .where(
          (t) => !tiposCarisma.contains(t) && !carismasRetirados.contains(t),
        )
        .toSet(),
  ];

  /// Sección de solo lectura cuyos datos vienen de otra pantalla.
  Widget _seccionExterna(
    String titulo,
    List<Map<String, dynamic>> lista,
    String ruta,
  ) {
    return SectionCard(
      title: '$titulo  (${lista.length})',
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          for (final m in lista)
            PersonaChip(
              nombre: m['nombre_completo'],
              etiqueta: m['es_responsable'] == 1 ? '★ Resp.' : null,
            ),
          ActionChip(
            avatar: const Icon(Icons.open_in_new, size: 16, color: kRojo),
            label: const Text('Gestionar'),
            side: const BorderSide(color: kRojo),
            backgroundColor: Colors.white,
            onPressed: () async {
              await Navigator.pushNamed(context, ruta);
              _cargar();
            },
          ),
        ],
      ),
    );
  }

  /// 'Didáscalos' -> 'didascalos' (nombre de la ruta).
  String _rutaServicio(String tipo) => tipo.toLowerCase().replaceAll('á', 'a');

  List<Map<String, dynamic>> _de(String tipo) =>
      carismas.where((c) => c['tipo'] == tipo).toList();

  Future<void> _editarTipo(String tipo) async {
    final sel = await seleccionarPersonas(
      context,
      titulo: tipo,
      personas: personas,
      seleccionadas: _de(tipo).map((c) => c['persona_id'] as int).toSet(),
    );
    if (sel == null) return;
    await DBHelper.setPersonasCarisma(tipo, sel.map((p) => p.id!).toList());
    await _cargar();
  }

  Future<void> _exportar() async {
    final opcion = await showAppSheet<String>(
      context,
      titulo: 'Descargar reporte',
      icon: Icons.file_download_outlined,
      builder: (ctx, _) => Column(
        children: [
          ListTile(
            leading: const Icon(Icons.table_chart_outlined, color: kRojo),
            title: const Text('Ficha de la comunidad'),
            subtitle: const Text('Excel (.xlsx)'),
            onTap: () => Navigator.pop(ctx, 'ficha'),
          ),
          ListTile(
            leading: const Icon(Icons.description_outlined, color: kRojo),
            title: const Text('Formato de convivencias'),
            subtitle: const Text('Word (.docx)'),
            onTap: () => Navigator.pop(ctx, 'convivencia'),
          ),
        ],
      ),
    );
    if (opcion == null || !mounted) return;
    try {
      final ruta = opcion == 'ficha'
          ? await Reportes.exportarFicha()
          : await _exportarConvivencia();
      if (ruta != null && mounted) toast(context, 'Descargado en $ruta');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('No se pudo exportar: $e')));
    }
  }

  Future<String?> _exportarConvivencia() async {
    final formKey = GlobalKey<FormState>();
    final convivencia = TextEditingController();
    final fecha = TextEditingController();
    final ok = await showAppSheet<bool>(
      context,
      titulo: 'Formato de convivencias',
      icon: Icons.description_outlined,
      builder: (ctx, _) => Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: convivencia,
              textCapitalization: TextCapitalization.sentences,
              decoration: appInput(
                'Convivencia de *',
                icon: Icons.event_note_outlined,
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Campo obligatorio' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: fecha,
              decoration: appInput(
                'Fecha de la convivencia',
                icon: Icons.calendar_today_outlined,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              style: primaryButton(),
              icon: const Icon(Icons.file_download_outlined),
              label: const Text('Exportar'),
              onPressed: () {
                if (formKey.currentState!.validate()) Navigator.pop(ctx, true);
              },
            ),
          ],
        ),
      ),
    );
    if (ok != true) return null;
    return Reportes.exportarConvivencia(
      convivencia: convivencia.text.trim(),
      fecha: fecha.text.trim(),
    );
  }

  Future<void> _quitar(Map<String, dynamic> c) async {
    final ok = await confirmar(
      context,
      titulo: 'Quitar carisma',
      mensaje: '¿Quitar "${c['tipo']}" a ${c['nombre_completo']}?',
      accion: 'Quitar',
    );
    if (!ok) return;
    await DBHelper.deleteCarisma(c['id']);
    await _cargar();
  }

  @override
  Widget build(BuildContext context) {
    final tipos = _tipos.where((t) => !soloConPersonas || _de(t).isNotEmpty);
    return AppPage(
      title: 'Consolidado',
      actions: [
        IconButton(
          tooltip: soloConPersonas ? 'Ver todos' : 'Solo con personas',
          icon: Icon(
            soloConPersonas ? Icons.filter_alt : Icons.filter_alt_outlined,
          ),
          onPressed: () => setState(() => soloConPersonas = !soloConPersonas),
        ),
      ],
      fab: AppFab(
        label: 'Reportes',
        icon: Icons.file_download_outlined,
        onPressed: _exportar,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : personas.isEmpty
          ? const EmptyState(
              icon: Icons.auto_awesome_outlined,
              text: 'No hay personas registradas',
              hint: 'Registra personas para asignarles carismas.',
            )
          : ListView(
              padding: const EdgeInsets.only(top: 10, bottom: 90),
              children: [
                if (!soloConPersonas || catequistas.isNotEmpty)
                  _seccionExterna('Catequistas', catequistas, 'catequista'),
                // Servicios: solo lectura, se gestionan en su propia página.
                for (final MapEntry(key: tipo, value: lista)
                    in servicios.entries)
                  if (!soloConPersonas || lista.isNotEmpty)
                    _seccionExterna(tipo, lista, _rutaServicio(tipo)),
                for (final t in tipos)
                  SectionCard(
                    title: '$t  (${_de(t).length})',
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final c in _de(t))
                          PersonaChip(
                            nombre: c['nombre_completo'],
                            onDeleted: () => _quitar(c),
                          ),
                        ActionChip(
                          avatar: const Icon(
                            Icons.edit,
                            size: 16,
                            color: kRojo,
                          ),
                          label: const Text('Editar'),
                          side: const BorderSide(color: kRojo),
                          backgroundColor: Colors.white,
                          onPressed: () => _editarTipo(t),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }
}
