import 'dart:convert';
import 'dart:io';

import 'package:app_movil_comunidad/db/db_helper.dart';
import 'package:app_movil_comunidad/models/comunidad.dart';
import 'package:app_movil_comunidad/models/persona.dart';
import 'package:archive/archive.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Genera los reportes oficiales rellenando las plantillas de
/// `assets/reports` (un .xlsx y un .docx son archivos zip con XML dentro).
class Reportes {
  static const _plantillaFicha = 'assets/reports/ficha_comunidad.xlsx';
  static const _plantillaConvivencia =
      'assets/reports/formato_convivencias.docx';

  // ===========================================================
  // FICHA DE LA COMUNIDAD (Excel)
  // ===========================================================

  static Future<String> exportarFicha() async {
    final d = await _Datos.cargar();
    final c = d.comunidad;
    final celdas = <String, Object?>{};

    if (c != null) {
      celdas['C8'] = c.tipoParroquia.isEmpty ? null : c.tipoParroquia;
      celdas['C12'] = c.parroquia;
      celdas['C16'] = _ordinal(c.numero);
      celdas['C17'] = _serialExcel(c.fechaNacimiento);
      celdas['C18'] = [
        c.catequistaComunidad,
        c.catequistaParroquia,
      ].where((s) => s.isNotEmpty).join(' - ');
      celdas['C19'] = c.catequista;
      celdas['C29'] = _pasoFicha(c.pasoActual);
      celdas['C30'] = _serialExcel(c.fechaPaso);
      celdas['C31'] = c.huboRito == 1 ? 'Si' : 'No';
    }

    celdas['C22'] = d.matrimonios;
    celdas['C23'] = d.solos('M').length;
    celdas['C24'] = d.solos('F').length;
    celdas['C25'] = d.presbiteros.length;
    celdas['C27'] = d.personas.length;

    void persona(int fila, Persona? per, {int? filaCorreo}) {
      if (per == null) return;
      celdas['B$fila'] = per.nombreCompleto;
      celdas['C$fila'] = per.direccion;
      celdas['E$fila'] = per.telefono;
      if (filaCorreo != null) celdas['D$filaCorreo'] = per.correo;
    }

    void lista(int desde, int hasta, Iterable<Persona> ps) {
      var fila = desde;
      for (final per in ps) {
        if (fila > hasta) break;
        persona(fila++, per);
      }
    }

    persona(35, d.cargo('Responsable').firstOrNull, filaCorreo: 36);
    persona(38, d.cargo('Viceresponsable').firstOrNull, filaCorreo: 39);
    lista(41, 45, d.presbiteros);
    lista(47, 51, d.cargo('Corresponsable'));

    // Hasta 4 equipos de catequistas: responsable + correo, luego 5 miembros.
    for (var i = 0; i < d.equiposCatequistas.length && i < 4; i++) {
      final base = 53 + i * 8;
      final miembros = d.equiposCatequistas[i];
      persona(base, miembros.firstOrNull, filaCorreo: base + 1);
      lista(base + 2, base + 6, miembros.skip(1));
    }
    celdas['D85'] = d.equiposCatequistas.fold<int>(0, (s, e) => s + e.length);

    // Carismas (las zonas de misión y seminarios no se registran en la app).
    lista(90, 97, d.carisma('Itinerante'));
    lista(100, 107, d.carisma('Familia en misión'));
    lista(110, 114, d.carisma('Seminarista'));
    persona(118, d.responsableServicio('Salmistas'));
    persona(120, d.responsableServicio('Lectores'));
    persona(122, d.responsableServicio('Ostiarios'));
    persona(124, d.responsableServicio('Didáscalos'));

    celdas['D127'] = d.cargo('Responsable').firstOrNull?.nombreCompleto;
    celdas['D128'] = _serialExcel(
      DateFormat('yyyy-MM-dd').format(DateTime.now()),
    );

    final bytes = await _editarZip(_plantillaFicha, {
      'xl/worksheets/sheet1.xml': (xml) {
        celdas.forEach((ref, v) => xml = _setCelda(xml, ref, v));
        return xml;
      },
      // Excel recalcula las fórmulas (hoja de impresión) al abrir.
      'xl/workbook.xml': (xml) => xml.contains('<calcPr')
          ? xml.replaceFirst('<calcPr', '<calcPr fullCalcOnLoad="1"')
          : xml.replaceFirst(
              '</workbook>',
              '<calcPr fullCalcOnLoad="1"/></workbook>',
            ),
    });
    return _descargar(bytes, 'Ficha Comunidad ${c?.numero ?? ''}.xlsx'.trim());
  }

  static const _ordinales = [
    'Primera',
    'Segunda',
    'Tercera',
    'Cuarta',
    'Quinta',
    'Sexta',
    'Séptima',
    'Octava',
    'Novena',
    'Décima',
    'Undécima',
    'Duodécima',
    'Décimo tercera',
    'Décimo cuarta',
    'Décimo quinta',
    'Décimo sexta',
    'Décimo séptima',
    'Décimo octava',
    'Décimo novena',
    'Vigésima',
    'Vigésimo primera',
    'Vigésimo segunda',
    'Vigésimo tercera',
    'Vigésimo cuarta',
    'Vigésimo quinta',
    'Vigésimo sexta',
    'Vigésimo séptima',
    'Vigésimo octava',
    'Vigésimo novena',
    'Trigésima',
  ];

  /// La plantilla espera el número de comunidad como en su lista desplegable.
  static String _ordinal(String numero) {
    final n = int.tryParse(numero.trim());
    return n != null && n >= 1 && n <= _ordinales.length
        ? _ordinales[n - 1]
        : numero;
  }

  static const _pasos = {
    'Primer escrutinio': 'I Escrutinio',
    'Shemá': 'Shema',
    'Segundo escrutinio': 'II Escrutinio',
    'Iniciación a la oración': 'Iniciación a la Oración',
    'Traditio Symboli': 'Traditio',
    'Redditio Symboli': 'Redditio',
    'Padre Nuestro': 'I Padre Nuestro',
    'Elección': 'I Elección',
    'Renovación de promesas bautismales': 'RPB',
  };

  static String? _pasoFicha(String paso) =>
      paso.isEmpty ? null : _pasos[paso] ?? paso;

  /// Fecha 'yyyy-MM-dd' a número de serie de Excel.
  static int? _serialExcel(String fecha) {
    final f = DateTime.tryParse(fecha);
    if (f == null) return null;
    return DateTime.utc(
      f.year,
      f.month,
      f.day,
    ).difference(DateTime.utc(1899, 12, 30)).inDays;
  }

  /// Escribe un valor en la celda conservando su estilo.
  static String _setCelda(String xml, String ref, Object? valor) {
    if (valor == null || (valor is String && valor.trim().isEmpty)) return xml;
    final fila = ref.replaceAll(RegExp(r'[A-Z]'), '');
    final col = ref.replaceAll(RegExp(r'\d'), '');

    String celda(String estilo) => valor is num
        ? '<c r="$ref"$estilo><v>$valor</v></c>'
        : '<c r="$ref"$estilo t="inlineStr"><is><t xml:space="preserve">'
              '${_esc(valor.toString())}</t></is></c>';

    final existente = RegExp(
      '<c r="$ref"([^>]*?)(?:/>|>.*?</c>)',
      dotAll: true,
    ).firstMatch(xml);
    if (existente != null) {
      final s = RegExp(r' s="\d+"').firstMatch(existente[1]!)?[0] ?? '';
      return xml.replaceRange(existente.start, existente.end, celda(s));
    }

    final row = RegExp(
      '<row r="$fila"[^>]*?(/>|>(.*?)</row>)',
      dotAll: true,
    ).firstMatch(xml);
    if (row == null) return xml;
    if (row[1] == '/>') {
      final abierta = row[0]!.replaceFirst('/>', '>');
      return xml.replaceRange(row.start, row.end, '$abierta${celda('')}</row>');
    }
    // Inserta antes de la primera celda de una columna posterior.
    final inicioCeldas = row.start + row[0]!.indexOf('>') + 1;
    for (final c in RegExp(r'<c r="([A-Z]+)\d+"').allMatches(row[2]!)) {
      final otra = c[1]!;
      if (otra.length > col.length ||
          (otra.length == col.length && otra.compareTo(col) > 0)) {
        final pos = inicioCeldas + c.start;
        return xml.replaceRange(pos, pos, celda(''));
      }
    }
    final fin = row.end - '</row>'.length;
    return xml.replaceRange(fin, fin, celda(''));
  }

  // ===========================================================
  // FORMATO DE CONVIVENCIAS (Word)
  // ===========================================================

  static Future<String> exportarConvivencia({
    required String convivencia,
    required String fecha,
  }) async {
    final d = await _Datos.cargar();
    final c = d.comunidad;
    final resp = d.cargo('Responsable').firstOrNull;
    final presb = d.presbiteros.length;
    final semin = d.carisma('Seminarista').length;
    final mujeres = d.solos('F', menores: false).length;
    final mujeresMen = d.solos('F', menores: true).length;
    final hombres = d.solos('M', menores: false).length;
    final hombresMen = d.solos('M', menores: true).length;
    final total =
        presb +
        d.matrimonios * 2 +
        mujeres +
        mujeresMen +
        hombres +
        hombresMen +
        semin;
    String n(int v) => v == 0 ? '' : '$v';

    // Párrafo -> {índice de <w:t> dentro del párrafo: texto}.
    final valores = <int, Map<int, String>>{
      3: {1: c?.parroquia.toUpperCase() ?? ''},
      4: {1: c?.numero ?? ''},
      5: {1: convivencia},
      6: {1: fecha},
      7: {
        1: d.presbiteros.firstOrNull?.nombreCompleto ?? '',
        2: '',
        3: '',
        4: '',
        5: '',
      },
      8: {2: resp?.nombreCompleto ?? ''},
      10: {2: resp?.correo ?? ''},
      11: {1: resp?.telefono ?? ''},
      16: {3: n(presb), 4: '', 5: '', 6: '', 7: ''},
      18: {1: '', 2: n(d.matrimonios), 3: '', 6: n(d.matrimonios * 2)},
      19: {0: ''},
      20: {3: n(mujeres)},
      22: {1: n(mujeresMen), 2: '', 3: '', 4: '', 5: ''},
      24: {2: n(hombres), 3: '', 4: '', 5: '', 6: ''},
      26: {1: n(hombresMen), 2: '', 3: '', 4: '', 5: ''},
      28: {2: n(semin), 3: '', 4: '', 5: '', 6: ''},
      30: {4: '$total'},
      37: {1: ' ${DateFormat('dd/MM/yyyy').format(DateTime.now())}'},
      40: {1: resp?.nombreCompleto ?? ''},
    };

    final bytes = await _editarZip(_plantillaConvivencia, {
      'word/document.xml': (xml) {
        var i = 0;
        return xml.replaceAllMapped(
          RegExp(r'<w:p[ >].*?</w:p>', dotAll: true),
          (m) {
            final cambios = valores[i++];
            if (cambios == null) return m[0]!;
            var t = 0;
            return m[0]!.replaceAllMapped(
              RegExp(r'<w:t(?: [^>]*)?>(.*?)</w:t>', dotAll: true),
              (r) {
                final nuevo = cambios[t++];
                return nuevo == null
                    ? r[0]!
                    : '<w:t xml:space="preserve">${_esc(nuevo)}</w:t>';
              },
            );
          },
        );
      },
    });
    return _descargar(
      bytes,
      'Convivencia ${c?.numero ?? ''} - $convivencia.docx'.replaceAll(
        RegExp(r'[\\/:*?"<>|]'),
        '-',
      ),
    );
  }

  // ===========================================================
  // UTILIDADES
  // ===========================================================

  static Future<List<int>> _editarZip(
    String asset,
    Map<String, String Function(String)> cambios,
  ) async {
    final data = await rootBundle.load(asset);
    final original = ZipDecoder().decodeBytes(data.buffer.asUint8List());
    final salida = Archive();
    for (final f in original.files) {
      if (!f.isFile) continue;
      final editar = cambios[f.name];
      List<int> contenido = f.content as List<int>;
      if (editar != null) {
        contenido = utf8.encode(editar(utf8.decode(contenido)));
      }
      salida.addFile(ArchiveFile(f.name, contenido.length, contenido));
    }
    return ZipEncoder().encode(salida)!;
  }

  /// Guarda el archivo en Descargas (Android) o en Documentos (iOS, visible
  /// en la app Archivos) y devuelve la ruta.
  static Future<String> _descargar(List<int> bytes, String nombre) async {
    if (Platform.isAndroid) {
      try {
        final file = File(p.join('/storage/emulated/0/Download', nombre));
        await file.writeAsBytes(bytes, flush: true);
        return file.path;
      } on FileSystemException {
        // Sin acceso a Descargas: se usa la carpeta externa de la app.
      }
    }
    final dir = Platform.isAndroid
        ? (await getExternalStorageDirectory() ??
              await getApplicationDocumentsDirectory())
        : await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, nombre));
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  static String _esc(String s) => s
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;');
}

/// Datos de la comunidad que necesitan ambos reportes.
class _Datos {
  final Comunidad? comunidad;
  final List<Persona> personas;
  final Map<int, Persona> porId;
  final List<Map<String, dynamic>> equipo;
  final List<Map<String, dynamic>> carismas;
  final List<List<Persona>> equiposCatequistas;
  final Map<String, Persona?> responsables;

  _Datos(
    this.comunidad,
    this.personas,
    this.equipo,
    this.carismas,
    this.equiposCatequistas,
    this.responsables,
  ) : porId = {for (final p in personas) p.id!: p};

  static Future<_Datos> cargar() async {
    final personas = await DBHelper.getPersonas();
    final porId = {for (final p in personas) p.id!: p};
    final equipos = <List<Persona>>[];
    for (final e in await DBHelper.getEquiposCatequistas()) {
      final miembros = await DBHelper.getMiembrosEquipoCatequista(e['id']);
      equipos.add([
        for (final m in miembros)
          if (porId[m['persona_id']] != null) porId[m['persona_id']]!,
      ]);
    }
    Future<Persona?> resp(String tipo) async {
      final m = (await DBHelper.getServicio(
        tipo,
      )).where((s) => s['es_responsable'] == 1).firstOrNull;
      return m == null ? null : porId[m['persona_id']];
    }

    return _Datos(
      await DBHelper.obtenerComunidad(),
      personas,
      await DBHelper.getEquipo(),
      await DBHelper.getCarismas(),
      equipos,
      {
        'Salmistas': await resp('Salmistas'),
        'Lectores': await resp('Lectores'),
        'Ostiarios': await resp('Ostiarios'),
        'Didáscalos': await resp('Didáscalos'),
      },
    );
  }

  Iterable<Persona> _ids(Iterable<Map<String, dynamic>> filas) =>
      filas.map((f) => porId[f['persona_id']]).whereType<Persona>();

  Iterable<Persona> cargo(String cargo) =>
      _ids(equipo.where((m) => m['cargo'] == cargo));

  Iterable<Persona> carisma(String tipo) =>
      _ids(carismas.where((c) => c['tipo'] == tipo));

  Persona? responsableServicio(String tipo) => responsables[tipo];

  List<Persona> get presbiteros => carisma('Presbítero').toList();

  int get matrimonios => personas.where((p) => p.conyugeId != null).length ~/ 2;

  /// Personas sin cónyuge del sexo dado (sin presbíteros ni seminaristas).
  /// `menores`: null = todas, true = menores de 18, false = adultos.
  List<Persona> solos(String sexo, {bool? menores}) {
    final excluir = {
      ...presbiteros.map((p) => p.id),
      ...carisma('Seminarista').map((p) => p.id),
    };
    return personas.where((p) {
      if (p.sexo != sexo || p.conyugeId != null || excluir.contains(p.id)) {
        return false;
      }
      if (menores == null) return true;
      return _esMenor(p) == menores;
    }).toList();
  }

  static bool _esMenor(Persona p) {
    final n = DateTime.tryParse(p.fechaNacimiento ?? '');
    if (n == null) return false;
    final hoy = DateTime.now();
    var edad = hoy.year - n.year;
    if (hoy.month < n.month || (hoy.month == n.month && hoy.day < n.day))
      edad--;
    return edad < 18;
  }
}
