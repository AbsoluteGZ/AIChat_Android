// providers/chat_provider.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:convert';
import 'dart:io';
import '../models/message.dart';
import '../api/openrouter_client.dart';
import '../services/database_service.dart';
import '../services/analytics_service.dart';
import '../services/settings_service.dart';

class ChatProvider with ChangeNotifier {
  final SettingsService _settingsService = SettingsService();
  final OpenRouterClient _api = OpenRouterClient(); // Получаем экземпляр синглтона
  final List<ChatMessage> _messages = [];
  final List<String> _debugLogs = [];
  List<Map<String, dynamic>> _availableModels = [];
  String? _currentModel;
  String _balance = '\$0.00';
  bool _isLoading = false;
  String _selectedProvider = 'OpenRouter';
  String? get selectedProvider => _selectedProvider;

  void _log(String message) {
    _debugLogs.add('${DateTime.now()}: $message');
    debugPrint(message);
  }

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  List<Map<String, dynamic>> get availableModels => _availableModels;
  String? get currentModel => _currentModel;
  String get balance => _balance;
  bool get isLoading => _isLoading;
  String? get baseUrl => _api.baseUrl;

  ChatProvider() {
    _initializeProvider();
  }

  Future<void> _initializeProvider() async {
    try {
      _log('Initializing provider...');

      final savedApiKey = await _settingsService.getApiKey();
      if (savedApiKey != null && savedApiKey.isNotEmpty) {
        _api.setApiKey(savedApiKey);
      } else {
        _log('API Key not found in settings.');
      }

      final savedProvider = await _settingsService.getProvider();
      if (savedProvider != null && savedProvider.isNotEmpty) {
        _selectedProvider = savedProvider;
      } else {
        _selectedProvider = 'OpenRouter';
        await _settingsService.saveProvider(_selectedProvider);
      }
      _updateBaseUrl(); // Вызываем _updateBaseUrl после загрузки провайдера

      await _loadModels();
      _log('Models loaded: $_availableModels');

      if (_api.apiKey != null) {
        await _loadBalance();
        _log('Balance loaded: $_balance');
      }

      await _loadHistory();
      _log('History loaded: ${_messages.length} messages');
    } catch (e, stackTrace) {
      _log('Error initializing provider: $e');
      _log('Stack trace: $stackTrace');
    }
  }

  void _updateBaseUrl() {
    String baseUrl;
    if (_selectedProvider == 'VSEGPT') {
      baseUrl = 'https://api.vsetgpt.ru/v1';
    } else {
      baseUrl = 'https://openrouter.ai/api/v1'; // OpenRouter по умолчанию
    }
    _api.baseUrl = baseUrl; // Используем setter для обновления baseUrl в синглтоне
    notifyListeners(); // Важно уведомить слушателей, что API клиент изменился
  }


  Future<void> _loadModels() async {
    try {
      _availableModels = await _api.getModels();
      _availableModels
          .sort((a, b) => (a['name'] as String).compareTo(b['name'] as String));

      if (_availableModels.isNotEmpty && _currentModel == null) {
        _currentModel = _availableModels[0]['id'];
      }
      notifyListeners();
    } catch (e) {
      _log('Error loading models: $e');
    }
  }

  Future<void> _loadBalance() async {
    try {
      _balance = await _api.getBalance();
      notifyListeners();
    } catch (e) {
      _log('Error loading balance: $e');
    }
  }

  final DatabaseService _db = DatabaseService();
  final AnalyticsService _analytics = AnalyticsService();

  Future<void> _loadHistory() async {
    try {
      final messages = await _db.getMessages();
      _messages.clear();
      _messages.addAll(messages);
      notifyListeners();
    } catch (e) {
      _log('Error loading history: $e');
    }
  }

  Future<void> _saveMessage(ChatMessage message) async {
    try {
      await _db.saveMessage(message);
    } catch (e) {
      _log('Error saving message: $e');
    }
  }

  Future<void> sendMessage(String content, {bool trackAnalytics = true}) async {
    if (content.trim().isEmpty || _currentModel == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      content = utf8.decode(utf8.encode(content));

      final userMessage = ChatMessage(
        content: content,
        isUser: true,
        modelId: _currentModel,
      );
      _messages.add(userMessage);
      notifyListeners();

      await _saveMessage(userMessage);

      final startTime = DateTime.now();

      final response = await _api.sendMessage(content, _currentModel!);
      _log('API Response: $response');

      final responseTime =
          DateTime.now().difference(startTime).inMilliseconds / 1000;

      if (response.containsKey('error')) {
        final errorMessage = ChatMessage(
          content: utf8.decode(utf8.encode('Error: ${response['error']}')),
          isUser: false,
          modelId: _currentModel,
        );
        _messages.add(errorMessage);
        await _saveMessage(errorMessage);
      } else if (response.containsKey('choices') &&
          response['choices'] is List &&
          response['choices'].isNotEmpty &&
          response['choices'][0] is Map &&
          response['choices'][0]['message'] is Map &&
          response['choices'][0]['message'].containsKey('content')) {
        final aiContent = utf8.decode(utf8.encode(
          response['choices'][0]['message']['content'] as String,
        ));
        final tokens = response['usage']?['total_tokens'] as int? ?? 0;

        final promptTokens = response['usage']['prompt_tokens'] ?? 0;
        final completionTokens = response['usage']['completion_tokens'] ?? 0;
        final totalCost = response['usage']?['total_cost'];
        final model = _availableModels
            .firstWhere((model) => model['id'] == _currentModel);


        final cost = (totalCost == null)
            ? ((promptTokens *
            (double.tryParse(model['pricing']?['prompt']) ?? 0)) +
            (completionTokens *
                (double.tryParse(model['pricing']?['completion']) ?? 0)))
            : totalCost;
        _log('Cost Response: $cost');


        if (trackAnalytics) {
          print("totalCost: $totalCost");
          print("promptTokens: $promptTokens");
          print("completionTokens: $completionTokens");
          print("model['pricing']?['prompt']: ${model['pricing']?['prompt']}");
          print("model['pricing']?['completion']: ${model['pricing']?['completion']}");
          print("Cost before trackMessage: $cost");
          _analytics.trackMessage(
            model: _currentModel!,
            messageLength: content.length,
            responseTime: responseTime,
            tokensUsed: tokens,
            cost: cost,
          );
        }


        final aiMessage = ChatMessage(
          content: aiContent,
          isUser: false,
          modelId: _currentModel,
          tokens: tokens,
          cost: cost,
        );
        _messages.add(aiMessage);
        await _saveMessage(aiMessage);

        await _loadBalance();
      } else {
        throw Exception('Invalid API response format');
      }
    } catch (e) {
      _log('Error sending message: $e');
      final errorMessage = ChatMessage(
        content: utf8.decode(utf8.encode('Error: $e')),
        isUser: false,
        modelId: _currentModel,
      );
      _messages.add(errorMessage);
      await _saveMessage(errorMessage);
    } finally {
      _isLoading = false;
      notifyListeners();
      _notifyChartListeners();
    }
  }

  void _notifyChartListeners() {
    notifyListeners();
  }

  void setCurrentModel(String modelId) {
    _currentModel = modelId;
    notifyListeners();
  }

  Future<void> clearHistory() async {
    _messages.clear();
    await _db.clearHistory();
    _analytics.clearData();
    notifyListeners();
  }

  Future<String> exportLogs() async {
    final directory = await getApplicationDocumentsDirectory();
    final now = DateTime.now();
    final fileName =
        'chat_logs_${now.year}${now.month}${now.day}_${now.hour}${now.minute}${now.second}.txt';
    final file = File('${directory.path}/$fileName');

    final buffer = StringBuffer();
    buffer.writeln('=== Debug Logs ===\n');
    for (final log in _debugLogs) {
      buffer.writeln(log);
    }

    buffer.writeln('\n=== Chat Logs ===\n');
    buffer.writeln('Generated: ${now.toString()}\n');

    for (final message in _messages) {
      buffer.writeln('${message.isUser ? "User" : "AI"} (${message.modelId}):');
      buffer.writeln(message.content);
      if (message.tokens != null) {
        buffer.writeln('Tokens: ${message.tokens}');
      }
      buffer.writeln('Time: ${message.timestamp}');
      buffer.writeln('---\n');
    }

    await file.writeAsString(buffer.toString());
    return file.path;
  }

  Future<String> exportMessagesAsJson() async {
    final directory = await getApplicationDocumentsDirectory();
    final now = DateTime.now();
    final fileName =
        'chat_history_${now.year}${now.month}${now.day}_${now.hour}${now.minute}${now.second}.json';
    final file = File('${directory.path}/$fileName');

    final List<Map<String, dynamic>> messagesJson =
    _messages.map((message) => message.toJson()).toList();
    await file.writeAsString(jsonEncode(messagesJson));
    return file.path;
  }

  String formatPricing(double pricing) {
    return _api.formatPricing(pricing);
  }

  Future<Map<String, dynamic>> exportHistory() async {
    print("exportHistory() is called");
    final dbStats = await _db.getStatistics();
    final analyticsStats = _analytics.getStatistics();
    final sessionData = _analytics.exportSessionData();
    final modelEfficiency = _analytics.getModelEfficiency();
    final responseTimeStats = _analytics.getResponseTimeStats();
    final messageLengthStats = _analytics.getMessageLengthStats();

    return {
      'database_stats': dbStats,
      'analytics_stats': analyticsStats,
      'session_data': sessionData,
      'model_efficiency': modelEfficiency,
      'response_time_stats': responseTimeStats,
      'message_length_stats': messageLengthStats,
    };
  }

  Future<void> setApiKey(String apiKey) async {
    if (apiKey.isNotEmpty) {
      await _settingsService.saveApiKey(apiKey);
      _api.setApiKey(apiKey);
      notifyListeners();
      await _loadBalance();
    }
  }

  Future<void> setSelectedProvider(String provider) async {
    if (_selectedProvider != provider) {
      _selectedProvider = provider;
      await _settingsService.saveProvider(provider);
      _updateBaseUrl(); // Вызываем _updateBaseUrl для обновления baseUrl
      await _loadModels();
      await _loadBalance();
      notifyListeners();
    }
  }
}