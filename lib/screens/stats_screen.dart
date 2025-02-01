import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';

class StatsScreen extends StatefulWidget { // <--- Изменили на StatefulWidget
  const StatsScreen({Key? key}) : super(key: key);

  @override
  State<StatsScreen> createState() => _StatsScreenState(); // <--- Создаем State
}

class _StatsScreenState extends State<StatsScreen> { // <--- Класс State
  @override
  Widget build(BuildContext context) {
    return Consumer<ChatProvider>( // <--- Оборачиваем в Consumer
      builder: (context, chatProvider, _) { // <--- Получаем ChatProvider из Consumer
        return Scaffold(
          appBar: AppBar(title: const Text('Stats')),
          body: FutureBuilder<Map<String, dynamic>>(
            future: chatProvider.exportHistory(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              } else if (!snapshot.hasData || snapshot.data == null) {
                return const Center(child: Text('No data available.'));
              } else {
                final data = snapshot.data!;
                final dbStats = data['database_stats'] ?? {};
                final totalMessages = dbStats['totalMessages'] ?? 0;
                final userMessages = dbStats['userMessages'] ?? 0;
                final aiMessages = dbStats['aiMessages'] ?? 0;

                final analyticsStats = data['analytics_stats'] ?? {};
                final totalTokens = analyticsStats['total_tokens'] ?? 0;
                final messagesPerMinute = analyticsStats['messages_per_minute'] ?? 0;
                final tokensPerMessage = analyticsStats['tokens_per_message'] ?? 0;
                final sessionDuration = analyticsStats['session_duration'] ?? 0;

                final modelEfficiency = data['model_efficiency'] ?? {};
                final responseTimeStats = data['response_time_stats'] ?? {};
                final messageLengthStats = data['message_length_stats'] ?? {};

                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ListView(
                    children: [
                      _buildStatItem('Total Messages:', totalMessages.toString()),
                      _buildStatItem('User Messages:', userMessages.toString()),
                      _buildStatItem('AI Messages:', aiMessages.toString()),
                      _buildStatItem('Total Tokens:', totalTokens.toString()),
                      _buildStatItem('Messages Per Minute:', messagesPerMinute.toStringAsFixed(2)),
                      _buildStatItem('Tokens Per Message:', tokensPerMessage.toStringAsFixed(2)),
                      _buildStatItem('Session Duration (seconds):', sessionDuration.toString()),
                      const SizedBox(height: 20),
                      const Text('Model Efficiency:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      for (final entry in modelEfficiency.entries)
                        _buildStatItem('${entry.key}:', entry.value.toStringAsFixed(2)),
                      const SizedBox(height: 20),
                      const Text('Response Time Stats:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      _buildStatItem('Average Response Time:', (responseTimeStats['average'] ?? 0).toStringAsFixed(2)),
                      _buildStatItem('Median Response Time:', (responseTimeStats['median'] ?? 0).toStringAsFixed(2)),
                      _buildStatItem('Min Response Time:', (responseTimeStats['min'] ?? 0).toStringAsFixed(2)),
                      _buildStatItem('Max Response Time:', (responseTimeStats['max'] ?? 0).toStringAsFixed(2)),
                      const SizedBox(height: 20),
                      const Text('Message Length Stats:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      _buildStatItem('Average Message Length:', (messageLengthStats['average_length'] ?? 0).toStringAsFixed(2)),
                      _buildStatItem('Total Characters:', (messageLengthStats['total_characters'] ?? 0).toString()),
                      _buildStatItem('Message Count:', (messageLengthStats['message_count'] ?? 0).toString()),
                    ],
                  ),
                );
              }
            },
          ),
        );
      },
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16)),
          Text(value, style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }
}