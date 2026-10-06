import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

abstract interface class DatabaseKeyStore {
  Future<String?> read(String key);

  Future<void> write({required String key, required String value});
}

class _SecureDatabaseKeyStore implements DatabaseKeyStore {
  _SecureDatabaseKeyStore(this._storage);

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write({required String key, required String value}) {
    return _storage.write(key: key, value: value);
  }
}

/// Owns the database encryption key and upgrades legacy plaintext databases.
///
/// The password is generated on-device and kept by the platform's secure
/// storage. It is never written to SQLite, SharedPreferences, or application
/// logs.
class DatabaseEncryptionService {
  static const _keyName = 'barq_database_key_v1';
  static const _encryptedSuffix = '.encrypting';
  static const _backupSuffix = '.plaintext_backup';

  final DatabaseKeyStore _keyStore;

  DatabaseEncryptionService({
    DatabaseKeyStore? keyStore,
    FlutterSecureStorage? secureStorage,
  }) : _keyStore = keyStore ??
            _SecureDatabaseKeyStore(
              secureStorage ??
                  const FlutterSecureStorage(
                    aOptions: AndroidOptions(
                      storageNamespace: 'barq_sms_security',
                      migrateWithBackup: true,
                    ),
                  ),
            );

  Future<String> prepareEncryptedDatabase(String databasePath) async {
    final databaseFile = File(databasePath);
    final temporaryFile = File('$databasePath$_encryptedSuffix');
    final backupFile = File('$databasePath$_backupSuffix');

    await _recoverInterruptedMigration(
      databaseFile: databaseFile,
      temporaryFile: temporaryFile,
      backupFile: backupFile,
    );

    final databaseExists =
        await databaseFile.exists() && await databaseFile.length() > 0;
    final isPlaintext = databaseExists && await _isPlaintext(databaseFile);
    final storedKey = await _keyStore.read(_keyName);

    if (databaseExists && !isPlaintext && storedKey == null) {
      throw StateError(
        'تعذر فتح البيانات المشفرة لأن مفتاح الحماية غير موجود. '
        'قد تكون بيانات التطبيق قد نُقلت من جهاز آخر.',
      );
    }

    final key = storedKey ?? await _createAndStoreKey();

    if (isPlaintext) {
      await _encryptPlaintextDatabase(
        sourceFile: databaseFile,
        temporaryFile: temporaryFile,
        backupFile: backupFile,
        password: key,
      );
    } else if (await backupFile.exists()) {
      // An encrypted main database means the swap succeeded; the remaining
      // plaintext backup is no longer needed.
      await backupFile.delete();
    }

    return key;
  }

  Future<String> _createAndStoreKey() async {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    final key = base64Url.encode(bytes);
    await _keyStore.write(key: _keyName, value: key);
    return key;
  }

  Future<void> _recoverInterruptedMigration({
    required File databaseFile,
    required File temporaryFile,
    required File backupFile,
  }) async {
    if (!await databaseFile.exists() && await backupFile.exists()) {
      // Restore the known-good source and retry the migration from scratch.
      await backupFile.rename(databaseFile.path);
    }

    if (await temporaryFile.exists()) {
      await temporaryFile.delete();
    }
  }

  Future<bool> _isPlaintext(File file) async {
    final handle = await file.open();
    try {
      final header = await handle.read(16);
      return ascii.decode(header, allowInvalid: true) ==
          'SQLite format 3\u0000';
    } finally {
      await handle.close();
    }
  }

  Future<void> _encryptPlaintextDatabase({
    required File sourceFile,
    required File temporaryFile,
    required File backupFile,
    required String password,
  }) async {
    Database? encryptedDatabase;

    try {
      encryptedDatabase = await openDatabase(
        temporaryFile.path,
        password: password,
        singleInstance: false,
      );

      final sourcePath = _sqlString(sourceFile.path);
      await encryptedDatabase.execute(
        "ATTACH DATABASE '$sourcePath' AS plaintext KEY ''",
      );

      try {
        await encryptedDatabase.rawQuery(
          "SELECT sqlcipher_export('main', 'plaintext')",
        );

        final versionRows = await encryptedDatabase.rawQuery(
          'PRAGMA plaintext.user_version',
        );
        final version = versionRows.isEmpty
            ? 0
            : (versionRows.first.values.first as num?)?.toInt() ?? 0;
        await encryptedDatabase.execute('PRAGMA main.user_version = $version');

        await _verifyExport(encryptedDatabase);
      } finally {
        await encryptedDatabase.execute('DETACH DATABASE plaintext');
      }

      await encryptedDatabase.close();
      encryptedDatabase = null;

      if (await backupFile.exists()) {
        await backupFile.delete();
      }

      await sourceFile.rename(backupFile.path);

      try {
        await temporaryFile.rename(sourceFile.path);
        await _verifyEncryptedFile(sourceFile.path, password);
      } catch (_) {
        if (await sourceFile.exists()) {
          await sourceFile.delete();
        }
        await backupFile.rename(sourceFile.path);
        rethrow;
      }

      await backupFile.delete();
    } catch (_) {
      await encryptedDatabase?.close();
      if (await temporaryFile.exists()) {
        await temporaryFile.delete();
      }
      rethrow;
    }
  }

  Future<void> _verifyExport(Database database) async {
    final sourceTables = await database.rawQuery('''
      SELECT name FROM plaintext.sqlite_master
      WHERE type = 'table' AND name NOT LIKE 'sqlite_%'
      ORDER BY name
    ''');
    final targetTables = await database.rawQuery('''
      SELECT name FROM main.sqlite_master
      WHERE type = 'table' AND name NOT LIKE 'sqlite_%'
      ORDER BY name
    ''');

    final sourceNames = sourceTables.map((row) => row['name']).toList();
    final targetNames = targetTables.map((row) => row['name']).toList();
    if (sourceNames.join('|') != targetNames.join('|')) {
      throw StateError('فشل التحقق من بنية قاعدة البيانات المشفرة.');
    }

    for (final tableName in sourceNames.whereType<String>()) {
      final identifier = _sqlIdentifier(tableName);
      final sourceCount = Sqflite.firstIntValue(
        await database.rawQuery('SELECT COUNT(*) FROM plaintext.$identifier'),
      );
      final targetCount = Sqflite.firstIntValue(
        await database.rawQuery('SELECT COUNT(*) FROM main.$identifier'),
      );
      if (sourceCount != targetCount) {
        throw StateError('فشل التحقق من بيانات الجدول $tableName.');
      }
    }
  }

  Future<void> _verifyEncryptedFile(String path, String password) async {
    final database = await openDatabase(
      path,
      password: password,
      readOnly: true,
      singleInstance: false,
    );
    try {
      await database.rawQuery('SELECT count(*) FROM sqlite_master');
    } finally {
      await database.close();
    }
  }

  String _sqlString(String value) => value.replaceAll("'", "''");

  String _sqlIdentifier(String value) => '"${value.replaceAll('"', '""')}"';
}
