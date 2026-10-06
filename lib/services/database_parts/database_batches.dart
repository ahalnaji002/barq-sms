part of '../database_service.dart';

extension DatabaseBatches on DatabaseService {
  Future<List<BeneficiaryBatch>> getBeneficiaryBatches() async {
    final db = await database;

    final result = await db.query(
      'beneficiary_batches',
      orderBy: 'created_at DESC, id DESC',
    );

    return result
        .map(
          (row) => BeneficiaryBatch.fromMap(row),
        )
        .toList();
  }

  Future<BeneficiaryBatch?> getBeneficiaryBatchById(
    int batchId,
  ) async {
    final db = await database;

    final result = await db.query(
      'beneficiary_batches',
      where: 'id = ?',
      whereArgs: [batchId],
      limit: 1,
    );

    if (result.isEmpty) {
      return null;
    }

    return BeneficiaryBatch.fromMap(result.first);
  }

  Future<int> getBeneficiaryBatchesCount() async {
    final db = await database;

    final result = await db.rawQuery(
      'SELECT COUNT(*) AS count FROM beneficiary_batches',
    );

    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<bool> batchNameExists(
    String name, {
    int? excludedBatchId,
  }) async {
    final db = await database;
    final normalizedName = name.trim();

    String where = 'LOWER(name) = LOWER(?)';
    final whereArgs = <Object?>[
      normalizedName,
    ];

    if (excludedBatchId != null) {
      where += ' AND id != ?';
      whereArgs.add(excludedBatchId);
    }

    final result = await db.query(
      'beneficiary_batches',
      columns: ['id'],
      where: where,
      whereArgs: whereArgs,
      limit: 1,
    );

    return result.isNotEmpty;
  }

  Future<String> generateUniqueBatchName(
    String requestedName, {
    int? excludedBatchId,
  }) async {
    var cleanName = _removeExcelExtension(
      requestedName.trim(),
    );

    if (cleanName.isEmpty) {
      cleanName = 'كشف جديد';
    }

    final originalNameExists = await batchNameExists(
      cleanName,
      excludedBatchId: excludedBatchId,
    );

    if (!originalNameExists) {
      return cleanName;
    }

    final firstDuplicateName = '$cleanName (مكرر)';

    final firstDuplicateExists = await batchNameExists(
      firstDuplicateName,
      excludedBatchId: excludedBatchId,
    );

    if (!firstDuplicateExists) {
      return firstDuplicateName;
    }

    var duplicateNumber = 2;

    while (true) {
      final duplicateName = '$cleanName (مكرر $duplicateNumber)';

      final duplicateExists = await batchNameExists(
        duplicateName,
        excludedBatchId: excludedBatchId,
      );

      if (!duplicateExists) {
        return duplicateName;
      }

      duplicateNumber++;
    }
  }

  Future<BeneficiaryBatch> createBeneficiaryBatch({
    required String name,
    required String originalFileName,
  }) async {
    final db = await database;

    final uniqueName = await generateUniqueBatchName(name);
    final createdAt = DateTime.now().toIso8601String();

    final id = await db.insert(
      'beneficiary_batches',
      {
        'name': uniqueName,
        'original_file_name': originalFileName.trim(),
        'created_at': createdAt,
      },
    );

    return BeneficiaryBatch(
      id: id,
      name: uniqueName,
      originalFileName: originalFileName.trim(),
      createdAt: createdAt,
    );
  }

  Future<String> renameBeneficiaryBatch({
    required int batchId,
    required String newName,
  }) async {
    final db = await database;

    final cleanName = _removeExcelExtension(
      newName.trim(),
    );

    if (cleanName.isEmpty) {
      throw ArgumentError(
        'اسم الكشف لا يمكن أن يكون فارغًا.',
      );
    }

    final uniqueName = await generateUniqueBatchName(
      cleanName,
      excludedBatchId: batchId,
    );

    final updatedRows = await db.update(
      'beneficiary_batches',
      {
        'name': uniqueName,
      },
      where: 'id = ?',
      whereArgs: [batchId],
    );

    if (updatedRows == 0) {
      throw StateError(
        'الكشف المطلوب غير موجود.',
      );
    }

    return uniqueName;
  }

  Future<int> deleteBeneficiaryBatch(
    int batchId,
  ) async {
    final db = await database;

    return db.transaction((transaction) async {
      // الحذف اليدوي يضمن حذف المستفيدين حتى في قواعد
      // البيانات القديمة التي أضيف لها batch_id بالترقية.
      await transaction.delete(
        'beneficiaries',
        where: 'batch_id = ?',
        whereArgs: [batchId],
      );

      return transaction.delete(
        'beneficiary_batches',
        where: 'id = ?',
        whereArgs: [batchId],
      );
    });
  }

  Future<int> getBatchBeneficiariesCount(
    int batchId,
  ) async {
    final db = await database;

    final result = await db.rawQuery(
      '''
      SELECT COUNT(*) AS count
      FROM beneficiaries
      WHERE batch_id = ?
      ''',
      [batchId],
    );

    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<Map<int, int>> getBatchBeneficiaryCounts() async {
    final db = await database;

    final result = await db.rawQuery('''
      SELECT
        batch_id,
        COUNT(*) AS beneficiary_count
      FROM beneficiaries
      WHERE batch_id IS NOT NULL
      GROUP BY batch_id
    ''');

    final counts = <int, int>{};

    for (final row in result) {
      final batchId = row['batch_id'] as int?;
      final count = row['beneficiary_count'] as int?;

      if (batchId != null) {
        counts[batchId] = count ?? 0;
      }
    }

    return counts;
  }
}
