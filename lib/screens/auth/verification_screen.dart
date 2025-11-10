import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'signup_screen.dart';
import '../../services/mock_auth_service.dart';
import '../../app.dart';
import '../onboarding/family_setup_flow.dart';

/// Verification screen for OTP/Magic Link
class VerificationScreen extends StatefulWidget {
  const VerificationScreen({
    super.key,
    required this.method,
    required this.contact,
    this.isSignup = true,
  });

  final SignupMethod method;
  final String contact;
  final bool isSignup;

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  final List<TextEditingController> _controllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(
    6,
    (_) => FocusNode(),
  );

  bool _isLoading = false;
  bool _isResending = false;
  int _resendTimer = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _startTimer() {
    _resendTimer = 60;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendTimer > 0) {
        setState(() => _resendTimer--);
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _handleVerify() async {
    final code = _controllers.map((c) => c.text).join();
    if (code.length != 6) {
      _showError('Please enter the complete code');
      return;
    }

    setState(() => _isLoading = true);

    try {
      bool success = false;

      if (widget.method == SignupMethod.email) {
        success = await MockAuthService.verifyEmailCode(widget.contact, code);
      } else {
        success = await MockAuthService.verifyPhoneCode(widget.contact, code);
      }

      if (!mounted) return;

      if (success) {
        // Success! Navigate based on signup or login
        if (widget.isSignup) {
          // New registration - go through family setup
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const FamilySetupFlow()),
            (route) => false,
          );
        } else {
          // Existing user login - go directly to app
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const FamilyCalApp()),
            (route) => false,
          );
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Welcome back!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        _showError('Invalid code. Please try again.');
      }
    } catch (e) {
      if (mounted) {
        _showError('Verification failed: ${e.toString()}');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleResend() async {
    setState(() => _isResending = true);

    try {
      if (widget.method == SignupMethod.email) {
        await MockAuthService.sendEmailVerification(widget.contact, 'User');
      } else {
        await MockAuthService.sendPhoneVerification(widget.contact, 'User');
      }

      if (!mounted) return;

      _startTimer();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.method == SignupMethod.email
                ? 'Magic link sent to ${widget.contact}'
                : 'Code sent to ${widget.contact}',
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        _showError('Failed to resend. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
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
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  widget.method == SignupMethod.email
                      ? Icons.email_outlined
                      : Icons.message_outlined,
                  size: 40,
                  color: colorScheme.primary,
                ),
              ),

              const SizedBox(height: 32),

              // Header
              Text(
                widget.method == SignupMethod.email
                    ? 'Check Your Email'
                    : 'Enter Verification Code',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 12),

              // Description
              Text(
                widget.method == SignupMethod.email
                    ? 'We sent a magic link to\n${widget.contact}'
                    : 'We sent a 6-digit code to\n${widget.contact}',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 48),

              // OTP Input (only for phone)
              if (widget.method == SignupMethod.phone) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(6, (index) {
                    return SizedBox(
                      width: 48,
                      height: 56,
                      child: TextField(
                        controller: _controllers[index],
                        focusNode: _focusNodes[index],
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        maxLength: 1,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        decoration: InputDecoration(
                          counterText: '',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: EdgeInsets.zero,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        onChanged: (value) {
                          if (value.length == 1) {
                            if (index < 5) {
                              _focusNodes[index + 1].requestFocus();
                            } else {
                              _focusNodes[index].unfocus();
                              _handleVerify();
                            }
                          } else if (value.isEmpty && index > 0) {
                            _focusNodes[index - 1].requestFocus();
                          }
                        },
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 32),
              ],

              // Magic Link Info (for email)
              if (widget.method == SignupMethod.email) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: colorScheme.primary.withOpacity(0.2),
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.touch_app_outlined,
                        size: 32,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Click the link in your email to sign in',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'The link will expire in 15 minutes',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
              ],

              // Verify Button (for phone)
              if (widget.method == SignupMethod.phone)
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: FilledButton(
                    onPressed: _isLoading ? null : _handleVerify,
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Verify',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),

              const SizedBox(height: 24),

              // Resend
              if (_resendTimer > 0)
                Text(
                  'Resend code in $_resendTimer seconds',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                )
              else
                TextButton(
                  onPressed: _isResending ? null : _handleResend,
                  child: _isResending
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          widget.method == SignupMethod.email
                              ? 'Resend magic link'
                              : 'Resend code',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),

              const SizedBox(height: 16),

              // Wrong contact
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  widget.method == SignupMethod.email
                      ? 'Use different email'
                      : 'Use different number',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

