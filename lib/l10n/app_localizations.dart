import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'settings': 'Settings',
      'dark_theme': 'Dark Theme',
      'home': 'Home',
      'add_item': 'Add item',
      'barcode': 'Barcode',
      'history': 'History',
    },
    'ru': {
      'settings': 'Настройки',
      'dark_theme': 'Тёмная тема',
      'home': 'Главная',
      'add_item': 'Добавить',
      'barcode': 'Штрихкод',
      'history': 'История',
    },
    'kk': {
      'settings': 'Параметрлер',
      'dark_theme': 'Қараңғы тақырып',
      'home': 'Басты бет',
      'add_item': 'Қосу',
      'barcode': 'Штрихкод',
      'history': 'Тарих',
    },
  };

  String translate(String key) {
    return _localizedValues[locale.languageCode]?[key] ??
        _localizedValues['en']![key]!;
  }

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }
}

class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      ['en', 'ru', 'kk'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(covariant LocalizationsDelegate old) => false;
}
