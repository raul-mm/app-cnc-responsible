import 'package:app_movil_comunidad/models/persona.dart';
import 'package:app_movil_comunidad/utils/catalogos.dart';
import 'package:app_movil_comunidad/widgets/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PersonaForm extends StatefulWidget {
  final Persona? persona;
  final List<Persona> personas;
  final ScrollController scrollController;
  final Future<void> Function(Persona persona, bool isEdit) onSave;

  const PersonaForm({
    super.key,
    this.persona,
    required this.personas,
    required this.scrollController,
    required this.onSave,
  });

  @override
  State<PersonaForm> createState() => _PersonaFormState();
}

class _PersonaFormState extends State<PersonaForm> {
  final formKey = GlobalKey<FormState>();

  late final nombres = TextEditingController(text: widget.persona?.nombres);
  late final apellidos = TextEditingController(text: widget.persona?.apellidos);
  late final fecha = TextEditingController(
    text: widget.persona?.fechaNacimiento,
  );
  late final documento = TextEditingController(text: widget.persona?.documento);
  late final telefono = TextEditingController(text: widget.persona?.telefono);
  late final direccion = TextEditingController(text: widget.persona?.direccion);
  late final correo = TextEditingController(text: widget.persona?.correo);
  late final aniversario = TextEditingController(
    text: widget.persona?.fechaAniversario,
  );
  late final hijos = TextEditingController(
    text: widget.persona?.numeroHijos?.toString(),
  );

  late String? sexo = widget.persona?.sexo;
  late String estadoCivil = estadosCiviles.contains(widget.persona?.estadoCivil)
      ? widget.persona!.estadoCivil!
      : 'Soltero';
  late int? conyugeId = widget.persona?.conyugeId;
  bool guardando = false;

  /// Candidatos a cónyuge: otras personas que no estén casadas con alguien más.
  List<Persona> get _candidatosConyuge {
    final yo = widget.persona?.id;
    return widget.personas
        .where((p) => p.id != yo)
        .where((p) => p.conyugeId == null || p.conyugeId == yo)
        .toList();
  }

  Future<void> _save() async {
    if (!formKey.currentState!.validate()) return;
    String? vacio(TextEditingController c) =>
        c.text.trim().isEmpty ? null : c.text.trim();
    final casado = estadoCivil == 'Casado';

    final persona = Persona(
      id: widget.persona?.id,
      nombres: nombres.text.trim(),
      apellidos: apellidos.text.trim(),
      sexo: sexo,
      fechaNacimiento: vacio(fecha),
      documento: vacio(documento),
      telefono: vacio(telefono),
      direccion: vacio(direccion),
      correo: vacio(correo),
      estadoCivil: estadoCivil,
      conyugeId: casado ? conyugeId : null,
      fechaAniversario: casado ? vacio(aniversario) : null,
      numeroHijos: int.tryParse(hijos.text),
    );

    setState(() => guardando = true);
    await widget.onSave(persona, widget.persona != null);
    if (mounted) setState(() => guardando = false);
  }

  Widget _gap() => const SizedBox(height: 12);

  @override
  Widget build(BuildContext context) {
    final candidatos = _candidatosConyuge;
    final casado = estadoCivil == 'Casado';

    return Form(
      key: formKey,
      child: ListView(
        controller: widget.scrollController,
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
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
          Text(
            widget.persona == null ? 'Nueva persona' : 'Editar persona',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 18),
          const _Titulo('Datos personales'),
          TextFormField(
            controller: nombres,
            textCapitalization: TextCapitalization.words,
            decoration: appInput('Nombres *', icon: Icons.person_outline),
            validator: (v) =>
                v == null || v.trim().isEmpty ? 'Campo obligatorio' : null,
          ),
          _gap(),
          TextFormField(
            controller: apellidos,
            textCapitalization: TextCapitalization.words,
            decoration: appInput('Apellidos *', icon: Icons.badge_outlined),
            validator: (v) =>
                v == null || v.trim().isEmpty ? 'Campo obligatorio' : null,
          ),
          _gap(),
          SegmentedButton<String>(
            emptySelectionAllowed: true,
            segments: const [
              ButtonSegment(
                value: 'M',
                label: Text('Hombre'),
                icon: Icon(Icons.male),
              ),
              ButtonSegment(
                value: 'F',
                label: Text('Mujer'),
                icon: Icon(Icons.female),
              ),
            ],
            selected: {?sexo},
            onSelectionChanged: (s) =>
                setState(() => sexo = s.isEmpty ? null : s.first),
          ),
          _gap(),
          DateField(
            controller: fecha,
            label: 'Fecha de nacimiento',
            lastDate: DateTime.now(),
          ),
          _gap(),
          TextFormField(
            controller: documento,
            keyboardType: TextInputType.number,
            decoration: appInput('Documento (DNI)', icon: Icons.credit_card),
          ),
          const SizedBox(height: 18),
          const _Titulo('Contacto'),
          TextFormField(
            controller: telefono,
            keyboardType: TextInputType.phone,
            decoration: appInput('Teléfono', icon: Icons.phone_outlined),
          ),
          _gap(),
          TextFormField(
            controller: correo,
            keyboardType: TextInputType.emailAddress,
            decoration: appInput('Correo', icon: Icons.email_outlined),
            validator: (v) => v == null || v.isEmpty || v.contains('@')
                ? null
                : 'Correo no válido',
          ),
          _gap(),
          TextFormField(
            controller: direccion,
            decoration: appInput('Dirección', icon: Icons.home_outlined),
          ),
          const SizedBox(height: 18),
          const _Titulo('Familia'),
          DropdownButtonFormField<String>(
            initialValue: estadoCivil,
            decoration: appInput('Estado civil', icon: Icons.favorite_border),
            items: estadosCiviles
                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                .toList(),
            onChanged: (v) => setState(() => estadoCivil = v!),
          ),
          if (casado) ...[
            _gap(),
            DropdownButtonFormField<int?>(
              initialValue: candidatos.any((p) => p.id == conyugeId)
                  ? conyugeId
                  : null,
              isExpanded: true,
              decoration: appInput('Cónyuge', icon: Icons.people_outline),
              items: [
                const DropdownMenuItem<int?>(
                  value: null,
                  child: Text('— No registrado en la comunidad —'),
                ),
                ...candidatos.map(
                  (p) => DropdownMenuItem<int?>(
                    value: p.id,
                    child: Text(p.nombreCompleto),
                  ),
                ),
              ],
              onChanged: (v) => setState(() => conyugeId = v),
            ),
            _gap(),
            DateField(
              controller: aniversario,
              label: 'Aniversario de matrimonio',
              lastDate: DateTime.now(),
            ),
          ],
          _gap(),
          TextFormField(
            controller: hijos,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: appInput(
              'Número de hijos',
              icon: Icons.child_care_outlined,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            style: primaryButton(),
            icon: guardando
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.save),
            label: const Text('Guardar'),
            onPressed: guardando ? null : _save,
          ),
        ],
      ),
    );
  }
}

class _Titulo extends StatelessWidget {
  final String text;
  const _Titulo(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          letterSpacing: 1,
          fontWeight: FontWeight.w700,
          color: Colors.grey.shade600,
        ),
      ),
    );
  }
}
