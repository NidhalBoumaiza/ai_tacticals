import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'theme_state.dart';

class ThemeCubit extends Cubit<ThemeMode> {
  ThemeCubit([ThemeMode initialThemeMode = ThemeMode.system]) : super(initialThemeMode) {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final savedTheme = prefs.getString('themeMode');
    if (savedTheme != null) {
      emit(savedTheme == 'light' ? ThemeMode.light : savedTheme == 'dark' ? ThemeMode.dark : ThemeMode.system);
    }
    // If no saved theme, keep the initialThemeMode (no emit needed since it's already the state)
  }

  Future<void> toggleTheme({ThemeMode? specificMode}) async {
    final prefs = await SharedPreferences.getInstance();
    ThemeMode newMode;

    if (specificMode != null) {
      newMode = specificMode;
    } else {
      // Toggle between light and dark if no specific mode is provided
      newMode = state == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    }

    emit(newMode);
    await prefs.setString('themeMode', newMode == ThemeMode.light ? 'light' : newMode == ThemeMode.dark ? 'dark' : 'system');
  }
}