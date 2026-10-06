import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:barq_sms/services/database_encryption_service.dart';
import 'package:barq_sms/services/database_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DatabaseEncryptionService', () {
    late Directory temporaryDirectory;
    late _MemoryDatabaseKeyStore keyStore;
    late DatabaseEncryptionService encryptionService;

    setUp(() async {
      temporaryDirectory = await Directory.systemTemp.createTemp(
        'barq_database_security_',
      );
      keyStore = _MemoryDatabaseKeyStore();
      encryptionService = DatabaseEncryptionService(keyStore: keyStore);
    });

    tearDown(() async {
      if (await temporaryDirectory.exists()) {
        await temporaryDirectory.delete(recursive: true);
      }
    });

    test('creates and reuses a random key when no database exists', () async {
      final databasePath = '${temporaryDirectory.path}/barq_sms.db';

      final firstKey = await encryptionService.prepareEncryptedDatabase(
        databasePath,
      );
      final secondKey = await encryptionService.prepareEncryptedDatabase(
        databasePath,
      );

      expect(base64Url.decode(base64Url.normalize(firstKey)), hasLength(32));
      expect(secondKey, firstKey);
      expect(keyStore.values, hasLength(1));
      expect(await File(databasePath).exists(), isFalse);
    });

    test('refuses encrypted data when its key is missing and preserves it',
        () async {
      final database = File('${temporaryDirectory.path}/barq_sms.db');
      final originalBytes = List<int>.generate(64, (index) => index + 1);
      await database.writeAsBytes(originalBytes);

      await expectLater(
        encryptionService.prepareEncryptedDatabase(database.path),
        throwsA(isA<StateError>()),
      );

      expect(await database.readAsBytes(), originalBytes);
    });

    test('recovers the database backup and removes an incomplete temp file',
        () async {
      final databasePath = '${temporaryDirectory.path}/barq_sms.db';
      final key =
          await encryptionService.prepareEncryptedDatabase(databasePath);
      final backup = File('$databasePath.plaintext_backup');
      final temporary = File('$databasePath.encrypting');
      final encryptedBytes = List<int>.generate(64, (index) => 255 - index);
      await backup.writeAsBytes(encryptedBytes);
      await temporary.writeAsBytes([1, 2, 3]);

      final recoveredKey = await encryptionService.prepareEncryptedDatabase(
        databasePath,
      );

      expect(recoveredKey, key);
      expect(await File(databasePath).readAsBytes(), encryptedBytes);
      expect(await backup.exists(), isFalse);
      expect(await temporary.exists(), isFalse);
    });
  });

  group('DatabaseService initialization', () {
    test('parallel requests share one database open', () async {
      final openCompleter = Completer<Database>();
      final database = _FakeDatabase();
      var openCount = 0;
      final service = DatabaseService.forTesting(
        databaseOpener: () {
          openCount++;
          return openCompleter.future;
        },
      );

      final firstRequest = service.database;
      final secondRequest = service.database;
      expect(openCount, 1);

      openCompleter.complete(database);
      final openedDatabases = await Future.wait([
        firstRequest,
        secondRequest,
      ]);

      expect(identical(openedDatabases[0], database), isTrue);
      expect(identical(openedDatabases[1], database), isTrue);
      expect(openCount, 1);
    });

    test('clears a failed open so a later request can retry', () async {
      final database = _FakeDatabase();
      var openCount = 0;
      final service = DatabaseService.forTesting(
        databaseOpener: () async {
          openCount++;
          if (openCount == 1) {
            throw StateError('temporary open failure');
          }
          return database;
        },
      );

      await expectLater(service.database, throwsStateError);
      final reopened = await service.database;

      expect(identical(reopened, database), isTrue);
      expect(openCount, 2);
    });
  });
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

class _FakeDatabase implements Database {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
