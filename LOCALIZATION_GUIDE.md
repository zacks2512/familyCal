# 🌍 Localization Implementation Guide

## Overview

FamilyCal now supports **Hebrew (עברית)** and **English** with a clean, professional implementation using Flutter's official localization system.

## ✅ What's Implemented

### 1. **Core Infrastructure**

- **ARB Files** (Application Resource Bundle):
  - `lib/l10n/app_en.arb` - English translations
  - `lib/l10n/app_he.arb` - Hebrew translations (עברית)
  
- **Auto-Generated Code**:
  - Flutter generates type-safe `AppLocalizations` class
  - Compile-time safety - typos won't compile
  - Full IDE autocomplete support

- **State Management**:
  - `LocaleProvider` persists language choice using `shared_preferences`
  - Real-time language switching without app restart
  - Default language: **Hebrew** (עברית)

### 2. **User Interface**

#### Registration Flow
- Language selector in signup screen
- User can choose Hebrew or English during registration
- Segmented button design (modern Material 3 style)

#### Settings Screen
- Language option under "Account" section
- Dialog-based language picker
- Shows current language selection
- Instant language switching

### 3. **Localized Screens**

✅ **Fully Localized:**
- Welcome Screen
- Registration Options Screen
- Login Options Screen  
- Signup Screen (Email/Phone)
- Settings Screen (all sections)

🔄 **To Be Localized** (next steps):
- Verification Screen
- Calendar Screen
- Family Setup Flow
- Dialogs and alerts

## 📱 How to Use

### For Users

1. **During Registration:**
   - On the signup screen, you'll see a "Language" selector
   - Choose between עברית (Hebrew) or English
   - Default is Hebrew

2. **In Settings:**
   - Go to Settings tab
   - Under "Account" section, tap "Language"
   - Select your preferred language
   - The app updates immediately

### For Developers

#### Adding New Translations

1. **Add to English ARB** (`lib/l10n/app_en.arb`):
```json
{
  "myNewKey": "My English Text",
  "@myNewKey": {
    "description": "Description of what this text is for"
  }
}
```

2. **Add to Hebrew ARB** (`lib/l10n/app_he.arb`):
```json
{
  "myNewKey": "הטקסט העברי שלי"
}
```

3. **Use in Code:**
```dart
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

// In build method:
final l10n = AppLocalizations.of(context)!;
Text(l10n.myNewKey)
```

4. **Run code generation** (automatic with hot reload):
```bash
flutter pub get  # Regenerates localization files
```

#### Text with Parameters

**ARB file:**
```json
{
  "welcomeUser": "Welcome, {name}!",
  "@welcomeUser": {
    "description": "Welcome message with user name",
    "placeholders": {
      "name": {
        "type": "String",
        "example": "Sarah"
      }
    }
  }
}
```

**Dart code:**
```dart
Text(l10n.welcomeUser('Sarah'))
```

#### Plural Forms

**ARB file:**
```json
{
  "eventCount": "{count,plural, =0{No events} =1{1 event} other{{count} events}}",
  "@eventCount": {
    "description": "Number of events",
    "placeholders": {
      "count": {
        "type": "int"
      }
    }
  }
}
```

**Dart code:**
```dart
Text(l10n.eventCount(5))  // "5 events"
```

## 🛠️ Technical Details

### Architecture

1. **Code Generation**
   - Flutter automatically generates `AppLocalizations` class
   - Generated code is in `.dart_tool/flutter_gen/gen_l10n/`
   - Never edit generated files manually

2. **State Management**
   - `LocaleProvider` extends `ChangeNotifier`
   - Wrapped around app root in `main.dart`
   - Persists to `SharedPreferences`

3. **MaterialApp Configuration**
   ```dart
   MaterialApp(
     locale: localeProvider.locale,
     localizationsDelegates: [
       AppLocalizations.delegate,
       GlobalMaterialLocalizations.delegate,
       GlobalWidgetsLocalizations.delegate,
       GlobalCupertinoLocalizations.delegate,
     ],
     supportedLocales: [
       Locale('he'),  // Hebrew
       Locale('en'),  // English
     ],
   )
   ```

### Right-to-Left (RTL) Support

Flutter automatically handles RTL layout for Hebrew:
- Text alignment
- Icon positions
- Scroll direction
- Navigation direction

**No extra code needed!** Just set the locale to `he`.

## 🎯 Best Practices

### DO ✅

- Use `AppLocalizations.of(context)!` at the top of `build()`
- Add descriptions to all ARB keys
- Keep keys descriptive (e.g., `signupTitle` not `st`)
- Test in both languages
- Use parameters for dynamic text

### DON'T ❌

- Hardcode strings in UI
- Use string concatenation for translations
- Forget to update both ARB files
- Edit generated code
- Use emojis in keys

## 🌐 Adding More Languages

To add a new language (e.g., Arabic):

1. Create `lib/l10n/app_ar.arb`
2. Copy structure from `app_en.arb`
3. Translate all values
4. Add to `supportedLocales` in `main.dart`:
   ```dart
   supportedLocales: [
     Locale('he'),
     Locale('en'),
     Locale('ar'),  // Arabic
   ],
   ```
5. Update `LanguageSelector` widget to include Arabic option

## 📊 Translation Status

| Screen | English | Hebrew |
|--------|---------|--------|
| Welcome | ✅ | ✅ |
| Registration Options | ✅ | ✅ |
| Login Options | ✅ | ✅ |
| Signup | ✅ | ✅ |
| Settings | ✅ | ✅ |
| Calendar | ⏳ | ⏳ |
| Family Setup | ⏳ | ⏳ |
| Verification | ⏳ | ⏳ |

**Legend:** ✅ Complete | ⏳ To Do

## 🔍 Testing

### Manual Testing

1. Start app (defaults to Hebrew)
2. Navigate to Signup → Language selector should show
3. Switch to English → All text should update
4. Go to Settings → Account → Language
5. Switch language → Should persist after app restart

### Automated Testing

```dart
testWidgets('Language switching works', (tester) async {
  await tester.pumpWidget(
    ChangeNotifierProvider(
      create: (_) => LocaleProvider(),
      child: MyApp(),
    ),
  );
  
  // Test Hebrew (default)
  expect(find.text('הרשמה'), findsOneWidget);
  
  // Switch to English
  final provider = tester.widget<ChangeNotifierProvider>(
    find.byType(ChangeNotifierProvider),
  ).create(null) as LocaleProvider;
  
  await provider.setLocale(Locale('en'));
  await tester.pumpAndSettle();
  
  // Test English
  expect(find.text('Register'), findsOneWidget);
});
```

## 📚 Resources

- [Flutter Internationalization](https://docs.flutter.dev/ui/accessibility-and-internationalization/internationalization)
- [ARB Format Specification](https://github.com/google/app-resource-bundle/wiki/ApplicationResourceBundleSpecification)
- [Material 3 Localization](https://m3.material.io/foundations/content-design/internationalization)

## ⚡ Quick Reference

```dart
// Get localization instance
final l10n = AppLocalizations.of(context)!;

// Use translation
Text(l10n.appName)

// Check current language
Provider.of<LocaleProvider>(context).isHebrew

// Change language programmatically
Provider.of<LocaleProvider>(context, listen: false)
    .setLocale(Locale('en'));

// Toggle between languages
Provider.of<LocaleProvider>(context, listen: false)
    .toggleLanguage();
```

---

**Implementation Date:** November 2025  
**Status:** ✅ Production Ready  
**Default Language:** Hebrew (עברית)

