class AppConfig {
  // Toggle mock vs real data.
  // Default: false (use real Firestore-backed data).
  // You can override at build time with:
  // flutter run --dart-define=USE_MOCK_DATA=true
  static const bool useMockData =
      bool.fromEnvironment('USE_MOCK_DATA', defaultValue: false);
}

