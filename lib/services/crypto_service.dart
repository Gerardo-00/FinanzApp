import 'dart:convert';
import 'dart:math';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class CryptoService {
  static const _storage = FlutterSecureStorage();
  static const _keyName = 'finanzapp_aes_key';

  static Future<enc.Key> _key() async {
    var raw = await _storage.read(key: _keyName);
    if (raw == null) {
      final random = Random.secure();
      raw = base64Encode(List<int>.generate(32, (_) => random.nextInt(256)));
      await _storage.write(key: _keyName, value: raw);
    }
    return enc.Key.fromBase64(raw);
  }

  static Future<String> encryptText(String value) async {
    final key = await _key();
    final iv = enc.IV.fromSecureRandom(16);
    final encrypted = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc)).encrypt(value, iv: iv);
    return '${base64Encode(iv.bytes)}:${encrypted.base64}';
  }

  static Future<String> decryptText(String value) async {
    final parts = value.split(':');
    if (parts.length != 2) return value; // compatibilidad con registros antiguos
    final key = await _key();
    final iv = enc.IV.fromBase64(parts[0]);
    return enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc))
        .decrypt(enc.Encrypted.fromBase64(parts[1]), iv: iv);
  }
}
