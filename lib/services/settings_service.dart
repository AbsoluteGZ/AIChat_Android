// services/settings_service.dart
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const String _apiKeyKey = 'apiKey';
  static const String _providerKey = 'selectedProvider'; // Ключ для сохранения провайдера

  Future<String?> getApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_apiKeyKey);
  }

  Future<void> saveApiKey(String apiKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_apiKeyKey, apiKey);
  }

  Future<String?> getProvider() async { // Метод для получения провайдера
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_providerKey);
  }

  Future<void> saveProvider(String provider) async { // Метод для сохранения провайдера
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_providerKey, provider);
  }
}