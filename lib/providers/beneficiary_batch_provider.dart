import 'package:flutter/material.dart';

import '../models/beneficiary_batch.dart';
import '../repositories/beneficiary_batch_repository.dart';
import '../services/app_error_message.dart';

class BeneficiaryBatchProvider extends ChangeNotifier {
  final BeneficiaryBatchRepository _repository;

  BeneficiaryBatchProvider({
    BeneficiaryBatchRepository? repository,
  }) : _repository = repository ?? BeneficiaryBatchRepository();

  List<BeneficiaryBatch> _batches = [];
  Map<int, int> _beneficiaryCounts = {};

  bool _isLoading = false;
  String? _errorMessage;

  List<BeneficiaryBatch> get batches => List.unmodifiable(_batches);

  Map<int, int> get beneficiaryCounts => Map.unmodifiable(_beneficiaryCounts);

  bool get isLoading => _isLoading;

  String? get errorMessage => _errorMessage;

  bool get hasError => _errorMessage != null;

  bool get isEmpty => _batches.isEmpty;

  int get count => _batches.length;

  Future<void> loadBatches() async {
    _setLoading(true);
    _clearError();

    try {
      final results = await Future.wait([
        _repository.getAllBatches(),
        _repository.getBatchBeneficiaryCounts(),
      ]);

      _batches = results[0] as List<BeneficiaryBatch>;

      _beneficiaryCounts = results[1] as Map<int, int>;
    } catch (error) {
      _setError(
        AppErrorMessage.from(error, action: 'تحميل الكشوفات'),
      );
    } finally {
      _setLoading(false);
    }
  }

  Future<BeneficiaryBatch?> createBatch({
    required String name,
    required String originalFileName,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final batch = await _repository.createBatch(
        name: name,
        originalFileName: originalFileName,
      );

      _batches.insert(0, batch);

      if (batch.id != null) {
        _beneficiaryCounts[batch.id!] = 0;
      }

      notifyListeners();

      return batch;
    } catch (error) {
      _setError(
        AppErrorMessage.from(error, action: 'إنشاء الكشف'),
      );

      return null;
    } finally {
      _setLoading(false);
    }
  }

  Future<String?> renameBatch({
    required int batchId,
    required String newName,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final updatedName = await _repository.renameBatch(
        batchId: batchId,
        newName: newName,
      );

      final index = _batches.indexWhere(
        (batch) => batch.id == batchId,
      );

      if (index != -1) {
        _batches[index] = _batches[index].copyWith(
          name: updatedName,
        );
      }

      notifyListeners();

      return updatedName;
    } catch (error) {
      _setError(
        AppErrorMessage.from(error, action: 'إعادة تسمية الكشف'),
      );

      return null;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> deleteBatch(
    int batchId,
  ) async {
    _setLoading(true);
    _clearError();

    try {
      await _repository.deleteBatch(batchId);

      _batches.removeWhere(
        (batch) => batch.id == batchId,
      );

      _beneficiaryCounts.remove(batchId);

      notifyListeners();

      return true;
    } catch (error) {
      _setError(
        AppErrorMessage.from(error, action: 'حذف الكشف'),
      );

      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> refreshBatchCount(
    int batchId,
  ) async {
    try {
      final count = await _repository.getBatchBeneficiariesCount(
        batchId,
      );

      _beneficiaryCounts[batchId] = count;

      notifyListeners();
    } catch (error) {
      _setError(
        AppErrorMessage.from(error, action: 'تحديث عدد المستفيدين'),
      );
    }
  }

  Future<void> refreshAllCounts() async {
    try {
      _beneficiaryCounts = await _repository.getBatchBeneficiaryCounts();

      notifyListeners();
    } catch (error) {
      _setError(
        AppErrorMessage.from(error, action: 'تحديث أعداد المستفيدين'),
      );
    }
  }

  int getBeneficiariesCount(
    int batchId,
  ) {
    return _beneficiaryCounts[batchId] ?? 0;
  }

  BeneficiaryBatch? getBatchById(
    int batchId,
  ) {
    try {
      return _batches.firstWhere(
        (batch) => batch.id == batchId,
      );
    } catch (_) {
      return null;
    }
  }

  Future<bool> batchNameExists(
    String name,
  ) {
    return _repository.batchNameExists(
      name.trim(),
    );
  }

  void clearError() {
    _clearError();
    notifyListeners();
  }

  void clear() {
    _batches = [];
    _beneficiaryCounts = {};
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }
}
