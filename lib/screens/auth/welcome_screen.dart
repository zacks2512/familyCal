import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'login_screen.dart';
import 'signup_screen.dart';
import '../../services/firebase_auth_service.dart';
import '../onboarding/family_setup_flow.dart';
import '../../app.dart';
import '../../widgets/language_selector.dart';

/// Welcome screen - first screen users see
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  bool _isLoading = false;
  final _authService = FirebaseAuthService();

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);

    try {
      final userCredential = await _authService.signInWithGoogle();
      
      if (!mounted) return;
      
      // Navigate to family setup flow after social sign-in (new registration)
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const FamilySetupFlow()),
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      // If Firebase already considers the user signed in, proceed as success
      if (FirebaseAuth.instance.currentUser != null && mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const FamilySetupFlow()),
          (route) => false,
        );
      } else if (mounted) {
        String message = 'Google Sign-In failed';
        if (e.code == 'ERROR_ABORTED_BY_USER') {
          message = 'Sign-in cancelled';
        } else {
          message = 'Google Sign-In failed: ${e.message}';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } catch (e) {
      // If Firebase already considers the user signed in, proceed as success
      if (FirebaseAuth.instance.currentUser != null && mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const FamilySetupFlow()),
          (route) => false,
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Google Sign-In failed: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context);
    
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const Spacer(flex: 2),
              
              // Logo/Icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(32),
                ),
                child: Icon(
                  Icons.calendar_month_rounded,
                  size: 64,
                  color: colorScheme.primary,
                ),
              ),
              
              const SizedBox(height: 32),
              
              // App Name
              Text(
                (AppLocalizations.of(context)?.appName) ?? 'FamilyCal',
                style: theme.textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Tagline
              Text(
                (AppLocalizations.of(context)?.appTagline) ??
                    'Coordinate family schedules.\nNever miss a drop-off or pickup.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
              
              const Spacer(flex: 2),
              
              // Register Button (Primary - Filled)
              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton(
                  onPressed: _isLoading
                      ? null
                      : () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => RegisterOptionsScreen(
                                onGoogleSignIn: _handleGoogleSignIn,
                              ),
                            ),
                          );
                        },
                  child: Text(
                    (AppLocalizations.of(context)?.register) ?? 'Register',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Login Button (Secondary - Outlined)
              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton(
                  onPressed: _isLoading
                      ? null
                      : () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const LoginOptionsScreen(),
                            ),
                          );
                        },
                  child: Text(
                    (AppLocalizations.of(context)?.login) ?? 'Log In',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              
              const Spacer(flex: 1),
              
              // Terms & Privacy
              Text(
                (AppLocalizations.of(context)?.termsAndPrivacy) ??
                    'By continuing, you agree to our Terms of Service\nand Privacy Policy',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
              
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

/// Register options screen - shows social and email/phone options
class RegisterOptionsScreen extends StatelessWidget {
  const RegisterOptionsScreen({
    super.key,
    required this.onGoogleSignIn,
  });

  final Future<void> Function() onGoogleSignIn;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: const [LanguageActionButton()],
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                (AppLocalizations.of(context)?.registerTitle) ?? 'Register',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                (AppLocalizations.of(context)?.registerSubtitle) ?? 'Choose how you\'d like to register',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              
              const SizedBox(height: 40),
              
              // Social Options
              _SocialButton(
                icon: Icons.g_mobiledata,
                label: (AppLocalizations.of(context)?.continueWithGoogle) ?? 'Continue with Google',
                onPressed: onGoogleSignIn,
              ),
              
              const SizedBox(height: 12),
              
              // Facebook Sign-In (not yet implemented)
              _SocialButton(
                icon: Icons.facebook,
                label: (AppLocalizations.of(context)?.continueWithFacebook) ?? 'Continue with Facebook',
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text((AppLocalizations.of(context)?.facebookComingSoon) ?? 'Facebook Sign-In coming soon!'),
                    ),
                  );
                },
              ),
              
              const SizedBox(height: 24),
              
              // Divider
              Row(
                children: [
                  Expanded(child: Divider(color: colorScheme.outlineVariant)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      (AppLocalizations.of(context)?.orDivider) ?? 'or',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  Expanded(child: Divider(color: colorScheme.outlineVariant)),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Email/Phone Option
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const SignupScreen(),
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                ),
                icon: const Icon(Icons.email_outlined),
                label: Text(
                  (AppLocalizations.of(context)?.registerWithEmailPhone) ?? 'Register with Email or Phone',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
              
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}

/// Login options screen - shows social and email/phone options
class LoginOptionsScreen extends StatefulWidget {
  const LoginOptionsScreen({super.key});

  @override
  State<LoginOptionsScreen> createState() => _LoginOptionsScreenState();
}

class _LoginOptionsScreenState extends State<LoginOptionsScreen> {
  bool _isLoading = false;
  final _authService = FirebaseAuthService();

  Future<void> _handleGoogleLogin() async {
    setState(() => _isLoading = true);

    try {
      final userCredential = await _authService.signInWithGoogle();
      
      if (!mounted) return;
      
      // Login goes directly to calendar app (user already has family setup)
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const FamilyCalApp()),
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      // If Firebase already considers the user signed in, proceed as success
      if (FirebaseAuth.instance.currentUser != null && mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const FamilyCalApp()),
          (route) => false,
        );
      } else if (mounted) {
        String message = 'Google Login failed';
        if (e.code == 'ERROR_ABORTED_BY_USER') {
          message = 'Login cancelled';
        } else {
          message = 'Google Login failed: ${e.message}';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } catch (e) {
      // If Firebase already considers the user signed in, proceed as success
      if (FirebaseAuth.instance.currentUser != null && mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const FamilyCalApp()),
          (route) => false,
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Google Login failed: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: const [LanguageActionButton()],
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                (AppLocalizations.of(context)?.loginTitle) ?? 'Log In',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                (AppLocalizations.of(context)?.loginSubtitle) ?? 'Choose how you\'d like to log in',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              
              const SizedBox(height: 40),
              
              // Social Options
              _SocialButton(
                icon: Icons.g_mobiledata,
                label: (AppLocalizations.of(context)?.continueWithGoogle) ?? 'Continue with Google',
                onPressed: _isLoading ? null : _handleGoogleLogin,
              ),
              
              const SizedBox(height: 12),
              
              // Facebook Sign-In (not yet implemented)
              _SocialButton(
                icon: Icons.facebook,
                label: (AppLocalizations.of(context)?.continueWithFacebook) ?? 'Continue with Facebook',
                onPressed: _isLoading
                    ? null
                    : () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text((AppLocalizations.of(context)?.facebookComingSoon) ?? 'Facebook Sign-In coming soon!'),
                          ),
                        );
                      },
              ),
              
              const SizedBox(height: 24),
              
              // Divider
              Row(
                children: [
                  Expanded(child: Divider(color: colorScheme.outlineVariant)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      (AppLocalizations.of(context)?.orDivider) ?? 'or',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  Expanded(child: Divider(color: colorScheme.outlineVariant)),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Email/Phone Option
              OutlinedButton.icon(
                onPressed: _isLoading
                    ? null
                    : () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const LoginScreen(),
                          ),
                        );
                      },
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                ),
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.email_outlined),
                label: Text(
                  (AppLocalizations.of(context)?.loginWithEmailPhone) ?? 'Log In with Email or Phone',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
              
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}

/// Social button widget
class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: colorScheme.outline),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        icon: Icon(icon, size: 24),
        label: Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
