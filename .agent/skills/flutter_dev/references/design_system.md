# Дизайн-система SportOS

Справочник по цветам, типографике и готовым виджетам.

## Цвета (AppColors)

Файл: `core/theme/app_colors.dart`

### Основные

| Константа | Hex | Использование |
|---|---|---|
| `primary` | `#6366F1` | Основной акцент (кнопки, ссылки, активные элементы) |
| `primaryLight` | `#818CF8` | Градиенты, hover-эффекты |
| `primaryDark` | `#4F46E5` | Pressed-состояние |

### Семантические

| Константа | Hex | Использование |
|---|---|---|
| `success` | `#22C55E` | Оплачено, Пройдено, Онлайн |
| `successLight` | `#BBF7D0` | Фон бейджа "успех" |
| `successDark` | `#15803D` | Текст на светлом фоне "успех" |
| `warning` | `#F59E0B` | Без VET, Ожидание, Слабый сигнал |
| `error` | `#EF4444` | Долг, Ошибка, Красный флаг |

### Нейтральные (Slate шкала)

| Константа | Использование |
|---|---|
| `black` (Slate 900) | Основной текст |
| `grey800` | Поверхности (dark mode) |
| `grey600` | Вторичный текст |
| `grey500` | Мета-информация, подзаголовки |
| `grey400` | Placeholder, disabled |
| `grey200` | Границы, разделители |
| `grey100` | Фон карточек (light mode) |
| `white` | Текст на тёмном фоне |

## Типографика (AppTypography)

Файл: `core/theme/app_typography.dart`

Шрифт: **Inter** (через `google_fonts`)

| Стиль | Размер | Weight | Использование |
|---|---|---|---|
| `headlineLarge` | 28 | Bold | Заголовок экрана |
| `headlineSmall` | 22 | Bold | Заголовок секции |
| `titleLarge` | 18 | SemiBold | Имя участника, название карточки |
| `bodyLarge` | 16 | Regular | Основной текст |
| `bodyMedium` | 14 | Regular | Описания, подзаголовки |
| `labelLarge` | 14 | Bold | Кнопки |
| `labelSmall` | 11 | Medium | Бейджи, время, мета |

## Готовые виджеты

### AppButton

Файл: `core/widgets/app_button.dart`

```dart
// Основная кнопка (индиго)
AppButton.primary(text: 'Сохранить', onPressed: () {})

// Вторичная кнопка (обводка)
AppButton.secondary(text: 'Отмена', onPressed: () {})

// Кнопка опасного действия (красная)
AppButton.danger(text: 'Остановить гонку', icon: Icons.flag, onPressed: () {})
```

### StatusBadge

Файл: `core/widgets/status_badge.dart`

```dart
const StatusBadge(text: 'ОПЛАЧЕНО', type: BadgeType.success)
const StatusBadge(text: 'ДОЛГ', type: BadgeType.error)
const StatusBadge(text: 'ОЖИДАНИЕ', type: BadgeType.warning)
const StatusBadge(text: 'ЧЕРНОВИК', type: BadgeType.neutral)
```

### OpsContextBanner

Файл: `core/widgets/ops_context_banner.dart`

Оранжевый баннер в верхней части экрана в Ops-режиме. Показывает роль и кнопку "Выйти" с диалогом подтверждения.

```dart
const OpsContextBanner(eventName: 'Чемпионат Урала 2026')
```

Встроен в `OpsRootShell` — **автоматически** виден на каждом экране Ops-режима. Не нужно добавлять вручную.

## Темы

Файл: `core/theme/app_theme.dart`

Две темы: `AppTheme.lightTheme` и `AppTheme.darkTheme`. Переключение автоматическое через `ThemeMode.system`.

### Как использовать цвета в виджетах

```dart
// ✅ Для стандартных surface/background:
Theme.of(context).colorScheme.surface

// ✅ Для бренд-цветов и семантических:
AppColors.primary
AppColors.success
AppColors.grey500

// ✅ Для текстовых стилей:
Theme.of(context).textTheme.headlineSmall
```

## Принципы дизайна (Glassmorphism / iOS Style)

1. **Pill Shapes (Пилюли)** — `StadiumBorder()` или `BorderRadius.circular(999)` для всех кнопок, табов и бейджей. Никаких слегка скругленных прямоугольников.
2. **Glass Cards & Panels** — `BorderRadius.circular(20)` или `24` для крупных элементов (карточки, модалки, `BottomSheet`). ОБЯЗАТЕЛЬНО использование полупрозрачного фона (`withValues(alpha: 0.8)`) в комбинации с `BackdropFilter` (Blur 16-24) для создания эффекта матового стекла (Frosted Glass).
3. **Subtle borders** — `AppColors.grey200` (или `outlineVariant.withValues(alpha: 0.2)`) с шириной 1px для акцентирования эффекта толщины стекла.
4. **No Elevation (Без теней)** — Использование стандартных теней Material (`elevation`) строго запрещено. Интерфейс должен ощущаться легким, многослойность достигается за счет размытия фона (`BackdropFilter`).
5. **Color-coded icons** — каждая секция/действие имеет свой цвет иконки.
6. **Grouped cards** — связанные элементы группируются в одну карточку с разделителями (стиль Apple Settings).
7. **Оранжевый = Ops** — весь Ops-режим маркирован оранжевым (#EA580C → #F97316).
8. **Индиго = Primary** — основной акцент приложения (#6366F1).
