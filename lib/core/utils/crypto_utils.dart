import 'dart:io';
import 'dart:isolate';
import 'package:crypto/crypto.dart';
import 'package:uuid/uuid.dart';

/// Utilitários criptográficos para cálculo de SHA-256 e geração de UUID v4.
class CryptoUtils {
  const CryptoUtils._();

  static const Uuid _uuid = Uuid();

  static String randomUuid() => _uuid.v4();

  static String sha256Bytes(List<int> bytes) {
    return sha256.convert(bytes).toString();
  }

  /// Calcula o SHA-256 de um arquivo em um Isolate separado para não bloquear
  /// a thread de UI em pacotes `.apkg` (até 50 MiB) ou mídias (até 25 MiB).
  static Future<String> sha256File(File file) async {
    final path = file.path;
    return Isolate.run(() async {
      final bytes = await File(path).readAsBytes();
      return sha256.convert(bytes).toString();
    });
  }
}
