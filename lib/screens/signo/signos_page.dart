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
                if (signo == null) {
                  await DBHelper.insertarSigno(nuevo);
                } else {
                  await DBHelper.actualizarSigno(nuevo);
                }
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
          if (resp.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: resp
                  .map((r) => PersonaChip(nombre: r['nombre_completo']))
                  .toList(),
            ),
          ],
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
