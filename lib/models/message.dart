// Импорт основных классов Flutter
import 'package:flutter/foundation.dart';

// Класс, представляющий сообщение в чате
class ChatMessage {
  // Текст сообщения
  final String content;
  // Флаг, указывающий, является ли сообщение от пользователя
  final bool isUser;
  // Временная метка сообщения
  final DateTime timestamp;
  // Идентификатор модели, использованной для генерации ответа
  final String? modelId;
  // Количество использованных токенов
  final int? tokens;
  // Стоимость запроса
  final double? cost;

  // Конструктор класса ChatMessage
  ChatMessage({
    required this.content, // Обязательный параметр: текст сообщения
    required this.isUser, // Обязательный параметр: флаг пользователя
    DateTime? timestamp, // Необязательный параметр: временная метка
    this.modelId, // Необязательный параметр: идентификатор модели
    this.tokens, // Необязательный параметр: количество токенов
    this.cost, // Необязательный параметр: стоимость запроса
  }) : timestamp = timestamp ??
            DateTime.now(); // Установка текущего времени, если не указано

  // Преобразование объекта в JSON
  Map<String, dynamic> toJson() {
    return {
      'content': content, // Текст сообщения
      'isUser': isUser, // Флаг пользователя
      'timestamp':
          timestamp.toIso8601String(), // Временная метка в формате ISO 8601
      'modelId': modelId, // Идентификатор модели
      'tokens': tokens, // Количество токенов
      'cost': cost, // Стоимость запроса
    };
  }

  // Фабричный метод для создания объекта из JSON
  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    try {
      // Создание объекта ChatMessage из JSON
      return ChatMessage(
        content: json['content'] as String, // Получение текста сообщения
        isUser: json['isUser'] as bool, // Получение флага пользователя
        timestamp: DateTime.parse(
            json['timestamp'] as String), // Парсинг временной метки
        modelId: json['modelId'] as String?, // Получение идентификатора модели
        tokens: json['tokens'] as int?, // Получение количества токенов
        cost: json['cost'] as double?, // Получение стоимости запроса
      );
    } catch (e) {
      // Логирование ошибок при декодировании
      debugPrint('Error decoding message: $e');
      // Возвращение объекта с теми же данными, даже если произошла ошибка
      return ChatMessage(
        content: json['content'] as String,
        isUser: json['isUser'] as bool,
        timestamp: DateTime.parse(json['timestamp'] as String),
        modelId: json['modelId'] as String?,
        tokens: json['tokens'] as int?,
      );
    }
  }

  // Геттер для получения очищенного текста сообщения
  String get cleanContent {
    try {
      // Удаление лишних пробелов в начале и конце текста
      return content.trim();
    } catch (e) {
      // Логирование ошибок при очистке текста
      debugPrint('Error cleaning message content: $e');
      // Возвращение исходного текста в случае ошибки
      return content;
    }
  }
}
