import 'package:app_movil_comunidad/db/db_helper.dart';
import 'package:app_movil_comunidad/models/persona.dart';
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
    if (!mounted) return;
    setState(() {
      personas = p;
      carismas = c;
      loading = false;
    });
  }

  /// Incluye tipos antiguos que no estén en el catálogo actual.
  List<String> get _tipos => [
    ...tiposCarisma,
    ...carismas
        .map((c) => c['tipo'] as String)
        .where((t) => !tiposCarisma.contains(t))
        .toSet(),
  ];

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

  Future<void> _porPersona() async {
    final sel = await seleccionarPersonas(
      context,
      titulo: 'Elige una persona',
      personas: personas,
      multiple: false,
    );
    if (sel == null || sel.isEmpty || !mounted) return;
    final p = sel.first;
    final marcados = carismas
        .where((c) => c['persona_id'] == p.id)
        .map((c) => c['tipo'] as String)
        .toSet();

    final guardar = await showAppSheet<bool>(
      context,
      titulo: 'Carismas de ${p.nombreCompleto}',
      icon: Icons.auto_awesome_outlined,
      builder: (ctx, setSheet) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _tipos
                .map(
                  (t) => FilterChip(
                    label: Text(t),
                    selected: marcados.contains(t),
                    selectedColor: kRojo.withValues(alpha: 0.15),
                    checkmarkColor: kRojo,
                    onSelected: (v) =>
                        setSheet(() => v ? marcados.add(t) : marcados.remove(t)),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            style: primaryButton(),
            icon: const Icon(Icons.save),
            label: const Text('Guardar'),
            onPressed: () => Navigator.pop(ctx, true),
          ),
        ],
      ),
    );
    if (guardar != true) return;
    await DBHelper.setCarismasPersona(p.id!, marcados.toList());
    await _cargar();
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
      title: 'Carismas',
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
        label: 'Por persona',
        icon: Icons.person_search,
        onPressed: _porPersona,
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
                          avatar: const Icon(Icons.edit, size: 16, color: kRojo),
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
