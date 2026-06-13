import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';

class TokenStorage {
  const TokenStorage._();

  static final _secureStorage = FlutterSecureStorage(
    aOptions: const AndroidOptions(encryptedSharedPreferences: true),
  );
  static final _localAuth = LocalAuthentication();

  static const _tokenKey = 'auth_token';
  static const _userNameKey = 'user_name';
  static const _userEmailKey = 'user_email';
  static const _cryptoSaltKey = 'crypto_salt';
  static const _cryptoIterationsKey = 'crypto_iterations';
  static const _biometricEnabledKey = 'biometric_enabled';
  static const _masterPasswordKey = 'vault_master_password';

  static String? _inMemoryMasterPassword;

  static Future<void> saveSession({
    required String token,
    required String name,
    required String email,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_userNameKey, name);
    await prefs.setString(_userEmailKey, email);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<String?> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userNameKey);
  }

  static Future<String?> getUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userEmailKey);
  }

  static Future<void> saveCrypto({
    required String salt,
    required int iterations,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cryptoSaltKey, salt);
    await prefs.setInt(_cryptoIterationsKey, iterations);
  }

  static Future<String?> getCryptoSalt() async {
    final prefs = await SharedPreferences.getInstance();
    final salt = prefs.getString(_cryptoSaltKey);
    debugPrint('[TokenStorage] getCryptoSalt: $salt');
    return salt;
  }

  static Future<int> getCryptoIterations() async {
    final prefs = await SharedPreferences.getInstance();
    final iterations = prefs.getInt(_cryptoIterationsKey) ?? 100000;
    debugPrint('[TokenStorage] getCryptoIterations: $iterations');
    return iterations;
  }

  static void setMasterPassword(String password) {
    _inMemoryMasterPassword = password;
  }

  static String? getMasterPassword() => _inMemoryMasterPassword;

  static Future<void> saveMasterPasswordSecure(String password) async {
    if (password.isEmpty) return;
    try {
      await _secureStorage.write(key: _masterPasswordKey, value: password);
    } catch (e) {
      debugPrint('[TokenStorage] saveMasterPasswordSecure failed: $e');
    }
  }

  static Future<String?> getMasterPasswordSecure() async {
    try {
      return await _secureStorage.read(key: _masterPasswordKey);
    } catch (e) {
      debugPrint('[TokenStorage] getMasterPasswordSecure failed: $e');
      return null;
    }
  }

  static Future<void> clearSecureMasterPassword() async {
    try {
      await _secureStorage.delete(key: _masterPasswordKey);
    } catch (e) {
      debugPrint('[TokenStorage] clearSecureMasterPassword failed: $e');
    }
  }

  static Future<bool> isBiometricAvailable() async {
    try {
      return await _localAuth.isDeviceSupported() &&
          await _localAuth.canCheckBiometrics;
    } catch (e) {
      debugPrint('[TokenStorage] isBiometricAvailable failed: $e');
      return false;
    }
  }

  static Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      debugPrint('[TokenStorage] getAvailableBiometrics failed: $e');
      return <BiometricType>[];
    }
  }

  static Future<String> getBiometricLabel() async {
    final biometrics = await getAvailableBiometrics();
    if (biometrics.contains(BiometricType.face)) return 'Face ID';
    if (biometrics.contains(BiometricType.fingerprint)) return 'Fingerprint';
    if (biometrics.contains(BiometricType.iris)) return 'Iris';
    return 'Biometrics';
  }

  static Future<bool> authenticateBiometric({
    String reason = 'Authenticate to unlock your vault',
  }) async {
    try {
      if (!await isBiometricAvailable()) return false;
      return await _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
          useErrorDialogs: true,
        ),
      );
    } catch (e) {
      debugPrint('[TokenStorage] authenticateBiometric failed: $e');
      return false;
    }
  }

  static Future<bool> isBiometricEnabled() async {
    if (!await isBiometricAvailable()) return false;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_biometricEnabledKey) ?? false;
  }

  static Future<void> setBiometricEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_biometricEnabledKey, value);
  }

  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userNameKey);
    await prefs.remove(_userEmailKey);
    await prefs.remove(_cryptoSaltKey);
    await prefs.remove(_cryptoIterationsKey);
    await prefs.remove(_biometricEnabledKey);
    await clearSecureMasterPassword();
    _inMemoryMasterPassword = null;
  }

  static Future<bool> hasSession() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
}
