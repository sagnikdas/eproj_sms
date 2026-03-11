import 'package:flutter/material.dart';

/// Supported app languages.
enum AppLanguage { english, bengali, kannada, hindi, urdu, assamese, tamil, malayalam, telugu }

extension AppLanguageX on AppLanguage {
  String get code {
    switch (this) {
      case AppLanguage.english:
        return 'en';
      case AppLanguage.bengali:
        return 'bn';
      case AppLanguage.kannada:
        return 'kn';
      case AppLanguage.hindi:
        return 'hi';
      case AppLanguage.urdu:
        return 'ur';
      case AppLanguage.assamese:
        return 'as';
      case AppLanguage.tamil:
        return 'ta';
      case AppLanguage.malayalam:
        return 'ml';
      case AppLanguage.telugu:
        return 'te';
    }
  }

  Locale get locale => Locale(code);
}

