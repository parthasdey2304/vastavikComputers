import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart' show StateNotifierProvider, StateNotifier;
import 'package:shared_preferences/shared_preferences.dart';
import 'app_theme.dart';

/// Holds the currently active theme mode (persisted via SharedPreferences).
class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  static const _storageKey = 'vastavik_theme_mode';

  ThemeModeNotifier() : super(ThemeMode.light) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    switch (raw) {
      case 'dark':
        state = ThemeMode.dark;
        break;
      case 'system':
        state = ThemeMode.system;
        break;
      default:
        state = ThemeMode.light;
    }
  }

  Future<void> _save(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _storageKey,
      mode == ThemeMode.dark
          ? 'dark'
          : (mode == ThemeMode.system ? 'system' : 'light'),
    );
  }

  Future<void> set(ThemeMode mode) async {
    state = mode;
    await _save(mode);
  }

  Future<void> toggle() async {
    final next = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    await set(next);
  }
}

final themeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier();
});

/// Convenience getter for the currently active ThemeData.
final appThemeProvider = Provider<ThemeData>((ref) {
  final mode = ref.watch(themeModeProvider);
  return mode == ThemeMode.dark ? AppTheme.darkTheme : AppTheme.lightTheme;
});
