import 'package:app_movil_comunidad/db/db_helper.dart';
import 'package:app_movil_comunidad/models/persona.dart';
import 'package:app_movil_comunidad/screens/comunidad/persona_form.dart';
import 'package:app_movil_comunidad/widgets/ui.dart';
import 'package:flutter/material.dart';

/// Registro de las personas (hermanos) de la comunidad.
class ComunidadPage extends StatefulWidget {
  const ComunidadPage({super.key});

  @override
  State<ComunidadPage> createState() => _ComunidadPageState();
}

class _ComunidadPageState extends State<ComunidadPage> {
  List<Persona> personas = [];
  String filtro = '';
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadPersonas();
  }

  Future<void> _loadPersonas() async {
    final data = await DBHelper.getPersonas();
    if (!mounted) return;
    setState(() {
      personas = data;
      loading = false;
    });
  }

  List<Persona> get _filtradas {
    final q = filtro.toLowerCase();
    return personas
        .where(
          (p) =>
              p.nombreCompleto.toLowerCase().contains(q) ||
              (p.documento ?? '').contains(q),
        )
        .toList();
  }

  Future<void> _savePersona(Persona persona, bool isEdit) async {
    isEdit
        ? await DBHelper.updatePersona(persona)
        : await DBHelper.insertPersona(persona);
    await _loadPersonas();
    if (!mounted) return;
    Navigator.pop(context);
    toast(context, isEdit ? 'Persona actualizada' : 'Persona registrada');
  }

  Future<void> _confirmDelete(Persona p) async {
    final ok = await confirmar(
      context,
      titulo: 'Eliminar persona',
      mensaje:
          '¿Eliminar a ${p.nombreCompleto}? También se quitará de equipos, '
          'grupos, signos y carismas.',
    );
    if (!ok) return;
    await DBHelper.deletePersona(p.id!);
    await _loadPersonas();
  }

  void _showPersonaForm({Persona? persona}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.92,
          maxChildSize: 0.95,
          builder: (_, controller) => PersonaForm(
            persona: persona,
            personas: personas,
            scrollController: controller,
            onSave: _savePersona,
          ),
        ),
      ),
    );
  }

  String? _conyuge(Persona p) {
    if (p.conyugeId == null) return null;
    for (final o in personas) {
      if (o.id == p.conyugeId) return o.nombreCompleto;
    }
    return null;
  }

  Widget _tile(Persona p) {
    final conyuge = _conyuge(p);
    final detalles = [
      if (p.telefono != null) p.telefono!,
      if (p.estadoCivil != null) p.estadoCivil!,
      if (conyuge != null) 'con $conyuge',
    ];
    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ListTile(
        onTap: () => _showPersonaForm(persona: p),
        leading: Avatar(p.nombreCompleto),
        title: Text(
          p.nombreCompleto,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: detalles.isEmpty ? null : Text(detalles.join(' · ')),
        trailing: IconButton(
          icon: Icon(Icons.delete_outline, color: Colors.grey.shade600),
          onPressed: () => _confirmDelete(p),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lista = _filtradas;
    return AppPage(
      title: 'Personas (${personas.length})',
      fab: AppFab(
        label: 'Persona',
        icon: Icons.person_add_alt_1,
        onPressed: () => _showPersonaForm(),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: TextField(
                    onChanged: (v) => setState(() => filtro = v),
                    decoration: appInput(
                      'Buscar por nombre o DNI',
                      icon: Icons.search,
                    ),
                  ),
                ),
                Expanded(
                  child: lista.isEmpty
                      ? EmptyState(
                          icon: Icons.people_outline,
                          text: personas.isEmpty
                              ? 'Aún no hay personas'
                              : 'Sin resultados',
                          hint: personas.isEmpty
                              ? 'Registra a los hermanos de la comunidad para '
                                    'luego formar equipos, grupos y carismas.'
                              : null,
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.only(bottom: 90),
                          itemCount: lista.length,
                          itemBuilder: (_, i) => _tile(lista[i]),
                        ),
                ),
              ],
            ),
    );
  }
}
