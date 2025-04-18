import 'package:flutter/material.dart';
import 'package:agrilab_app/screens/splash.dart'; // Import your splash screen

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AgriLab App',
      // Define the theme here
      theme: ThemeData(
        // Primary color of the app
        primarySwatch: MaterialColor(0xFF6B3022, <int, Color>{ // Changed to a custom color
          50: Color(0xFFF5E5DF),
          100: Color(0xFFE9BDBD),
          200: Color(0xFFDC9496),
          300: Color(0xFFCF6B6F),
          400: Color(0xFFC54E52),
          500: Color(0xFF6B3022), // Main color
          600: Color(0xFFA24235),
          700: Color(0xFF8B382B),
          800: Color(0xFF742E21),
          900: Color(0xFF5C2417),
        }),
        // Background color for most screens
        scaffoldBackgroundColor: Colors.white,
        // Color for buttons in the app
        buttonTheme: const ButtonThemeData(
          buttonColor: Colors.blue,
          textTheme: ButtonTextTheme.primary,
        ),
        //app bar theme
        appBarTheme: const AppBarTheme(
          color: Colors.grey, //background color for app bar
          titleTextStyle: TextStyle(color: Colors.white, fontSize: 20), //style for title in app bar
        ),
        // Text theme for the app
        textTheme: const TextTheme(
          bodyLarge: TextStyle(fontSize: 16.0, color: Colors.black), // Default text
          bodyMedium: TextStyle(fontSize: 14.0, color: Colors.black87),
          displayLarge: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold, color: Colors.black), // For large titles
        ),
        colorScheme: ColorScheme.fromSwatch().copyWith(
          secondary: const Color(0xFF5F9931), // Secondary color
        ),
      ),
      home: SplashScreen(),
    );
  }
}