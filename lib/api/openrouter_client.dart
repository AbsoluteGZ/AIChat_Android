import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../services/settings_service.dart';

class OpenRouterClient {
  String? _apiKey;
  String? _baseUrl; // _baseUrl теперь может меняться
  final Map<String, String> _headers = {
    'Content-Type': 'application/json',
    'X-Title': 'AI Chat Flutter',
  };
  final SettingsService _settingsService = SettingsService();

  static final OpenRouterClient _instance = OpenRouterClient._internal();

  factory OpenRouterClient() => _instance;

  OpenRouterClient._internal() {
    _baseUrl = dotenv.env['BASE_URL']; // Изначальное значение из .env (может быть null)
    _initializeClient();
  }

  void _initializeClient() {
    if (kDebugMode) {
      print('Initializing OpenRouterClient...');
      print('Base URL: $_baseUrl');
    }

    if (_baseUrl == null) {
      if (kDebugMode) print('BASE_URL not found in .env');
      // Обработка отсутствия BASE_URL. Возможно, установка значения по умолчанию или вывод ошибки.
      // Можно установить дефолтное значение, например, OpenRouter URL:
      _baseUrl = 'https://openrouter.ai/api/v1'; // Дефолтное значение, если не задано в .env
      if (kDebugMode) print('Using default BASE_URL: $_baseUrl');
    }

    if (kDebugMode) {
      print('OpenRouterClient initialized successfully');
    }
  }

  // Метод для асинхронного получения API ключа с приоритетом .env и SettingsService
  Future<String?> _getApiKey() async {
    String? apiKey = dotenv.env['OPENROUTER_API_KEY'];
    if (apiKey != null && apiKey.isNotEmpty) {
      if (kDebugMode) print('API Key loaded from .env');
      return apiKey;
    } else {
      apiKey = await _settingsService.getApiKey();
      if (apiKey != null && apiKey.isNotEmpty) {
        if (kDebugMode) print('API Key loaded from SettingsService');
        return apiKey;
      }
    }
    if (kDebugMode) print('API Key not found in .env or SettingsService');
    return null;
  }

  // Метод setApiKey для явной установки и сохранения ключа в SettingsService
  Future<void> setApiKey(String apiKey) async {
    _apiKey = apiKey;
    await _settingsService.saveApiKey(apiKey);
    _headers.addAll({'Authorization': 'Bearer $apiKey'});
    if (kDebugMode) print('API Key saved to SettingsService and set in headers: $apiKey');
  }

  String? get apiKey => _apiKey;

  // Setter для baseUrl, чтобы можно было менять BASE_URL динамически
  set baseUrl(String? baseUrl) {
    _baseUrl = baseUrl;
    if (kDebugMode) print('Base URL updated to: $_baseUrl');
  }

  String? get baseUrl => _baseUrl;

  Map<String, String> get headers => _headers;

  Future<List<Map<String, dynamic>>> getModels() async {
    final apiKey = await _getApiKey();
    if (apiKey == null) {
      throw Exception('API key is not found. Please set it in .env or application settings.');
    }
    Map<String, String> currentHeaders = Map.from(_headers);
    currentHeaders['Authorization'] = 'Bearer $apiKey';
    try {
      final response = await http.get(Uri.parse('$_baseUrl/models'), headers: currentHeaders);

      if (kDebugMode) {
        print('Models response status: ${response.statusCode}');
        print('Models response body: ${response.body}');
      }

      if (response.statusCode == 200) {
        final modelsData = json.decode(response.body);
        if (modelsData['data'] != null) {
          return (modelsData['data'] as List).map((model) {
            String name = '';
            try {
              name = utf8.decode((model['name'] as String).codeUnits);
            } catch (e) {
              final cleaned = (model['name'] as String).replaceAll(RegExp(r'[^\x00-\x7F]'), '');
              name = utf8.decode(cleaned.codeUnits);
            }
            return {
              'id': model['id'] as String,
              'name': name,
              'pricing': model['pricing'] != null
                  ? {
                'prompt': model['pricing']['prompt'] as String,
                'completion': model['pricing']['completion'] as String,
              }
                  : null,
              'context_length': (model['context_length'] ?? model['top_provider']?['context_length'] ?? 0).toString(),
            };
          }).toList();
        }
        throw Exception('Invalid API response format');
      }
      return [];
    } catch (e) {
      if (kDebugMode) {
        print('Error getting models: $e');
      }
      return [];
    }
  }

  Future<Map<String, dynamic>> sendMessage(String message, String model) async {
    final apiKey = await _getApiKey();
    if (apiKey == null) {
      throw Exception('API key is not found. Please set it in .env or application settings.');
    }
    Map<String, String> currentHeaders = Map.from(_headers);
    currentHeaders['Authorization'] = 'Bearer $apiKey';

    try {
      final data = {
        'model': model,
        'messages': [
          {'role': 'user', 'content': message}
        ],
        'max_tokens': int.parse(dotenv.env['MAX_TOKENS'] ?? '1000'),
        'temperature': double.parse(dotenv.env['TEMPERATURE'] ?? '0.7'),
        'stream': false,
      };

      if (kDebugMode) {
        print('Sending message to API: ${json.encode(data)}');
      }

      final response = await http.post(
        Uri.parse('$_baseUrl/chat/completions'),
        headers: currentHeaders,
        body: json.encode(data),
      );

      if (kDebugMode) {
        print('Message response status: ${response.statusCode}');
        print('Message response body: ${response.body}');
      }

      if (response.statusCode == 200) {
        final responseData = json.decode(utf8.decode(response.bodyBytes));
        return responseData;
      } else {
        final errorData = json.decode(utf8.decode(response.bodyBytes));
        return {'error': errorData['error']?['message'] ?? 'Unknown error occurred'};
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error sending message: $e');
      }
      return {'error': e.toString()};
    }
  }

  Future<String> getBalance() async {
    final apiKey = await _getApiKey();
    if (apiKey == null) {
      throw Exception('API key is not found. Please set it in .env or application settings.');
    }
    Map<String, String> currentHeaders = Map.from(_headers);
    currentHeaders['Authorization'] = 'Bearer $apiKey';

    try {
      final response = await http.get(
        Uri.parse(_baseUrl!.contains('vsegpt.ru') ? '$_baseUrl/balance' : '$_baseUrl/credits'),
        headers: currentHeaders,
      );

      if (kDebugMode) {
        print('Balance response status: ${response.statusCode}');
        print('Balance response body: ${response.body}');
      }

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data != null && data['data'] != null) {
          if (_baseUrl!.contains('vsegpt.ru')) {
            final credits = double.tryParse(data['data']['credits'].toString()) ?? 0.0;
            return '${credits.toStringAsFixed(2)}₽';
          } else {
            final credits = data['data']['total_credits'] ?? 0;
            final usage = data['data']['total_usage'] ?? 0;
            return '\$${(credits - usage).toStringAsFixed(2)}';
          }
        }
      }
      return _baseUrl!.contains('vsegpt.ru') ? '0.00₽' : '\$0.00';
    } catch (e) {
      if (kDebugMode) {
        print('Error getting balance: $e');
      }
      return 'Error';
    }
  }

  String formatPricing(double pricing) {
    try {
      if (_baseUrl!.contains('vsegpt.ru')) {
        return '${pricing.toStringAsFixed(3)}₽/K';
      } else {
        return '\$${(pricing * 1000000).toStringAsFixed(3)}/M';
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error formatting pricing: $e');
      }
      return '0.00';
    }
  }
}