import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AppSecurityProvider extends ChangeNotifier {
  static const _pinHashKey = 'barq_app_pin_hash_v1';
  static const _pinSaltKey = 'barq_app_pin_salt_v1';

  final FlutterSecureStorage _storage;

  AppSecurityProvider({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(
                storageNamespace: 'barq_sms_security',
                migrateWithBackup: true,
              ),
            );

  bool _initialized = false;
  bool _isEnabled = false;
  bool _isUnlocked = true;

  bool get initialized => _initialized;
  bool get isEnabled => _isEnabled;
  bool get isUnlocked => !_isEnabled || _isUnlocked;

  Future<void> initialize() async {
    _isEnabled = await _storage.containsKey(key: _pinHashKey);
    _isUnlocked = !_isEnabled;
    _initialized = true;
    notifyListeners();
  }

  Future<void> enable(String pin) async {
    _validatePin(pin);
    final salt = _randomSalt();
    await _storage.write(key: _pinSaltKey, value: salt);
    await _storage.write(key: _pinHashKey, value: _hash(pin, salt));
    _isEnabled = true;
    _isUnlocked = true;
    notifyListeners();
  }

  Future<bool> unlock(String pin) async {
    final isValid = await verifyPin(pin);
    if (isValid) {
      _isUnlocked = true;
      notifyListeners();
    }
    return isValid;
  }

  Future<bool> verifyPin(String pin) async {
    final salt = await _storage.read(key: _pinSaltKey);
    final expectedHash = await _storage.read(key: _pinHashKey);
    if (salt == null || expectedHash == null) return false;
    return _constantTimeEquals(_hash(pin, salt), expectedHash);
  }

  Future<bool> changePin(String currentPin, String newPin) async {
    if (!await verifyPin(currentPin)) return false;
    await enable(newPin);
    return true;
  }

  Future<bool> disable(String pin) async {
    if (!await verifyPin(pin)) return false;
    await clearPin();
    return true;
  }

  Future<void> clearPin() async {
    await _storage.delete(key: _pinHashKey);
    await _storage.delete(key: _pinSaltKey);
    _isEnabled = false;
    _isUnlocked = true;
    notifyListeners();
  }

  void lock() {
    if (!_isEnabled || !_isUnlocked) return;
    _isUnlocked = false;
    notifyListeners();
  }

  void _validatePin(String pin) {
    if (!RegExp(r'^\d{4,8}$').hasMatch(pin)) {
      throw const FormatException('يجب أن يتكون رمز PIN من 4 إلى 8 أرقام.');
    }
  }

  String _randomSalt() {
    final random = Random.secure();
    return base64Url.encode(List<int>.generate(32, (_) => random.nextInt(256)));
  }

  String _hash(String pin, String salt) {
    return sha256.convert(utf8.encode('$salt:$pin')).toString();
  }

  bool _constantTimeEquals(String left, String right) {
    if (left.length != right.length) return false;
    var difference = 0;
    for (var index = 0; index < left.length; index++) {
      difference |= left.codeUnitAt(index) ^ right.codeUnitAt(index);
    }
    return difference == 0;
  }
}
