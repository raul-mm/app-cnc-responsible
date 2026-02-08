class Signo {
  final int? id;
  final String nombre;
  final int cantidad;
  final String fechaCompra;
  final String fechaEntrega;
  final String? observacion;

  Signo({
    this.id,
    required this.nombre,
    required this.cantidad,
    required this.fechaCompra,
    required this.fechaEntrega,
    this.observacion,
  });

  factory Signo.fromMap(Map<String, dynamic> json) => Signo(
        id: json['id'],
        nombre: json['nombre'],
        cantidad: json['cantidad'],
        fechaCompra: json['fechaCompra'],
        fechaEntrega: json['fechaEntrega'],
        observacion: json['observacion'],
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'nombre': nombre,
        'cantidad': cantidad,
        'fechaCompra': fechaCompra,
        'fechaEntrega': fechaEntrega,
        'observacion': observacion,
      };
}
