import 'dart:convert';
import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

class LocalCipherStore {
  LocalCipherStore({FlutterSecureStorage? secureStorage})
      : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  static const _databaseName = 'cryptosafe_mobile.db';
  static const _passphraseKey = 'cryptosafe_mobile_sqlcipher_passphrase';

  final FlutterSecureStorage _secureStorage;
  Database? _database;

  Future<Database> _openDatabase() async {
    if (_database != null) {
      return _database!;
    }

    final directory = await getApplicationDocumentsDirectory();
    final dbPath = p.join(directory.path, _databaseName);
    final passphrase = await _loadOrCreatePassphrase();

    _database = await openDatabase(
      dbPath,
      password: passphrase,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE app_state (
            key TEXT PRIMARY KEY,
            value TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
        ''');
      },
    );
    return _database!;
  }

  Future<String> _loadOrCreatePassphrase() async {
    final saved = await _secureStorage.read(key: _passphraseKey);
    if (saved != null && saved.isNotEmpty) {
      return saved;
    }

    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    final passphrase = base64UrlEncode(bytes);
    await _secureStorage.write(key: _passphraseKey, value: passphrase);
    return passphrase;
  }

  Future<String?> readValue(String key) async {
    final db = await _openDatabase();
    final rows = await db.query(
      'app_state',
      columns: const ['value'],
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );
    if (rows.isEmpty) {
      return null;
    }
    return rows.first['value'] as String?;
  }

  Future<void> writeValue(String key, String value) async {
    final db = await _openDatabase();
    await db.insert(
      'app_state',
      {
        'key': key,
        'value': value,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteValue(String key) async {
    final db = await _openDatabase();
    await db.delete('app_state', where: 'key = ?', whereArgs: [key]);
  }

  Future<void> clear() async {
    final db = await _openDatabase();
    await db.delete('app_state');
  }

  Future<void> clearSession() async {
    await deleteValue('session_cookies');
    await deleteValue('last_url');
    await deleteValue('last_userid');
  }

  Future<String?> loadBaseUrl() => readValue('base_url');

  Future<void> saveBaseUrl(String value) => writeValue('base_url', value);

  Future<String?> loadLastUrl() => readValue('last_url');

  Future<void> saveLastUrl(String value) => writeValue('last_url', value);

  Future<String?> loadLastUserId() => readValue('last_userid');

  Future<void> saveLastUserId(String value) => writeValue('last_userid', value);

  Future<void> dispose() async {
    await _database?.close();
    _database = null;
  }
}
