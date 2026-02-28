import 'package:app_movil_comunidad/screens/comunidad/persona_form.dart';
import 'package:flutter/material.dart';
import 'package:app_movil_comunidad/db/db_helper.dart';
import 'package:app_movil_comunidad/models/persona.dart';

class ComunidadPage extends StatefulWidget {
  const ComunidadPage({super.key});

  @override
  State<ComunidadPage> createState() => _ComunidadPageState();
}

class _ComunidadPageState extends State<ComunidadPage> {
  List<Persona> personas = [];
  List<Persona> personasFiltradas = [];
  final searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadPersonas();
  }

  Future<void> _loadPersonas() async {
    final data = await DBHelper.getPersonas();
    setState(() {
      personas = data;
      personasFiltradas = data;
    });
  }

  void _filterPersonas(String query) {
    final q = query.toLowerCase();
    setState(() {
      personasFiltradas = personas.where((p) {
        return p.nombres.toLowerCase().contains(q) ||
            p.apellidos.toLowerCase().contains(q) ||
            (p.documento ?? '').contains(q);
      }).toList();
    });
  }

  Future<void> _savePersona(Persona persona, bool isEdit) async {
    if (isEdit) {
      await DBHelper.updatePersona(persona);
    } else {
      await DBHelper.insertPersona(persona);
    }

    await _loadPersonas();

    if (!mounted) return;

    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isEdit
              ? 'Persona actualizada correctamente'
              : 'Persona registrada correctamente',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _confirmDelete(Persona p) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar persona'),
        content: Text('¿Desea eliminar a ${p.nombres}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await DBHelper.deletePersona(p.id!);
      _loadPersonas();
    }
  }

  void _showPersonaForm({Persona? persona}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.9,
        maxChildSize: 0.95,
        builder: (_, controller) {
          return PersonaForm(
            persona: persona,
            personas: personas,
            scrollController: controller,
            onSave: _savePersona,
          );
        },
      ),
    );
  }

  Widget _emptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 70, color: Colors.grey),
          SizedBox(height: 10),
          Text('No hay personas registradas'),
        ],
      ),
    );
  }

  Widget _buildList() {
    return ListView.separated(
      itemCount: personasFiltradas.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, index) {
        final p = personasFiltradas[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(14),
            title: Text(
              '${p.nombres} ${p.apellidos}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (p.documento != null) Text('DNI: ${p.documento}'),
                if (p.telefono != null) Text('Tel: ${p.telefono}'),
                if (p.estadoCivil != null)
                  Text('Estado civil: ${p.estadoCivil}'),
              ],
            ),
            trailing: Wrap(
              spacing: 6,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.orange),
                  onPressed: () => _showPersonaForm(persona: p),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _confirmDelete(p),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi comunidad'),
        backgroundColor: const Color(0xFFC62828),
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.black,
        onPressed: () => _showPersonaForm(),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: searchController,
              onChanged: _filterPersonas,
              decoration: InputDecoration(
                hintText: 'Buscar persona...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: personasFiltradas.isEmpty ? _emptyState() : _buildList(),
          ),
        ],
      ),
    );
  }
}
