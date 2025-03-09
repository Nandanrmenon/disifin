import 'package:disifin/services/audio_player_service.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseService {
  static Database? _database;

  static Future<void> initDatabase() async {
    if (_database != null) return;
    _database = await openDatabase(
      join(await getDatabasesPath(), 'app_database.db'),
      onCreate: (db, version) {
        db.execute(
          'CREATE TABLE cache(key TEXT PRIMARY KEY, value TEXT)',
        );
        db.execute(
          'CREATE TABLE login_credentials(id INTEGER PRIMARY KEY, username TEXT, password TEXT)',
        );
        db.execute(
          'CREATE TABLE song_history(id INTEGER PRIMARY KEY, name TEXT, imageUrl TEXT, artist TEXT)',
        );
      },
      version: 1,
    );
  }

  static Future<void> saveCache(String key, String value) async {
    await initDatabase();
    await _database?.insert(
      'cache',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<String?> loadCache(String key) async {
    await initDatabase();
    final List<Map<String, dynamic>> maps = await _database?.query(
          'cache',
          where: 'key = ?',
          whereArgs: [key],
        ) ??
        [];
    if (maps.isNotEmpty) {
      return maps.first['value'] as String?;
    }
    return null;
  }

  static Future<void> clearCache(String key) async {
    await initDatabase();
    await _database?.delete(
      'cache',
      where: 'key = ?',
      whereArgs: [key],
    );
  }

  static Future<void> saveLoginCredentials(
      String username, String password) async {
    await initDatabase();
    await _database?.insert(
      'login_credentials',
      {'username': username, 'password': password},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<Map<String, String>?> loadLoginCredentials() async {
    await initDatabase();
    final List<Map<String, dynamic>> maps =
        await _database?.query('login_credentials') ?? [];
    if (maps.isNotEmpty) {
      return {
        'username': maps.first['username'] as String,
        'password': maps.first['password'] as String,
      };
    }
    return null;
  }

  static Future<void> clearLoginCredentials() async {
    await initDatabase();
    await _database?.delete('login_credentials');
  }

  static Future<void> saveSongHistory(TrackInfo trackInfo) async {
    await initDatabase();
    await _database?.insert(
      'song_history',
      {
        'name': trackInfo.name,
        'imageUrl': trackInfo.imageUrl,
        'artist': trackInfo.artist,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<List<TrackInfo>> loadSongHistory() async {
    await initDatabase();
    final List<Map<String, dynamic>> maps =
        await _database?.query('song_history') ?? [];
    return List.generate(maps.length, (i) {
      return TrackInfo(
        name: maps[i]['name'] as String?,
        imageUrl: maps[i]['imageUrl'] as String?,
        artist: maps[i]['artist'] as String?,
      );
    });
  }

  static Future<void> clearSongHistory() async {
    await initDatabase();
    await _database?.delete('song_history');
  }
}
