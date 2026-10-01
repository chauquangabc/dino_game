import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class MemorySecureStorage extends FlutterSecureStorage {
  MemorySecureStorage([Map<String, String>? initial]) : values = {...?initial};
  final Map<String, String> values;
  int writes = 0;
  int? failAt;
  bool failAfterWrite = false;

  void _before() {
    writes++;
    if (!failAfterWrite && writes == failAt) {
      throw StateError('Simulated storage interruption');
    }
  }

  void _after() {
    if (failAfterWrite && writes == failAt) {
      throw StateError('Simulated storage interruption');
    }
  }

  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async => values[key];

  @override
  Future<void> write({
    required String key,
    required String? value,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    _before();
    if (value == null) {
      values.remove(key);
    } else {
      values[key] = value;
    }
    _after();
  }

  @override
  Future<void> delete({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    _before();
    values.remove(key);
    _after();
  }
}
