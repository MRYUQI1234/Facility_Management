import 'package:flutter/material.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/auth/presentation/screens/register_screen.dart';
import 'features/resident/presentation/screens/repair_list_screen.dart';
// import 'features/resident/presentation/screens/create_repair_screen.dart'; // REMOVED
import 'features/resident/presentation/screens/model_view_screen.dart'; // Import
import 'features/admin/presentation/screens/admin_dashboard_screen.dart';

import 'package:fcm_app/core/data/auth_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final isLoggedIn = await AuthRepository.instance.isLoggedIn();
  runApp(FcmApp(initialRoute: isLoggedIn ? '/3d_model' : '/login'));
}

class FcmApp extends StatelessWidget {
  final String initialRoute;
  const FcmApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FCM System',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF121212), // Dark Background
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFFFD700), // Gold
          secondary: Color(0xFFD4AF37), // Metallic Gold
          surface: Color(0xFF1E1E1E), // Dark Grey Surface
          onPrimary: Colors.black, // Text on Gold
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF121212),
          foregroundColor: Color(0xFFFFD700), // Gold Text in AppBar
          centerTitle: true,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFFD700), // Gold Button
            foregroundColor: Colors.black, // Black Text
            textStyle: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(
            borderSide: BorderSide(color: Color(0xFFFFD700)), // Gold Border
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Color(0xFFFFD700), width: 2),
          ),
          labelStyle: TextStyle(color: Color(0xFFD4AF37)),
          prefixIconColor: Color(0xFFFFD700),
        ),
      ),
      initialRoute: initialRoute,
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/home': (context) => const RepairListScreen(), // Main Dashboard for Resident
        // '/create_repair': (context) => const CreateRepairScreen(), // REMOVED
        '/3d_model': (context) => const ModelViewScreen(), // New Route
        '/admin': (context) => const AdminDashboardScreen(),
      },
    );
  }
}
