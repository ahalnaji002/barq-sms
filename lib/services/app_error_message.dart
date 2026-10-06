import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';

/// Converts technical exceptions into short, actionable Arabic messages.
class AppErrorMessage {
  static String from(
    Object error, {
    String action = 'إكمال العملية',
  }) {
    if (error is StateError) {
      final message = error.message.toString().trim();
      if (message.isNotEmpty) return message;
    }

    if (error is FormatException) {
      final message = error.message.trim();
      if (message.contains(RegExp(r'[\u0600-\u06FF]'))) return message;
      return 'تعذر قراءة الملف. تأكد أنه ملف Excel بصيغة xlsx ويحتوي الأعمدة المطلوبة.';
    }

    if (error is FileSystemException) {
      return 'تعذر الوصول إلى الملف. تحقق من وجوده وصلاحية الوصول إليه، ثم أعد المحاولة.';
    }

    if (error is TimeoutException) {
      return 'انتهى وقت الانتظار أثناء $action. تحقق من حالة العملية ثم أعد المحاولة.';
    }

    if (error is PlatformException) {
      final code = error.code.toLowerCase();
      if (code.contains('permission') || code.contains('security')) {
        return 'لا توجد صلاحية كافية لإتمام العملية. راجع أذونات التطبيق من إعدادات الهاتف.';
      }
      if (code.contains('sim')) {
        return 'تعذر إرسال الرسالة. تحقق من وجود شريحة اتصال فعالة.';
      }
      if (code.contains('sms') || code.contains('telephony')) {
        return 'تعذر إرسال الرسالة. تحقق من الرقم والتغطية وصلاحية الرسائل، ثم أعد المحاولة.';
      }
    }

    final details = error.toString().toLowerCase();
    if (details.contains('open_failed') ||
        details.contains('databaseexception') ||
        details.contains('sqlcipher') ||
        details.contains('sqlite')) {
      if (details.contains('unique constraint') ||
          details.contains('constraint failed')) {
        return 'تعذر حفظ البيانات بسبب قيمة مكررة. تحقق من رقم الهوية أو رقم الجوال.';
      }
      return 'تعذر فتح قاعدة البيانات أو حفظ البيانات. أغلق التطبيق وافتحه مجددًا، '
          'ولا تحذف بيانات التطبيق. إذا استمرت المشكلة، أرسل صورة الخطأ للدعم.';
    }

    return 'تعذر $action. أعد المحاولة، وإذا تكررت المشكلة أغلق التطبيق وافتحه مجددًا.';
  }
}
