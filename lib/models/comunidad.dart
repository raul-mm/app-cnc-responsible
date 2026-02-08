class Comunidad {
  final int? id;
  final String numero;
  final String fechaNacimiento;
  final String parroquia;
  final String pasoActual;
  final String catequista;
  final String tipoParroquia; // nuevo
  final String fechaPaso;     // nuevo
  final int huboRito;         // nuevo (0 = no, 1 = sí)

  Comunidad({
    this.id,
    required this.numero,
    required this.fechaNacimiento,
    required this.parroquia,
    required this.pasoActual,
    required this.catequista,
    required this.tipoParroquia,
    required this.fechaPaso,
    required this.huboRito,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'numero': numero,
      'fechaNacimiento': fechaNacimiento,
      'parroquia': parroquia,
      'pasoActual': pasoActual,
      'catequista': catequista,
      'tipoParroquia': tipoParroquia,
      'fechaPaso': fechaPaso,
      'huboRito': huboRito,
    };
  }

  factory Comunidad.fromMap(Map<String, dynamic> map) {
    return Comunidad(
      id: map['id'],
      numero: map['numero'],
      fechaNacimiento: map['fechaNacimiento'],
      parroquia: map['parroquia'],
      pasoActual: map['pasoActual'],
      catequista: map['catequista'],
      tipoParroquia: map['tipoParroquia'],
      fechaPaso: map['fechaPaso'],
      huboRito: map['huboRito'],
    );
  }
}
