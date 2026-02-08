import 'dart:math';
import 'package:flutter/material.dart';
import 'package:app_movil_comunidad/db/db_helper.dart';

class CrearGruposPage extends StatefulWidget {
  const CrearGruposPage({super.key});

  @override
  State<CrearGruposPage> createState() => _CrearGruposPageState();
}

class _CrearGruposPageState extends State<CrearGruposPage> {
  List<Map<String, dynamic>> personasConGrupo = [];
  List<String> grupos = ['Palabra', 'Eucaristía', 'Doméstica'];

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    personasConGrupo = await DBHelper.getPersonasConGrupo();
    final personalizados = await DBHelper.getGruposUnicos();
    final predefinidos = ['Palabra', 'Eucaristía', 'Doméstica'];
    final otros = personalizados.where((g) => !predefinidos.contains(g)).toList();
    grupos = [...predefinidos, ...otros.toSet()];
    setState(() {});
  }

  Future<void> _asignarGrupoManual(int personaId) async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) {
        return ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(vertical: 16),
          children: grupos.map((g) {
            return ListTile(
              leading: const Icon(Icons.group),
              title: Text(g),
              onTap: () async {
                await DBHelper.asignarGrupoPersona(personaId, g);
                Navigator.pop(context);
                _loadAll();
              },
            );
          }).toList(),
        );
      },
    );
  }

  Future<void> _generarAleatorio() async {
    final sinGrupo = personasConGrupo.where((p) => p['grupo'] == null).toList();

    if (sinGrupo.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Todos ya tienen grupo asignado.')),
      );
      return;
    }

    final confirmado = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('¿Asignar aleatoriamente?'),
        content: Text('¿Deseas asignar aleatoriamente a ${sinGrupo.length} personas?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Confirmar')),
        ],
      ),
    );

    if (confirmado != true) return;

    final random = Random();
    for (final p in sinGrupo) {
      final grupo = grupos[random.nextInt(grupos.length)];
      await DBHelper.asignarGrupoPersona(p['id'], grupo);
    }

    _loadAll();
  }

  Future<void> _crearNuevoGrupo() async {
    final controller = TextEditingController();

    final creado = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Nuevo grupo"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: "Nombre del grupo",
          ),
        ),
        actions: [
          TextButton(
            child: const Text("Cancelar"),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            child: const Text("Crear"),
            onPressed: () {
              final nombre = controller.text.trim();
              if (nombre.isNotEmpty && !grupos.contains(nombre)) {
                Navigator.pop(context, nombre);
              } else {
                Navigator.pop(context);
              }
            },
          ),
        ],
      ),
    );

    if (creado != null && creado.isNotEmpty) {
      grupos.add(creado);
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear grupos'),
        backgroundColor: Colors.brown,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_box_rounded),
            tooltip: 'Nuevo grupo',
            onPressed: _crearNuevoGrupo,
          ),
          IconButton(
            icon: const Icon(Icons.shuffle),
            tooltip: 'Asignar aleatorio',
            onPressed: _generarAleatorio,
          ),
        ],
      ),
      body: personasConGrupo.isEmpty
          ? const Center(child: Text('No hay personas registradas.'))
          : ListView.builder(
              itemCount: personasConGrupo.length,
              itemBuilder: (_, index) {
                final p = personasConGrupo[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    title: Text('${p['nombres']} ${p['apellidos']}'),
                    subtitle: Text(p['grupo'] ?? 'Sin grupo'),
                    trailing: IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => _asignarGrupoManual(p['id']),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
