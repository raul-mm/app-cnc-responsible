import 'package:app_movil_comunidad/models/comunidad.dart';
import 'package:app_movil_comunidad/utils/catalogos.dart';
import 'package:app_movil_comunidad/widgets/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Formulario usado al crear la comunidad y al configurarla.
class ComunidadForm extends StatefulWidget {
  final Comunidad? inicial;
  final String textoBoton;
  final Future<void> Function(Comunidad comunidad) onSave;

  const ComunidadForm({
    super.key,
    this.inicial,
    required this.textoBoton,
    required this.onSave,
  });

  @override
  State<ComunidadForm> createState() => _ComunidadFormState();
}

class _ComunidadFormState extends State<ComunidadForm> {
  final _formKey = GlobalKey<FormState>();
  late final _numero = TextEditingController(text: widget.inicial?.numero);
  late final _fechaNacimiento = TextEditingController(
    text: widget.inicial?.fechaNacimiento,
  );
  late final _parroquia = TextEditingController(
    text: widget.inicial?.parroquia,
  );
  late final _catequista = TextEditingController(
    text: widget.inicial?.catequista,
  );
  late final _catequistaComunidad = TextEditingController(
    text: widget.inicial?.catequistaComunidad,
  );
  late final _catequistaParroquia = TextEditingController(
    text: widget.inicial?.catequistaParroquia,
  );
  late final _fechaPaso = TextEditingController(
    text: widget.inicial?.fechaPaso,
  );

  late String _tipoParroquia = widget.inicial?.tipoParroquia ?? 'Parroquia';
  late String? _paso = (widget.inicial?.pasoActual.isNotEmpty ?? false)
      ? widget.inicial!.pasoActual
      : null;
  late bool _huboRito = widget.inicial?.huboRito == 1;
  bool _guardando = false;

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _guardando = true);
    await widget.onSave(
      Comunidad(
        id: widget.inicial?.id,
        numero: _numero.text.trim(),
        fechaNacimiento: _fechaNacimiento.text,
        parroquia: _parroquia.text.trim(),
        tipoParroquia: _tipoParroquia,
        pasoActual: _paso ?? '',
        fechaPaso: _fechaPaso.text,
        huboRito: _huboRito ? 1 : 0,
        catequista: _catequista.text.trim(),
        catequistaComunidad: _catequistaComunidad.text.trim(),
        catequistaParroquia: _catequistaParroquia.text.trim(),
        equipoCatequistaId: widget.inicial?.equipoCatequistaId,
      ),
    );
    if (mounted) setState(() => _guardando = false);
  }

  @override
  Widget build(BuildContext context) {
    // Conserva un paso escrito a mano en versiones anteriores
    final pasos = [
      ...pasosCamino,
      if (_paso != null && !pasosCamino.contains(_paso)) _paso!,
    ];
    const gap = SizedBox(height: 12);

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionCard(
            title: 'Datos de la comunidad',
            child: Column(
              children: [
                DropdownButtonFormField<String>(
                  initialValue: _numero.text.isEmpty ? null : _numero.text,
                  decoration: appInput(
                    'Número de comunidad *',
                    icon: Icons.tag,
                  ),
                  menuMaxHeight: 320,
                  items:
                      [
                            for (var i = 1; i <= 30; i++) '$i',
                            // Conserva un número fuera de rango guardado antes
                            if (_numero.text.isNotEmpty &&
                                !List.generate(
                                  30,
                                  (i) => '${i + 1}',
                                ).contains(_numero.text))
                              _numero.text,
                          ]
                          .map(
                            (n) => DropdownMenuItem(value: n, child: Text(n)),
                          )
                          .toList(),
                  onChanged: (v) => _numero.text = v ?? '',
                  validator: (v) => v == null ? 'Selecciona el número' : null,
                ),
                gap,
                DateField(
                  controller: _fechaNacimiento,
                  label: 'Fecha de nacimiento *',
                  requerido: true,
                  lastDate: DateTime.now(),
                ),
              ],
            ),
          ),
          SectionCard(
            title: 'Parroquia',
            child: Column(
              children: [
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(
                      value: 'Parroquia',
                      label: Text('Parroquia'),
                      icon: Icon(Icons.church_outlined),
                    ),
                    ButtonSegment(
                      value: 'Capilla',
                      label: Text('Capilla'),
                      icon: Icon(Icons.home_work_outlined),
                    ),
                  ],
                  selected: {_tipoParroquia},
                  onSelectionChanged: (s) =>
                      setState(() => _tipoParroquia = s.first),
                ),
                gap,
                TextFormField(
                  controller: _parroquia,
                  textCapitalization: TextCapitalization.words,
                  decoration: appInput(
                    _tipoParroquia == 'Capilla'
                        ? 'Nombre de la capilla *'
                        : 'Nombre de la parroquia *',
                    icon: Icons.place_outlined,
                  ),
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Campo obligatorio'
                      : null,
                ),
              ],
            ),
          ),
          SectionCard(
            title: 'Etapa del Camino',
            child: Column(
              children: [
                DropdownButtonFormField<String>(
                  initialValue: _paso,
                  isExpanded: true,
                  decoration: appInput(
                    'Último paso *',
                    icon: Icons.flag_outlined,
                  ),
                  items: pasos
                      .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                      .toList(),
                  onChanged: (v) => setState(() => _paso = v),
                  validator: (v) => v == null ? 'Selecciona el paso' : null,
                ),
                gap,
                DateField(
                  controller: _fechaPaso,
                  label: 'Fecha del paso',
                  lastDate: DateTime.now(),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('¿Hubo rito?'),
                  activeThumbColor: kRojo,
                  value: _huboRito,
                  onChanged: (v) => setState(() => _huboRito = v),
                ),
              ],
            ),
          ),
          SectionCard(
            title: 'Catequista',
            child: Column(
              children: [
                TextFormField(
                  controller: _catequista,
                  textCapitalization: TextCapitalization.words,
                  decoration: appInput('Nombre', icon: Icons.school_outlined),
                ),
                gap,
                TextFormField(
                  controller: _catequistaComunidad,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: appInput('N.º de comunidad', icon: Icons.tag),
                ),
                gap,
                TextFormField(
                  controller: _catequistaParroquia,
                  textCapitalization: TextCapitalization.words,
                  decoration: appInput(
                    'Parroquia',
                    icon: Icons.church_outlined,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            child: ElevatedButton.icon(
              style: primaryButton(),
              onPressed: _guardando ? null : _guardar,
              icon: const Icon(Icons.save),
              label: Text(widget.textoBoton),
            ),
          ),
        ],
      ),
    );
  }
}
