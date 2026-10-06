import 'dart:io';

import 'package:barq_sms/models/beneficiary.dart';
import 'package:barq_sms/services/database_encryption_service.dart';
import 'package:barq_sms/services/database_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite_sqlcipher/sqflite.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'plaintext version 3 data is encrypted, migrated, and reopens intact',
    (tester) async {
      final temporaryDirectory = await Directory.systemTemp.createTemp(
        'barq_database_migration_',
      );
      final databasePath = path.join(temporaryDirectory.path, 'barq_sms.db');
      final keyStore = _MemoryDatabaseKeyStore();
      final encryptionService = DatabaseEncryptionService(keyStore: keyStore);

      try {
        await encryptionService.prepareEncryptedDatabase(databasePath);
        final legacyDatabase = await openDatabase(
          databasePath,
          version: 3,
          onCreate: (database, version) async {
            await database.execute('''
              CREATE TABLE beneficiaries (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                serial_number INTEGER NOT NULL,
                name TEXT NOT NULL,
                national_id TEXT NOT NULL,
                phone_number TEXT NOT NULL,
                area TEXT NOT NULL,
                family_members INTEGER NOT NULL
              )
            ''');
            await database.execute('''
              CREATE UNIQUE INDEX beneficiaries_national_id_index
              ON beneficiaries(national_id)
            ''');
            await database.execute('''
              CREATE UNIQUE INDEX beneficiaries_phone_index
              ON beneficiaries(phone_number)
            ''');
            await database.execute('''
              CREATE TABLE sms_logs (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                beneficiary_name TEXT NOT NULL,
                phone_number TEXT NOT NULL,
                message TEXT NOT NULL,
                sent_at TEXT NOT NULL,
                is_success INTEGER NOT NULL,
                error_message TEXT
              )
            ''');
            await database.insert('beneficiaries', {
              'serial_number': 17,
              'name': 'مستفيد تجريبي',
              'national_id': '123456789',
              'phone_number': '0591234567',
              'area': 'غزة',
              'family_members': 4,
            });
            await database.insert('sms_logs', {
              'beneficiary_name': 'مستفيد تجريبي',
              'phone_number': '0591234567',
              'message': 'رسالة تجريبية',
              'sent_at': '2026-01-01T10:00:00.000',
              'is_success': 1,
            });
          },
        );
        await legacyDatabase.close();

        final service = DatabaseService.forTesting(
          databasePath: databasePath,
          encryptionService: encryptionService,
        );
        final migratedDatabase = await service.database;

        expect(
          Sqflite.firstIntValue(
            await migratedDatabase.rawQuery('PRAGMA user_version'),
          ),
          8,
        );
        final beneficiary =
            (await migratedDatabase.query('beneficiaries')).single;
        expect(beneficiary['name'], 'مستفيد تجريبي');
        expect(beneficiary['serial_number'], 17);
        expect(beneficiary['family_members'], 4);
        expect(beneficiary['batch_id'], isNotNull);
        expect(beneficiary['student_name'], '');
        expect(beneficiary['guardian_name'], '');

        await service.insertBeneficiary(
          const Beneficiary(
            serialNumber: 18,
            name: 'طالبة جديدة',
            nationalId: '',
            phoneNumber: '0561234567',
            area: 'رفح',
            familyMembers: 2,
            studentName: 'طالبة جديدة',
            guardianName: 'ولي أمر جديد',
          ),
          batchId: beneficiary['batch_id'] as int,
        );
        await service.insertBeneficiary(
          const Beneficiary(
            serialNumber: 19,
            name: 'طالب جديد آخر',
            nationalId: '',
            phoneNumber: '0597654321',
            area: 'غزة',
            familyMembers: 1,
          ),
          batchId: beneficiary['batch_id'] as int,
        );
        expect(
          await migratedDatabase.query(
            'beneficiaries',
            where: "national_id = ''",
          ),
          hasLength(2),
        );

        await service.insertBeneficiary(
          const Beneficiary(
            serialNumber: 18,
            name: 'مستفيد جديد',
            nationalId: '987654321',
            phoneNumber: '0561234567',
            area: 'رفح',
            familyMembers: 2,
            studentName: 'طالبة جديدة',
            guardianName: 'ولي أمر جديد',
          ),
          batchId: beneficiary['batch_id'] as int,
        );
        final insertedBeneficiary = await migratedDatabase.query(
          'beneficiaries',
          where: 'national_id = ?',
          whereArgs: ['987654321'],
        );
        expect(insertedBeneficiary.single['student_name'], 'طالبة جديدة');
        expect(insertedBeneficiary.single['guardian_name'], 'ولي أمر جديد');

        final smsLog = (await migratedDatabase.query('sms_logs')).single;
        expect(smsLog['status'], 'sent');
        expect(smsLog['delivered_at'], isNull);
        expect(
          await migratedDatabase.rawQuery(
            'PRAGMA foreign_key_check(beneficiaries)',
          ),
          isEmpty,
        );

        await service.closeForTesting();
        final reopenedDatabase = await service.database;
        expect(
          (await reopenedDatabase.query('beneficiaries')).single['name'],
          'مستفيد تجريبي',
        );
        expect(
          Sqflite.firstIntValue(
            await reopenedDatabase.rawQuery('PRAGMA user_version'),
          ),
          8,
        );
        await service.closeForTesting();

        final databaseHeader = await File(databasePath).open();
        try {
          expect(
            await databaseHeader.read(16),
            isNot(equals('SQLite format 3\u0000'.codeUnits)),
          );
        } finally {
          await databaseHeader.close();
        }
      } finally {
        if (await temporaryDirectory.exists()) {
          await temporaryDirectory.delete(recursive: true);
        }
      }
    },
  );
}

class _MemoryDatabaseKeyStore implements DatabaseKeyStore {
  final Map<String, String> values = {};

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write({required String key, required String value}) async {
    values[key] = value;
  }
}
