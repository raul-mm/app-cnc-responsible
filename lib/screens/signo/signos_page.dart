import 'package:app_movil_comunidad/db/db_helper.dart';
import 'package:app_movil_comunidad/models/persona.dart';
import 'package:app_movil_comunidad/models/signo.dart';
import 'package:app_movil_comunidad/widgets/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Signos de la comunidad y las personas responsables de cada uno.
class SignosPage extends StatefulWidget {
  const SignosPage({super.key});

  @override
  State<SignosPage> createState() => _SignosPageState();
}

class _SignosPageState extends State<SignosPage> {
  List<Signo> signos = [];
  Map<int, List<Map<String, dynamic>>> responsables = {};
  List<Persona> personas = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    final s = await DBHelper.obtenerSignos();
    final r = await DBHelper.getResponsablesSignos();
    final p = await DBHelper.getPersonas();
    if (!mounted) return;
    setState(() {
      signos = s;
      responsables = r;
      personas = p;
      loading = false;
    });
  }

  Future<void> _formulario({Signo? signo}) async {
    final formKey = GlobalKey<FormState>();
    final nombre = TextEditingController(text: signo?.nombre);
    final cantidad = TextEditingController(text: signo?.cantidad.toString());
    final compra = TextEditingController(text: signo?.fechaCompra);
    final entrega = TextEditingController(text: signo?.fechaEntrega);
    final obs = TextEditingController(text: signo?.observacion);
    final elegidos = <Persona>[
      for (final r in responsables[signo?.id] ?? const [])
        ...personas.where((p) => p.id == r['persona_id']),
    ];
    const gap = SizedBox(height: 12);

    await showAppSheet(
      context,
      titulo: signo == null ? 'Nuevo signo' : 'Editar signo',
      icon: Icons.volunteer_activism_outlined,
      builder: (ctx, setSheet) => Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: nombre,
              textCapitalization: TextCapitalization.sentences,
              decoration: appInput('Nombre del signo *', icon: Icons.label_outline),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Campo obligatorio' : null,
            ),
            gap,
            TextFormField(
              controller: cantidad,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: appInput('Cantidad', icon: Icons.numbers),
            ),
            gap,
            DateField(controller: compra, label: 'Fecha de compra'),
            gap,
            DateField(controller: entrega, label: 'Fecha de entrega'),
            gap,
            TextFormField(
              controller: obs,
              maxLines: 2,
              decoration: appInput('Observación', icon: Icons.notes),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Responsables',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.person_add_alt, color: kRojo),
                  label: const Text('Elegir', style: TextStyle(color: kRojo)),
                  onPressed: () async {
                    final sel = await seleccionarPersonas(
                      ctx,
                      titulo: 'Responsables del signo',
                      personas: personas,
                      seleccionadas: elegidos.map((p) => p.id!).toSet(),
                    );
                    if (sel != null) {
                      setSheet(() => elegidos
                        ..clear()
                        ..addAll(sel));
                    }
                  },
                ),
              ],
            ),
            if (elegidos.isEmpty)
              Text(
                'Sin responsables asignados',
                style: TextStyle(color: Colors.grey.shade600),
              )
            else
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: elegidos
                    .map(
                      (p) => PersonaChip(
                        nombre: p.nombreCompleto,
                        onDeleted: () => setSheet(() => elegidos.remove(p)),
                      ),
                    )
                    .toList(),
              ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              style: primaryButton(),
              icon: const Icon(Icons.save),
              label: const Text('Guardar'),
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                String? vacio(TextEditingController c) =>
                    c.text.trim().isEmpty ? null : c.text.trim();
                final nuevo = Signo(
                  id: signo?.id,
                  nombre: nombre.text.trim(),
                  cantidad: int.tryParse(cantidad.text) ?? 0,
                  fechaCompra: vacio(compra),
                  fechaEntrega: vacio(entrega),
                  observacion: vacio(obs),
                );
                int id;
                if (signo == null) {
                  id = await DBHelper.insertarSigno(nuevo);
                } else {
                  await DBHelper.actualizarSigno(nuevo);
                  id = signo.id!;
                }
                await DBHelper.setResponsablesSigno(
                  id,
                  elegidos.map((p) => p.id!).toList(),
                );
                if (ctx.mounted) Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
    await _cargar();
  }

  Future<void> _eliminar(Signo s) async {
    final ok = await confirmar(
      context,
      titulo: 'Eliminar signo',
      mensaje: '¿Eliminar "${s.nombre}"?',
    );
    if (!ok) return;
    await DBHelper.eliminarSigno(s.id!);
    await _cargar();
  }

  Widget _card(Signo s) {
    final resp = responsables[s.id] ?? const [];
    final fechas = [
      if (s.fechaCompra != null) 'Compra: ${s.fechaCompra}',
      if (s.fechaEntrega != null) 'Entrega: ${s.fechaEntrega}',
    ];
    return SectionCard(
      title: s.nombre,
      actions: [
        Chip(
          label: Text('x${s.cantidad}'),
          visualDensity: VisualDensity.compact,
          side: BorderSide.none,
        ),
        IconButton(
          icon: const Icon(Icons.edit_outlined),
          onPressed: () => _formulario(signo: s),
        ),
        IconButton(
          icon: const Icon(Icons.delete_outline),
          onPressed: () => _eliminar(s),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (fechas.isNotEmpty)
            Text(
              fechas.join('  ·  '),
              style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
            ),
          if (s.observacion != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(s.observacion!, style: const TextStyle(fontSize: 13)),
            ),
          const SizedBox(height: 8),
          resp.isEmpty
              ? Text(
                  'Sin responsables',
                  style: TextStyle(color: Colors.orange.shade800, fontSize: 13),
                )
              : Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: resp
                      .map((r) => PersonaChip(nombre: r['nombre_completo']))
                      .toList(),
                ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: 'Signos',
      fab: AppFab(label: 'Signo', icon: Icons.add, onPressed: () => _formulario()),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : signos.isEmpty
          ? const EmptyState(
              icon: Icons.volunteer_activism_outlined,
              text: 'No hay signos registrados',
              hint: 'Registra cada signo y asigna a sus responsables.',
            )
          : ListView(
              padding: const EdgeInsets.only(top: 10, bottom: 90),
              children: signos.map(_card).toList(),
            ),
    );
  }
}
