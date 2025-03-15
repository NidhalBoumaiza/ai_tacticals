import 'package:flutter/material.dart';

class AppThemes {
  static const Color primaryColor = Color(0xFFfbc02d); // Yellow-orange
  static const Color darkGray = Color(0xFF37383c); // Dark gray

  static final lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: primaryColor,
    scaffoldBackgroundColor: Colors.grey[50]!,
    // Very light gray for background
    colorScheme: ColorScheme.light(
      primary: primaryColor,
      // Main accent color
      secondary: Colors.grey[700]!,
      // Darker gray for secondary elements
      surface: Colors.white,
      // White for cards and containers
      onPrimary: Colors.black,
      // Text/icons on primary color
      onSecondary: Colors.white,
      // Text/icons on secondary color
      // Modify it if its no good to darkGray
      onSurface: Colors.black,
      // Text/icons on surfaces (dark gray for contrast)
      background: Colors.grey[50]!,
      // Matches scaffold background
      error: Colors.red, // Standard error color
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: primaryColor, // Yellow-orange app bar
      foregroundColor: Colors.black, // Black text/icons for contrast
      elevation: 0, // Flat design
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor, // Yellow-orange buttons
        foregroundColor: Colors.black, // Black text/icons on buttons
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    textTheme: TextTheme(
      bodyLarge: TextStyle(color: darkGray),
      // Dark gray for primary text
      bodyMedium: TextStyle(color: Colors.grey[800]!),
      // Slightly lighter for secondary text
      headlineMedium: TextStyle(
        color: primaryColor,
      ), // Headlines in primary color
    ),
  );

  static final darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: primaryColor,
    scaffoldBackgroundColor: darkGray,
    // Dark gray as main background
    colorScheme: ColorScheme.dark(
      primary: primaryColor,
      // Yellow-orange remains the accent
      secondary: Colors.grey[400]!,
      // Lighter gray for secondary elements
      surface: Colors.grey[850]!,
      // Slightly lighter than background for cards
      onPrimary: Colors.black,
      // Black on primary for contrast
      onSecondary: Colors.black,
      // Black on secondary for readability
      onSurface: Colors.white,
      // White text/icons on surfaces
      background: darkGray,
      // Matches scaffold background
      error: Colors.redAccent, // Brighter error color for dark mode
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: primaryColor, // Yellow-orange app bar
      foregroundColor: Colors.black, // Black text/icons for contrast
      elevation: 0, // Flat design
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor, // Yellow-orange buttons
        foregroundColor: Colors.black, // Black text/icons on buttons
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    textTheme: TextTheme(
      bodyLarge: TextStyle(color: Colors.white),
      // White for primary text
      bodyMedium: TextStyle(color: Colors.grey[300]!),
      // Lighter gray for secondary text
      headlineMedium: TextStyle(
        color: primaryColor,
      ), // Headlines in primary color
    ),
  );
}
