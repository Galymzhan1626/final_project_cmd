import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive/hive.dart';
import 'package:invent_app_redesign/services/auth_service.dart';
import 'package:invent_app_redesign/screens/login_screen.dart';

class LocaleProvider with ChangeNotifier {
  Locale _locale = const Locale('en');
  final AuthService _authService = AuthService();

  Locale get locale => _locale;

  LocaleProvider() {
    _loadLocale();
  }

  Future<void> _loadLocale() async {
    final box = Hive.box('settings');
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      final prefs = await _authService.loadUserPreferences(user.uid);
      final langCode = prefs['language'] ?? box.get('language', defaultValue: 'en') as String;
      _locale = Locale(langCode);
      await box.put('language', langCode);
      notifyListeners();
    } else {
      final langCode = box.get('language', defaultValue: 'en') as String;
      _locale = Locale(langCode);
      notifyListeners();
    }
  }

  void setLanguage(String languageCode) async {
    _locale = Locale(languageCode);
    notifyListeners();

    final box = Hive.box('settings');
    await box.put('language', languageCode);

    final user = FirebaseAuth.instance.currentUser;
    if (user != null && (await NetworkService.isOnline())) {
      final theme = ''; // Не трогаем тему
      await _authService.saveUserPreferences(user.uid, theme, languageCode);
    }
  }
}