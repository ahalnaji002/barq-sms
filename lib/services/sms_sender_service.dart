import 'dart:async';

import 'package:flutter/services.dart';

import '../models/sms_log.dart';
import 'app_error_message.dart';
import 'database_service.dart';

class SmsSenderService {
  SmsSenderService._() {
    _channel.setMethodCallHandler(_handleNativeStatus);
  }

  static final SmsSenderService instance = SmsSenderService._();
  static const _channel = MethodChannel('barq_sms/sms_sender');

  final Map<int, Completer<SmsLogStatus>> _pending = {};

  Future<SmsLogStatus> send({
    required int logId,
    required String phoneNumber,
    required String message,
  }) async {
    final completer = Completer<SmsLogStatus>();
    _pending[logId] = completer;
    try {
      await _channel.invokeMethod<void>('sendSms', {
        'logId': logId,
        'phoneNumber': phoneNumber,
        'message': message,
      });
      return await completer.future.timeout(
        const Duration(seconds: 45),
        onTimeout: () async {
          _pending.remove(logId);
          await DatabaseService.instance.updateSmsLogStatus(
            logId,
            SmsLogStatus.failed,
            errorMessage: 'انتهت مهلة انتظار نتيجة الإرسال من النظام',
          );
          return SmsLogStatus.failed;
        },
      );
    } on PlatformException catch (error) {
      _pending.remove(logId);
      await DatabaseService.instance.updateSmsLogStatus(
        logId,
        SmsLogStatus.failed,
        errorMessage: AppErrorMessage.from(error, action: 'إرسال الرسالة'),
      );
      return SmsLogStatus.failed;
    }
  }

  Future<void> _handleNativeStatus(MethodCall call) async {
    if (call.method != 'smsStatus') return;
    final args = Map<String, dynamic>.from(call.arguments as Map);
    final logId = args['logId'] as int;
    final status = SmsLogStatus.values.firstWhere(
      (value) => value.name == args['status'],
      orElse: () => SmsLogStatus.failed,
    );
    final nativeError = args['error']?.toString();
    final error = status == SmsLogStatus.failed && nativeError != null
        ? AppErrorMessage.from(
            PlatformException(
              code: 'native_sms_failure',
              message: nativeError,
            ),
            action: 'إرسال الرسالة',
          )
        : nativeError;
    await DatabaseService.instance.updateSmsLogStatus(
      logId,
      status,
      errorMessage: error,
    );
    if (status == SmsLogStatus.sent || status == SmsLogStatus.failed) {
      final completer = _pending.remove(logId);
      if (completer != null && !completer.isCompleted) {
        completer.complete(status);
      }
    }
  }
}
