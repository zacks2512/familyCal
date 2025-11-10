import 'package:flutter/foundation.dart';

/// Global app configuration for toggling between mock and Firebase modes
/// 
/// Set [useMockData] to true during development to use mock data for UI testing
/// Default is false = connected to Firebase (production mode)
class AppConfig {
  /// 🔥 Set to false to use FIREBASE (default, production mode)
  /// 🧪 Set to true to use MOCK DATA (for UI testing without Firebase)
  /// 
  /// Change this value in code to switch modes during development
  static bool useMockData = false; // false = Firebase (default), true = Mock data for testing
  
  /// Check if currently using mock data
  static bool isMockMode() => useMockData;
}

