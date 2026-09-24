import 'package:flutter/material.dart';

enum AppLocale {
  arabic(code: 'ar'),
  english(code: 'en');

  const AppLocale({required this.code});

  final String code;

  Locale get locale => Locale(code);

  static AppLocale fromCode(String? code) {
    return switch (code?.trim().toLowerCase()) {
      'en' => AppLocale.english,
      _ => AppLocale.arabic,
    };
  }

  AppLocale get alternate => switch (this) {
    AppLocale.arabic => AppLocale.english,
    AppLocale.english => AppLocale.arabic,
  };
}
