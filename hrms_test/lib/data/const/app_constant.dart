import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AppConstant {
  static const String storageKey = 'base_url';
  // static const String defaultUrl = 'http://10.0.2.2:3000/api';
  static const String defaultUrl = 'http://192.168.1.5:3000/api';
  static String baseUrl = defaultUrl;
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  static Future<String> getBaseUrl() async {
    final value = (await _storage.read(key: storageKey))?.trim();
    if (value != null && value.isNotEmpty) {
      baseUrl = value;
      return value;
    }
    baseUrl = defaultUrl;
    return baseUrl;
  }

  static Future<void> setBaseUrl(String url) async {
    final normalized = url.trim();
    baseUrl = normalized;
    await _storage.write(key: storageKey, value: normalized);
  }

  static Future<bool> isConfigured() async {
    return _storage.containsKey(key: storageKey);
  }
}
