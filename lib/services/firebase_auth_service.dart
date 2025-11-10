import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Service for Firebase Authentication
class FirebaseAuthService {
  static final FirebaseAuthService _instance = FirebaseAuthService._internal();
  
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  factory FirebaseAuthService() {
    return _instance;
  }
  
  FirebaseAuthService._internal();
  
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  
  /// Get current user
  User? get currentUser => _auth.currentUser;
  
  
  /// Sign in with email and password
  Future<UserCredential> signInWithEmailPassword(String email, String password) async {
    try {
      debugPrint('🔑 Signing in with email: $email');
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      debugPrint('✅ Email sign-in successful: ${credential.user?.uid}');
      return credential;
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ Firebase Auth Error: ${e.code} - ${e.message}');
      rethrow;
    }
  }
  
  /// Sign up with email and password
  Future<UserCredential> signUpWithEmailPassword(String email, String password) async {
    try {
      debugPrint('🔑 Creating account with email: $email');
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      debugPrint('✅ Account created: ${credential.user?.uid}');
      return credential;
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ Firebase Auth Error: ${e.code} - ${e.message}');
      rethrow;
    }
  }
  
  /// Sign in with Google
  Future<UserCredential> signInWithGoogle() async {
    try {
      debugPrint('🔑 Starting Google Sign-In...');
      
      // First, ensure any previous session is cleared
      try {
        await _googleSignIn.signOut();
        debugPrint('🧹 Cleared previous Google session');
      } catch (e) {
        debugPrint('⚠️  No previous session to clear');
      }
      // Also disconnect to force showing the account picker reliably
      try {
        await _googleSignIn.disconnect();
        debugPrint('🧹 Disconnected any cached Google account');
      } catch (e) {
        debugPrint('⚠️  No cached Google account to disconnect');
      }
      
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        debugPrint('❌ Google Sign-In cancelled by user');
        throw FirebaseAuthException(
          code: 'ERROR_ABORTED_BY_USER',
          message: 'Sign in aborted by user',
        );
      }
      
      debugPrint('✅ Google user selected: ${googleUser.email}');
      final selectedEmail = googleUser.email;
      
      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      if (googleAuth.accessToken == null || googleAuth.idToken == null) {
        debugPrint('❌ Failed to get Google authentication tokens');
        throw FirebaseAuthException(
          code: 'missing-google-tokens',
          message: 'Failed to retrieve authentication tokens from Google',
        );
      }
      
      debugPrint('✅ Google authentication tokens received');
      
      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      
      debugPrint('🔑 Signing in to Firebase with Google credential...');
      
      // Sign in to Firebase with the Google credential
      UserCredential userCredential;
      try {
        userCredential = await _auth.signInWithCredential(credential);
      } on FirebaseAuthException catch (e) {
        // Special handling when the email already exists with a different provider
        if (e.code == 'account-exists-with-different-credential' ||
            e.code == 'email-already-in-use') {
          try {
            final methods = await _auth.fetchSignInMethodsForEmail(selectedEmail);
            debugPrint('⚠️  Account exists with different provider(s): $methods for $selectedEmail');
            throw FirebaseAuthException(
              code: 'account-exists-with-different-credential',
              message:
                  'This email is already registered with a different sign-in method: ${methods.join(', ')}. '
                  'Please sign in using ${methods.isNotEmpty ? methods.first : 'the original method'} and link Google in Settings.',
            );
          } catch (inner) {
            rethrow;
          }
        }
        rethrow;
      }
      
      debugPrint('✅ Google Sign-In successful: ${userCredential.user?.uid}');
      debugPrint('   Email: ${userCredential.user?.email}');
      debugPrint('   Display Name: ${userCredential.user?.displayName}');
      
      return userCredential;
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ Firebase Auth Error: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('❌ Google Sign-In Error: $e');
      debugPrint('   Error type: ${e.runtimeType}');
      rethrow;
    }
  }
  
  /// Sign out (includes Google Sign-Out)
  Future<void> signOut() async {
    try {
      debugPrint('👋 Signing out...');
      
      // Disconnect and sign out from Google if signed in
      if (await _googleSignIn.isSignedIn()) {
        await _googleSignIn.disconnect();  // Disconnect to clear cached account
        await _googleSignIn.signOut();
        debugPrint('✅ Disconnected and signed out from Google');
      }
      
      await _auth.signOut();
      debugPrint('✅ Signed out from Firebase');
    } catch (e) {
      debugPrint('❌ Sign out error: $e');
      // Continue even if Google sign out fails
      try {
        await _auth.signOut();
        debugPrint('✅ Signed out from Firebase (after Google error)');
      } catch (authError) {
        debugPrint('❌ Firebase sign out also failed: $authError');
        rethrow;
      }
    }
  }
  
  /// Get the Google Sign In instance (for testing or advanced use)
  GoogleSignIn get googleSignIn => _googleSignIn;
  
  /// Check if user is authenticated
  bool get isAuthenticated => _auth.currentUser != null;
  
  /// Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;
  
  /// Get current user email
  String? get currentUserEmail => _auth.currentUser?.email;
  
  /// Get current user display name
  String? get currentUserDisplayName => _auth.currentUser?.displayName;
  
  /// Listen to authentication state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();
}

