import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'providers/chat_provider.dart';
import 'screens/chat_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/stats_screen.dart';
import 'screens/chart_screen.dart';
import 'services/settings_service.dart';

enum AppTheme {
  dark,
  light,
  system,
}

// Виджет для обработки и отлова ошибок в приложении
class ErrorBoundaryWidget extends StatelessWidget {
  // Дочерний виджет, который будет обернут в обработчик ошибок
  final Widget child;

  // Конструктор с обязательным параметром child
  const ErrorBoundaryWidget({super.key, required this.child});

  // Метод построения виджета
  @override
  Widget build(BuildContext context) {
    // Используем Builder для создания нового контекста
    return Builder(
      // Функция построения виджета с обработкой ошибок
      builder: (context) {
        // Пытаемся построить дочерний виджет
        try {
          // Возвращаем дочерний виджет, если ошибок нет
          return child;
          // Ловим и обрабатываем ошибки
        } catch (error, stackTrace) {
          // Логируем ошибку в консоль
          debugPrint('Error in ErrorBoundaryWidget: $error');
          // Логируем стек вызовов для отладки
          debugPrint('Stack trace: $stackTrace');
          // Возвращаем MaterialApp с экраном ошибки
          return MaterialApp(
            // Основной экран приложения
            home: Scaffold(
              // Красный фон для экрана ошибки
              backgroundColor: Colors.red,
              // Центрируем содержимое
              body: Center(
                // Добавляем отступы
                child: Padding(
                  // Отступы 16 пикселей со всех сторон
                  padding: const EdgeInsets.all(16.0),
                  // Текст с описанием ошибки
                  child: Text(
                    // Отображаем текст ошибки
                    'Error: $error',
                    // Белый цвет текста
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),
          );
        }
      },
    );
  }
}

// Основная точка входа в приложение
void main() async {
  try {
    // Инициализация Flutter биндингов
    WidgetsFlutterBinding.ensureInitialized();

    // Настройка обработки ошибок Flutter
    FlutterError.onError = (FlutterErrorDetails details) {
      // Отображение ошибки
      FlutterError.presentError(details);
      // Логирование ошибки
      debugPrint('Flutter error: ${details.exception}');
      // Логирование стека вызовов
      debugPrint('Stack trace: ${details.stack}');
    };

    // Загрузка переменных окружения из .env файла
    await dotenv.load(fileName: ".env");
    // Логирование успешной загрузки
    debugPrint('Environment loaded');
    // Проверка наличия API ключа
    debugPrint('API Key present: ${dotenv.env['OPENROUTER_API_KEY'] != null}');
    // Логирование базового URL
    debugPrint('Base URL: ${dotenv.env['BASE_URL']}');

    // Запуск приложения с обработчиком ошибок
    runApp(ErrorBoundaryWidget(child: const MyApp()));
  } catch (e, stackTrace) {
    // Логирование ошибки запуска приложения
    debugPrint('Error starting app: $e');
    // Логирование стека вызовов
    debugPrint('Stack trace: $stackTrace');
    // Запуск приложения с экраном ошибки
    runApp(
      MaterialApp(
        home: Scaffold(
          backgroundColor: Colors.red,
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Error starting app: $e',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Глобальный ключ для доступа к состоянию MyApp
final GlobalKey<_MyAppState> myAppStateKey = GlobalKey<_MyAppState>(); // <--- GlobalKey

// Основной виджет приложения
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  int _selectedIndex = 0;
  AppTheme _currentTheme = AppTheme.system; // Тема по умолчанию
  final SettingsService _settingsService = SettingsService();
  final PageController _pageController = PageController(); // <--- PageController

  @override
  void dispose() {
    _pageController.dispose(); // <--- Dispose PageController
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {

    List<Widget> _widgetOptions = <Widget>[
      const ChatScreen(),
      const SettingsScreen(),
      const StatsScreen(),
      const ChartScreen(),
    ];

    return ChangeNotifierProvider(
      create: (_) => ChatProvider(),
      child: Consumer<ChatProvider>(builder: (context, chatProvider, _) {
        return MaterialApp(
          // Настройка поведения прокрутки
          builder: (context, child) {
            return ScrollConfiguration(
              behavior: ScrollBehavior(),
              child: child!,
            );
          },
          title: 'AI Chat',
          debugShowCheckedModeBanner: false,
          locale: const Locale('ru', 'RU'),
          supportedLocales: const [
            Locale('ru', 'RU'),
            Locale('en', 'US'),
          ],
          localizationsDelegates: [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          theme: ThemeData( // <--- Темная тема по умолчанию
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.blue,
              brightness: Brightness.dark,
            ),
            useMaterial3: true,
            scaffoldBackgroundColor: const Color(0xFF1E1E1E),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF262626),
              foregroundColor: Colors.white,
            ),
            dialogTheme: const DialogTheme(
              backgroundColor: Color(0xFF333333),
              titleTextStyle: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                fontFamily: 'Roboto',
              ),
              contentTextStyle: TextStyle(
                color: Colors.white70,
                fontSize: 16,
                fontFamily: 'Roboto',
              ),
            ),
            textTheme: const TextTheme(
              bodyLarge: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 16,
                color: Colors.white,
              ),
              bodyMedium: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 14,
                color: Colors.white,
              ),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                textStyle: const TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 14,
                ),
              ),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                textStyle: const TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 14,
                ),
              ),
            ),
          ),
          home: Scaffold(
            body: PageView( // <--- Заменили Center на PageView
              controller: _pageController, // <--- Подключили PageController
              children: _widgetOptions, // <--- Ваши экраны
              onPageChanged: (index) { // <--- Слушатель смены страниц
                setState(() {
                  _selectedIndex = index;
                });
              },
            ),
            bottomNavigationBar: BottomNavigationBar(
              items: const <BottomNavigationBarItem>[
                BottomNavigationBarItem(
                  icon: Icon(Icons.home),
                  label: 'Home',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.settings),
                  label: 'Settings',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.analytics),
                  label: 'Stats',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.bar_chart),
                  label: 'Payments',
                ),
              ],
              currentIndex: _selectedIndex,
              selectedItemColor: Colors.blue, // Изменяет цвет активной вкладки
              unselectedItemColor: Colors.grey, // Изменяет цвет неактивных вкладок
              onTap: (index) {
                setState(() {
                  _selectedIndex = index;
                  _pageController.animateToPage( // <--- Анимация переключения страниц
                    index,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                });
              },
            ),
          ),
        );
      }),
    );
  }
}