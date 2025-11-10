import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'screens/auth/welcome_screen.dart';
import 'services/mock_auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // TODO: Initialize Firebase when ready
  // await Firebase.initializeApp();
  
  runApp(const FamilyCalRoot());
}

class FamilyCalRoot extends StatelessWidget {
  const FamilyCalRoot({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FamilyCal',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1A73E8),
          brightness: Brightness.light,
        ),
      ),
      home: const AuthGate(),
    );
  }
}

/// Gate that checks auth state and shows appropriate screen
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    // Check if user is logged in
    final isLoggedIn = MockAuthService.isLoggedIn;
    
    if (isLoggedIn) {
      return const FamilyCalApp();
    } else {
      return const WelcomeScreen();
    }
  }
}
