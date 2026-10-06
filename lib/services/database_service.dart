import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

import 'database_encryption_service.dart';

import '../models/beneficiary.dart';
import '../models/beneficiary_batch.dart';
import '../models/sms_log.dart';

part 'database_parts/database_batches.dart';
part 'database_parts/database_beneficiaries.dart';
part 'database_parts/database_sms_logs.dart';

class DatabaseService {
  DatabaseService._()
      : _databasePathOverride = null,
        _encryptionServiceOverride = null,
        _databaseOpener = null;

  @visibleForTesting
  DatabaseService.forTesting({
    String? databasePath,
    DatabaseEncryptionService? encryptionService,
    Future<Database> Function()? databaseOpener,
  })  : _databasePathOverride = databasePath,
        _encryptionServiceOverride = encryptionService,
        _databaseOpener = databaseOpener;

  static final DatabaseService instance = DatabaseService._();

  final String? _databasePathOverride;
  final DatabaseEncryptionService? _encryptionServiceOverride;
  final Future<Database> Function()? _databaseOpener;

  Database? _database;
  Future<Database>? _databaseOpening;

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    // Several providers can request the database during the same startup
    // frame. Reuse one opening operation so encryption-key creation and the
    // initial database open can never race each other.
    return _databaseOpening ??= _openAndCacheDatabase();
  }

  Future<Database> _openAndCacheDatabase() async {
    try {
      final openedDatabase = await _initializeDatabase();
      _database = openedDatabase;
      return openedDatabase;
    } finally {
      _databaseOpening = null;
    }
  }

  Future<Database> _initializeDatabase() async {
    final databaseOpener = _databaseOpener;
    if (databaseOpener != null) {
      return databaseOpener();
    }

    final path =
        _databasePathOverride ?? join(await getDatabasesPath(), 'barq_sms.db');
    await Directory(dirname(path)).create(recursive: true);

    final encryption =
        _encryptionServiceOverride ?? DatabaseEncryptionService();
    final password = await encryption.prepareEncryptedDatabase(path);

    return openDatabase(
      path,
      password: password,
      version: 8,
      onConfigure: (database) async {
        await database.execute(
          'PRAGMA foreign_keys = ON',
        );
      },
      onCreate: (database, version) async {
        await _createBeneficiaryBatchesTable(database);
        await _createBeneficiariesTable(database);
        await _createSmsLogsTable(database);
        await _createBeneficiaryIndexes(database);
      },
      onUpgrade: (database, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await database.execute('''
            CREATE UNIQUE INDEX IF NOT EXISTS
            beneficiaries_national_id_index
            ON beneficiaries(national_id)
          ''');
        }

        if (oldVersion < 3) {
          await _createSmsLogsTable(database);
        }

        if (oldVersion < 4) {
          await _upgradeToVersion4(database);
        }
        if (oldVersion < 5) {
          await _upgradeToVersion5(database);
        }
        if (oldVersion < 6) {
          await _upgradeToVersion6(database);
        }
        if (oldVersion < 7) {
          await _upgradeToVersion7(database);
        }
        if (oldVersion < 8) {
          await _upgradeToVersion8(database);
        }
      },
    );
  }

  @visibleForTesting
  Future<void> closeForTesting() async {
    final opening = _databaseOpening;
    if (opening != null) {
      await opening;
    }

    final database = _database;
    _database = null;
    if (database != null && database.isOpen) {
      await database.close();
    }
  }

  // =========================================================
  // إنشاء الجداول
  // =========================================================

  Future<void> _createBeneficiaryBatchesTable(
    DatabaseExecutor database,
  ) async {
    await database.execute('''
      CREATE TABLE IF NOT EXISTS beneficiary_batches (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        original_file_name TEXT NOT NULL DEFAULT '',
        created_at TEXT NOT NULL
      )
    ''');

    await database.execute('''
      CREATE INDEX IF NOT EXISTS beneficiary_batches_created_at_index
      ON beneficiary_batches(created_at)
    ''');
  }

  Future<void> _createBeneficiariesTable(
    DatabaseExecutor database,
  ) async {
    await database.execute('''
      CREATE TABLE IF NOT EXISTS beneficiaries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        batch_id INTEGER NOT NULL,
        serial_number INTEGER NOT NULL,
        name TEXT NOT NULL,
        national_id TEXT NOT NULL,
        phone_number TEXT NOT NULL,
        area TEXT NOT NULL,
        family_members INTEGER NOT NULL,
        student_name TEXT NOT NULL DEFAULT '',
        guardian_name TEXT NOT NULL DEFAULT '',
        FOREIGN KEY(batch_id)
          REFERENCES beneficiary_batches(id)
          ON DELETE CASCADE
      )
    ''');
  }

  Future<void> _createSmsLogsTable(
    DatabaseExecutor database,
  ) async {
    await database.execute('''
      CREATE TABLE IF NOT EXISTS sms_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        beneficiary_name TEXT NOT NULL,
        phone_number TEXT NOT NULL,
        message TEXT NOT NULL,
        sent_at TEXT NOT NULL,
        is_success INTEGER NOT NULL,
        error_message TEXT,
        status TEXT NOT NULL DEFAULT 'failed',
        delivered_at TEXT
      )
    ''');
  }

  Future<void> _upgradeToVersion5(Database database) async {
    final columns = await database.rawQuery('PRAGMA table_info(sms_logs)');
    final names = columns.map((column) => column['name']).toSet();
    if (!names.contains('status')) {
      await database.execute(
        "ALTER TABLE sms_logs ADD COLUMN status TEXT NOT NULL DEFAULT 'failed'",
      );
      await database.execute('''
        UPDATE sms_logs
        SET status = CASE WHEN is_success = 1 THEN 'sent' ELSE 'failed' END
      ''');
    }
    if (!names.contains('delivered_at')) {
      await database.execute(
        'ALTER TABLE sms_logs ADD COLUMN delivered_at TEXT',
      );
    }
  }

  Future<void> _upgradeToVersion7(DatabaseExecutor database) async {
    final columns = await database.rawQuery(
      'PRAGMA table_info(beneficiaries)',
    );
    final names = columns.map((column) => column['name']).toSet();

    if (!names.contains('student_name')) {
      await database.execute('''
        ALTER TABLE beneficiaries
        ADD COLUMN student_name TEXT NOT NULL DEFAULT ''
      ''');
    }
    if (!names.contains('guardian_name')) {
      await database.execute('''
        ALTER TABLE beneficiaries
        ADD COLUMN guardian_name TEXT NOT NULL DEFAULT ''
      ''');
    }
  }

  Future<void> _upgradeToVersion8(DatabaseExecutor database) async {
    await database.execute(
      'DROP INDEX IF EXISTS beneficiaries_national_id_index',
    );
    await database.execute(
      'DROP INDEX IF EXISTS beneficiaries_batch_national_id_index',
    );
    await database.execute('''
      CREATE UNIQUE INDEX beneficiaries_batch_national_id_index
      ON beneficiaries(batch_id, national_id)
      WHERE national_id != ''
    ''');
  }

  Future<void> _upgradeToVersion6(DatabaseExecutor database) async {
    await _createBeneficiaryBatchesTable(database);

    final oldCount = Sqflite.firstIntValue(
          await database.rawQuery('SELECT COUNT(*) FROM beneficiaries'),
        ) ??
        0;

    final defaultBatchId = await _getOrCreateDefaultBatchId(database);

    // Index names remain reserved after a table rename, so remove them before
    // rebuilding the table and recreate them on the final schema.
    await database.execute('DROP INDEX IF EXISTS beneficiaries_batch_index');
    await database.execute(
      'DROP INDEX IF EXISTS beneficiaries_batch_phone_index',
    );
    await database.execute(
      'DROP INDEX IF EXISTS beneficiaries_batch_national_id_index',
    );
    await database.execute('DROP INDEX IF EXISTS beneficiaries_phone_index');
    await database.execute(
      'DROP INDEX IF EXISTS beneficiaries_national_id_index',
    );

    await database.execute(
      'ALTER TABLE beneficiaries RENAME TO beneficiaries_legacy_v6',
    );
    await _createBeneficiariesTable(database);

    await database.execute('''
      INSERT INTO beneficiaries (
        id,
        batch_id,
        serial_number,
        name,
        national_id,
        phone_number,
        area,
        family_members
      )
      SELECT
        legacy.id,
        CASE
          WHEN legacy.batch_id IS NOT NULL
            AND EXISTS (
              SELECT 1 FROM beneficiary_batches batch
              WHERE batch.id = legacy.batch_id
            )
          THEN legacy.batch_id
          ELSE $defaultBatchId
        END,
        COALESCE(legacy.serial_number, legacy.id, 0),
        COALESCE(legacy.name, ''),
        COALESCE(legacy.national_id, ''),
        COALESCE(legacy.phone_number, ''),
        COALESCE(legacy.area, ''),
        COALESCE(legacy.family_members, 0)
      FROM beneficiaries_legacy_v6 legacy
    ''');

    final newCount = Sqflite.firstIntValue(
          await database.rawQuery('SELECT COUNT(*) FROM beneficiaries'),
        ) ??
        0;
    if (newCount != oldCount) {
      throw StateError(
        'فشل ترحيل بيانات المستفيدين: العدد قبل الترحيل $oldCount '
        'وبعده $newCount.',
      );
    }

    final foreignKeyErrors = await database.rawQuery(
      'PRAGMA foreign_key_check(beneficiaries)',
    );
    if (foreignKeyErrors.isNotEmpty) {
      throw StateError('فشل التحقق من علاقات بيانات المستفيدين بعد الترحيل.');
    }

    await database.execute('DROP TABLE beneficiaries_legacy_v6');
    await _createBeneficiaryIndexes(database);
  }

  Future<void> _createBeneficiaryIndexes(
    DatabaseExecutor database,
  ) async {
    await database.execute('''
      CREATE INDEX IF NOT EXISTS beneficiaries_batch_index
      ON beneficiaries(batch_id)
    ''');

    await database.execute('''
      CREATE UNIQUE INDEX IF NOT EXISTS beneficiaries_batch_phone_index
      ON beneficiaries(batch_id, phone_number)
    ''');

    await database.execute('''
      CREATE UNIQUE INDEX IF NOT EXISTS beneficiaries_batch_national_id_index
      ON beneficiaries(batch_id, national_id)
      WHERE national_id != ''
    ''');
  }

  // =========================================================
  // ترقية قاعدة البيانات للإصدار 4
  // =========================================================

  Future<void> _upgradeToVersion4(
    Database database,
  ) async {
    await database.transaction((transaction) async {
      await _createBeneficiaryBatchesTable(transaction);

      final beneficiaryColumns = await transaction.rawQuery(
        'PRAGMA table_info(beneficiaries)',
      );

      final hasBatchId = beneficiaryColumns.any(
        (column) => column['name'] == 'batch_id',
      );

      if (!hasBatchId) {
        await transaction.execute('''
          ALTER TABLE beneficiaries
          ADD COLUMN batch_id INTEGER
        ''');
      }

      await transaction.execute(
        'DROP INDEX IF EXISTS beneficiaries_phone_index',
      );

      await transaction.execute(
        'DROP INDEX IF EXISTS beneficiaries_national_id_index',
      );

      final beneficiaryCountResult = await transaction.rawQuery(
        'SELECT COUNT(*) FROM beneficiaries',
      );

      final beneficiaryCount =
          Sqflite.firstIntValue(beneficiaryCountResult) ?? 0;

      if (beneficiaryCount > 0) {
        final existingLegacyBatches = await transaction.query(
          'beneficiary_batches',
          columns: ['id'],
          where: 'name = ?',
          whereArgs: ['الكشف القديم'],
          limit: 1,
        );

        late final int legacyBatchId;

        if (existingLegacyBatches.isNotEmpty) {
          legacyBatchId = existingLegacyBatches.first['id'] as int;
        } else {
          legacyBatchId = await transaction.insert(
            'beneficiary_batches',
            {
              'name': 'الكشف القديم',
              'original_file_name': '',
              'created_at': DateTime.now().toIso8601String(),
            },
          );
        }

        await transaction.update(
          'beneficiaries',
          {
            'batch_id': legacyBatchId,
          },
          where: 'batch_id IS NULL',
        );
      }

      await _createBeneficiaryIndexes(transaction);
    });
  }

  // =========================================================
  // الكشوفات
  // =========================================================

  Future<int> _getOrCreateDefaultBatchId(
    DatabaseExecutor database,
  ) async {
    final existingBatches = await database.query(
      'beneficiary_batches',
      columns: ['id'],
      where: 'name = ?',
      whereArgs: ['الكشف القديم'],
      limit: 1,
    );

    if (existingBatches.isNotEmpty) {
      return existingBatches.first['id'] as int;
    }

    return database.insert(
      'beneficiary_batches',
      {
        'name': 'الكشف القديم',
        'original_file_name': '',
        'created_at': DateTime.now().toIso8601String(),
      },
    );
  }

  String _removeExcelExtension(String value) {
    return value.replaceFirst(
      RegExp(
        r'\.(xlsx|xls)$',
        caseSensitive: false,
      ),
      '',
    );
  }

  // =========================================================
  // المستفيدون
  // =========================================================
}
