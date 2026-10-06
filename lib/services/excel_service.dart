import 'dart:io';
import 'dart:typed_data';

import 'package:excel/excel.dart' as ex;
import 'package:file_picker/file_picker.dart';

import '../models/beneficiary.dart';

class ExcelImportResult {
  final String fileName;
  final String sheetName;
  final List<Beneficiary> beneficiaries;
  final int emptyRows;
  final int invalidNameRows;
  final int invalidPhoneRows;
  final int invalidNationalIdRows;
  final int duplicatePhoneRows;
  final int duplicateNationalIdRows;

  const ExcelImportResult({
    required this.fileName,
    this.sheetName = '',
    required this.beneficiaries,
    required this.emptyRows,
    required this.invalidNameRows,
    required this.invalidPhoneRows,
    required this.invalidNationalIdRows,
    required this.duplicatePhoneRows,
    required this.duplicateNationalIdRows,
  });

  int get importedCount => beneficiaries.length;

  int get skippedRows =>
      emptyRows +
      invalidNameRows +
      invalidPhoneRows +
      invalidNationalIdRows +
      duplicatePhoneRows +
      duplicateNationalIdRows;
}

enum _Column {
  serial,
  name,
  studentName,
  guardianName,
  nationalId,
  phone,
  area,
  familyMembers,
}

class _SheetLayout {
  final String name;
  final ex.Sheet sheet;
  final int firstDataRow;
  final Map<_Column, int> columns;

  const _SheetLayout(this.name, this.sheet, this.firstDataRow, this.columns);
}

class ExcelService {
  static const Map<_Column, List<String>> _aliases = {
    _Column.serial: [
      'م',
      'الرقم',
      'رقم',
      'رقم تسلسلي',
      'الرقم التسلسلي',
      'serial',
      'serial number',
      'no',
      'number',
    ],
    _Column.name: [
      'الاسم',
      'اسم',
      'اسم المستفيد',
      'المستفيد',
      'name',
      'beneficiary',
      'beneficiary name',
      'full name',
    ],
    _Column.studentName: [
      'اسم الطالب',
      'اسم الطالبة',
      'اسم الطالب/ة',
      'اسم الطالب او الطالبة',
      'student name',
      'pupil name',
    ],
    _Column.guardianName: [
      'اسم ولي الامر',
      'ولي الامر',
      'اسم الوصي',
      'اسم الوالد',
      'اسم الاب',
      'اسم الأم',
      'اسم الام',
      'guardian name',
      'parent name',
    ],
    _Column.nationalId: [
      'رقم الهوية',
      'الهوية',
      'رقم الهويه',
      'الهويه',
      'هوية',
      'national id',
      'nationalid',
      'id number',
      'identity number',
    ],
    _Column.phone: [
      'رقم الجوال',
      'الجوال',
      'رقم الهاتف',
      'الهاتف',
      'رقم الموبايل',
      'الموبايل',
      'phone',
      'phone number',
      'mobile',
      'mobile number',
    ],
    _Column.area: [
      'المنطقة',
      'منطقة',
      'العنوان',
      'المحافظة',
      'area',
      'address',
      'location',
    ],
    _Column.familyMembers: [
      'عدد افراد الاسرة',
      'افراد الاسرة',
      'عدد أفراد الأسرة',
      'أفراد الأسرة',
      'عدد الافراد',
      'عدد الأفراد',
      'family members',
      'family size',
      'members',
    ],
  };

  Future<ExcelImportResult?> pickAndReadExcelFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
      allowMultiple: false,
    );
    if (result == null) return null;

    final selectedFile = result.files.single;
    final path = selectedFile.path;
    if (path == null || path.isEmpty) {
      throw Exception('تعذر الوصول إلى مسار الملف.');
    }

    return readExcelBytes(
      await File(path).readAsBytes(),
      fileName: selectedFile.name,
    );
  }

  /// منفصلة عن منتقي الملفات حتى تكون قواعد الاستيراد قابلة للاختبار.
  ExcelImportResult readExcelBytes(
    Uint8List bytes, {
    required String fileName,
  }) {
    final workbook = ex.Excel.decodeBytes(bytes);
    if (workbook.tables.isEmpty) {
      throw const FormatException('ملف Excel لا يحتوي على أوراق عمل.');
    }

    final layout = _findLayout(workbook);
    if (layout == null) {
      throw const FormatException(
        'لم يتم العثور على ورقة بيانات صالحة. يجب أن يحتوي الملف على '
        'عمود رقم الجوال، وعمود واحد على الأقل للاسم أو اسم الطالب أو ولي الأمر.',
      );
    }

    final beneficiaries = <Beneficiary>[];
    final seenPhones = <String>{};
    final seenNationalIds = <String>{};
    var emptyRows = 0;
    var invalidNames = 0;
    var invalidPhones = 0;
    var invalidNationalIds = 0;
    var duplicatePhones = 0;
    var duplicateNationalIds = 0;

    for (var index = layout.firstDataRow;
        index < layout.sheet.rows.length;
        index++) {
      final row = layout.sheet.rows[index];
      if (row.every((cell) =>
          cell?.value == null || cell!.value.toString().trim().isEmpty)) {
        emptyRows++;
        continue;
      }

      final studentName =
          _value(row, layout.columns, _Column.studentName).trim();
      final guardianName =
          _value(row, layout.columns, _Column.guardianName).trim();
      final name = _value(row, layout.columns, _Column.name).trim().isNotEmpty
          ? _value(row, layout.columns, _Column.name).trim()
          : guardianName.isNotEmpty
              ? guardianName
              : studentName;
      final nationalId = Beneficiary.normalizeNationalId(
        _value(row, layout.columns, _Column.nationalId),
      );
      final phone = Beneficiary.normalizePhoneNumber(
        _value(row, layout.columns, _Column.phone),
      );

      if (!Beneficiary.isValidName(name)) {
        invalidNames++;
        continue;
      }
      if (!Beneficiary.isValidPhoneNumber(phone)) {
        invalidPhones++;
        continue;
      }
      if (nationalId.isNotEmpty && !Beneficiary.isValidNationalId(nationalId)) {
        invalidNationalIds++;
        continue;
      }
      if (!seenPhones.add(phone)) {
        duplicatePhones++;
        continue;
      }
      if (nationalId.isNotEmpty && !seenNationalIds.add(nationalId)) {
        seenPhones.remove(phone);
        duplicateNationalIds++;
        continue;
      }

      final serial = _parseInteger(
        _value(row, layout.columns, _Column.serial),
      );
      beneficiaries.add(Beneficiary(
        serialNumber: serial > 0 ? serial : beneficiaries.length + 1,
        name: name,
        nationalId: nationalId,
        phoneNumber: phone,
        area: _value(row, layout.columns, _Column.area).trim(),
        studentName: studentName,
        guardianName: guardianName,
        familyMembers: _parseInteger(
          _value(row, layout.columns, _Column.familyMembers),
        ),
      ));
    }

    return ExcelImportResult(
      fileName: fileName,
      sheetName: layout.name,
      beneficiaries: beneficiaries,
      emptyRows: emptyRows,
      invalidNameRows: invalidNames,
      invalidPhoneRows: invalidPhones,
      invalidNationalIdRows: invalidNationalIds,
      duplicatePhoneRows: duplicatePhones,
      duplicateNationalIdRows: duplicateNationalIds,
    );
  }

  _SheetLayout? _findLayout(ex.Excel workbook) {
    _SheetLayout? headerlessFallback;
    for (final entry in workbook.tables.entries) {
      final sheet = entry.value;
      if (sheet.rows.isEmpty) continue;

      final limit = sheet.rows.length < 25 ? sheet.rows.length : 25;
      for (var rowIndex = 0; rowIndex < limit; rowIndex++) {
        final columns = _detectColumns(sheet.rows[rowIndex]);
        if (_hasRequiredColumns(columns)) {
          return _SheetLayout(entry.key, sheet, rowIndex + 1, columns);
        }
      }

      // توافق مع الملفات القديمة بلا عناوين، من دون إسقاط أول سجل.
      if (headerlessFallback == null &&
          _looksLikeLegacyData(sheet.rows.first)) {
        headerlessFallback = _SheetLayout(entry.key, sheet, 0, const {
          _Column.serial: 0,
          _Column.name: 1,
          _Column.nationalId: 2,
          _Column.phone: 3,
          _Column.area: 4,
          _Column.familyMembers: 5,
        });
      }
    }
    return headerlessFallback;
  }

  Map<_Column, int> _detectColumns(List<ex.Data?> row) {
    final result = <_Column, int>{};
    for (var index = 0; index < row.length; index++) {
      final header = _normalizeHeader(_cellValue(row, index));
      if (header.isEmpty) continue;
      for (final entry in _aliases.entries) {
        if (!result.containsKey(entry.key) &&
            entry.value.any((alias) => _normalizeHeader(alias) == header)) {
          result[entry.key] = index;
          break;
        }
      }
    }
    return result;
  }

  bool _hasRequiredColumns(Map<_Column, int> columns) =>
      columns.containsKey(_Column.phone) &&
      (columns.containsKey(_Column.name) ||
          columns.containsKey(_Column.studentName) ||
          columns.containsKey(_Column.guardianName));

  bool _looksLikeLegacyData(List<ex.Data?> row) =>
      Beneficiary.isValidName(_cellValue(row, 1)) &&
      Beneficiary.isValidNationalId(_cellValue(row, 2)) &&
      Beneficiary.isValidPhoneNumber(_cellValue(row, 3));

  String _normalizeHeader(String value) =>
      Beneficiary.convertArabicNumbersToEnglish(value)
          .trim()
          .toLowerCase()
          .replaceAll(RegExp(r'[أإآ]'), 'ا')
          .replaceAll('ة', 'ه')
          .replaceAll(RegExp(r'[_\-./\\]+'), ' ')
          .replaceAll(RegExp(r'\s+'), ' ');

  String _value(List<ex.Data?> row, Map<_Column, int> columns, _Column column) {
    final index = columns[column];
    return index == null ? '' : _cellValue(row, index);
  }

  String _cellValue(List<ex.Data?> row, int index) {
    if (index < 0 || index >= row.length) return '';
    return row[index]?.value?.toString().trim() ?? '';
  }

  int _parseInteger(String value) {
    final cleaned = Beneficiary.convertArabicNumbersToEnglish(value)
        .replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(cleaned) ?? 0;
  }
}
