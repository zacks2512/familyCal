import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'verification_screen.dart';
import '../../services/mock_auth_service.dart';
import '../../widgets/language_selector.dart';

enum SignupMethod { email, phone }

/// Clean signup screen with email or phone options
class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  
  SignupMethod _method = SignupMethod.email;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      if (_method == SignupMethod.email) {
        // Send email verification
        await MockAuthService.sendEmailVerification(
          _emailController.text.trim(),
          _nameController.text.trim(),
        );
      } else {
        // Send phone verification
        await MockAuthService.sendPhoneVerification(
          _phoneController.text.trim(),
          _nameController.text.trim(),
        );
      }

      if (!mounted) return;

      // Navigate to verification
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => VerificationScreen(
            method: _method,
            contact: _method == SignupMethod.email
                ? _emailController.text.trim()
                : _phoneController.text.trim(),
            isSignup: true,
          ),
        ),
      );
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

  String _getLocalizedText(String key, BuildContext context) {
    final l10n = AppLocalizations.of(context);
    
    // Default English fallbacks
    final defaults = {
      'signupTitle': 'Create Account',
      'signupSubtitle': 'Enter your details to get started',
      'fullName': 'Full Name',
      'enterYourName': 'Enter your name',
      'pleaseEnterYourName': 'Please enter your name',
      'contactMethod': 'Contact Method',
      'email': 'Email',
      'phone': 'Phone',
      'emailAddress': 'Email Address',
      'enterYourEmail': 'Enter your email',
      'pleaseEnterEmail': 'Please enter your email',
      'pleaseEnterValidEmail': 'Please enter a valid email',
      'phoneNumber': 'Phone Number',
      'enterPhoneNumber': 'Enter phone number',
      'pleaseEnterPhoneNumber': 'Please enter your phone number',
      'pleaseEnterValidPhoneNumber': 'Please enter a valid phone number',
      'continueButton': 'Continue',
      'language': 'Language',
    };
    
    if (l10n == null) {
      return defaults[key] ?? key;
    }
    
    switch (key) {
      case 'signupTitle': return l10n.signupTitle;
      case 'signupSubtitle': return l10n.signupSubtitle;
      case 'fullName': return l10n.fullName;
      case 'enterYourName': return l10n.enterYourName;
      case 'pleaseEnterYourName': return l10n.pleaseEnterYourName;
      case 'contactMethod': return l10n.contactMethod;
      case 'email': return l10n.email;
      case 'phone': return l10n.phone;
      case 'emailAddress': return l10n.emailAddress;
      case 'enterYourEmail': return l10n.enterYourEmail;
      case 'pleaseEnterEmail': return l10n.pleaseEnterEmail;
      case 'pleaseEnterValidEmail': return l10n.pleaseEnterValidEmail;
      case 'phoneNumber': return l10n.phoneNumber;
      case 'enterPhoneNumber': return l10n.enterPhoneNumber;
      case 'pleaseEnterPhoneNumber': return l10n.pleaseEnterPhoneNumber;
      case 'pleaseEnterValidPhoneNumber': return l10n.pleaseEnterValidPhoneNumber;
      case 'continueButton': return l10n.continueButton;
      case 'language': return l10n.language;
      default: return defaults[key] ?? key;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context);

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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Text(
                  _getLocalizedText('signupTitle', context),
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _getLocalizedText('signupSubtitle', context),
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                
                const SizedBox(height: 40),
                
                // Name Field
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: _getLocalizedText('fullName', context),
                    hintText: _getLocalizedText('enterYourName', context),
                    prefixIcon: const Icon(Icons.person_outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return _getLocalizedText('pleaseEnterYourName', context);
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 24),
                
                // Method Selector
                Text(
                  _getLocalizedText('contactMethod', context),
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                SegmentedButton<SignupMethod>(
                  segments: [
                    ButtonSegment(
                      value: SignupMethod.email,
                      label: Text(_getLocalizedText('email', context)),
                      icon: const Icon(Icons.email_outlined, size: 20),
                    ),
                    ButtonSegment(
                      value: SignupMethod.phone,
                      label: Text(_getLocalizedText('phone', context)),
                      icon: const Icon(Icons.phone_outlined, size: 20),
                    ),
                  ],
                  selected: {_method},
                  onSelectionChanged: (Set<SignupMethod> selection) {
                    setState(() => _method = selection.first);
                  },
                  style: const ButtonStyle(
                    visualDensity: VisualDensity.comfortable,
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Email or Phone Field
                if (_method == SignupMethod.email)
                  TextFormField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: _getLocalizedText('emailAddress', context),
                      hintText: _getLocalizedText('enterYourEmail', context),
                      prefixIcon: const Icon(Icons.email_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.done,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return _getLocalizedText('pleaseEnterEmail', context);
                      }
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                          .hasMatch(value)) {
                        return _getLocalizedText('pleaseEnterValidEmail', context);
                      }
                      return null;
                    },
                  )
                else
                  TextFormField(
                    controller: _phoneController,
                    decoration: InputDecoration(
                      labelText: _getLocalizedText('phoneNumber', context),
                      hintText: _getLocalizedText('enterPhoneNumber', context),
                      prefixIcon: const Icon(Icons.phone_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.done,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9+\-\(\) ]')),
                    ],
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return _getLocalizedText('pleaseEnterPhoneNumber', context);
                      }
                      if (value.replaceAll(RegExp(r'[^0-9]'), '').length < 10) {
                        return _getLocalizedText('pleaseEnterValidPhoneNumber', context);
                      }
                      return null;
                    },
                  ),
                
                const SizedBox(height: 24),
                
                // Info Box
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: colorScheme.primary.withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 20,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _method == SignupMethod.email
                              ? 'We\'ll send a magic link to verify your email'
                              : 'We\'ll send a verification code via SMS',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Continue Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                    child: FilledButton(
                    onPressed: _isLoading ? null : _handleSignup,
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            _getLocalizedText('continueButton', context),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
