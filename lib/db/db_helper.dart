import 'package:app_movil_comunidad/models/comunidad.dart';
import 'package:app_movil_comunidad/models/signo.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/persona.dart';

class DBHelper {
  static Database? _database;
  static Future<Database> getDatabase() async {
    if (_database != null) return _database!;
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'comunidad.db');

    _database = await openDatabase(
      path,
      version: 1,
      onOpen: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) async {
        // Personas
        await db.execute('''
    CREATE TABLE personas (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      nombres TEXT,
      apellidos TEXT,
      fechaNacimiento TEXT,
      documento TEXT,
      telefono TEXT,
      direccion TEXT,
      correo TEXT,
      estadoCivil TEXT,
      conyugeId INTEGER,
      fechaAniversario TEXT,
      numeroHijos INTEGER
    )
  ''');

        // Comunidad (solo una)
        await db.execute('''
    CREATE TABLE comunidad (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      numero TEXT,
      fechaNacimiento TEXT,
      parroquia TEXT,
      pasoActual TEXT,
      catequista TEXT,
      tipoParroquia TEXT,
      fechaPaso TEXT,
      huboRito INTEGER
    )
  ''');

        // Miembros del equipo general
        await db.execute('''
    CREATE TABLE equipo (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      persona_id INTEGER NOT NULL,
      cargo TEXT NOT NULL,
      FOREIGN KEY (persona_id) REFERENCES personas(id) ON DELETE CASCADE
    )
  ''');

        // Equipos de catequistas
        await db.execute('''
    CREATE TABLE equipos_catequistas (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      nombre TEXT NOT NULL
    )
  ''');

        // Miembros de equipos de catequistas
        await db.execute('''
    CREATE TABLE equipo_catequistas_miembros (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      equipo_id INTEGER NOT NULL,
      persona_id INTEGER NOT NULL,
      rol TEXT NOT NULL,
      FOREIGN KEY (equipo_id) REFERENCES equipos_catequistas(id) ON DELETE CASCADE,
      FOREIGN KEY (persona_id) REFERENCES personas(id) ON DELETE CASCADE
    )
  ''');

        // Signos
        await db.execute('''
    CREATE TABLE signos (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      nombre TEXT NOT NULL,
      cantidad INTEGER NOT NULL,
      fechaCompra TEXT NOT NULL,
      fechaEntrega TEXT NOT NULL,
      observacion TEXT
    )
  ''');

        await db.execute('''
    CREATE TABLE grupo_persona (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      persona_id INTEGER NOT NULL,
      grupo TEXT NOT NULL,
      UNIQUE(persona_id),
      FOREIGN KEY (persona_id) REFERENCES personas(id) ON DELETE CASCADE
    )
  ''');

        await db.execute('''
    CREATE TABLE carismas (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      persona_id INTEGER,
      tipo TEXT,
      FOREIGN KEY(persona_id) REFERENCES personas(id)
    )
  ''');
      },
    );

    return _database!;
  }

  // Insertar nueva persona
  static Future<void> insertPersona(Persona persona) async {
    final db = await getDatabase();
    await db.insert(
      'personas',
      persona.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Obtener todas las personas
  static Future<List<Persona>> getPersonas() async {
    final db = await getDatabase();
    final maps = await db.query('personas');
    return List.generate(maps.length, (i) => Persona.fromMap(maps[i]));
  }

  // Actualizar persona
  static Future<void> updatePersona(Persona persona) async {
    final db = await getDatabase();
    await db.update(
      'personas',
      persona.toMap(),
      where: 'id = ?',
      whereArgs: [persona.id],
    );
  }

  // Eliminar persona
  static Future<void> deletePersona(int id) async {
    final db = await getDatabase();
    await db.delete('personas', where: 'id = ?', whereArgs: [id]);
  }

  // Obtener miembros del equipo con nombre completo y cargo
  static Future<List<Map<String, dynamic>>> getEquipo() async {
    final db = await getDatabase();
    return db.rawQuery('''
      SELECT e.id, p.id as persona_id, p.nombres || ' ' || p.apellidos AS nombre_completo, e.cargo
      FROM equipo e
      JOIN personas p ON e.persona_id = p.id
    ''');
  }

  // Insertar o actualizar miembro del equipo
  static Future<void> insertOrUpdateEquipo(Map<String, dynamic> miembro) async {
    final db = await getDatabase();
    await db.insert(
      'equipo',
      miembro,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Eliminar miembro del equipo
  static Future<void> deleteMiembroEquipo(int miembroId) async {
    final db = await getDatabase();
    await db.delete('equipo', where: 'id = ?', whereArgs: [miembroId]);
  }

  static Future<void> insertOrUpdateCatequista(
    Map<String, dynamic> data,
  ) async {
    final db = await getDatabase();
    await db.insert(
      'catequistas',
      data,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<void> deleteCatequista(int personaId) async {
    final db = await getDatabase();
    await db.delete(
      'catequistas',
      where: 'persona_id = ?',
      whereArgs: [personaId],
    );
  }

  static Future<List<Map<String, dynamic>>> getCatequistas() async {
    final db = await getDatabase();
    return db.rawQuery('''
    SELECT persona_id, rol FROM catequistas
  ''');
  }

  static Future<int> insertEquipoCatequista(String nombre) async {
    final db = await getDatabase();

    // Verificar si ya existe
    final existing = await db.query(
      'equipos_catequistas',
      where: 'nombre = ?',
      whereArgs: [nombre],
    );

    if (existing.isNotEmpty) {
      return existing.first['id'] as int;
    }

    return await db.insert('equipos_catequistas', {'nombre': nombre});
  }

  static Future<List<Map<String, dynamic>>> getEquiposCatequistas() async {
    final db = await getDatabase();
    return db.query('equipos_catequistas');
  }

  static Future<void> insertMiembroEquipoCatequista(
    Map<String, dynamic> data,
  ) async {
    final db = await getDatabase();
    await db.insert('equipo_catequistas_miembros', data);
  }

  static Future<List<Map<String, dynamic>>> getMiembrosEquipo(
    int equipoId,
  ) async {
    final db = await getDatabase();
    return db.rawQuery(
      '''
    SELECT p.id, p.nombres, p.apellidos, m.rol
    FROM equipo_catequistas_miembros m
    JOIN personas p ON p.id = m.persona_id
    WHERE m.equipo_id = ?
  ''',
      [equipoId],
    );
  }

  static Future<List<Map<String, dynamic>>> getMiembrosEquipoCatequista(
    int equipoId,
  ) async {
    final db = await getDatabase();

    return await db.rawQuery(
      '''
    SELECT 
      m.equipo_id,
      m.persona_id,
      m.rol,
      p.nombres,
      p.apellidos
    FROM equipo_catequistas_miembros m
    INNER JOIN personas p ON p.id = m.persona_id
    WHERE m.equipo_id = ?
    ORDER BY p.nombres
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

  static Future<int> insertarComunidad(Comunidad comunidad) async {
    final dbClient = await getDatabase();
    return await dbClient.insert(
      'comunidad',
      comunidad.toMap(),
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  static Future<Comunidad?> obtenerComunidad() async {
    final dbClient = await getDatabase();
    final result = await dbClient.query('comunidad', limit: 1);
    if (result.isNotEmpty) {
      return Comunidad.fromMap(result.first);
    }
    return null;
  }

  static Future<int> actualizarComunidad(Comunidad comunidad) async {
    final dbClient = await getDatabase();
    return await dbClient.update(
      'comunidad',
      comunidad.toMap(),
      where: 'id = ?',
      whereArgs: [comunidad.id],
    );
  }

  // Insertar signo
  static Future<int> insertarSigno(Signo signo) async {
    final db = await getDatabase();
    return await db.insert('signos', signo.toMap());
  }

  // Obtener todos los signos
  static Future<List<Signo>> obtenerSignos() async {
    final db = await getDatabase();
    final res = await db.query('signos', orderBy: 'nombre ASC');
    return res.map((e) => Signo.fromMap(e)).toList();
  }

  // Actualizar signo
  static Future<int> actualizarSigno(Signo signo) async {
    final db = await getDatabase();
    return await db.update(
      'signos',
      signo.toMap(),
      where: 'id = ?',
      whereArgs: [signo.id],
    );
  }

  // Eliminar signo
  static Future<int> eliminarSigno(int id) async {
    final db = await getDatabase();
    return await db.delete('signos', where: 'id = ?', whereArgs: [id]);
  }

  // Insertar persona en grupo
  static Future<void> asignarGrupoPersona(int personaId, String grupo) async {
    final db = await getDatabase();
    await db.insert('grupo_persona', {
      'persona_id': personaId,
      'grupo': grupo,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // Eliminar asignación de grupo
  static Future<void> eliminarGrupoPersona(int personaId) async {
    final db = await getDatabase();
    await db.delete(
      'grupo_persona',
      where: 'persona_id = ?',
      whereArgs: [personaId],
    );
  }

  // Obtener todas las personas con grupo
  static Future<List<Map<String, dynamic>>> getPersonasConGrupo() async {
    final db = await getDatabase();
    return db.rawQuery('''
    SELECT p.id, p.nombres, p.apellidos, g.grupo
    FROM personas p
    LEFT JOIN grupo_persona g ON g.persona_id = p.id
    ORDER BY p.apellidos
  ''');
  }

  // Obtener todos los grupos creados (únicos)
  static Future<List<String>> getGruposUnicos() async {
    final db = await getDatabase();
    final result = await db.rawQuery(
      'SELECT DISTINCT grupo FROM grupo_persona',
    );
    return result.map((e) => e['grupo'].toString()).toList();
  }

  // Insertar nuevo grupo sin persona (solo si deseas registrar el nombre del grupo antes de asignar)
  static Future<void> crearGrupoVacio(String nombre) async {
    // puedes registrar los nombres de grupos en otra tabla si lo deseas, por ahora no es necesario
  }

  
static Future<List<Map<String, dynamic>>> getCarismas() async {
  final db = await getDatabase();

  return await db.rawQuery('''
    SELECT 
      c.id,
      c.persona_id,
      c.tipo,
      p.nombres || ' ' || p.apellidos AS nombre_completo
    FROM carismas c
    INNER JOIN personas p ON p.id = c.persona_id
    ORDER BY p.nombres
  ''');
}

static Future<void> insertOrUpdateCarisma(Map<String, dynamic> data) async {
  final db = await getDatabase();

  if (data['id'] != null) {
    await db.update(
      'carismas',
      data,
      where: 'id = ?',
      whereArgs: [data['id']],
    );
  } else {
    await db.insert('carismas', data);
  }
}

static Future<void> deleteCarisma(int id) async {
  final db = await getDatabase();
  await db.delete('carismas', where: 'id = ?', whereArgs: [id]);
}
}
