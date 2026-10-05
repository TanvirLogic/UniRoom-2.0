import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../providers/auth_provider.dart';
import 'main_navigation_shell.dart';

/// Email Verification Screen
/// Validates user registration via a 6-digit cryptographic PIN sent to their email.
class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  final _pinController = TextEditingController();
  final FocusNode _pinFocusNode = FocusNode();

  // 60-second cooldown timer for resend rate limiting
  int _secondsRemaining = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
    final auth = context.read<AuthProvider>();
    if (auth.fallbackPin != null && auth.fallbackPin!.isNotEmpty) {
      _pinController.text = auth.fallbackPin!;
    }
    _pinFocusNode.addListener(() {
      if (mounted) setState(() {});
    });
  }

  void _startTimer() {
    _secondsRemaining = 60;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
      } else {
        _timer?.cancel();
      }
    });
  }

  @override
  void dispose() {
    _pinController.dispose();
    _pinFocusNode.dispose();
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _handleVerify() async {
    final pin = _pinController.text.trim();
    if (pin.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.error,
          content: Text('Please enter the complete 6-digit PIN'),
        ),
      );
      _pinFocusNode.requestFocus();
      return;
    }

    final auth = context.read<AuthProvider>();
    final success = await auth.verifyEmail(pin);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.success,
          content: Text('Email verified successfully! Welcome!'),
        ),
      );
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const MainNavigationShell()),
        (route) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.error,
          content: Text(auth.errorMessage ?? 'Verification failed. Please try again.'),
        ),
      );
    }
  }

  Future<void> _handleResend() async {
    if (_secondsRemaining > 0) return;

    final auth = context.read<AuthProvider>();
    final success = await auth.resendVerificationPin();

    if (!mounted) return;

    if (success) {
      _startTimer();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.primarySky,
          content: Text('A new 6-digit PIN has been sent to your email.'),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.error,
          content: Text(auth.errorMessage ?? 'Failed to resend PIN. Please try again.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final targetEmail = auth.pendingEmail ?? 'your email address';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Verify Email'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: MediaQuery.sizeOf(context).width < 380 ? 16 : 24,
              vertical: 20,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primarySky, width: 2),
                    ),
                    child: const Icon(
                      Icons.mark_email_read_outlined,
                      color: AppColors.primarySky,
                      size: 36,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Check Your Inbox',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'We have sent a 6-digit verification code to:\n$targetEmail',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
                if (auth.fallbackPin != null && auth.fallbackPin!.isNotEmpty) ...[
                  Container(
                    margin: const EdgeInsets.only(bottom: 24),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, color: Colors.amber, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Auto-Retrieved PIN (Cloud Port Blocked)',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.amber),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Your verification code is: ${auth.fallbackPin}',
                                style: const TextStyle(fontSize: 12, color: AppColors.textPrimary, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  const SizedBox(height: 32),
                ],

                const Text(
                  'Enter 6-Digit PIN',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 14),

                // Cool 6-Box PIN Field
                _buildCoolPinBoxes(),
                const SizedBox(height: 12),
                const Text(
                  '⏱️ This PIN expires in 10 minutes',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 24),

                // Verify Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: auth.isLoading ? null : _handleVerify,
                    child: auth.isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Verify & Activate'),
                  ),
                ),

                const SizedBox(height: 24),

                // Resend PIN Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Didn't receive code? ",
                      style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    ),
                    if (_secondsRemaining > 0)
                      Text(
                        'Resend in ${_secondsRemaining}s',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textMuted,
                        ),
                      )
                    else
                      GestureDetector(
                        onTap: auth.isLoading ? null : _handleResend,
                        child: const Text(
                          'Resend Code',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primarySky,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Modern 6-box PIN field widget
  Widget _buildCoolPinBoxes() {
    final text = _pinController.text;
    final hasFocus = _pinFocusNode.hasFocus;

    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        final boxWidth = ((totalWidth - 30) / 6).clamp(36.0, 48.0);
        final boxHeight = boxWidth * 1.16;

        return Stack(
          alignment: Alignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(6, (index) {
                final isFilled = index < text.length;
                final isCurrent = hasFocus && (index == text.length || (index == 5 && text.length == 6));
                final digit = isFilled ? text[index] : '';

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: boxWidth,
                  height: boxHeight,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isFilled
                        ? AppColors.primaryLight.withValues(alpha: 0.35)
                        : AppColors.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isCurrent
                          ? AppColors.primarySky
                          : (isFilled ? AppColors.primarySky.withValues(alpha: 0.6) : AppColors.border),
                      width: isCurrent ? 2.0 : 1.2,
                    ),
                    boxShadow: isCurrent
                        ? [
                            BoxShadow(
                              color: AppColors.primarySky.withValues(alpha: 0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            )
                          ]
                        : null,
                  ),
                  child: Text(
                    digit,
                    style: TextStyle(
                      fontSize: boxWidth < 42 ? 18 : 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                );
              }),
            ),

            // Invisible touch-receiving text input
            Positioned.fill(
              child: Opacity(
                opacity: 0.01,
                child: TextField(
                  controller: _pinController,
                  focusNode: _pinFocusNode,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  autofocus: false,
                  enableInteractiveSelection: false,
                  decoration: const InputDecoration(
                    counterText: '',
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    fillColor: Colors.transparent,
                  ),
                  onChanged: (_) {
                    setState(() {});
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
