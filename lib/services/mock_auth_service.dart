import 'dart:async';

/// Mock authentication service for development
/// Replace with real Firebase implementation later
class MockAuthService {
  // Simulated user database
  static final Map<String, Map<String, String>> _mockUsers = {
    'test@example.com': {'name': 'Test User', 'id': 'user_1'},
    '+15551234567': {'name': 'Phone User', 'id': 'user_2'},
  };

  static String? _currentUserId;
  static String? _currentUserName;
  static String? _currentUserEmail;
  static String? _pendingEmail;
  static String? _pendingPhone;
  static String? _pendingName;

  /// Check if user is logged in
  static bool get isLoggedIn => _currentUserId != null;

  /// Get current user ID
  static String? get currentUserId => _currentUserId;

  /// Get current user name
  static String? get currentUserName => _currentUserName;

  /// Send email verification (mock)
  static Future<void> sendEmailVerification(String email, String name) async {
    await Future.delayed(const Duration(seconds: 1)); // Simulate network delay
    _pendingEmail = email;
    _pendingName = name;
    print('📧 Mock: Email verification sent to $email');
  }

  /// Send phone verification (mock)
  static Future<void> sendPhoneVerification(String phone, String name) async {
    await Future.delayed(const Duration(seconds: 1)); // Simulate network delay
    _pendingPhone = phone;
    _pendingName = name;
    print('📱 Mock: SMS verification sent to $phone');
  }

  /// Verify email code (mock - any 6-digit code works)
  static Future<bool> verifyEmailCode(String email, String code) async {
    await Future.delayed(const Duration(seconds: 1));
    
    // In mock mode, accept any 6-digit code
    if (code.length == 6) {
      _currentUserId = _mockUsers[email]?['id'] ?? 'user_${DateTime.now().millisecondsSinceEpoch}';
      _currentUserName = _pendingName ?? _mockUsers[email]?['name'] ?? 'User';
      
      // Add to mock database if new user
      if (!_mockUsers.containsKey(email)) {
        _mockUsers[email] = {'name': _currentUserName!, 'id': _currentUserId!};
      }
      
      print('✅ Mock: Email verified for $email');
      return true;
    }
    return false;
  }

  /// Verify phone code (mock - any 6-digit code works)
  static Future<bool> verifyPhoneCode(String phone, String code) async {
    await Future.delayed(const Duration(seconds: 1));
    
    // In mock mode, accept any 6-digit code
    if (code.length == 6) {
      _currentUserId = _mockUsers[phone]?['id'] ?? 'user_${DateTime.now().millisecondsSinceEpoch}';
      _currentUserName = _pendingName ?? _mockUsers[phone]?['name'] ?? 'User';
      
      // Add to mock database if new user
      if (!_mockUsers.containsKey(phone)) {
        _mockUsers[phone] = {'name': _currentUserName!, 'id': _currentUserId!};
      }
      
      print('✅ Mock: Phone verified for $phone');
      return true;
    }
    return false;
  }

  /// Verify magic link (mock - auto-success for email)
  static Future<bool> verifyMagicLink(String email) async {
    await Future.delayed(const Duration(seconds: 1));
    
    _currentUserId = _mockUsers[email]?['id'] ?? 'user_${DateTime.now().millisecondsSinceEpoch}';
    _currentUserName = _pendingName ?? _mockUsers[email]?['name'] ?? 'User';
    
    // Add to mock database if new user
    if (!_mockUsers.containsKey(email)) {
      _mockUsers[email] = {'name': _currentUserName!, 'id': _currentUserId!};
    }
    
    print('✅ Mock: Magic link verified for $email');
    return true;
  }

  /// Sign in with Google (mock)
  static Future<bool> signInWithGoogle() async {
    await Future.delayed(const Duration(seconds: 1));
    
    _currentUserId = 'google_${DateTime.now().millisecondsSinceEpoch}';
    _currentUserName = 'Google User';
    _currentUserEmail = 'google.user@gmail.com';
    
    print('✅ Mock: Google Sign-In successful');
    return true;
  }

  /// Sign in with Apple (mock)
  static Future<bool> signInWithApple() async {
    await Future.delayed(const Duration(seconds: 1));
    
    _currentUserId = 'apple_${DateTime.now().millisecondsSinceEpoch}';
    _currentUserName = 'Apple User';
    _currentUserEmail = 'apple.user@icloud.com';
    
    print('✅ Mock: Apple Sign-In successful');
    return true;
  }

  /// Sign in with Facebook (mock)
  static Future<bool> signInWithFacebook() async {
    await Future.delayed(const Duration(seconds: 1));
    
    _currentUserId = 'fb_${DateTime.now().millisecondsSinceEpoch}';
    _currentUserName = 'Facebook User';
    _currentUserEmail = 'fb.user@facebook.com';
    
    print('✅ Mock: Facebook Sign-In successful');
    return true;
  }

  /// Sign out
  static Future<void> signOut() async {
    _currentUserId = null;
    _currentUserName = null;
    _currentUserEmail = null;
    _pendingEmail = null;
    _pendingPhone = null;
    _pendingName = null;
    print('👋 Mock: User signed out');
  }

  /// Get pending contact (for verification screen)
  static String? get pendingEmail => _pendingEmail;
  static String? get pendingPhone => _pendingPhone;

  /// Check if contact exists (for login flow)
  static bool contactExists(String contact) {
    return _mockUsers.containsKey(contact);
  }
}

