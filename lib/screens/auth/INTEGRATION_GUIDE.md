# Integration Guide - Authentication Screens

## Quick Start

### 1. Update Main App Entry Point

**Option A: Show auth if not logged in**
```dart
// lib/main.dart
import 'package:flutter/material.dart';
import 'screens/auth/welcome_screen.dart';
import 'app.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FamilyCal',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1A73E8),
        ),
      ),
      // Check auth state
      home: _isLoggedIn() ? const FamilyCalApp() : const WelcomeScreen(),
    );
  }

  bool _isLoggedIn() {
    // TODO: Check actual auth state from Firebase/SharedPreferences
    return false;
  }
}
```

**Option B: Use navigator routes**
```dart
// lib/main.dart
MaterialApp(
  initialRoute: _isLoggedIn() ? '/home' : '/welcome',
  routes: {
    '/welcome': (context) => const WelcomeScreen(),
    '/signup': (context) => const SignupScreen(),
    '/login': (context) => const LoginScreen(),
    '/home': (context) => const FamilyCalApp(),
  },
)
```

---

## 2. Connect to Firebase Authentication

### Setup Firebase
```dart
// lib/services/auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Send magic link to email
  Future<void> sendMagicLink(String email) async {
    var actionCodeSettings = ActionCodeSettings(
      url: 'https://familycal.page.link/verify',
      handleCodeInApp: true,
      androidPackageName: 'com.familycal.app',
      iOSBundleId: 'com.familycal.ios',
    );

    await _auth.sendSignInLinkToEmail(
      email: email,
      actionCodeSettings: actionCodeSettings,
    );
  }

  // Send SMS OTP
  Future<void> sendPhoneOTP(
    String phoneNumber,
    Function(String) onCodeSent,
    Function(String) onError,
  ) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (PhoneAuthCredential credential) async {
        await _auth.signInWithCredential(credential);
      },
      verificationFailed: (FirebaseAuthException e) {
        onError(e.message ?? 'Verification failed');
      },
      codeSent: (String verificationId, int? resendToken) {
        onCodeSent(verificationId);
      },
      codeAutoRetrievalTimeout: (String verificationId) {},
    );
  }

  // Verify OTP
  Future<UserCredential> verifyOTP(
    String verificationId,
    String otp,
  ) async {
    PhoneAuthCredential credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: otp,
    );
    return await _auth.signInWithCredential(credential);
  }

  // Check if user is logged in
  User? get currentUser => _auth.currentUser;

  // Sign out
  Future<void> signOut() => _auth.signOut();
}
```

---

## 3. Update Signup Screen to Use Firebase

```dart
// In signup_screen.dart
import '../../services/auth_service.dart';

class _SignupScreenState extends State<SignupScreen> {
  final _authService = AuthService();
  String? _verificationId;

  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      if (_method == SignupMethod.email) {
        // Send magic link
        await _authService.sendMagicLink(_emailController.text.trim());
        
        if (!mounted) return;
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => VerificationScreen(
              method: _method,
              contact: _emailController.text,
            ),
          ),
        );
      } else {
        // Send SMS OTP
        await _authService.sendPhoneOTP(
          _phoneController.text.trim(),
          (verificationId) {
            _verificationId = verificationId;
            if (mounted) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => VerificationScreen(
                    method: _method,
                    contact: _phoneController.text,
                    verificationId: verificationId,
                  ),
                ),
              );
            }
          },
          (error) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(error),
                  backgroundColor: Theme.of(context).colorScheme.error,
                ),
              );
            }
          },
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
```

---

## 4. Update Verification Screen

```dart
// In verification_screen.dart
class VerificationScreen extends StatefulWidget {
  const VerificationScreen({
    super.key,
    required this.method,
    required this.contact,
    this.verificationId, // For phone OTP
  });

  final SignupMethod method;
  final String contact;
  final String? verificationId;
  
  // ... rest of the class
}

class _VerificationScreenState extends State<VerificationScreen> {
  final _authService = AuthService();

  Future<void> _handleVerify() async {
    final code = _controllers.map((c) => c.text).join();
    if (code.length != 6) {
      _showError('Please enter the complete code');
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (widget.method == SignupMethod.phone) {
        // Verify OTP
        await _authService.verifyOTP(widget.verificationId!, code);
        
        if (!mounted) return;
        
        // Success! Navigate to main app
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const FamilyCalApp()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        _showError('Invalid code. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
```

---

## 5. Handle Deep Links (Magic Links)

### iOS Setup
```xml
<!-- ios/Runner/Info.plist -->
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>familycal</string>
    </array>
  </dict>
</array>
```

### Android Setup
```xml
<!-- android/app/src/main/AndroidManifest.xml -->
<intent-filter>
  <action android:name="android.intent.action.VIEW" />
  <category android:name="android.intent.category.DEFAULT" />
  <category android:name="android.intent.category.BROWSABLE" />
  <data
    android:scheme="https"
    android:host="familycal.page.link" />
</intent-filter>
```

### Handle Link in App
```dart
// lib/main.dart
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';

class MyApp extends StatefulWidget {
  // ... 
  
  @override
  void initState() {
    super.initState();
    _initDynamicLinks();
  }

  Future<void> _initDynamicLinks() async {
    // Handle link when app is already open
    FirebaseDynamicLinks.instance.onLink.listen((dynamicLinkData) {
      _handleDynamicLink(dynamicLinkData);
    });

    // Handle link when app is opened from terminated state
    final PendingDynamicLinkData? data =
        await FirebaseDynamicLinks.instance.getInitialLink();
    if (data != null) {
      _handleDynamicLink(data);
    }
  }

  void _handleDynamicLink(PendingDynamicLinkData data) async {
    final Uri deepLink = data.link;
    
    // Check if it's a sign-in link
    if (FirebaseAuth.instance.isSignInWithEmailLink(deepLink.toString())) {
      // Get email from storage (saved before sending link)
      final email = await _getEmailFromStorage();
      
      try {
        await FirebaseAuth.instance.signInWithEmailLink(
          email: email,
          emailLink: deepLink.toString(),
        );
        
        // Navigate to main app
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const FamilyCalApp()),
          (route) => false,
        );
      } catch (e) {
        // Handle error
      }
    }
  }
}
```

---

## 6. Persist Authentication State

```dart
// lib/services/auth_state_manager.dart
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthStateManager {
  static const _keyIsLoggedIn = 'is_logged_in';
  static const _keyEmail = 'user_email';

  // Save auth state
  static Future<void> saveAuthState(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsLoggedIn, true);
    await prefs.setString(_keyEmail, user.email ?? '');
  }

  // Check if logged in
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyIsLoggedIn) ?? false;
  }

  // Clear auth state on logout
  static Future<void> clearAuthState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyIsLoggedIn);
    await prefs.remove(_keyEmail);
  }

  // Get saved email (for magic link verification)
  static Future<String?> getSavedEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyEmail);
  }

  // Save email before sending magic link
  static Future<void> saveEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyEmail, email);
  }
}
```

---

## 7. Add Loading/Splash Screen

```dart
// lib/screens/splash_screen.dart
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthState();
  }

  Future<void> _checkAuthState() async {
    // Wait a bit for splash screen visibility
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    final isLoggedIn = await AuthStateManager.isLoggedIn();
    
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => isLoggedIn 
            ? const FamilyCalApp() 
            : const WelcomeScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(32),
              ),
              child: Icon(
                Icons.calendar_month_rounded,
                size: 64,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
```

---

## 8. Required Dependencies

Add to `pubspec.yaml`:
```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # Firebase
  firebase_core: ^2.24.0
  firebase_auth: ^4.15.0
  firebase_dynamic_links: ^5.4.0
  
  # State persistence
  shared_preferences: ^2.2.2
  
  # Existing dependencies
  provider: # (already in project)
  intl: # (already in project)
```

Run:
```bash
flutter pub get
```

---

## 9. Testing the Flow

### Manual Testing Checklist
1. [ ] Launch app → See welcome screen
2. [ ] Tap "Get Started" → See signup screen
3. [ ] Enter name, choose email → See email field
4. [ ] Switch to phone → See phone field
5. [ ] Submit invalid email → See error
6. [ ] Submit valid email → See verification screen
7. [ ] See "Check Email" message
8. [ ] Tap "Resend" → See timer countdown
9. [ ] Tap "Use different email" → Return to signup
10. [ ] Test phone flow similarly
11. [ ] Verify OTP auto-advance
12. [ ] Verify auto-submit on 6th digit
13. [ ] Test back button navigation
14. [ ] Test loading states
15. [ ] Close app and reopen → Should remember auth state

---

## 10. Common Issues & Solutions

### Issue: "Firebase not initialized"
```dart
// Make sure to initialize in main()
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}
```

### Issue: "SMS not received"
- Check Firebase console phone auth is enabled
- Verify phone number format (+1234567890)
- Check test numbers in Firebase console
- For production, configure proper SMS limits

### Issue: "Magic link doesn't work"
- Verify dynamic links domain in Firebase
- Check deep link configuration in iOS/Android
- Ensure email is saved before sending link
- Test with Firebase console test link first

### Issue: "User sees auth screens after login"
- Check `AuthStateManager.isLoggedIn()` logic
- Verify `SharedPreferences` is saving correctly
- Listen to `FirebaseAuth.instance.authStateChanges()`

---

## 11. Production Checklist

- [ ] Configure Firebase project for production
- [ ] Set up proper deep link domain
- [ ] Add rate limiting for SMS/email sends
- [ ] Implement proper error tracking (Sentry)
- [ ] Add analytics events (signup_started, signup_completed)
- [ ] Test on real devices (both iOS & Android)
- [ ] Test magic links in actual email clients
- [ ] Verify SMS arrives on real phone numbers
- [ ] Check all loading states work correctly
- [ ] Ensure back button works from all screens
- [ ] Test offline scenarios
- [ ] Add proper user onboarding after signup

---

This integration guide should get your authentication system fully functional and connected to Firebase!
