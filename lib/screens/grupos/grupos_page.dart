import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:app_movil_comunidad/db/db_helper.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class GruposPage extends StatefulWidget {
  const GruposPage({super.key});

  @override
  State<GruposPage> createState() => _GruposPageState();
}

class _GruposPageState extends State<GruposPage>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> personasConGrupo = [];
  List<String> grupos = [];

  bool loading = true;

  final Color primaryColor = const Color(0xFFC62828);

  late AnimationController _controller;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();

    _controller =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeIn);

    _loadAll();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // =====================
  // CARGA
  // =====================
  Future<void> _loadAll() async {
    loading = true;
    setState(() {});

    personasConGrupo = await DBHelper.getPersonasConGrupo();
    grupos = await DBHelper.getGruposUnicos();

    loading = false;
    setState(() {});
    _controller.forward(from: 0);
  }

  // =====================
  // SNACKBAR SEGURO
  // =====================
  void _showMessage(String msg) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(msg),
          behavior: SnackBarBehavior.fixed, // FIX ERROR
          duration: const Duration(seconds: 2),
        ),
      );
  }

  // =====================
  // CREAR GRUPOS
  // =====================
  Future<void> _crearGrupos() async {
    final controller = TextEditingController();

    final cantidad = await showDialog<int>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cantidad de grupos'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(hintText: 'Ej: 4'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
            onPressed: () {
              final value = int.tryParse(controller.text);
              if (value != null && value > 0) {
                Navigator.pop(context, value);
              }
            },
            child: const Text('Crear'),
          ),
        ],
      ),
    );

    if (cantidad == null) return;

    grupos = List.generate(cantidad, (i) => 'Grupo ${i + 1}');
    setState(() {});

    _showMessage('Grupos creados');
  }

  // =====================
  // ASIGNAR EQUITATIVO
  // =====================
  Future<void> _asignarEquitativo() async {
    if (grupos.isEmpty) {
      _showMessage('Primero crea los grupos');
      return;
    }

    final personas = await DBHelper.getPersonasConGrupo();

    if (personas.isEmpty) {
      _showMessage('No hay personas registradas');
      return;
    }

    personas.shuffle(Random());

    int index = 0;
    for (final p in personas) {
      final grupo = grupos[index % grupos.length];
      await DBHelper.asignarGrupoPersona(p['id'], grupo);
      index++;
    }

    _showMessage('Asignación realizada');
    _loadAll();
  }

  // =====================
  // REASIGNAR
  // =====================
  Future<void> _reasignar() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Reasignar'),
        content: const Text('¿Deseas redistribuir nuevamente?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Aceptar')),
        ],
      ),
    );

    if (confirm == true) {
      _asignarEquitativo();
    }
  }

  // =====================
  // EXPORTAR PDF
  // =====================
  Future<void> _exportarPDF() async {
    if (personasConGrupo.isEmpty) {
      _showMessage('No hay datos');
      return;
    }

    final pdf = pw.Document();

    Map<String, List<Map<String, dynamic>>> data = {};
    for (var g in grupos) {
      data[g] = personasConGrupo.where((p) => p['grupo'] == g).toList();
    }

    pdf.addPage(
      pw.MultiPage(
        build: (context) {
          return data.entries.map((entry) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(entry.key,
                    style: pw.TextStyle(
                        fontSize: 16, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 5),
                ...entry.value.map((p) => pw.Text(
                    "${p['nombres']} ${p['apellidos']}")),
                pw.SizedBox(height: 15),
              ],
            );
          }).toList();
        },
      ),
    );

    final dir = await getTemporaryDirectory();
    final file = File("${dir.path}/grupos.pdf");
    await file.writeAsBytes(await pdf.save());

    await Printing.sharePdf(bytes: await pdf.save(), filename: 'grupos.pdf');
  }

  // =====================
  // RESUMEN
  // =====================
  Map<String, int> _resumen() {
    final Map<String, int> data = {};
    for (var g in grupos) {
      data[g] = personasConGrupo.where((p) => p['grupo'] == g).length;
    }
    return data;
  }

  // =====================
  // UI
  // =====================
  @override
  Widget build(BuildContext context) {
    final resumen = _resumen();

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Grupos'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: _exportarPDF,
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : FadeTransition(
              opacity: _fade,
              child: Column(
                children: [
                  _ResumenSection(resumen: resumen),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: personasConGrupo.length,
                      itemBuilder: (_, i) {
                        final p = personasConGrupo[i];
                        return Card(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: primaryColor.withOpacity(0.15),
                              child: Icon(Icons.person, color: primaryColor),
                            ),
                            title: Text(
                                "${p['nombres']} ${p['apellidos']}"),
                            subtitle:
                                Text(p['grupo'] ?? 'Sin grupo',
                                    style: TextStyle(
                                        color: p['grupo'] == null
                                            ? Colors.red
                                            : Colors.grey.shade700)),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.extended(
            heroTag: "crear",
            backgroundColor: primaryColor,
            icon: const Icon(Icons.group_add),
            label: const Text('Crear grupos'),
            onPressed: _crearGrupos,
          ),
          const SizedBox(height: 10),
          FloatingActionButton.extended(
            heroTag: "asignar",
            backgroundColor: primaryColor,
            icon: const Icon(Icons.shuffle),
            label: const Text('Asignar'),
            onPressed: _asignarEquitativo,
          ),
          const SizedBox(height: 10),
          FloatingActionButton.extended(
            heroTag: "reasignar",
            backgroundColor: Colors.orange,
            icon: const Icon(Icons.refresh),
            label: const Text('Reasignar'),
            onPressed: _reasignar,
          ),
        ],
      ),
    );
  }
}

// =====================
// RESUMEN
// =====================
class _ResumenSection extends StatelessWidget {
  final Map<String, int> resumen;

  const _ResumenSection({required this.resumen});

  @override
  Widget build(BuildContext context) {
    if (resumen.isEmpty) return const SizedBox();

    return SizedBox(
      height: 70,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.all(8),
        children: resumen.entries.map((e) {
          return Card(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: Text(
                  "${e.key}: ${e.value}",
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
