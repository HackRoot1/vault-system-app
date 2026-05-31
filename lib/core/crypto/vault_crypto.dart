import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:convert/convert.dart';
import 'package:pointycastle/export.dart';

class VaultCrypto {
  const VaultCrypto._();

  static Uint8List deriveKey({
    required String masterPassword,
    required String saltHex,
    required int iterations,
  }) {
    final salt = Uint8List.fromList(hex.decode(saltHex));
    final passwordBytes = Uint8List.fromList(utf8.encode(masterPassword));

    final params = Pbkdf2Parameters(salt, iterations, 32);
    final keyDerivator = PBKDF2KeyDerivator(HMac(SHA256Digest(), 64))
      ..init(params);

    return keyDerivator.process(passwordBytes);
  }

  static Map<String, String> encrypt({
    required String plainText,
    required Uint8List key,
  }) {
    final iv = _randomBytes(12);
    final cipher = GCMBlockCipher(AESEngine());
    final params = AEADParameters(KeyParameter(key), 128, iv, Uint8List(0));
    cipher.init(true, params);

    final input = Uint8List.fromList(utf8.encode(plainText));
    final output = Uint8List(cipher.getOutputSize(input.length));
    final offset = cipher.processBytes(input, 0, input.length, output, 0);
    cipher.doFinal(output, offset);

    final cipherText = output.sublist(0, output.length - 16);
    final tag = output.sublist(output.length - 16);

    return {
      'encrypted_data': base64.encode(cipherText),
      'iv': base64.encode(iv),
      'tag': base64.encode(tag),
    };
  }

  static String decrypt({
    required String encryptedDataB64,
    required String ivB64,
    required String tagB64,
    required Uint8List key,
  }) {
    final iv = base64.decode(ivB64);
    final cipherText = base64.decode(encryptedDataB64);
    final tag = base64.decode(tagB64);

    final combined = Uint8List(cipherText.length + tag.length)
      ..setAll(0, cipherText)
      ..setAll(cipherText.length, tag);

    final cipher = GCMBlockCipher(AESEngine());
    final params = AEADParameters(KeyParameter(key), 128, iv, Uint8List(0));
    cipher.init(false, params);

    final output = Uint8List(cipher.getOutputSize(combined.length));
    final offset = cipher.processBytes(combined, 0, combined.length, output, 0);
    cipher.doFinal(output, offset);

    return utf8.decode(output);
  }

  static Uint8List _randomBytes(int length) {
    final random = Random.secure();
    return Uint8List.fromList(
      List.generate(length, (_) => random.nextInt(256)),
    );
  }
}
