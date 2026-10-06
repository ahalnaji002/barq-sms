import '../models/beneficiary_batch.dart';
import '../services/database_service.dart';

class BeneficiaryBatchRepository {
  final DatabaseService _databaseService;

  BeneficiaryBatchRepository({
    DatabaseService? databaseService,
  }) : _databaseService = databaseService ?? DatabaseService.instance;

  Future<List<BeneficiaryBatch>> getAllBatches() {
    return _databaseService.getBeneficiaryBatches();
  }

  Future<int> getBatchesCount() {
    return _databaseService.getBeneficiaryBatchesCount();
  }

  Future<BeneficiaryBatch> createBatch({
    required String name,
    required String originalFileName,
  }) {
    return _databaseService.createBeneficiaryBatch(
      name: name,
      originalFileName: originalFileName,
    );
  }

  Future<String> renameBatch({
    required int batchId,
    required String newName,
  }) {
    return _databaseService.renameBeneficiaryBatch(
      batchId: batchId,
      newName: newName,
    );
  }

  Future<void> deleteBatch(int batchId) async {
    await _databaseService.deleteBeneficiaryBatch(
      batchId,
    );
  }

  Future<BeneficiaryBatch?> getBatchById(
    int batchId,
  ) {
    return _databaseService.getBeneficiaryBatchById(
      batchId,
    );
  }

  Future<int> getBatchBeneficiariesCount(
    int batchId,
  ) {
    return _databaseService.getBatchBeneficiariesCount(
      batchId,
    );
  }

  Future<Map<int, int>> getBatchBeneficiaryCounts() {
    return _databaseService.getBatchBeneficiaryCounts();
  }

  Future<bool> batchNameExists(String name) {
    return _databaseService.batchNameExists(name);
  }

  Future<String> generateUniqueBatchName(
    String name,
  ) {
    return _databaseService.generateUniqueBatchName(
      name,
    );
  }
}
