# Продвинутые паттерны Flutter — Часть 2

Формы, тема, роутинг, тестирование, платформенные каналы, accessibility.

---

## 11. Multi-Step Wizard Form

Единый источник состояния + пошаговая валидация (используем в RegisterWizardScreen).

```dart
// domain/entity/registration_form.dart
@freezed
class RegistrationForm with _$RegistrationForm {
  const factory RegistrationForm({
    // Step 1: Дисциплина
    String? disciplineId,
    // Step 2: Участник + собака
    String? participantName,
    String? dogName,
    // Step 3: Оплата
    @Default(false) bool isPaid,
  }) = _RegistrationForm;
}

// domain/provider/registration_provider.dart
@riverpod
class RegistrationWizard extends _$RegistrationWizard {
  @override
  RegistrationForm build() => const RegistrationForm();

  void setDiscipline(String id) =>
      state = state.copyWith(disciplineId: id);

  void setParticipant(String name, String dog) =>
      state = state.copyWith(participantName: name, dogName: dog);

  void markPaid() =>
      state = state.copyWith(isPaid: true);

  bool canProceedStep(int step) => switch (step) {
    0 => state.disciplineId != null,
    1 => state.participantName != null && state.dogName != null,
    2 => state.isPaid,
    _ => false,
  };
}
```

### UI: PageView + индикатор шагов

```dart
class RegisterWizardScreen extends ConsumerStatefulWidget {
  @override
  ConsumerState createState() => _RegisterWizardState();
}

class _RegisterWizardState extends ConsumerState<RegisterWizardScreen> {
  final _pageController = PageController();
  int _currentStep = 0;

  @override
  Widget build(BuildContext context) {
    final wizard = ref.watch(registrationWizardProvider);
    final notifier = ref.read(registrationWizardProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: Text('Шаг ${_currentStep + 1} из 3')),
      body: Column(children: [
        // Прогресс-бар
        LinearProgressIndicator(value: (_currentStep + 1) / 3),

        // Контент шагов
        Expanded(
          child: PageView(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(), // Только через кнопки
            children: [
              DisciplineStep(onSelect: notifier.setDiscipline),
              ParticipantStep(onSave: notifier.setParticipant),
              PaymentStep(onPaid: notifier.markPaid),
            ],
          ),
        ),
      ]),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(children: [
          if (_currentStep > 0)
            OutlinedButton(onPressed: _prevStep, child: const Text('Назад')),
          const Spacer(),
          FilledButton(
            onPressed: notifier.canProceedStep(_currentStep) ? _nextStep : null,
            child: Text(_currentStep == 2 ? 'Отправить' : 'Далее'),
          ),
        ]),
      ),
    );
  }

  void _nextStep() {
    if (_currentStep < 2) {
      setState(() => _currentStep++);
      _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    } else {
      _submit();
    }
  }

  void _prevStep() {
    setState(() => _currentStep--);
    _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
  }

  void _submit() { /* ... */ }
}
```

---

## 12. Валидация форм — переиспользуемые правила

```dart
// core/utils/validators.dart
class Validators {
  static String? required(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Обязательное поле' : null;

  static String? email(String? v) {
    if (v == null || v.isEmpty) return 'Введите email';
    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v)) return 'Некорректный email';
    return null;
  }

  static String? bib(String? v) {
    if (v == null || v.isEmpty) return 'Введите номер';
    final n = int.tryParse(v);
    if (n == null) return 'Только цифры';
    if (n < 1 || n > 999) return 'BIB от 1 до 999';
    return null;
  }

  static String? phone(String? v) {
    if (v == null || v.isEmpty) return 'Введите телефон';
    if (v.replaceAll(RegExp(r'\D'), '').length < 10) return 'Минимум 10 цифр';
    return null;
  }

  /// Компоновщик: обязательное + email
  static FormFieldValidator<String> compose(List<FormFieldValidator<String>> validators) {
    return (value) {
      for (final v in validators) {
        final result = v(value);
        if (result != null) return result;
      }
      return null;
    };
  }
}

// Использование:
TextFormField(
  validator: Validators.compose([Validators.required, Validators.email]),
)
```

---

## 13. Material 3 Theming — ColorScheme.fromSeed

```dart
// core/theme/app_theme.dart — правильный подход

class AppTheme {
  // Seed-цвет генерирует ПОЛНУЮ палитру (50+ оттенков)
  static final lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF6366F1), // Индиго
      brightness: Brightness.light,
    ),
    textTheme: GoogleFonts.interTextTheme(),
    // Переопределяем отдельные компоненты:
    cardTheme: CardThemeData(elevation: 0, shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: BorderSide(color: Colors.grey.shade200),
    )),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      filled: true,
    ),
  );

  static final darkTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF6366F1),
      brightness: Brightness.dark,
    ),
    textTheme: GoogleFonts.interTextTheme(ThemeData(brightness: Brightness.dark).textTheme),
  );
}
```

### Переключение темы через Riverpod

```dart
// domain/provider/theme_provider.dart
@riverpod
class ThemeModeNotifier extends _$ThemeModeNotifier {
  @override
  ThemeMode build() => ThemeMode.system; // По умолчанию — системная

  void toggle() => state = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
  void setSystem() => state = ThemeMode.system;
}

// В MaterialApp:
MaterialApp.router(
  themeMode: ref.watch(themeModeNotifierProvider),
  theme: AppTheme.lightTheme,
  darkTheme: AppTheme.darkTheme,
  routerConfig: router,
);
```

---

## 14. GoRouter: Auth Guard + Deep Link Restore

```dart
final router = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/hub',
  refreshListenable: authNotifier, // Перестраивает redirect при смене auth-стейта

  redirect: (context, state) {
    final isLoggedIn = authNotifier.isLoggedIn;
    final isAuthRoute = state.matchedLocation.startsWith('/welcome') ||
                        state.matchedLocation.startsWith('/login');

    // Не авторизован → на логин (сохранив целевой URL)
    if (!isLoggedIn && !isAuthRoute) {
      return '/login?redirect=${Uri.encodeComponent(state.uri.toString())}';
    }

    // Авторизован + на странице логина → домой (или на сохранённый URL)
    if (isLoggedIn && isAuthRoute) {
      final redirect = state.uri.queryParameters['redirect'];
      return redirect != null ? Uri.decodeComponent(redirect) : '/hub';
    }

    // Role-based guards
    if (state.matchedLocation.startsWith('/manage') && !authNotifier.isOrganizer) {
      return '/hub';
    }
    if (state.matchedLocation.startsWith('/ops') && !authNotifier.hasOpsRole) {
      return '/hub';
    }

    return null; // Пропускаем
  },
  routes: [ /* ... */ ],
);
```

---

## 15. Тестирование — уровни и паттерны

### Unit-тест: Entity

```dart
test('TimingRecord.duration вычисляется корректно', () {
  final record = TimingRecord(
    id: '1', bib: 42,
    startTime: DateTime(2026, 3, 11, 10, 0, 0),
    finishTime: DateTime(2026, 3, 11, 10, 5, 30),
  );
  expect(record.duration, const Duration(minutes: 5, seconds: 30));
});

test('TimingRecord.duration = null если не финишировал', () {
  final record = TimingRecord(id: '1', bib: 42, startTime: DateTime.now());
  expect(record.duration, isNull);
});
```

### Unit-тест: Riverpod Provider

```dart
test('TimingNotifier загружает записи', () async {
  final container = ProviderContainer(overrides: [
    timingRepositoryProvider.overrideWithValue(MockTimingRepository()),
  ]);

  // Ждём загрузки
  await container.read(timingNotifierProvider.future);

  final state = container.read(timingNotifierProvider);
  expect(state.value, hasLength(3)); // Mock возвращает 3 записи
});
```

### Widget-тест: экран с Riverpod

```dart
testWidgets('CheckInScreen показывает список участников', (tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        participantListProvider.overrideWith((_) => [
          Participant(bib: 1, name: 'Алексей', checkedIn: false),
          Participant(bib: 2, name: 'Мария', checkedIn: true),
        ]),
      ],
      child: const MaterialApp(home: CheckInScreen()),
    ),
  );

  expect(find.text('Алексей'), findsOneWidget);
  expect(find.text('Мария'), findsOneWidget);
  expect(find.byIcon(Icons.check_circle), findsOneWidget); // Мария отмечена
});
```

### Integration-тест: полный flow

```dart
// integration_test/checkin_flow_test.dart
void main() {
  testWidgets('Чек-ин flow от начала до финиша', (tester) async {
    app.main(); // Запустить реальное приложение
    await tester.pumpAndSettle();

    // Навигация к чек-ину
    await tester.tap(find.text('Мои'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Чемпионат Урала'));
    await tester.pumpAndSettle();

    // Проверяем чек-ин участника
    await tester.tap(find.byKey(const Key('checkin-bib-42')));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.check_circle), findsWidgets);
  });
}
```

---

## 16. Platform Channels — NFC / BLE / GPS

```dart
// core/services/nfc_service.dart
class NfcService {
  static const _channel = MethodChannel('sportos/nfc');

  /// Читает BIB с NFC-браслета. Null если таймаут или ошибка.
  static Future<int?> readBib({Duration timeout = const Duration(seconds: 10)}) async {
    try {
      final result = await _channel
          .invokeMethod<int>('readBib')
          .timeout(timeout);
      return result;
    } on PlatformException catch (e) {
      debugPrint('NFC error: ${e.message}');
      return null;
    } on TimeoutException {
      return null;
    }
  }

  /// Проверяет доступен ли NFC на устройстве
  static Future<bool> isAvailable() async {
    try {
      return await _channel.invokeMethod<bool>('isAvailable') ?? false;
    } catch (_) {
      return false;
    }
  }
}

// Использование в UI:
final bib = await NfcService.readBib();
if (bib != null) {
  ref.read(timingNotifierProvider.notifier).recordFinish(bib);
  context.showSnack('BIB $bib — Финиш зафиксирован!');
}
```

---

## 17. Accessibility — доступность

```dart
// ✅ Семантика для скринридера
Semantics(
  label: 'Участник номер 42, Алексей Петров, чек-ин не пройден',
  child: ListTile(
    leading: Text('42'),
    title: Text('Алексей Петров'),
    trailing: Icon(Icons.radio_button_unchecked),
  ),
)

// ✅ Минимальный тач-таргет (48x48 по Material Guidelines)
SizedBox(
  width: 48, height: 48,
  child: IconButton(
    icon: const Icon(Icons.check),
    onPressed: () => checkIn(42),
  ),
)

// ✅ Контраст — проверять через DevTools > Accessibility
// Минимум 4.5:1 для текста, 3:1 для крупного текста

// ✅ Поддержка клавиатуры (macOS/desktop)
Shortcuts(
  shortcuts: {
    LogicalKeySet(LogicalKeyboardKey.enter): const ActivateIntent(),
    LogicalKeySet(LogicalKeyboardKey.escape): const DismissIntent(),
  },
  child: Focus(
    autofocus: true,
    child: yourWidget,
  ),
)
```

---

## 18. Isolates — тяжёлые вычисления без фризов

```dart
// Парсинг большого JSON в фоне (не блокирует UI)
Future<List<Result>> parseResults(String jsonString) async {
  return compute(_parseResultsIsolate, jsonString);
}

List<Result> _parseResultsIsolate(String json) {
  final list = jsonDecode(json) as List;
  return list.map((e) => Result.fromJson(e as Map<String, dynamic>)).toList();
}

// Генерация дипломов PDF (тяжёлая операция)
Future<Uint8List> generateDiploma(DiplomaData data) async {
  return compute(_buildPdf, data);
}
```

---

## 19. Drift: Миграции и Seed Data

```dart
// data/database/app_database.dart
@DriftDatabase(tables: [TimingRecords, Participants, SyncQueue])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 3; // Увеличивать при каждом изменении схемы

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll(); // Создаём все таблицы
    },
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        // v2: Добавили колонку synced
        await m.addColumn(timingRecords, timingRecords.synced);
      }
      if (from < 3) {
        // v3: Добавили таблицу sync_queue
        await m.createTable(syncQueue);
      }
    },
    beforeOpen: (details) async {
      // Включаем WAL для производительности
      await customStatement('PRAGMA journal_mode=WAL');
      // Включаем foreign keys
      await customStatement('PRAGMA foreign_keys=ON');
    },
  );
}
```

---

## 20. Localization — мультиязычность

```dart
// Структура:
// lib/l10n/
//   app_ru.arb  (русский — основной)
//   app_en.arb  (английский)

// app_ru.arb:
{
  "appTitle": "SportOS",
  "checkinTitle": "Чек-ин",
  "participantCount": "{count} участников",
  "@participantCount": {
    "placeholders": {
      "count": { "type": "int" }
    }
  },
  "bibLabel": "BIB #{bib}",
  "timeFormat": "{hours}ч {minutes}мин {seconds}сек"
}

// Использование:
Text(AppLocalizations.of(context)!.participantCount(48))
// → "48 участников"
```
