import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

class VaultCrypto {
  const VaultCrypto._();

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

  static Future<EncryptedPayload> encrypt({
    required String plainText,
    required SecretKey key,
  }) async {
    final aesGcm = AesGcm.with256bits(nonceLength: 12);
    final iv = _randomBytes(12);

    final secretBox = await aesGcm.encrypt(
      utf8.encode(plainText),
      secretKey: key,
      nonce: iv,
    );

    return EncryptedPayload(
      encryptedData: base64.encode(secretBox.cipherText),
      iv: base64.encode(iv),
      tag: base64.encode(secretBox.mac.bytes),
    );
  }

  static Future<String> decrypt({
    required String encryptedDataB64,
    required String ivB64,
    required String tagB64,
    required SecretKey key,
  }) async {
    final aesGcm = AesGcm.with256bits(nonceLength: 12);
    final cipherText = base64.decode(encryptedDataB64);
    final iv = base64.decode(ivB64);
    final tag = base64.decode(tagB64);

    final secretBox = SecretBox(
      cipherText,
      nonce: iv,
      mac: Mac(tag),
    );

    final plainBytes = await aesGcm.decrypt(
      secretBox,
      secretKey: key,
    );

    return utf8.decode(plainBytes);
  }

  static Uint8List _randomBytes(int length) {
    final random = Random.secure();
    return Uint8List.fromList(
      List.generate(length, (_) => random.nextInt(256)),
    );
  }

  static Uint8List _hexDecode(String hex) {
    final bytes = <int>[];
    for (var i = 0; i < hex.length - 1; i += 2) {
      bytes.add(int.parse(hex.substring(i, i + 2), radix: 16));
    }
    return Uint8List.fromList(bytes);
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
