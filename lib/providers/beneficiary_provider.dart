import 'package:flutter/material.dart';

import '../models/beneficiary.dart';
import '../repositories/beneficiary_repository.dart';
import '../services/database_service.dart';

class BeneficiaryProvider extends ChangeNotifier {
  final BeneficiaryRepository _repository = BeneficiaryRepository();

  final DatabaseService _databaseService = DatabaseService.instance;

  List<Beneficiary> _beneficiaries = [];
  int _uniqueCount = 0;

  bool _isLoading = false;
  int? _currentBatchId;
  bool _isDataMode = false;

  List<Beneficiary> get beneficiaries => _beneficiaries;

  bool get isLoading => _isLoading;

  int get count => _beneficiaries.length;

  int get uniqueCount => _uniqueCount;

  int? get currentBatchId => _currentBatchId;

  bool get isDataMode => _isDataMode;

  Future<void> loadBeneficiaries({
    int? batchId,
  }) async {
    _isDataMode = false;
    _currentBatchId = batchId;

    _isLoading = true;
    notifyListeners();

    try {
      final results = await Future.wait([
        _repository.getAllBeneficiaries(batchId: batchId),
        _repository.getUniqueBeneficiariesCount(),
      ]);

      _beneficiaries = results[0] as List<Beneficiary>;
      _uniqueCount = results[1] as int;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadUniqueBeneficiaries() async {
    _isDataMode = true;
    _currentBatchId = null;

    _isLoading = true;
    notifyListeners();

    try {
      _beneficiaries = await _repository.getUniqueBeneficiaries();
      _uniqueCount = _beneficiaries.length;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _reloadCurrentView() async {
    if (_isDataMode) {
      await loadUniqueBeneficiaries();
      return;
    }

    final batchId = _currentBatchId;

    if (batchId == null) {
      _beneficiaries = [];
      notifyListeners();
      return;
    }

    await loadBeneficiaries(
      batchId: batchId,
    );
  }

  Future<int> importBeneficiaries({
    required List<Beneficiary> beneficiaries,
    required String fileName,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final batch = await _databaseService.createBeneficiaryBatch(
        name: fileName,
        originalFileName: fileName,
      );

      final batchId = batch.id;

      if (batchId == null) {
        throw StateError(
          'تعذر إنشاء الكشف الجديد.',
        );
      }

      final insertedCount = await _databaseService.insertBeneficiaries(
        beneficiaries,
        batchId: batchId,
      );

      _isDataMode = false;
      _currentBatchId = batchId;

      _beneficiaries = await _repository.getAllBeneficiaries(
        batchId: batchId,
      );

      _uniqueCount = await _repository.getUniqueBeneficiariesCount();

      return insertedCount;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateBeneficiary(
    Beneficiary beneficiary,
  ) async {
    await _repository.updateBeneficiary(
      beneficiary,
    );

    await _reloadCurrentView();
  }

  Future<String?> findDuplicateBeneficiaryForUpdate({
    required int currentId,
    required String nationalId,
    required String phoneNumber,
  }) {
    return _repository.findDuplicateBeneficiaryForUpdate(
      currentId: currentId,
      nationalId: nationalId,
      phoneNumber: phoneNumber,
      batchId: _currentBatchId,
    );
  }

  Future<void> deleteBeneficiary(
    int id,
  ) async {
    await _repository.deleteBeneficiary(id);

    await _reloadCurrentView();
  }

  Future<void> deleteBeneficiaries(
    List<int> ids,
  ) async {
    if (ids.isEmpty) return;

    await _repository.deleteBeneficiaries(ids);

    await _reloadCurrentView();
  }

  Future<void> deleteAll() async {
    if (_isDataMode) {
      throw StateError(
        'لا يمكن حذف جميع المستفيدين من مجلد Data.',
      );
    }

    final batchId = _currentBatchId;

    if (batchId == null) {
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      await _databaseService.deleteAllBeneficiaries(
        batchId: batchId,
      );

      _beneficiaries = [];
      _uniqueCount = await _repository.getUniqueBeneficiariesCount();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clear() {
    _beneficiaries = [];
    _uniqueCount = 0;
    _currentBatchId = null;
    _isDataMode = false;
    _isLoading = false;

    notifyListeners();
  }
}
