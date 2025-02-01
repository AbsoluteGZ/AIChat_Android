# Инструкция по установке

## Системные требования

### Общие требования
- [Flutter SDK](https://flutter.dev/docs/get-started/install)
- Git
- VS Code или Android Studio (рекомендуется)

### Windows
- Windows 10 или выше
- Visual Studio 2019 или выше с Desktop development with C++ workload
- Windows 10 SDK

### Android
- Android Studio
- Android SDK
- Java Development Kit (JDK)

### iOS (для сборки под iOS)
- macOS с Xcode
- CocoaPods

## Установка

1. Клонируйте репозиторий:
```bash
git clone https://github.com/neuro-fill/AIChatFlutter.git
cd AIChatFlutter
```

2. Установите Flutter SDK:
   - Скачайте Flutter SDK с [официального сайта](https://flutter.dev/docs/get-started/install)
   - Добавьте Flutter в PATH
   - Запустите `flutter doctor` и следуйте инструкциям для установки недостающих компонентов

3. Настройка VSCode:
   - Установите расширения Flutter и Dart
   - Настройте форматирование кода (рекомендуется использовать dart format)
   - Убедитесь, что в настройках включена поддержка Flutter

4. Установите зависимости проекта:
```bash
flutter pub get
```

## Настройка окружения для сборки

### Windows
1. Установите Visual Studio с компонентами для разработки на C++:
   - Desktop development with C++
   - Windows 10 SDK
   - Visual C++ tools for CMake
   
2. Включите режим разработчика в Windows:
   - Настройки > Обновление и безопасность > Для разработчиков
   - Включите "Режим разработчика"

3. Проверьте настройку Flutter для Windows:
```bash
flutter config --enable-windows-desktop
flutter doctor -v
```

### Android
1. Установите Android Studio:
   - Скачайте и установите [Android Studio](https://developer.android.com/studio)
   - Запустите Android Studio и пройдите начальную настройку
   - Установите Android SDK через SDK Manager
   - В SDK Manager установите:
     - Android SDK Build-Tools
     - Android SDK Command-line Tools
     - Android SDK Platform-Tools

2. Настройте Android Studio:
   - Установите Flutter и Dart плагины
   - Настройте Android SDK
   - Создайте и настройте Android эмулятор

3. Настройте подписывание APK (для release-сборки):
   - Создайте keystore для подписи релизной версии:
     ```bash
     keytool -genkey -v -keystore android/app/upload-keystore.jks -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 -alias upload
     ```
   - Создайте файл `android/key.properties` со следующим содержимым:
     ```properties
     storePassword=<пароль от keystore>
     keyPassword=<пароль от ключа>
     keyAlias=upload
     storeFile=app/upload-keystore.jks
     ```
   - Добавьте `key.properties` в `.gitignore`

4. Проверьте настройку Flutter для Android:
```bash
flutter doctor -v
```

### iOS
1. Установите Xcode с App Store
2. Установите CocoaPods:
```bash
sudo gem install cocoapods
```
3. Настройте Xcode:
   - Откройте ios/Runner.xcworkspace в Xcode
   - Убедитесь, что выбрана последняя версия iOS SDK
   - Настройте подписание приложения (автоматическое или вручную)

## Сборка приложения

### Android
1. Debug версия (для тестирования):
```bash
flutter build apk --debug
```
2. Release версия (для публикации):
```bash
flutter build apk --release
```
3. Split APKs по архитектуре (оптимизированный размер):
```bash
flutter build apk --split-per-abi
```

### iOS
1. Debug версия (для тестирования):
```bash
flutter build ios --debug
```
2. Release версия (для публикации):
```bash
flutter build ios --release
```
3. Создание .ipa файла:
```bash
flutter build ipa
```

## Расположение сбилденных файлов

### Android
- Debug APK: `build/app/outputs/flutter-apk/app-debug.apk`
- Release APK: `build/app/outputs/flutter-apk/app-release.apk`
- Split APKs:
  - `build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk`
  - `build/app/outputs/flutter-apk/app-arm64-v8a-release.apk`
  - `build/app/outputs/flutter-apk/app-x86_64-release.apk`

### iOS
- Debug: `build/ios/iphoneos/Runner.app`
- Release: `build/ios/iphoneos/Runner.app`
- IPA: `build/ios/ipa/Runner.ipa`

### Windows
- Debug: `build/windows/runner/Debug/`
- Release: `build/windows/runner/Release/`

### Linux
- Debug: `build/linux/x64/debug/bundle/`
- Release: `build/linux/x64/release/bundle/`

## Запуск приложения в desktop режиме для отладки

### Windows
1. Убедитесь, что установлены все необходимые компоненты:
   - Visual Studio с поддержкой C++
   - Windows 10 SDK
2. Включите поддержку Windows desktop:
```bash
flutter config --enable-windows-desktop
```
3. Запустите приложение:
```bash
flutter run -d windows
```

### Linux
1. Установите необходимые зависимости:
```bash
sudo apt-get install clang cmake ninja-build pkg-config libgtk-3-dev
```
2. Включите поддержку Linux desktop:
```bash
flutter config --enable-linux-desktop
```
3. Запустите приложение:
```bash
flutter run -d linux
```

## Запуск приложения в Android эмуляторе

1. Создание эмулятора:
   - Откройте Android Studio
   - Перейдите в Device Manager (Tools > Device Manager)
   - Нажмите "Create Device"
   - Выберите тип устройства (например, Pixel 6)
   - Выберите образ системы (рекомендуется API 33 или новее)
   - Задайте имя эмулятора и нажмите "Finish"

2. Запуск эмулятора:
   - В Device Manager нажмите ▶️ рядом с созданным эмулятором
   - Или через командную строку:
     ```bash
     emulator -avd имя_эмулятора
     ```

3. Запуск приложения:
   - Убедитесь, что эмулятор запущен
   - Выполните команду:
     ```bash
     flutter run
     ```
   - Если нужно указать конкретный эмулятор:
     ```bash
     flutter run -d имя_эмулятора
     ```

4. Горячие клавиши:
   - R - Перезагрузить приложение
   - r - Hot reload (быстрая перезагрузка изменений)
   - q - Выйти из режима разработки

## Конфигурация

1. Создайте файл .env на основе .env.example:
```bash
cp .env.example .env
```

2. Отредактируйте .env и добавьте ваш API ключ:
```
OPENROUTER_API_KEY=ваш-ключ-здесь
```

## Проверка установки

1. Проверьте статус Flutter:
```bash
flutter doctor
```

2. Запустите приложение для проверки:
```bash
flutter run
```

Если все установлено правильно, приложение должно запуститься на выбранном устройстве (эмулятор Android, iOS или Windows).
