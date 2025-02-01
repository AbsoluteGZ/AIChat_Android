// screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import '../services/settings_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _settingsService = SettingsService();
  String _apiKey = '';
  bool _isApiKeySaved = false;
  String? _selectedProvider; // Может быть null до загрузки

  @override
  void initState() {
    super.initState();
    _loadSettings(); // Загружаем настройки (API Key и Provider)
  }

  Future<void> _loadSettings() async {
    final apiKey = await _settingsService.getApiKey();
    final provider = await _settingsService.getProvider();
    setState(() {
      _apiKey = apiKey ?? '';
      _selectedProvider = provider; // Загружаем сохраненного провайдера
    });
  }

  @override
  Widget build(BuildContext context) {
    final chatProvider = Provider.of<ChatProvider>(context);
    if (_selectedProvider == null) {
      _selectedProvider = chatProvider.selectedProvider; // Если еще не загрузился, берем из ChatProvider
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text('Provider:', style: TextStyle(fontSize: 18)),
            DropdownButton<String>(
              value: _selectedProvider,
              isExpanded: true,
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedProvider = newValue;
                  });
                  Provider.of<ChatProvider>(context, listen: false).setSelectedProvider(newValue); // Используем setSelectedProvider
                  print('Selected provider: $_selectedProvider');
                }
              },
              items: <String>['OpenRouter', 'VSEGPT']
                  .map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),

            const SizedBox(height: 20),
            Text('${_selectedProvider ?? "Provider"} API Key:', style: const TextStyle(fontSize: 18)), // Используем _selectedProvider для заголовка
            TextFormField(
              initialValue: _apiKey,
              onChanged: (value) {
                setState(() {
                  _apiKey = value;
                  _isApiKeySaved = false;
                });
                _settingsService.saveApiKey(value).then((_) {
                  setState(() {
                    _isApiKeySaved = true;
                  });
                  Provider.of<ChatProvider>(context, listen: false).setApiKey(value);
                  Future.delayed(const Duration(seconds: 2), () {
                    setState(() {
                      _isApiKeySaved = false;
                    });
                  });
                });
              },
              decoration: InputDecoration(
                hintText: 'Enter API Key',
                suffixIcon: _isApiKeySaved ? const Icon(Icons.check, color: Colors.green) : null,
              ),
            ),
            const SizedBox(height: 20),
            const Text('Model:', style: TextStyle(fontSize: 18)),
            DropdownButton<String>(
              value: chatProvider.currentModel,
              isExpanded: true,
              onChanged: (String? newValue) {
                if (newValue != null) {
                  chatProvider.setCurrentModel(newValue);
                }
              },
              items: chatProvider.availableModels.map((model) {
                return DropdownMenuItem<String>(
                  value: model['id'],
                  child: Text(model['name']),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}