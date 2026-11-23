// Cifra de segredos em repouso: senha e token cifrados com AES-CFB64.
// Implementação utilitária portável para persistência segura em clientes locais.

import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart';

/// Utilitário de criptografia simétrica para segredos e dados confidenciais em repouso.
class SecretCipher {
  final String secret;

  const SecretCipher(this.secret);

  Key _chave(String segredo) {
    final digest = sha256.convert(utf8.encode(segredo));
    final fDigest = md5.convert(digest.bytes);
    return Key.fromUtf8(fDigest.toString());
  }

  /// Cifra a string [input] usando AES-CFB64 com um IV aleatório seguro de 16 bytes.
  String encrypt(String input) {
    final iv = IV.fromSecureRandom(16);
    final encrypter = Encrypter(AES(_chave(secret), mode: AESMode.cfb64));
    final cipher = encrypter.encrypt(input, iv: iv);
    return '${iv.base64}:${cipher.base64}';
  }

  /// Decifra os dados no formato `iv:cipherBase64`.
  String decrypt(String data) {
    final parts = data.split(':');
    if (parts.length != 2) {
      throw const FormatException('Formato de dados cifrados inválido.');
    }
    final iv = IV.fromBase64(parts[0]);
    final encrypter = Encrypter(AES(_chave(secret), mode: AESMode.cfb64));
    return encrypter.decrypt64(parts[1], iv: iv);
  }

  /// Retorna `true` se o segredo não estiver vazio.
  bool hasSecret() => secret.isNotEmpty;
}
