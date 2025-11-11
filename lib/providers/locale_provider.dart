import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider for managing app locale/language
class LocaleProvider with ChangeNotifier {
  Locale _locale = const Locale('he'); // Default to Hebrew
  static const String _localeKey = 'app_locale';

  Locale get locale => _locale;

  LocaleProvider() {
    _loadLocale();
  }

  /// Load saved locale from SharedPreferences
  Future<void> _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString(_localeKey);
    
    if (languageCode != null) {
      _locale = Locale(languageCode);
      notifyListeners();
    }
  }

  /// Set new locale and save to SharedPreferences
  Future<void> setLocale(Locale locale) async {
    if (_locale == locale) return;
    
    _locale = locale;
    notifyListeners();
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localeKey, locale.languageCode);
  }

  /// Helper to check if current language is Hebrew
  bool get isHebrew => _locale.languageCode == 'he';

  /// Helper to check if current language is English
  bool get isEnglish => _locale.languageCode == 'en';

  /// Toggle between Hebrew and English
  Future<void> toggleLanguage() async {
    final newLocale = isHebrew ? const Locale('en') : const Locale('he');
    await setLocale(newLocale);
  }
}

