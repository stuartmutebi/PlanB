import 'firebase_options.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:lostandfound/services/auth_service.dart';
import 'package:lostandfound/screens/splash_screen.dart';
import 'package:lostandfound/screens/auth/login_screen.dart';
import 'package:lostandfound/screens/home_screen.dart';
import 'package:lostandfound/screens/landing_page.dart';
import 'package:lostandfound/screens/auth/signup_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Only initialize Firebase if it hasn't been initialized yet
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
      ],
      child: MaterialApp(
        title: 'Lost and Found',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme(
            brightness: Brightness.light,
            primary: Color(0xFF1A4B8C), // Deep Blue
            onPrimary: Colors.white,
            secondary: Color(0xFF2EC4B6), // Teal
            onSecondary: Colors.white,
            background: Color(0xFFF5F5F5), // Light Gray
            onBackground: Colors.black,
            surface: Colors.white,
            onSurface: Colors.black,
            error: Color(0xFFFF6B6B), // Red/Soft Coral
            onError: Colors.white,
          ),
          scaffoldBackgroundColor: Color(0xFFF5F5F5),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF2EC4B6), // Teal
              foregroundColor: Colors.white,
              textStyle: const TextStyle(fontWeight: FontWeight.bold),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          outlinedButtonTheme: OutlinedButtonThemeData(
            style: OutlinedButton.styleFrom(
              foregroundColor: Color(0xFF1A4B8C), // Deep Blue
              side: const BorderSide(color: Color(0xFF1A4B8C)),
              textStyle: const TextStyle(fontWeight: FontWeight.bold),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          inputDecorationTheme: const InputDecorationTheme(
            filled: true,
            fillColor: Color(0xFFF5F5F5), // Light Gray
            border: OutlineInputBorder(),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Color(0xFF2EC4B6)), // Teal
            ),
            labelStyle: TextStyle(color: Color(0xFF1A4B8C)), // Deep Blue
          ),
          snackBarTheme: const SnackBarThemeData(
            backgroundColor: Color(0xFF1A4B8C), // Deep Blue
            contentTextStyle: TextStyle(color: Colors.white),
          ),
        ),
        home: const LandingPage(),
        routes: {
          '/login': (context) => const LoginScreen(),
          '/signup': (context) => const SignupScreen(),
          '/home': (context) => const HomeScreen(),
        },
      ),
    );
  }
}