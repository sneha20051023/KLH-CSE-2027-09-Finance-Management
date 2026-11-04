import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages app-wide user preferences and settings.
///
/// Persists settings locally with [SharedPreferences].
class SettingsProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;
  String _currencySymbol = '₹';
  String _currencyCode = 'INR';
  bool _notificationsEnabled = true;
  bool _billRemindersEnabled = true;
  int _reminderDaysBefore = 1;

  SharedPreferences? _prefs;

  // ── Getters ──────────────────────────────────────────────────────────
  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;
  String get currencySymbol => _currencySymbol;
  String get currencyCode => _currencyCode;
  bool get notificationsEnabled => _notificationsEnabled;
  bool get billRemindersEnabled => _billRemindersEnabled;
  bool get billReminders => _billRemindersEnabled;
  int get reminderDaysBefore => _reminderDaysBefore;

  SettingsProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      final isDark = _prefs?.getBool('is_dark_mode') ?? false;
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
      _currencySymbol = _prefs?.getString('currency_symbol') ?? '₹';
      _currencyCode = _prefs?.getString('currency_code') ?? 'INR';
      _notificationsEnabled = _prefs?.getBool('notifications_enabled') ?? true;
      _billRemindersEnabled = _prefs?.getBool('bill_reminders_enabled') ?? true;
      _reminderDaysBefore = _prefs?.getInt('reminder_days_before') ?? 1;
      notifyListeners();
    } catch (_) {
      // Use defaults if SharedPreferences is unavailable
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    try {
      await _prefs?.setBool('is_dark_mode', mode == ThemeMode.dark);
    } catch (_) {}
  }

  Future<void> toggleTheme() async {
    if (_themeMode == ThemeMode.dark) {
      await setThemeMode(ThemeMode.light);
    } else {
      await setThemeMode(ThemeMode.dark);
    }
  }

  Future<void> setCurrency(String symbolOrCode, String codeOrSymbol) async {
    String symbol;
    String code;
    if (symbolOrCode.length == 3 && codeOrSymbol.length <= 2) {
      code = symbolOrCode;
      symbol = codeOrSymbol;
    } else {
      symbol = symbolOrCode;
      code = codeOrSymbol;
    }
    _currencySymbol = symbol;
    _currencyCode = code;
    notifyListeners();
    try {
      await _prefs?.setString('currency_symbol', symbol);
      await _prefs?.setString('currency_code', code);
    } catch (_) {}
  }

  Future<void> setNotificationsEnabled(bool value) async {
    _notificationsEnabled = value;
    notifyListeners();
    try {
      await _prefs?.setBool('notifications_enabled', value);
    } catch (_) {}
  }

  Future<void> setNotifications(bool value) => setNotificationsEnabled(value);

  Future<void> setBillRemindersEnabled(bool value) async {
    _billRemindersEnabled = value;
    notifyListeners();
    try {
      await _prefs?.setBool('bill_reminders_enabled', value);
    } catch (_) {}
  }

  Future<void> setBillReminders(bool value) => setBillRemindersEnabled(value);

  Future<void> setReminderDaysBefore(int days) async {
    _reminderDaysBefore = days;
    notifyListeners();
    try {
      await _prefs?.setInt('reminder_days_before', days);
    } catch (_) {}
  }
}

