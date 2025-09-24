import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/gesture_model.dart';
import '../models/workspace_model.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'speakthands.db');
    
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Create workspaces table
    await db.execute('''
      CREATE TABLE workspaces(
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT NOT NULL,
        language TEXT NOT NULL,
        imagePath TEXT,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL,
        gestureCount INTEGER DEFAULT 0
      )
    ''');

    // Create gestures table
    await db.execute('''
      CREATE TABLE gestures(
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        workspaceId TEXT NOT NULL,
        thumb INTEGER NOT NULL,
        indexFinger INTEGER NOT NULL,
        middle INTEGER NOT NULL,
        ring INTEGER NOT NULL,
        pinky INTEGER NOT NULL,
        handRotation INTEGER NOT NULL,
        textMappings TEXT NOT NULL,
        audioPath TEXT,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL,
        FOREIGN KEY (workspaceId) REFERENCES workspaces (id) ON DELETE CASCADE
      )
    ''');

    // Create indexes
    await db.execute('CREATE INDEX idx_gestures_workspace ON gestures(workspaceId)');
    await db.execute('CREATE INDEX idx_gestures_created ON gestures(createdAt)');
  }

  // Workspace operations
  Future<String> insertWorkspace(WorkspaceModel workspace) async {
    final db = await database;
    await db.insert('workspaces', workspace.toJson());
    return workspace.id;
  }

  Future<List<WorkspaceModel>> getAllWorkspaces() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'workspaces',
      orderBy: 'updatedAt DESC',
    );

    return List.generate(maps.length, (i) {
      return WorkspaceModel.fromJson(maps[i]);
    });
  }

  Future<WorkspaceModel?> getWorkspace(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'workspaces',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return WorkspaceModel.fromJson(maps.first);
    }
    return null;
  }

  Future<int> updateWorkspace(WorkspaceModel workspace) async {
    final db = await database;
    return await db.update(
      'workspaces',
      workspace.toJson(),
      where: 'id = ?',
      whereArgs: [workspace.id],
    );
  }

  Future<int> deleteWorkspace(String id) async {
    final db = await database;
    return await db.delete(
      'workspaces',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Gesture operations
  Future<String> insertGesture(GestureModel gesture) async {
    final db = await database;
    
    // Convert gesture to database format
    final gestureData = {
      'id': gesture.id,
      'name': gesture.name,
      'workspaceId': gesture.workspaceId,
      'thumb': gesture.sensorData.thumb,
      'indexFinger': gesture.sensorData.indexFinger,
      'middle': gesture.sensorData.middle,
      'ring': gesture.sensorData.ring,
      'pinky': gesture.sensorData.pinky,
      'handRotation': gesture.sensorData.handRotation,
      'textMappings': _encodeTextMappings(gesture.textMappings),
      'audioPath': gesture.audioPath,
      'createdAt': gesture.createdAt.toIso8601String(),
      'updatedAt': gesture.updatedAt.toIso8601String(),
    };

    await db.insert('gestures', gestureData);
    
    // Update gesture count in workspace
    await _updateWorkspaceGestureCount(gesture.workspaceId);
    
    return gesture.id;
  }

  Future<List<GestureModel>> getGesturesByWorkspace(String workspaceId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'gestures',
      where: 'workspaceId = ?',
      whereArgs: [workspaceId],
      orderBy: 'updatedAt DESC',
    );

    return List.generate(maps.length, (i) {
      return _gestureFromMap(maps[i]);
    });
  }

  Future<List<GestureModel>> getAllGestures() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'gestures',
      orderBy: 'updatedAt DESC',
    );

    return List.generate(maps.length, (i) {
      return _gestureFromMap(maps[i]);
    });
  }

  Future<GestureModel?> getGesture(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'gestures',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return _gestureFromMap(maps.first);
    }
    return null;
  }

  Future<int> updateGesture(GestureModel gesture) async {
    final db = await database;
    
    final gestureData = {
      'id': gesture.id,
      'name': gesture.name,
      'workspaceId': gesture.workspaceId,
      'thumb': gesture.sensorData.thumb,
      'indexFinger': gesture.sensorData.indexFinger,
      'middle': gesture.sensorData.middle,
      'ring': gesture.sensorData.ring,
      'pinky': gesture.sensorData.pinky,
      'handRotation': gesture.sensorData.handRotation,
      'textMappings': _encodeTextMappings(gesture.textMappings),
      'audioPath': gesture.audioPath,
      'createdAt': gesture.createdAt.toIso8601String(),
      'updatedAt': gesture.updatedAt.toIso8601String(),
    };

    return await db.update(
      'gestures',
      gestureData,
      where: 'id = ?',
      whereArgs: [gesture.id],
    );
  }

  Future<int> deleteGesture(String id) async {
    final db = await database;
    
    // Get gesture to find workspace
    final gesture = await getGesture(id);
    
    final result = await db.delete(
      'gestures',
      where: 'id = ?',
      whereArgs: [id],
    );
    
    // Update gesture count in workspace
    if (gesture != null) {
      await _updateWorkspaceGestureCount(gesture.workspaceId);
    }
    
    return result;
  }

  // Helper methods
  GestureModel _gestureFromMap(Map<String, dynamic> map) {
    return GestureModel(
      id: map['id'] as String,
      name: map['name'] as String,
      workspaceId: map['workspaceId'] as String,
      sensorData: SensorData(
        thumb: map['thumb'] as int,
        indexFinger: map['indexFinger'] as int,
        middle: map['middle'] as int,
        ring: map['ring'] as int,
        pinky: map['pinky'] as int,
        handRotation: map['handRotation'] as int,
      ),
      textMappings: _decodeTextMappings(map['textMappings'] as String),
      audioPath: map['audioPath'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }

  String _encodeTextMappings(Map<String, String> mappings) {
    return mappings.entries
        .map((e) => '${e.key}:${e.value}')
        .join('|');
  }

  Map<String, String> _decodeTextMappings(String encoded) {
    if (encoded.isEmpty) return {};
    
    final Map<String, String> mappings = {};
    final pairs = encoded.split('|');
    
    for (final pair in pairs) {
      final parts = pair.split(':');
      if (parts.length == 2) {
        mappings[parts[0]] = parts[1];
      }
    }
    
    return mappings;
  }

  Future<void> _updateWorkspaceGestureCount(String workspaceId) async {
    final db = await database;
    
    final List<Map<String, dynamic>> result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM gestures WHERE workspaceId = ?',
      [workspaceId],
    );
    
    final count = result.first['count'] as int;
    
    await db.update(
      'workspaces',
      {'gestureCount': count, 'updatedAt': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [workspaceId],
    );
  }

  // Search gestures
  Future<List<GestureModel>> searchGestures(String query) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'gestures',
      where: 'name LIKE ? OR textMappings LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'updatedAt DESC',
    );

    return List.generate(maps.length, (i) {
      return _gestureFromMap(maps[i]);
    });
  }

  // Close database
  Future<void> close() async {
    final db = await database;
    await db.close();
  }
} 