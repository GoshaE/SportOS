# Web Release Build — Паттерны и ограничения

> **ВАЖНО**: SportOS собирается под Web (CanvasKit) через `flutter build web --release`.
> Компилятор `dart2js` при минификации ломает некоторые паттерны Dart-кода,
> которые отлично работают в debug-режиме и native builds.

---

## 1. Map Access + Null-Safe Chaining ⚠️

### Проблема
`dart2js` некорректно компилирует **chained null-safe access** на результате Map lookup:

```dart
// ❌ ЛОМАЕТСЯ в web release — возвращает '' вместо '1':
final place = row.cells['place']?.display ?? '';

// ❌ Даже с промежуточной переменной — тоже может ломаться:
final cell = row.cells['place'];
final place = cell?.display ?? '';
```

### Решение
Используй **helper-метод класса**, который инкапсулирует `?.display` внутри:

```dart
// ✅ ПРАВИЛЬНО — метод класса:
final place = row.cell('place');  // → '1'

// Реализация в ResultRow:
String cell(String columnId) => cells[columnId]?.display ?? '';
```

### Правило
> Если класс содержит `Map<String, T>` и `T` имеет поля (`.display`, `.value`, etc.),
> **ВСЕГДА** предоставляй helper-метод для безопасного доступа.
> Не полагайся на inline `map['key']?.field` в web release.

---

## 2. Emoji в CanvasKit 🚫

### Проблема
Flutter Web использует CanvasKit renderer, который **не рендерит color emoji** надёжно.
Emoji (🥇🥈🥉) отображаются как невидимые символы (пустое место).

### Решение
Заменяй emoji на **styled виджеты**:

```dart
// ❌ НЕ РАБОТАЕТ на web:
const Text('🥇', style: TextStyle(fontSize: 16))

// ✅ ПРАВИЛЬНО — styled badge:
Container(
  width: 26, height: 26,
  alignment: Alignment.center,
  decoration: BoxDecoration(
    color: Color(0xFFFFD700).withOpacity(0.2),  // gold
    shape: BoxShape.circle,
    border: Border.all(color: Color(0xFFFFD700), width: 1.5),
  ),
  child: Text('1', style: TextStyle(
    color: Color(0xFFFFD700), fontSize: 13, fontWeight: FontWeight.w900)),
)
```

### Стандартные цвета медалей
```dart
const medalColors = {
  '1': Color(0xFFFFD700),  // Gold
  '2': Color(0xFFC0C0C0),  // Silver
  '3': Color(0xFFCD7F32),  // Bronze
};
```

---

## 3. Сложность build() метода ⚠️

### Проблема
`dart2js` может сломать виджет, если `build()` метод слишком сложный:
- Много ветвлений (`if/else` chains)
- Dynamic type checks (`value is int`, `value is Duration`)
- Enum comparisons в комбинации с dynamic access
- Большое количество локальных переменных разных типов

### Решение
- Разбивай сложную логику на **private helper-методы**
- Избегай `is` type checks на `dynamic` полях в `build()`
- Используй **строковые значения** (`.display`) вместо raw/dynamic полей
- Если виджет падает только на web release — бисекция: убирай половину кода, тестируй

---

## 4. Шрифты: GoogleFonts vs Local ⚠️

### Проблема
`GoogleFonts.jetBrainsMono()` может не грузиться на web или вызывать CORS-ошибки.

### Решение
Для критичных шрифтов (моноширинный timing) используй web-safe fallback:

```dart
// ✅ Web-safe mono:
static const monoTiming = TextStyle(
  fontFamily: 'monospace',  // всегда доступен
  fontFeatures: [FontFeature.tabularFigures()],
);
```

---

## 5. Чеклист перед web release

- [ ] Нет прямого `map['key']?.field` — используй helper-методы
- [ ] Нет emoji в `Text()` — используй styled виджеты
- [ ] Нет `is` type checks на `dynamic` в `build()`
- [ ] `build()` метод компактный (< 80 строк)
- [ ] Шрифты web-safe или с fallback
- [ ] Протестировано на iOS Safari (основная платформа пользователей)

---

## 6. Отладка web release

Если виджет ломается только на web release:

1. **Бисекция**: заменяй `build()` на `const Text('test')`, убедись что работает
2. **Добавляй код частями**: 20-30 строк за раз, пуш + тест
3. **Debug текст**: добавь `Text(debugInfo)` с значениями переменных, чтобы увидеть что приходит
4. **Три подхода сравнения**: тестируй inline access, local variable, helper method
5. **Commit каждый шаг**: чтобы можно было откатиться
