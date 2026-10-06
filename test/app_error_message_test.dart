import 'package:barq_sms/services/app_error_message.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppErrorMessage', () {
    test('preserves actionable application state errors', () {
      expect(
        AppErrorMessage.from(StateError('تعذر فتح البيانات المشفرة.')),
        'تعذر فتح البيانات المشفرة.',
      );
    });

    test('replaces raw database failures with a safe next step', () {
      final message = AppErrorMessage.from(
        Exception('DatabaseException(open_failed /data/user/0/app.db)'),
        action: 'تحميل البيانات',
      );

      expect(message, contains('لا تحذف بيانات التطبيق'));
      expect(message, isNot(contains('/data/user/0')));
    });

    test('explains missing Android permissions without native details', () {
      final message = AppErrorMessage.from(
        PlatformException(code: 'permission_denied', message: 'native text'),
        action: 'إرسال الرسائل',
      );

      expect(message, contains('أذونات التطبيق'));
      expect(message, isNot(contains('native text')));
    });

    test('gives a useful message for unreadable Excel files', () {
      final message = AppErrorMessage.from(
        const FormatException('Unexpected token near byte 12'),
        action: 'استيراد الملف',
      );

      expect(message, contains('ملف Excel بصيغة xlsx'));
    });
  });
}
