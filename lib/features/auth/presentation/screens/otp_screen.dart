import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:logger/logger.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/models/otp_request.dart';

final logger = Logger(printer: PrettyPrinter());

class OtpScreen extends StatefulWidget {
  final String email;
  final bool otpAlreadySent;
  const OtpScreen({super.key, required this.email, this.otpAlreadySent = false});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final AuthRepository _authRepository = AuthRepository();
  final _otpController = TextEditingController();
  String _otpCode = "";
  bool _isLoading = false;
  int _secondsRemaining = 60;
  bool _canResend = true;
  bool _otpBlocked = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.otpAlreadySent) {
      _startCountdown();
    } else {
      _sendOtp();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpController.dispose();
    super.dispose();
  }

  void _startCountdown() {
    setState(() => _secondsRemaining = 120); // 2 minutes
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining == 0) {
        timer.cancel();
        setState(() {}); // just to rebuild the UI
      } else {
        setState(() => _secondsRemaining--);
      }
    });
  }

  String _formatTime(int seconds) {
    final duration = Duration(seconds: seconds);
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final secs = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return "$minutes:$secs";
  }


  Future<void> _sendOtp() async {
    setState(() => _isLoading = true);
    final result = await _authRepository.sendOtp(widget.email);
    logger.i("OTP send result: $result");

    if (!mounted) return;
    if (result == 'MAX_ATTEMPTS_REACHED') {
      setState(() {
        _otpBlocked = true;
        _canResend = false;
        _secondsRemaining = 0;
      });
      _showMessage("Too many requests. Please wait 10 minutes.");
    } else if (result == 'SUCCESS') {
      setState(() {
        _otpBlocked = false;
        _canResend = true;
        _otpCode = "";
        _otpController.clear();
      });
      _startCountdown();
      _showMessage("OTP sent successfully");
    } else {
      setState(() {
        _otpBlocked = false;
        _canResend = true;
      });
      _showMessage("Failed to send OTP. Please try again.");
    }

    setState(() => _isLoading = false);
  }

  Future<void> _verifyOtp() async {
    if (_otpCode.length != 6) {
      _showMessage("Please fill all 6 digits");
      return;
    }

    setState(() => _isLoading = true);
    final result = await _authRepository.verifyOtp(OtpRequest(email: widget.email, otp: _otpCode));
    logger.i(result);
    if (!mounted) return;
    setState(() => _isLoading = false);

    switch (result) {
      case 'SUCCESS':
        _showMessage("OTP Verified Successfully");
        GoRouter.of(context).go('/create-or-join-home');
        break;
      case 'OTP_EXPIRED':
        setState(() {
          _otpCode = "";
          _otpController.clear();
        });
        _showMessage("OTP expired. Please resend.");
        break;
      case 'INVALID_OTP':
        _showMessage("Invalid OTP. Try again.");
        break;
      default:
        _showMessage("An unexpected error occurred. Try again.");
    }
  }

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: screenWidth > 500 ? 400 : double.infinity,
            ),
            child: Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 4,
              color: theme.colorScheme.surface,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Verify OTP',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'A 6-digit code has been sent to\n${widget.email}',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 24),
                    PinCodeTextField(
                      controller: _otpController,
                      appContext: context,
                      length: 6,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      animationType: AnimationType.fade,
                      autoDisposeControllers: false,
                      pinTheme: PinTheme(
                        shape: PinCodeFieldShape.box,
                        borderRadius: BorderRadius.circular(8),
                        fieldHeight: 50,
                        fieldWidth: 40,
                        activeColor: theme.colorScheme.primary,
                        selectedColor: theme.colorScheme.primaryContainer,
                        inactiveColor: theme.colorScheme.outline,
                      ),
                      onChanged: (value) => _otpCode = value,
                      onCompleted: (value) => _otpCode = value,
                      enabled: !_otpBlocked,
                    ),
                    const SizedBox(height: 24),
                    _isLoading
                        ? const CircularProgressIndicator()
                        : FilledButton.icon(
                      icon: const Icon(Icons.verified_user_outlined),
                      label: const Text("Verify"),
                      onPressed: _otpBlocked ? null : _verifyOtp,
                    ),
                    const SizedBox(height: 16),
                    if (_otpBlocked)
                      Text(
                        "🚫 OTP limit reached. Try again after 10 minutes.",
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error),
                        textAlign: TextAlign.center,
                      )
                    else if (_secondsRemaining > 0)
                      Text(
                        "Resend OTP in ${_formatTime(_secondsRemaining)}",
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      )
                    else
                      Column(
                        children: [
                          Text(
                            "Didn't receive the OTP?",
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          TextButton(
                            onPressed: _canResend ? _sendOtp : null,
                            child: Text(
                              "Resend OTP",
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: theme.colorScheme.primary,
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
        ),
      ),
    );
  }
}
