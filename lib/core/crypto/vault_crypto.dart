import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

class VaultCrypto {
  // Base64
  // Web btoa() produces standard base64 WITH padding.
  // Some web implementations may omit padding.
  // Always normalize before decoding.

  static Uint8List _b64Decode(String input) {
    var s = input.replaceAll('-', '+').replaceAll('_', '/');
    switch (s.length % 4) {
      case 0:
        break;
      case 2:
        s += '==';
      case 3:
        s += '=';
      default:
        throw const FormatException('Bad base64 length');
    }
    return base64.decode(s);
  }

  static String _b64Encode(List<int> bytes) {
    return base64.encode(bytes);
  }

  // Key Derivation

  static Future<SecretKey> deriveKey({
    required String masterPassword,
    required String saltHex,
    required int iterations,
  }) async {
    final pbkdf2 = Pbkdf2(
      macAlgorithm: Hmac.sha256(),
      iterations: iterations,
      bits: 256,
    );
    return pbkdf2.deriveKey(
      secretKey: SecretKey(utf8.encode(masterPassword)),
      nonce: _hexDecode(saltHex),
    );
  }

  // Encryption
  // Web Crypto output: [ciphertext bytes | 16 tag bytes]
  // We split: encrypted_data = base64(ciphertext), tag = base64(last 16)
  // Flutter cryptography package does the same split via secretBox.

  static Future<EncryptedPayload> encrypt({
    required String plainText,
    required SecretKey key,
  }) async {
    final algorithm = AesGcm.with256bits(nonceLength: 12);
    final iv = _randomBytes(12);

    final secretBox = await algorithm.encrypt(
      utf8.encode(plainText),
      secretKey: key,
      nonce: iv,
    );

    // secretBox.cipherText = ciphertext WITHOUT tag.
    // secretBox.mac.bytes  = 16-byte tag.
    return EncryptedPayload(
      encryptedData: _b64Encode(secretBox.cipherText),
      iv: _b64Encode(iv),
      tag: _b64Encode(secretBox.mac.bytes),
    );
  }

  // Decryption
  // Web sends: encrypted_data = base64(ciphertext), tag = base64(16-byte tag)
  // We recombine them into SecretBox for the cryptography package.

  static Future<String> decrypt({
    required String encryptedDataB64,
    required String ivB64,
    required String tagB64,
    required SecretKey key,
  }) async {
    final algorithm = AesGcm.with256bits(nonceLength: 12);

    final cipherText = _b64Decode(encryptedDataB64);
    final iv = _b64Decode(ivB64);
    final tag = _b64Decode(tagB64);

    assert(iv.length == 12, 'IV must be 12 bytes, got ${iv.length}');
    assert(tag.length == 16, 'Tag must be 16 bytes, got ${tag.length}');

    final secretBox = SecretBox(cipherText, nonce: iv, mac: Mac(tag));

    final plainBytes = await algorithm.decrypt(secretBox, secretKey: key);

    return utf8.decode(plainBytes);
  }

  static Future<Uint8List> decryptBytes({
    required Uint8List encryptedBytes,
    required String ivB64,
    required String tagB64,
    required SecretKey key,
  }) async {
    final algorithm = AesGcm.with256bits(nonceLength: 12);
    final iv = _b64Decode(ivB64);
    final tag = _b64Decode(tagB64);

    if (iv.length != 12) {
      throw FormatException('IV must be 12 bytes, got ${iv.length}');
    }
    if (tag.length != 16) {
      throw FormatException('Tag must be 16 bytes, got ${tag.length}');
    }

    Future<Uint8List> decryptWith(
      Uint8List cipherText,
      Uint8List macBytes,
    ) async {
      final secretBox = SecretBox(cipherText, nonce: iv, mac: Mac(macBytes));
      final plainBytes = await algorithm.decrypt(secretBox, secretKey: key);
      return Uint8List.fromList(plainBytes);
    }

    Object? lastError;

    try {
      return await decryptWith(encryptedBytes, tag);
    } catch (error) {
      lastError = error;
    }

    // Some download endpoints return a base64-encoded payload instead of raw
    // ciphertext bytes. Normalize that format before giving up.
    try {
      final decoded = utf8.decode(encryptedBytes, allowMalformed: false).trim();
      if (_looksLikeBase64(decoded)) {
        return await decryptWith(_b64Decode(decoded), tag);
      }
    } catch (_) {
      // Ignore and keep trying other recovery paths.
    }

    // If the server ever returns ciphertext with the tag appended, split it
    // back out and retry. This keeps downloads working across backend variants.
    if (encryptedBytes.length > 16) {
      try {
        final cipherText = Uint8List.sublistView(
          encryptedBytes,
          0,
          encryptedBytes.length - 16,
        );
        final macBytes = Uint8List.sublistView(
          encryptedBytes,
          encryptedBytes.length - 16,
        );
        return await decryptWith(cipherText, macBytes);
      } catch (_) {
        // Fall through to the original error below.
      }
    }

    Error.throwWithStackTrace(
      StateError('Unable to decrypt downloaded bytes: $lastError'),
      StackTrace.current,
    );
  }

  // Helpers

  static Uint8List _randomBytes(int n) {
    final rng = Random.secure();
    return Uint8List.fromList(List.generate(n, (_) => rng.nextInt(256)));
  }

  static Uint8List _hexDecode(String hex) {
    final h = hex.replaceAll(' ', '').toLowerCase();
    final out = Uint8List(h.length ~/ 2);
    for (var i = 0; i < out.length; i++) {
      out[i] = int.parse(h.substring(i * 2, i * 2 + 2), radix: 16);
    }
    return out;
  }

  static bool _looksLikeBase64(String value) {
    if (value.isEmpty || value.length % 4 != 0) {
      return false;
    }

    return RegExp(r'^[A-Za-z0-9+/_-]+={0,2}$').hasMatch(value);
  }
}

class EncryptedPayload {
  const EncryptedPayload({
    required this.encryptedData,
    required this.iv,
    required this.tag,
  });

  final String encryptedData;
  final String iv;
  final String tag;
}
