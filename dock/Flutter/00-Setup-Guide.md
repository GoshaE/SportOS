# 🛠 TimeUP Titan: Setup Guide

Since you are starting fresh, follow these steps to initialize the **Flutter** project.

## 1. Prerequisites
Ensure you have Flutter installed.
```bash
flutter --version
# Should output 3.x.x
```
*If not found, download from [flutter.dev](https://flutter.dev)*

## 2. Initialize Project
Run this in the folder where you want the app (e.g., inside `TimeUP` if you cleared it).

```bash
# Create the app (using "timeup_app" as internal name)
flutter create timeup_app --org io.timeup

# Move into the folder
cd timeup_app
```

## 3. Install Libraries (The Titan Stack)
Run these commands to install our core dependencies:

### Core Logic & State
```bash
flutter pub add flutter_riverpod riverpod_annotation freezed_annotation json_annotation
```

### Backend & Data
```bash
flutter pub add supabase_flutter isar isar_flutter_libs path_provider
```

### UI & Navigation
```bash
flutter pub add go_router flutter_svg gap google_fonts intl
```

### Utilities
```bash
flutter pub add wakelock_plus uuid connectivity_plus
```

### Dev Dependencies (Code Generation)
```bash
flutter pub add --dev build_runner riverpod_generator freezed json_serializable isar_generator
```

## 4. Verify Setup
Run the app to make sure everything links correctly.
```bash
flutter run
```
