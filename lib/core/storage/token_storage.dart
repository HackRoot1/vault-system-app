import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class TokenStorage {
  const TokenStorage._();

  static const _tokenKey = 'auth_token';
  static const _userNameKey = 'user_name';
  static const _userEmailKey = 'user_email';
  static const _cryptoSaltKey = 'crypto_salt';
  static const _cryptoIterationsKey = 'crypto_iterations';

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

  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userNameKey);
    await prefs.remove(_userEmailKey);
    await prefs.remove(_cryptoSaltKey);
    await prefs.remove(_cryptoIterationsKey);
    _inMemoryMasterPassword = null;
  }

  static Future<bool> hasSession() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
}
