import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../db/db_helper.dart';
import '../../../models/signo.dart';

class SignosPage extends StatefulWidget {
  const SignosPage({super.key});

  @override
  State<SignosPage> createState() => _SignosPageState();
}

class _SignosPageState extends State<SignosPage> {
  List<Signo> _signos = [];

  @override
  void initState() {
    super.initState();
    _cargarSignos();
  }

  Future<void> _cargarSignos() async {
    final signos = await DBHelper.obtenerSignos();
    setState(() {
      _signos = signos;
    });
  }

  void _mostrarFormulario({Signo? signo}) {
    final _formKey = GlobalKey<FormState>();
    final _nombre = TextEditingController(text: signo?.nombre ?? '');
    final _cantidad = TextEditingController(
      text: signo?.cantidad.toString() ?? '',
    );
    final _fechaCompra = TextEditingController(text: signo?.fechaCompra ?? '');
    final _fechaEntrega = TextEditingController(
      text: signo?.fechaEntrega ?? '',
    );
    final _observacion = TextEditingController(text: signo?.observacion ?? '');

    Future<void> _seleccionarFecha(TextEditingController controller) async {
      final fecha = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime(2000),
        lastDate: DateTime.now().add(const Duration(days: 365)),
      );
      if (fecha != null) {
        controller.text = DateFormat('yyyy-MM-dd').format(fecha);
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Form(
              key: _formKey,
              child: Wrap(
                runSpacing: 10,
                children: [
                  Center(
                    child: Text(
                      signo == null ? 'Agregar Signo' : 'Editar Signo',
                      style: const TextStyle(
                        fontFamily: 'Merriweather',
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  _campoTexto(_nombre, 'Nombre'),
                  _campoTexto(
                    _cantidad,
                    'Cantidad',
                    keyboardType: TextInputType.number,
                  ),
                  _campoFecha(
                    _fechaCompra,
                    'Fecha de Compra',
                    () => _seleccionarFecha(_fechaCompra),
                  ),
                  _campoFecha(
                    _fechaEntrega,
                    'Fecha de Entrega',
                    () => _seleccionarFecha(_fechaEntrega),
                  ),
                  _campoTexto(_observacion, 'Observación', requerido: false),
                  const SizedBox(height: 6),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: Icon(
                        signo == null ? Icons.add : Icons.save,
                        size: 18,
                        color: Colors.white,
                      ),
                      label: Text(
                        signo == null ? 'Agregar' : 'Actualizar',
                        style: TextStyle(color: Colors.white),
                      ),
                      onPressed: () async {
                        if (_formKey.currentState!.validate()) {
                          final nuevo = Signo(
                            id: signo?.id,
                            nombre: _nombre.text,
                            cantidad: int.tryParse(_cantidad.text) ?? 0,
                            fechaCompra: _fechaCompra.text,
                            fechaEntrega: _fechaEntrega.text,
                            observacion: _observacion.text,
                          );

                          signo == null
                              ? await DBHelper.insertarSigno(nuevo)
                              : await DBHelper.actualizarSigno(nuevo);

                          _cargarSignos();
                          Navigator.pop(context);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 30),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _campoTexto(
    TextEditingController controller,
    String label, {
    TextInputType keyboardType = TextInputType.text,
    bool requerido = true,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
      ),
      validator:
          requerido
              ? (v) => v == null || v.isEmpty ? 'Campo obligatorio' : null
              : null,
    );
  }

  Widget _campoFecha(
    TextEditingController controller,
    String label,
    VoidCallback onTap,
  ) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      onTap: onTap,
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: const Icon(
          Icons.calendar_today,
          size: 18,
          color: Colors.redAccent,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
      ),
      validator: (v) => v == null || v.isEmpty ? 'Campo obligatorio' : null,
    );
  }

  void _eliminarSigno(int id) async {
    await DBHelper.eliminarSigno(id);
    _cargarSignos();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Signos',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        backgroundColor: Color(0xFFC62828),
        foregroundColor: Colors.white,
        elevation: 4,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body:
          _signos.isEmpty
              ? const Center(child: Text('No hay signos registrados.'))
              : ListView.separated(
                padding: const EdgeInsets.all(12),
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemCount: _signos.length,
                itemBuilder: (context, index) {
                  final signo = _signos[index];
                  return Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 2,
                    child: ListTile(
                      title: Text(
                        signo.nombre,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      subtitle: Text('Cantidad: ${signo.cantidad}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.edit,
                              color: Colors.orange,
                              size: 20,
                            ),
                            onPressed: () => _mostrarFormulario(signo: signo),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.delete,
                              color: Colors.red,
                              size: 20,
                            ),
                            onPressed: () => _eliminarSigno(signo.id!),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _mostrarFormulario(),
        backgroundColor: Colors.black,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
