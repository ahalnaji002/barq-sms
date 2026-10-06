import 'dart:typed_data';

import 'package:barq_sms/services/excel_service.dart';
import 'package:excel/excel.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ExcelService', () {
    test('detects reordered Arabic columns after a title row', () {
      final excel = Excel.createExcel();
      final sheet = excel['بيانات'];
      sheet.appendRow([TextCellValue('كشف المستفيدين')]);
      sheet.appendRow([
        TextCellValue('رقم الجوال'),
        TextCellValue('المنطقة'),
        TextCellValue('اسم المستفيد'),
        TextCellValue('عدد أفراد الأسرة'),
        TextCellValue('رقم الهوية'),
      ]);
      sheet.appendRow([
        TextCellValue('0591234567'),
        TextCellValue('غزة'),
        TextCellValue('محمد أحمد'),
        const IntCellValue(5),
        TextCellValue('123456789'),
      ]);

      final result = _read(excel);

      expect(result.sheetName, 'بيانات');
      expect(result.importedCount, 1);
      expect(result.beneficiaries.single.name, 'محمد أحمد');
      expect(result.beneficiaries.single.familyMembers, 5);
    });

    test('finds a valid sheet instead of always using the first one', () {
      final excel = Excel.createExcel();
      excel['Sheet1'].appendRow([TextCellValue('تعليمات الملف')]);
      final data = excel['Data'];
      data.appendRow([
        TextCellValue('Name'),
        TextCellValue('National ID'),
        TextCellValue('Phone Number'),
      ]);
      data.appendRow([
        TextCellValue('Ali Hasan'),
        TextCellValue('987654321'),
        TextCellValue('+970591234567'),
      ]);

      final result = _read(excel);

      expect(result.sheetName, 'Data');
      expect(result.importedCount, 1);
      expect(result.beneficiaries.single.phoneNumber, '0591234567');
    });

    test('imports optional student and guardian name columns', () {
      final excel = Excel.createExcel();
      final sheet = excel['بيانات'];
      sheet.appendRow([
        TextCellValue('اسم الطالب'),
        TextCellValue('اسم ولي الأمر'),
        TextCellValue('اسم المستفيد'),
        TextCellValue('رقم الهوية'),
        TextCellValue('رقم الجوال'),
      ]);
      sheet.appendRow([
        TextCellValue('سارة أحمد'),
        TextCellValue('أحمد محمد'),
        TextCellValue('أحمد محمد'),
        TextCellValue('123456789'),
        TextCellValue('0591234567'),
      ]);

      final result = _read(excel);
      final beneficiary = result.beneficiaries.first;

      expect(beneficiary.studentName, 'سارة أحمد');
      expect(beneficiary.guardianName, 'أحمد محمد');
    });

    test('accepts student and guardian names with phone and no national ID',
        () {
      final excel = Excel.createExcel();
      final sheet = excel['كشف الطلاب'];
      sheet.appendRow([
        TextCellValue('اسم الطالب'),
        TextCellValue('اسم ولي الأمر'),
        TextCellValue('رقم الجوال'),
      ]);
      sheet.appendRow([
        TextCellValue('سارة أحمد'),
        TextCellValue('أحمد محمد'),
        TextCellValue('0591234567'),
      ]);
      sheet.appendRow([
        TextCellValue('ليان أحمد'),
        TextCellValue('أحمد محمد'),
        TextCellValue('0561234567'),
      ]);

      final result = _read(excel);
      final beneficiary = result.beneficiaries.first;

      expect(result.importedCount, 2);
      expect(beneficiary.name, 'أحمد محمد');
      expect(beneficiary.studentName, 'سارة أحمد');
      expect(beneficiary.guardianName, 'أحمد محمد');
      expect(beneficiary.nationalId, isEmpty);
    });

    test('does not discard row zero in a headerless legacy file', () {
      final excel = Excel.createExcel();
      excel['Sheet1'].appendRow([
        const IntCellValue(1),
        TextCellValue('أحمد علي'),
        TextCellValue('123456789'),
        TextCellValue('0561234567'),
        TextCellValue('رفح'),
        const IntCellValue(4),
      ]);

      final result = _read(excel);

      expect(result.importedCount, 1);
      expect(result.beneficiaries.single.name, 'أحمد علي');
    });

    test('rejects a workbook without required columns', () {
      final excel = Excel.createExcel();
      excel['Sheet1'].appendRow([
        TextCellValue('ملاحظات'),
        TextCellValue('قيمة'),
      ]);

      expect(() => _read(excel), throwsA(isA<FormatException>()));
    });
  });
}

ExcelImportResult _read(Excel excel) {
  final encoded = excel.encode();
  expect(encoded, isNotNull);
  return ExcelService().readExcelBytes(
    Uint8List.fromList(encoded!),
    fileName: 'test.xlsx',
  );
}
