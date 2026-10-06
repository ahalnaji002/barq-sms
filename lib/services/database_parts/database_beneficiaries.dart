part of '../database_service.dart';

extension DatabaseBeneficiaries on DatabaseService {
  Future<int> insertBeneficiary(
    Beneficiary beneficiary, {
    int? batchId,
  }) async {
    final db = await database;

    final effectiveBatchId = batchId ?? await _getOrCreateDefaultBatchId(db);

    final normalizedBeneficiary = beneficiary.normalized();
    final data = normalizedBeneficiary.toMap();

    data.remove('id');
    data['batch_id'] = effectiveBatchId;

    return db.insert(
      'beneficiaries',
      data,
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<int> insertBeneficiaries(
    List<Beneficiary> beneficiaries, {
    int? batchId,
  }) async {
    if (beneficiaries.isEmpty) {
      return 0;
    }

    final db = await database;

    return db.transaction((transaction) async {
      final effectiveBatchId =
          batchId ?? await _getOrCreateDefaultBatchId(transaction);

      var insertedCount = 0;

      for (final beneficiary in beneficiaries) {
        final normalizedBeneficiary = beneficiary.normalized();

        final data = normalizedBeneficiary.toMap();

        data.remove('id');
        data['batch_id'] = effectiveBatchId;

        final insertedId = await transaction.insert(
          'beneficiaries',
          data,
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );

        if (insertedId > 0) {
          insertedCount++;
        }
      }

      return insertedCount;
    });
  }

  Future<List<Beneficiary>> getBeneficiaries({
    int? batchId,
  }) async {
    final db = await database;

    final result = await db.query(
      'beneficiaries',
      where: batchId == null ? null : 'batch_id = ?',
      whereArgs: batchId == null ? null : [batchId],
      orderBy: 'serial_number ASC',
    );

    return result
        .map(
          (row) => Beneficiary.fromMap(row),
        )
        .toList();
  }

  Future<List<Beneficiary>> getBeneficiariesByBatch(
    int batchId,
  ) {
    return getBeneficiaries(
      batchId: batchId,
    );
  }

  Future<int> getBeneficiariesCount({
    int? batchId,
  }) async {
    final db = await database;

    if (batchId == null) {
      final result = await db.rawQuery(
        'SELECT COUNT(*) AS count FROM beneficiaries',
      );

      return Sqflite.firstIntValue(result) ?? 0;
    }

    return getBatchBeneficiariesCount(batchId);
  }

  Future<bool> phoneExists(
    String phoneNumber, {
    int? batchId,
  }) async {
    final db = await database;

    final normalizedPhoneNumber = Beneficiary.normalizePhoneNumber(phoneNumber);

    final result = await db.query(
      'beneficiaries',
      columns: ['id'],
      where: batchId == null
          ? 'phone_number = ?'
          : 'batch_id = ? AND phone_number = ?',
      whereArgs: batchId == null
          ? [normalizedPhoneNumber]
          : [batchId, normalizedPhoneNumber],
      limit: 1,
    );

    return result.isNotEmpty;
  }

  Future<bool> nationalIdExists(
    String nationalId, {
    int? batchId,
  }) async {
    final normalizedNationalId = Beneficiary.normalizeNationalId(nationalId);
    if (normalizedNationalId.isEmpty) return false;

    final db = await database;

    final result = await db.query(
      'beneficiaries',
      columns: ['id'],
      where: batchId == null
          ? 'national_id = ?'
          : 'batch_id = ? AND national_id = ?',
      whereArgs: batchId == null
          ? [normalizedNationalId]
          : [batchId, normalizedNationalId],
      limit: 1,
    );

    return result.isNotEmpty;
  }

  Future<int> deleteBeneficiary(int id) async {
    final db = await database;

    return db.delete(
      'beneficiaries',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteBeneficiaries(
    List<int> ids,
  ) async {
    if (ids.isEmpty) {
      return 0;
    }

    final db = await database;

    return db.delete(
      'beneficiaries',
      where: 'id IN (${List.filled(ids.length, '?').join(',')})',
      whereArgs: ids,
    );
  }

  Future<void> deleteAllBeneficiaries({
    int? batchId,
  }) async {
    final db = await database;

    if (batchId == null) {
      await db.delete('beneficiaries');
      return;
    }

    await db.delete(
      'beneficiaries',
      where: 'batch_id = ?',
      whereArgs: [batchId],
    );
  }

  Future<int> updateBeneficiary(
    Beneficiary beneficiary,
  ) async {
    final id = beneficiary.id;

    if (id == null) {
      throw ArgumentError(
        'Beneficiary id is required for update.',
      );
    }

    final normalizedBeneficiary = beneficiary.normalized();
    final data = normalizedBeneficiary.toMap();

    data.remove('id');

    // لا نرسل batch_id هنا حتى يبقى المستفيد
    // داخل الكشف الحالي أثناء تعديل بياناته.
    data.remove('batch_id');

    final db = await database;

    return db.update(
      'beneficiaries',
      data,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<String?> findDuplicateBeneficiaryForUpdate({
    required int currentId,
    required String nationalId,
    required String phoneNumber,
    int? batchId,
  }) async {
    final db = await database;

    final normalizedNationalId = Beneficiary.normalizeNationalId(nationalId);

    final normalizedPhoneNumber = Beneficiary.normalizePhoneNumber(phoneNumber);

    int? effectiveBatchId = batchId;

    if (effectiveBatchId == null) {
      final currentBeneficiary = await db.query(
        'beneficiaries',
        columns: ['batch_id'],
        where: 'id = ?',
        whereArgs: [currentId],
        limit: 1,
      );

      if (currentBeneficiary.isEmpty) {
        return null;
      }

      effectiveBatchId = currentBeneficiary.first['batch_id'] as int?;
    }

    if (effectiveBatchId == null) {
      return null;
    }

    if (normalizedNationalId.isNotEmpty) {
      final nationalIdResult = await db.query(
        'beneficiaries',
        columns: ['id'],
        where: '''
          id != ?
          AND batch_id = ?
          AND national_id = ?
        ''',
        whereArgs: [
          currentId,
          effectiveBatchId,
          normalizedNationalId,
        ],
        limit: 1,
      );

      if (nationalIdResult.isNotEmpty) {
        return 'nationalId';
      }
    }

    final phoneResult = await db.query(
      'beneficiaries',
      columns: ['id'],
      where: '''
        id != ?
        AND batch_id = ?
        AND phone_number = ?
      ''',
      whereArgs: [
        currentId,
        effectiveBatchId,
        normalizedPhoneNumber,
      ],
      limit: 1,
    );

    if (phoneResult.isNotEmpty) {
      return 'phoneNumber';
    }

    return null;
  }

  Future<List<Beneficiary>> getUniqueBeneficiaries() async {
    final db = await database;

    final result = await db.rawQuery('''
    SELECT b.*
    FROM beneficiaries b
    INNER JOIN (
      SELECT MIN(id) AS selected_id
      FROM beneficiaries
      GROUP BY CASE
        WHEN national_id != '' THEN 'id:' || national_id
        ELSE 'phone:' || phone_number
      END
    ) u
    ON b.id = u.selected_id
    ORDER BY b.name COLLATE NOCASE ASC
  ''');

    return result.map((row) => Beneficiary.fromMap(row)).toList();
  }

  Future<int> getUniqueBeneficiariesCount() async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT COUNT(*) FROM (
        SELECT 1
        FROM beneficiaries
        GROUP BY CASE
          WHEN national_id != '' THEN 'id:' || national_id
          ELSE 'phone:' || phone_number
        END
      )
    ''');

    return Sqflite.firstIntValue(result) ?? 0;
  }

  // =========================================================
  // سجل الرسائل
  // =========================================================
}
