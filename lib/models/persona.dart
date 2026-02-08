// MODELO PERSONA ACTUALIZADO
class Persona {
  int? id;
  String nombres;
  String apellidos;
  String? fechaNacimiento;
  String? documento;
  String? telefono;
  String? direccion;
  String? correo;
  String? estadoCivil;
  int? conyugeId;
  String? fechaAniversario;
  int? numeroHijos;

  Persona({
    this.id,
    required this.nombres,
    required this.apellidos,
    this.fechaNacimiento,
    this.documento,
    this.telefono,
    this.direccion,
    this.correo,
    this.estadoCivil,
    this.conyugeId,
    this.fechaAniversario,
    this.numeroHijos,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombres': nombres,
      'apellidos': apellidos,
      'fechaNacimiento': fechaNacimiento,
      'documento': documento,
      'telefono': telefono,
      'direccion': direccion,
      'correo': correo,
      'estadoCivil': estadoCivil,
      'conyugeId': conyugeId,
      'fechaAniversario': fechaAniversario,
      'numeroHijos': numeroHijos,
    };
  }

  factory Persona.fromMap(Map<String, dynamic> map) {
    return Persona(
      id: map['id'],
      nombres: map['nombres'],
      apellidos: map['apellidos'],
      fechaNacimiento: map['fechaNacimiento'],
      documento: map['documento'],
      telefono: map['telefono'],
      direccion: map['direccion'],
      correo: map['correo'],
      estadoCivil: map['estadoCivil'],
      conyugeId: map['conyugeId'],
      fechaAniversario: map['fechaAniversario'],
      numeroHijos: map['numeroHijos'],
    );
  }
}
