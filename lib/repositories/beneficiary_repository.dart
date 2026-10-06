import '../models/beneficiary.dart';
import '../services/database_service.dart';

class BeneficiaryRepository {
  final DatabaseService _databaseService;

  BeneficiaryRepository({
    DatabaseService? databaseService,
  }) : _databaseService = databaseService ?? DatabaseService.instance;

  Future<List<Beneficiary>> getAllBeneficiaries({
    int? batchId,
  }) {
    return _databaseService.getBeneficiaries(
      batchId: batchId,
    );
  }

  Future<int> getBeneficiariesCount({
    int? batchId,
  }) {
    return _databaseService.getBeneficiariesCount(
      batchId: batchId,
    );
  }

  Future<void> addBeneficiary(
    Beneficiary beneficiary, {
    int? batchId,
  }) {
    return _databaseService.insertBeneficiary(
      beneficiary,
      batchId: batchId,
    );
  }

  Future<void> addBeneficiaries(
    List<Beneficiary> beneficiaries, {
    int? batchId,
  }) {
    return _databaseService.insertBeneficiaries(
      beneficiaries,
      batchId: batchId,
    );
  }

  Future<void> deleteBeneficiary(int id) {
    return _databaseService.deleteBeneficiary(id);
  }

  Future<void> deleteBeneficiaries(
    List<int> ids,
  ) {
    return _databaseService.deleteBeneficiaries(ids);
  }

  Future<void> updateBeneficiary(
    Beneficiary beneficiary,
  ) {
    return _databaseService.updateBeneficiary(
      beneficiary,
    );
  }

  Future<String?> findDuplicateBeneficiaryForUpdate({
    required int currentId,
    required String nationalId,
    required String phoneNumber,
    int? batchId,
  }) {
    return _databaseService.findDuplicateBeneficiaryForUpdate(
      currentId: currentId,
      nationalId: nationalId,
      phoneNumber: phoneNumber,
      batchId: batchId,
    );
  }

  Future<void> deleteAllBeneficiaries({
    int? batchId,
  }) {
    return _databaseService.deleteAllBeneficiaries(
      batchId: batchId,
    );
  }

  Future<List<Beneficiary>> getUniqueBeneficiaries() {
    return _databaseService.getUniqueBeneficiaries();
  }

  Future<int> getUniqueBeneficiariesCount() {
    return _databaseService.getUniqueBeneficiariesCount();
  }
}
