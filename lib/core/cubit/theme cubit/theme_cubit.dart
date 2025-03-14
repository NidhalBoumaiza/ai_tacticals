// lib/core/cubit/theme_cubit.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'theme_state.dart';

class ThemeCubit extends Cubit<ThemeMode> {
  ThemeCubit() : super(ThemeMode.system) {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final savedTheme = prefs.getString('themeMode');
    if (savedTheme != null) {
      emit(savedTheme == 'light' ? ThemeMode.light : ThemeMode.dark);
    } else {
      emit(ThemeMode.system); // Default to system theme
    }
  }

  Future<void> toggleTheme() async {
    final prefs = await SharedPreferences.getInstance();
    if (state == ThemeMode.light) {
      emit(ThemeMode.dark);
      await prefs.setString('themeMode', 'dark');
    } else {
      emit(ThemeMode.light);
      await prefs.setString('themeMode', 'light');
    }
  }
}
