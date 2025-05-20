import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive/hive.dart';
import 'package:invent_app_redesign/services/auth_service.dart';
import 'package:invent_app_redesign/screens/login_screen.dart'; // Импорт для NetworkService

class ThemeProvider with ChangeNotifier {
  ThemeData _currentTheme = ThemeData.light();
  String _themeName = 'light';

  ThemeData get currentTheme => _currentTheme;
  String get themeName => _themeName;

  final AuthService _authService = AuthService();

  ThemeProvider() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final box = Hive.box('settings');
    final user = FirebaseAuth.instance.currentUser;

    try {
      if (user != null && (await NetworkService.isOnline())) {
        final prefs = await _authService.loadUserPreferences(user.uid);
        final theme = prefs['theme'] ?? box.get('theme', defaultValue: 'light') as String;
        _setThemeFromString(theme, notify: false);
        await box.put('theme', theme);
      } else {
        final theme = box.get('theme', defaultValue: 'light') as String;
        _setThemeFromString(theme, notify: false);
      }
    } catch (e) {
      print('Error loading theme: $e');
      _setThemeFromString('light', notify: false);
    }
  }

  Future<void> setTheme(String themeName) async {
    _setThemeFromString(themeName);
    final box = Hive.box('settings');
    await box.put('theme', themeName);

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        if (await NetworkService.isOnline()) {
          final language = ''; // Не трогаем язык
          await _authService.saveUserPreferences(user.uid, themeName, language);
        }
      } catch (e) {
        print('Error saving theme to Firestore: $e');
      }
    }
  }

  void _setThemeFromString(String themeName, {bool notify = true}) {
    _themeName = themeName;
    _currentTheme = themeName == 'dark' ? ThemeData.dark() : ThemeData.light();
    if (notify) {
      notifyListeners();
    }
  }
}