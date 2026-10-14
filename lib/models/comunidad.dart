class Comunidad {
  final int? id;
  final String numero;
  final String fechaNacimiento;
  final String parroquia;
  final String tipoParroquia; // Parroquia | Capilla
  final String pasoActual;
  final String fechaPaso;
  final int huboRito; // 0 = no, 1 = sí
  final String catequista;
  final String catequistaComunidad; // nro. de comunidad del catequista
  final String catequistaParroquia;
  final int? equipoCatequistaId;

  Comunidad({
    this.id,
    required this.numero,
    required this.fechaNacimiento,
    required this.parroquia,
    required this.tipoParroquia,
    required this.pasoActual,
    required this.fechaPaso,
    required this.huboRito,
    required this.catequista,
    this.catequistaComunidad = '',
    this.catequistaParroquia = '',
    this.equipoCatequistaId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'numero': numero,
      'fechaNacimiento': fechaNacimiento,
      'parroquia': parroquia,
      'tipoParroquia': tipoParroquia,
      'pasoActual': pasoActual,
      'fechaPaso': fechaPaso,
      'huboRito': huboRito,
      'catequista': catequista,
      'catequistaComunidad': catequistaComunidad,
      'catequistaParroquia': catequistaParroquia,
      'equipo_catequista_id': equipoCatequistaId,
    };
  }

  factory Comunidad.fromMap(Map<String, dynamic> map) {
    return Comunidad(
      id: map['id'],
      numero: map['numero'] ?? '',
      fechaNacimiento: map['fechaNacimiento'] ?? '',
      parroquia: map['parroquia'] ?? '',
      tipoParroquia: map['tipoParroquia'] ?? 'Parroquia',
      pasoActual: map['pasoActual'] ?? '',
      fechaPaso: map['fechaPaso'] ?? '',
      huboRito: map['huboRito'] ?? 0,
      catequista: map['catequista'] ?? '',
      catequistaComunidad: map['catequistaComunidad'] ?? '',
      catequistaParroquia: map['catequistaParroquia'] ?? '',
      equipoCatequistaId: map['equipo_catequista_id'],
    );
  }
}
