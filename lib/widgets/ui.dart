import 'package:app_movil_comunidad/models/persona.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// Componentes visuales compartidos por todas las pantallas.

const kRojo = Color(0xFFC62828);
const kFondo = Color(0xFFF7F7F9);

class AppPage extends StatelessWidget {
  final String title;
  final Widget body;
  final Widget? fab;
  final List<Widget>? actions;
  final PreferredSizeWidget? bottom;

  const AppPage({
    super.key,
    required this.title,
    required this.body,
    this.fab,
    this.actions,
    this.bottom,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kFondo,
      appBar: AppBar(
        title: Text(
          title,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
        backgroundColor: kRojo,
        foregroundColor: Colors.white,
        centerTitle: true,
        actions: actions,
        bottom: bottom,
      ),
      floatingActionButton: fab,
      body: body,
    );
  }
}

class AppFab extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  const AppFab({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      heroTag: label,
      backgroundColor: kRojo,
      foregroundColor: Colors.white,
      icon: Icon(icon),
      label: Text(label),
      onPressed: onPressed,
    );
  }
}

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String text;
  final String? hint;

  const EmptyState({
    super.key,
    required this.icon,
    required this.text,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
            if (hint != null) ...[
              const SizedBox(height: 6),
              Text(
                hint!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class Avatar extends StatelessWidget {
  final String nombre;
  final Color color;
  final double radius;

  const Avatar(
    this.nombre, {
    super.key,
    this.color = kRojo,
    this.radius = 20,
  });

  @override
  Widget build(BuildContext context) {
    final partes = nombre.trim().split(RegExp(r'\s+'));
    final iniciales = partes
        .where((p) => p.isNotEmpty)
        .take(2)
        .map((p) => p[0].toUpperCase())
        .join();
    return CircleAvatar(
      radius: radius,
      backgroundColor: color.withValues(alpha: 0.12),
      child: Text(
        iniciales,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: radius * 0.7,
        ),
      ),
    );
  }
}

/// Tarjeta con título de sección.
class SectionCard extends StatelessWidget {
  final String? title;
  final Widget child;
  final List<Widget>? actions;
  final EdgeInsets padding;

  const SectionCard({
    super.key,
    this.title,
    required this.child,
    this.actions,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title != null)
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title!,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  ...?actions,
                ],
              ),
            if (title != null) const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }
}

InputDecoration appInput(String label, {IconData? icon, Widget? suffix}) {
  return InputDecoration(
    labelText: label,
    prefixIcon: icon == null ? null : Icon(icon, color: kRojo),
    suffixIcon: suffix,
    filled: true,
    fillColor: Colors.grey.shade100,
    floatingLabelStyle: const TextStyle(
      color: kRojo,
      fontWeight: FontWeight.w600,
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
  );
}

ButtonStyle primaryButton() => ElevatedButton.styleFrom(
  backgroundColor: kRojo,
  foregroundColor: Colors.white,
  minimumSize: const Size.fromHeight(50),
  maximumSize: const Size(double.infinity, 56),
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
);

/// Campo de fecha con selector (formato yyyy-MM-dd).
class DateField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool requerido;
  final DateTime? lastDate;

  const DateField({
    super.key,
    required this.controller,
    required this.label,
    this.requerido = false,
    this.lastDate,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      decoration: appInput(
        label,
        icon: Icons.calendar_today_outlined,
        suffix: controller.text.isEmpty || requerido
            ? null
            : IconButton(
                icon: const Icon(Icons.clear, size: 18),
                onPressed: () => controller.clear(),
              ),
      ),
      validator: requerido
          ? (v) => v == null || v.isEmpty ? 'Campo obligatorio' : null
          : null,
      onTap: () async {
        final fecha = await showDatePicker(
          context: context,
          initialDate: DateTime.tryParse(controller.text) ?? DateTime.now(),
          firstDate: DateTime(1900),
          lastDate: lastDate ?? DateTime(DateTime.now().year + 5),
        );
        if (fecha != null) {
          controller.text = DateFormat('yyyy-MM-dd').format(fecha);
        }
      },
    );
  }
}

void toast(BuildContext context, String msg) {
  ScaffoldMessenger.of(context)
    ..clearSnackBars()
    ..showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
}

Future<bool> confirmar(
  BuildContext context, {
  required String titulo,
  required String mensaje,
  String accion = 'Eliminar',
}) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(titulo),
      content: Text(mensaje),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(accion, style: const TextStyle(color: kRojo)),
        ),
      ],
    ),
  );
  return ok ?? false;
}

Future<String?> pedirTexto(
  BuildContext context, {
  required String titulo,
  required String label,
  String inicial = '',
  TextInputType teclado = TextInputType.text,
}) {
  final c = TextEditingController(text: inicial);
  return showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(titulo),
      content: TextField(
        controller: c,
        autofocus: true,
        keyboardType: teclado,
        decoration: appInput(label),
        onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, c.text.trim()),
          child: const Text('Aceptar', style: TextStyle(color: kRojo)),
        ),
      ],
    ),
  );
}

/// Hoja inferior estándar con asa y título.
Future<T?> showAppSheet<T>(
  BuildContext context, {
  required String titulo,
  IconData? icon,
  required Widget Function(BuildContext ctx, StateSetter setSheet) builder,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(ctx).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 12,
      ),
      child: StatefulBuilder(
        builder: (ctx, setSheet) => SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  if (icon != null) ...[
                    Icon(icon, color: kRojo),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: Text(
                      titulo,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              builder(ctx, setSheet),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    ),
  );
}

/// Selector de personas con búsqueda. `bloqueadas` indica por qué una persona
/// no se puede elegir (p. ej. "Ya está en el equipo").
Future<List<Persona>?> seleccionarPersonas(
  BuildContext context, {
  required String titulo,
  required List<Persona> personas,
  Set<int> seleccionadas = const {},
  Map<int, String> bloqueadas = const {},
  bool multiple = true,
}) {
  final elegidas = {...seleccionadas};
  var filtro = '';

  return showModalBottomSheet<List<Persona>>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      builder: (ctx, scroll) => StatefulBuilder(
        builder: (ctx, setSheet) {
          final q = filtro.toLowerCase();
          final lista = personas
              .where((p) => p.nombreCompleto.toLowerCase().contains(q))
              .toList();
          return Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
                child: Text(
                  titulo,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  decoration: appInput('Buscar persona', icon: Icons.search),
                  onChanged: (v) => setSheet(() => filtro = v),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: personas.isEmpty
                    ? const EmptyState(
                        icon: Icons.person_off_outlined,
                        text: 'No hay personas registradas',
                        hint: 'Regístralas primero en "Personas".',
                      )
                    : ListView.builder(
                        controller: scroll,
                        itemCount: lista.length,
                        itemBuilder: (_, i) {
                          final p = lista[i];
                          final motivo = bloqueadas[p.id];
                          final marcada = elegidas.contains(p.id);
                          return ListTile(
                            enabled: motivo == null,
                            leading: Avatar(
                              p.nombreCompleto,
                              color: motivo == null ? kRojo : Colors.grey,
                            ),
                            title: Text(p.nombreCompleto),
                            subtitle: motivo == null ? null : Text(motivo),
                            trailing: motivo != null
                                ? const Icon(Icons.lock_outline, size: 18)
                                : multiple
                                ? Checkbox(
                                    value: marcada,
                                    activeColor: kRojo,
                                    onChanged: (_) => setSheet(
                                      () => marcada
                                          ? elegidas.remove(p.id)
                                          : elegidas.add(p.id!),
                                    ),
                                  )
                                : null,
                            onTap: () {
                              if (!multiple) {
                                Navigator.pop(ctx, [p]);
                                return;
                              }
                              setSheet(
                                () => marcada
                                    ? elegidas.remove(p.id)
                                    : elegidas.add(p.id!),
                              );
                            },
                          );
                        },
                      ),
              ),
              if (multiple)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: ElevatedButton.icon(
                    style: primaryButton(),
                    icon: const Icon(Icons.check),
                    label: Text('Confirmar (${elegidas.length})'),
                    onPressed: () => Navigator.pop(
                      ctx,
                      personas.where((p) => elegidas.contains(p.id)).toList(),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    ),
  );
}

/// Chip de persona con opción de quitar.
class PersonaChip extends StatelessWidget {
  final String nombre;
  final String? etiqueta;
  final VoidCallback? onDeleted;
  final VoidCallback? onTap;

  const PersonaChip({
    super.key,
    required this.nombre,
    this.etiqueta,
    this.onDeleted,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InputChip(
      avatar: Avatar(nombre, radius: 12),
      label: Text(etiqueta == null ? nombre : '$nombre · $etiqueta'),
      backgroundColor: Colors.grey.shade100,
      side: BorderSide.none,
      onDeleted: onDeleted,
      onPressed: onTap,
    );
  }
}
