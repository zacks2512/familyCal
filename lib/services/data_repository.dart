import 'package:flutter/foundation.dart';
import '../config/app_config.dart';
import '../data/mock_data.dart';
import '../models/entities.dart';
import 'firebase_repository.dart';

/// Simple data source abstraction - currently just used as a marker
/// Real database operations would go through FirebaseRepository or MockDataRepository
abstract class DataSource {
  bool get isMockMode;
}

/// Factory class to create the appropriate data source
class RepositoryFactory {
  static DataSource createDataSource() {
    if (AppConfig.isMockMode()) {
      return MockDataSource();
    } else {
      return FirebaseDataSource();
    }
  }
}

/// Firebase implementation marker
class FirebaseDataSource implements DataSource {
  final _firebaseRepo = FirebaseRepository();
  
  @override
  bool get isMockMode => false;
  
  // Expose Firebase repository methods as needed
  String? get currentUserId => _firebaseRepo.currentUserId;
  FirebaseRepository get repo => _firebaseRepo;
}

/// Mock implementation for testing UI
class MockDataSource implements DataSource {
  @override
  bool get isMockMode => true;
}


