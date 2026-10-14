import 'package:app_movil_comunidad/models/comunidad.dart';
import 'package:app_movil_comunidad/models/signo.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/persona.dart';

/// Esquema (v2). Todo gira alrededor de `personas`:
///
///   personas ─┬─< equipo                       (1 cargo por persona)
///             ├─< equipo_catequistas_miembros >─ equipos_catequistas
///             ├─< signo_responsables          >─ signos
///             ├─< grupo_miembros              >─ grupos (tipo: Palabra, ...)
///             └─< carismas                     (varios por persona)
///   comunidad ── equipo_catequista_id ──> equipos_catequistas
class DBHelper {
  static const _version = 3;
  static Database? _database;

  static Future<Database> getDatabase() async {
    if (_database != null) return _database!;
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'comunidad.db');

    _database = await openDatabase(
      path,
      version: _version,
      // Se activa en onOpen (no en onConfigure) para que las migraciones
      // puedan recrear tablas sin que las FK lo impidan.
      onOpen: (db) async => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: (db, version) async {
        await _crearPersonas(db);
        await _crearEquiposCatequistas(db);
        await _crearComunidad(db);
        await _crearEquipo(db);
        await _crearMiembrosCatequistas(db);
        await _crearSignos(db);
        await _crearSignoResponsables(db);
        await _crearGrupos(db);
        await _crearCarismas(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) await _migrarV2(db);
        if (oldVersion < 3) {
          await db.execute(
            'ALTER TABLE comunidad ADD COLUMN catequistaComunidad TEXT',
          );
          await db.execute(
            'ALTER TABLE comunidad ADD COLUMN catequistaParroquia TEXT',
          );
        }
      },
    );

    return _database!;
  }

  // ===========================================================
  // ESQUEMA
  // ===========================================================

  static Future<void> _crearPersonas(DatabaseExecutor db) => db.execute('''
    CREATE TABLE personas (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      nombres TEXT NOT NULL,
      apellidos TEXT NOT NULL,
      sexo TEXT,
      fechaNacimiento TEXT,
      documento TEXT,
      telefono TEXT,
      direccion TEXT,
      correo TEXT,
      estadoCivil TEXT,
      conyugeId INTEGER REFERENCES personas(id) ON DELETE SET NULL,
      fechaAniversario TEXT,
      numeroHijos INTEGER
    )
  ''');

  static Future<void> _crearComunidad(DatabaseExecutor db) => db.execute('''
    CREATE TABLE comunidad (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      numero TEXT,
      fechaNacimiento TEXT,
      parroquia TEXT,
      tipoParroquia TEXT,
      pasoActual TEXT,
      fechaPaso TEXT,
      huboRito INTEGER DEFAULT 0,
      catequista TEXT,
      catequistaComunidad TEXT,
      catequistaParroquia TEXT,
      equipo_catequista_id INTEGER
        REFERENCES equipos_catequistas(id) ON DELETE SET NULL
    )
  ''');

  static Future<void> _crearEquipo(DatabaseExecutor db) => db.execute('''
    CREATE TABLE equipo (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      persona_id INTEGER NOT NULL UNIQUE
        REFERENCES personas(id) ON DELETE CASCADE,
      cargo TEXT NOT NULL
    )
  ''');

  static Future<void> _crearEquiposCatequistas(DatabaseExecutor db) =>
      db.execute('''
    CREATE TABLE equipos_catequistas (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      nombre TEXT NOT NULL UNIQUE
    )
  ''');

  static Future<void> _crearMiembrosCatequistas(DatabaseExecutor db) =>
      db.execute('''
    CREATE TABLE equipo_catequistas_miembros (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      equipo_id INTEGER NOT NULL
        REFERENCES equipos_catequistas(id) ON DELETE CASCADE,
      persona_id INTEGER NOT NULL REFERENCES personas(id) ON DELETE CASCADE,
      rol TEXT NOT NULL,
      UNIQUE(equipo_id, persona_id)
    )
  ''');

  static Future<void> _crearSignos(DatabaseExecutor db) => db.execute('''
    CREATE TABLE signos (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      nombre TEXT NOT NULL,
      cantidad INTEGER NOT NULL DEFAULT 0,
      fechaCompra TEXT,
      fechaEntrega TEXT,
      observacion TEXT
    )
  ''');

  static Future<void> _crearSignoResponsables(DatabaseExecutor db) =>
      db.execute('''
    CREATE TABLE signo_responsables (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      signo_id INTEGER NOT NULL REFERENCES signos(id) ON DELETE CASCADE,
      persona_id INTEGER NOT NULL REFERENCES personas(id) ON DELETE CASCADE,
      UNIQUE(signo_id, persona_id)
    )
  ''');

  static Future<void> _crearGrupos(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE grupos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        tipo TEXT NOT NULL,
        nombre TEXT NOT NULL,
        UNIQUE(tipo, nombre)
      )
    ''');
    // `tipo` se repite aquí para garantizar 1 grupo por persona y tipo.
    await db.execute('''
      CREATE TABLE grupo_miembros (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        grupo_id INTEGER NOT NULL REFERENCES grupos(id) ON DELETE CASCADE,
        tipo TEXT NOT NULL,
        persona_id INTEGER NOT NULL REFERENCES personas(id) ON DELETE CASCADE,
        UNIQUE(tipo, persona_id)
      )
    ''');
  }

  static Future<void> _crearCarismas(DatabaseExecutor db) => db.execute('''
    CREATE TABLE carismas (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      persona_id INTEGER NOT NULL REFERENCES personas(id) ON DELETE CASCADE,
      tipo TEXT NOT NULL,
      UNIQUE(persona_id, tipo)
    )
  ''');

  /// v1 -> v2: añade restricciones, responsables de signos y grupos por tipo
  /// conservando los datos existentes.
  static Future<void> _migrarV2(Database db) async {
    await db.execute('ALTER TABLE personas ADD COLUMN sexo TEXT');
    await db.execute(
      'ALTER TABLE comunidad ADD COLUMN equipo_catequista_id INTEGER',
    );

    // equipo: una sola fila por persona (se conserva la más reciente)
    await db.execute('ALTER TABLE equipo RENAME TO equipo_old');
    await _crearEquipo(db);
    await db.execute('''
      INSERT OR IGNORE INTO equipo (persona_id, cargo)
      SELECT persona_id, cargo FROM equipo_old ORDER BY id DESC
    ''');
    await db.execute('DROP TABLE equipo_old');

    await db.execute(
      'ALTER TABLE equipo_catequistas_miembros RENAME TO ecm_old',
    );
    await _crearMiembrosCatequistas(db);
    await db.execute('''
      INSERT OR IGNORE INTO equipo_catequistas_miembros (equipo_id, persona_id, rol)
      SELECT equipo_id, persona_id, rol FROM ecm_old
    ''');
    await db.execute('DROP TABLE ecm_old');

    await _crearSignoResponsables(db);

    // grupo_persona (un único grupo genérico) -> grupos de Palabra
    await _crearGrupos(db);
    await db.execute('''
      INSERT OR IGNORE INTO grupos (tipo, nombre)
      SELECT DISTINCT 'Palabra', grupo FROM grupo_persona
    ''');
    await db.execute('''
      INSERT OR IGNORE INTO grupo_miembros (grupo_id, tipo, persona_id)
      SELECT g.id, 'Palabra', gp.persona_id
      FROM grupo_persona gp
      JOIN grupos g ON g.tipo = 'Palabra' AND g.nombre = gp.grupo
    ''');
    await db.execute('DROP TABLE grupo_persona');

    await db.execute('ALTER TABLE carismas RENAME TO carismas_old');
    await _crearCarismas(db);
    await db.execute('''
      INSERT OR IGNORE INTO carismas (persona_id, tipo)
      SELECT persona_id, tipo FROM carismas_old
      WHERE persona_id IS NOT NULL AND tipo IS NOT NULL
    ''');
    await db.execute('DROP TABLE carismas_old');
  }

  // ===========================================================
  // PERSONAS
  // ===========================================================

  static Future<int> insertPersona(Persona persona) async {
    final db = await getDatabase();
    final id = await db.insert('personas', persona.toMap()..remove('id'));
    persona.id = id;
    await _sincronizarConyuge(db, persona);
    return id;
  }

  static Future<List<Persona>> getPersonas() async {
    final db = await getDatabase();
    final maps = await db.query(
      'personas',
      orderBy: 'nombres COLLATE NOCASE, apellidos COLLATE NOCASE',
    );
    return maps.map(Persona.fromMap).toList();
  }

  static Future<void> updatePersona(Persona persona) async {
    final db = await getDatabase();
    await db.update(
      'personas',
      persona.toMap(),
      where: 'id = ?',
      whereArgs: [persona.id],
    );
    await _sincronizarConyuge(db, persona);
  }

  /// Mantiene el vínculo de matrimonio en ambos sentidos.
  static Future<void> _sincronizarConyuge(Database db, Persona p) async {
    // Desvincula a quien apuntaba a esta persona y ya no es su cónyuge
    await db.rawUpdate(
      'UPDATE personas SET conyugeId = NULL WHERE conyugeId = ? AND id IS NOT ?',
      [p.id, p.conyugeId],
    );
    if (p.estadoCivil == 'Casado' && p.conyugeId != null) {
      // Si el nuevo cónyuge estaba vinculado a otra persona, se libera
      await db.rawUpdate(
        'UPDATE personas SET conyugeId = NULL WHERE conyugeId = ? AND id != ?',
        [p.conyugeId, p.id],
      );
      await db.update(
        'personas',
        {'conyugeId': p.id, 'estadoCivil': 'Casado'},
        where: 'id = ?',
        whereArgs: [p.conyugeId],
      );
    } else if (p.conyugeId != null) {
      await db.update(
        'personas',
        {'conyugeId': null},
        where: 'id = ?',
        whereArgs: [p.id],
      );
    }
  }

  static Future<void> deletePersona(int id) async {
    final db = await getDatabase();
    await db.delete('personas', where: 'id = ?', whereArgs: [id]);
  }

  // ===========================================================
  // COMUNIDAD (solo una)
  // ===========================================================

  static Future<int> insertarComunidad(Comunidad comunidad) async {
    final db = await getDatabase();
    return db.insert('comunidad', comunidad.toMap()..remove('id'));
  }

  static Future<Comunidad?> obtenerComunidad() async {
    final db = await getDatabase();
    final result = await db.query('comunidad', limit: 1);
    return result.isEmpty ? null : Comunidad.fromMap(result.first);
  }

  static Future<int> actualizarComunidad(Comunidad comunidad) async {
    final db = await getDatabase();
    return db.update(
      'comunidad',
      comunidad.toMap(),
      where: 'id = ?',
      whereArgs: [comunidad.id],
    );
  }

  /// Totales para el panel principal.
  static Future<Map<String, int>> getResumen() async {
    final db = await getDatabase();
    Future<int> count(String sql) async =>
        Sqflite.firstIntValue(await db.rawQuery(sql)) ?? 0;
    return {
      'personas': await count('SELECT COUNT(*) FROM personas'),
      'matrimonios': await count(
        "SELECT COUNT(*) / 2 FROM personas WHERE conyugeId IS NOT NULL",
      ),
      'equipo': await count('SELECT COUNT(*) FROM equipo'),
      'catequistas': await count('SELECT COUNT(*) FROM equipos_catequistas'),
      'signos': await count('SELECT COUNT(*) FROM signos'),
      'grupos': await count('SELECT COUNT(*) FROM grupos'),
      'carismas': await count('SELECT COUNT(*) FROM carismas'),
    };
  }

  // ===========================================================
  // EQUIPO DE RESPONSABLES
  // ===========================================================

  static Future<List<Map<String, dynamic>>> getEquipo() async {
    final db = await getDatabase();
    return db.rawQuery('''
      SELECT e.id, e.persona_id, e.cargo,
             p.nombres || ' ' || p.apellidos AS nombre_completo, p.telefono
      FROM equipo e
      JOIN personas p ON e.persona_id = p.id
      ORDER BY CASE e.cargo
        WHEN 'Responsable' THEN 0 WHEN 'Viceresponsable' THEN 1 ELSE 2 END,
        p.nombres
    ''');
  }

  /// Inserta o cambia el cargo. Si hay `id` se actualiza esa fila.
  static Future<void> guardarMiembroEquipo({
    int? id,
    required int personaId,
    required String cargo,
  }) async {
    final db = await getDatabase();
    final data = {'persona_id': personaId, 'cargo': cargo};
    if (id != null) {
      await db.update('equipo', data, where: 'id = ?', whereArgs: [id]);
    } else {
      await db.insert(
        'equipo',
        data,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  static Future<void> deleteMiembroEquipo(int miembroId) async {
    final db = await getDatabase();
    await db.delete('equipo', where: 'id = ?', whereArgs: [miembroId]);
  }

  // ===========================================================
  // EQUIPOS DE CATEQUISTAS
  // ===========================================================

  static Future<int> insertEquipoCatequista(String nombre) async {
    final db = await getDatabase();
    final existing = await db.query(
      'equipos_catequistas',
      where: 'nombre = ?',
      whereArgs: [nombre],
    );
    if (existing.isNotEmpty) return existing.first['id'] as int;
    return db.insert('equipos_catequistas', {'nombre': nombre});
  }

  static Future<void> renombrarEquipoCatequista(int id, String nombre) async {
    final db = await getDatabase();
    await db.update(
      'equipos_catequistas',
      {'nombre': nombre},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<void> deleteEquipoCatequista(int id) async {
    final db = await getDatabase();
    await db.delete('equipos_catequistas', where: 'id = ?', whereArgs: [id]);
  }

  static Future<List<Map<String, dynamic>>> getEquiposCatequistas() async {
    final db = await getDatabase();
    return db.rawQuery('''
      SELECT e.id, e.nombre, COUNT(m.id) AS total
      FROM equipos_catequistas e
      LEFT JOIN equipo_catequistas_miembros m ON m.equipo_id = e.id
      GROUP BY e.id
      ORDER BY e.nombre
    ''');
  }

  static Future<void> insertMiembroEquipoCatequista({
    required int equipoId,
    required int personaId,
    required String rol,
  }) async {
    final db = await getDatabase();
    await db.insert('equipo_catequistas_miembros', {
      'equipo_id': equipoId,
      'persona_id': personaId,
      'rol': rol,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<List<Map<String, dynamic>>> getMiembrosEquipoCatequista(
    int equipoId,
  ) async {
    final db = await getDatabase();
    return db.rawQuery(
      '''
      SELECT m.equipo_id, m.persona_id, m.rol,
             p.nombres || ' ' || p.apellidos AS nombre_completo
      FROM equipo_catequistas_miembros m
      JOIN personas p ON p.id = m.persona_id
      WHERE m.equipo_id = ?
      ORDER BY m.rol = 'Responsable' DESC, p.nombres
    ''',
      [equipoId],
    );
  }

  static Future<void> deleteMiembroEquipoCatequista(
    int personaId,
    int equipoId,
  ) async {
    final db = await getDatabase();
    await db.delete(
      'equipo_catequistas_miembros',
      where: 'persona_id = ? AND equipo_id = ?',
      whereArgs: [personaId, equipoId],
    );
  }

  // ===========================================================
  // SIGNOS Y SUS RESPONSABLES
  // ===========================================================

  static Future<int> insertarSigno(Signo signo) async {
    final db = await getDatabase();
    return db.insert('signos', signo.toMap()..remove('id'));
  }

  static Future<List<Signo>> obtenerSignos() async {
    final db = await getDatabase();
    final res = await db.query('signos', orderBy: 'nombre COLLATE NOCASE');
    return res.map(Signo.fromMap).toList();
  }

  static Future<int> actualizarSigno(Signo signo) async {
    final db = await getDatabase();
    return db.update(
      'signos',
      signo.toMap(),
      where: 'id = ?',
      whereArgs: [signo.id],
    );
  }

  static Future<int> eliminarSigno(int id) async {
    final db = await getDatabase();
    return db.delete('signos', where: 'id = ?', whereArgs: [id]);
  }

  /// signo_id -> lista de responsables {persona_id, nombre_completo}
  static Future<Map<int, List<Map<String, dynamic>>>>
  getResponsablesSignos() async {
    final db = await getDatabase();
    final rows = await db.rawQuery('''
      SELECT r.signo_id, r.persona_id,
             p.nombres || ' ' || p.apellidos AS nombre_completo
      FROM signo_responsables r
      JOIN personas p ON p.id = r.persona_id
      ORDER BY p.nombres
    ''');
    final out = <int, List<Map<String, dynamic>>>{};
    for (final r in rows) {
      out.putIfAbsent(r['signo_id'] as int, () => []).add(r);
    }
    return out;
  }

  static Future<void> setResponsablesSigno(
    int signoId,
    List<int> personaIds,
  ) async {
    final db = await getDatabase();
    await db.transaction((txn) async {
      await txn.delete(
        'signo_responsables',
        where: 'signo_id = ?',
        whereArgs: [signoId],
      );
      for (final id in personaIds) {
        await txn.insert('signo_responsables', {
          'signo_id': signoId,
          'persona_id': id,
        });
      }
    });
  }

  // ===========================================================
  // GRUPOS (Palabra, Eucaristía, Artículo, Doméstica)
  // ===========================================================

  static Future<List<Map<String, dynamic>>> getGrupos(String tipo) async {
    final db = await getDatabase();
    return db.query(
      'grupos',
      where: 'tipo = ?',
      whereArgs: [tipo],
      orderBy: 'id',
    );
  }

  static Future<List<Map<String, dynamic>>> getMiembrosGrupos(
    String tipo,
  ) async {
    final db = await getDatabase();
    return db.rawQuery(
      '''
      SELECT gm.grupo_id, gm.persona_id,
             p.nombres || ' ' || p.apellidos AS nombre_completo
      FROM grupo_miembros gm
      JOIN personas p ON p.id = gm.persona_id
      WHERE gm.tipo = ?
      ORDER BY p.nombres
    ''',
      [tipo],
    );
  }

  /// Crea grupos numerados a continuación de los existentes.
  static Future<void> crearGrupos(String tipo, int cantidad) async {
    final db = await getDatabase();
    final existentes = await getGrupos(tipo);
    var n = existentes.length;
    await db.transaction((txn) async {
      for (var i = 0; i < cantidad; i++) {
        n++;
        await txn.insert('grupos', {
          'tipo': tipo,
          'nombre': 'Grupo $n',
        }, conflictAlgorithm: ConflictAlgorithm.ignore);
      }
    });
  }

  static Future<void> renombrarGrupo(int id, String nombre) async {
    final db = await getDatabase();
    await db.update(
      'grupos',
      {'nombre': nombre},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<void> eliminarGrupo(int id) async {
    final db = await getDatabase();
    await db.delete('grupos', where: 'id = ?', whereArgs: [id]);
  }

  static Future<void> eliminarGruposTipo(String tipo) async {
    final db = await getDatabase();
    await db.delete('grupos', where: 'tipo = ?', whereArgs: [tipo]);
  }

  /// Asigna (o mueve) personas a un grupo; cada persona queda en un solo
  /// grupo por tipo.
  static Future<void> asignarAGrupo(
    int grupoId,
    String tipo,
    List<int> personaIds,
  ) async {
    final db = await getDatabase();
    await db.transaction((txn) async {
      for (final id in personaIds) {
        await txn.insert('grupo_miembros', {
          'grupo_id': grupoId,
          'tipo': tipo,
          'persona_id': id,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
  }

  static Future<void> quitarDeGrupo(String tipo, int personaId) async {
    final db = await getDatabase();
    await db.delete(
      'grupo_miembros',
      where: 'tipo = ? AND persona_id = ?',
      whereArgs: [tipo, personaId],
    );
  }

  /// Reemplaza toda la distribución de un tipo: grupoId -> personas.
  static Future<void> guardarDistribucion(
    String tipo,
    Map<int, List<int>> distribucion,
  ) async {
    final db = await getDatabase();
    await db.transaction((txn) async {
      await txn.delete('grupo_miembros', where: 'tipo = ?', whereArgs: [tipo]);
      for (final e in distribucion.entries) {
        for (final personaId in e.value) {
          await txn.insert('grupo_miembros', {
            'grupo_id': e.key,
            'tipo': tipo,
            'persona_id': personaId,
          });
        }
      }
    });
  }

  // ===========================================================
  // CARISMAS
  // ===========================================================

  static Future<List<Map<String, dynamic>>> getCarismas() async {
    final db = await getDatabase();
    return db.rawQuery('''
      SELECT c.id, c.persona_id, c.tipo,
             p.nombres || ' ' || p.apellidos AS nombre_completo
      FROM carismas c
      JOIN personas p ON p.id = c.persona_id
      ORDER BY c.tipo, p.nombres
    ''');
  }

  static Future<void> setCarismasPersona(int personaId, List<String> tipos) async {
    final db = await getDatabase();
    await db.transaction((txn) async {
      await txn.delete(
        'carismas',
        where: 'persona_id = ?',
        whereArgs: [personaId],
      );
      for (final t in tipos) {
        await txn.insert('carismas', {'persona_id': personaId, 'tipo': t});
      }
    });
  }

  static Future<void> setPersonasCarisma(String tipo, List<int> personaIds) async {
    final db = await getDatabase();
    await db.transaction((txn) async {
      await txn.delete('carismas', where: 'tipo = ?', whereArgs: [tipo]);
      for (final id in personaIds) {
        await txn.insert('carismas', {'persona_id': id, 'tipo': tipo});
      }
    });
  }

  static Future<void> deleteCarisma(int id) async {
    final db = await getDatabase();
    await db.delete('carismas', where: 'id = ?', whereArgs: [id]);
  }
}
