import 'package:flutter/foundation.dart';

class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();

  factory AnalyticsService() => _instance;

  AnalyticsService._internal() {
    _resetSession(); // Сброс статистики при создании новой сессии
  }

  DateTime _sessionStartTime = DateTime.now();
  Map<String, _ModelStats> _modelUsage = {};
  List<Map<String, dynamic>> _sessionData = [];

  void _resetSession() {
    _sessionStartTime = DateTime.now();
    _modelUsage = {};
    _sessionData = [];
  }

  void trackMessage({
    required String model,
    required int messageLength,
    required double responseTime,
    required int tokensUsed,
    double? cost, // <--- Добавлен параметр cost (double, опциональный)
  }) {
    try {
      _modelUsage[model] ??= _ModelStats();
      _modelUsage[model]!.increment(tokensUsed);

      _sessionData.add({
        'timestamp': DateTime.now().toIso8601String(),
        'model': model,
        'message_length': messageLength,
        'response_time': responseTime,
        'tokens_used': tokensUsed,
        'cost': cost ?? 0.0, // <--- Сохраняйте cost, если передан, иначе 0.0
      });
    } catch (e) {
      debugPrint('Error tracking message: $e');
    }
  }

  Map<String, dynamic> getStatistics() {
    try {
      final sessionDuration = DateTime.now().difference(_sessionStartTime).inSeconds;

      int totalMessages = 0;
      int totalTokens = 0;
      _modelUsage.forEach((_, stats) {
        totalMessages += stats.count;
        totalTokens += stats.tokens;
      });

      final messagesPerMinute = sessionDuration > 0 ? (totalMessages * 60) / sessionDuration : 0;
      final tokensPerMessage = totalMessages > 0 ? totalTokens / totalMessages : 0;

      return {
        'total_messages': totalMessages,
        'total_tokens': totalTokens,
        'session_duration': sessionDuration,
        'messages_per_minute': messagesPerMinute,
        'tokens_per_message': tokensPerMessage,
        'model_usage': _modelUsage.map((key, value) => MapEntry(key, value.toMap())), // Convert _ModelStats to Map
        'start_time': _sessionStartTime.toIso8601String(),
      };
    } catch (e) {
      debugPrint('Error getting statistics: $e');
      return {'error': e.toString()};
    }
  }

  List<Map<String, dynamic>> exportSessionData() => List.from(_sessionData);

  void clearData() =>  _resetSession();

  Map<String, double> getModelEfficiency() {
    final efficiency = <String, double>{};
    _modelUsage.forEach((modelId, stats) {
      if (stats.count > 0) {
        efficiency[modelId] = stats.tokens / stats.count;
      }
    });
    return efficiency;
  }

  Map<String, dynamic> getResponseTimeStats() {
    if (_sessionData.isEmpty) return {};

    final responseTimes = _sessionData.map((data) => data['response_time'] as double).toList()..sort();
    final count = responseTimes.length;

    return {
      'average': responseTimes.reduce((a, b) => a + b) / count,
      'median': count.isOdd ? responseTimes[count ~/ 2] : (responseTimes[(count - 1) ~/ 2] + responseTimes[count ~/ 2]) / 2,
      'min': responseTimes.first,
      'max': responseTimes.last,
    };
  }

  Map<String, dynamic> getMessageLengthStats() {
    if (_sessionData.isEmpty) return {};

    final lengths = _sessionData.map((data) => data['message_length'] as int).toList();
    final count = lengths.length;
    final total = lengths.reduce((a, b) => a + b);

    return {
      'average_length': total / count,
      'total_characters': total,
      'message_count': count,
    };
  }
}

// Helper class for model statistics
class _ModelStats {
  int count = 0;
  int tokens = 0;

  void increment(int tokensUsed) {
    count++;
    tokens += tokensUsed;
  }

  Map<String, dynamic> toMap() => {'count': count, 'tokens': tokens};
}