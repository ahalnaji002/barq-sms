part of '../database_service.dart';

extension DatabaseSmsLogs on DatabaseService {
  Future<int> insertSmsLog(
    SmsLog log,
  ) async {
    final db = await database;

    return db.insert(
      'sms_logs',
      log.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateSmsLogStatus(
    int logId,
    SmsLogStatus status, {
    String? errorMessage,
  }) async {
    final db = await database;
    await db.update(
      'sms_logs',
      {
        'status': status.name,
        'is_success':
            status == SmsLogStatus.sent || status == SmsLogStatus.delivered
                ? 1
                : 0,
        'error_message': errorMessage,
        'delivered_at': status == SmsLogStatus.delivered
            ? DateTime.now().toIso8601String()
            : null,
      },
      where: 'id = ?',
      whereArgs: [logId],
    );
  }

  Future<List<SmsLog>> getSmsLogs() async {
    final db = await database;

    final result = await db.query(
      'sms_logs',
      orderBy: 'sent_at DESC',
    );

    return result
        .map(
          (row) => SmsLog.fromMap(row),
        )
        .toList();
  }

  Future<void> deleteAllSmsLogs() async {
    final db = await database;

    await db.delete('sms_logs');
  }

  Future<void> deleteAllSensitiveData() async {
    final db = await database;
    await db.transaction((transaction) async {
      await transaction.delete('sms_logs');
      await transaction.delete('beneficiaries');
      await transaction.delete('beneficiary_batches');
      await transaction.delete(
        'sqlite_sequence',
        where: 'name IN (?, ?, ?)',
        whereArgs: ['sms_logs', 'beneficiaries', 'beneficiary_batches'],
      );
    });
  }
}
