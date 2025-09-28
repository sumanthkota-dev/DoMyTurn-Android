import 'package:domyturn/features/auth/data/repositories/auth_repository.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final AuthRepository authRepository = AuthRepository();

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _emailError = false;
  bool _nameError = false;
  bool _passwordError = false;
  bool _loading = false;
  bool _showResetPasswordForm = false;

  Future<void> _verifyUser() async {
    final email = _emailController.text.trim();
    final name = _nameController.text.trim();

    setState(() {
      _emailError = email.isEmpty;
      _nameError = name.isEmpty;
    });

    if (_emailError || _nameError) return;

    setState(() => _loading = true);

    try {
      final result = await authRepository.verifyUserForPasswordReset(email, name);

      if (!mounted) return;

      if (result == 'VERIFIED') {
        setState(() => _showResetPasswordForm = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("User verified. Please enter new password.")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Verification failed. Please try again.")),
        );
      }
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Unexpected error. Please try again.")),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    setState(() {
      _passwordError = password.isEmpty;
    });

    if (_passwordError) return;

    setState(() => _loading = true);

    try {
      final result = await authRepository.changePassword(email, password);

      if (!mounted) return;

      if (result == 'SUCCESS') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Password reset successful. Please login.")),
        );
        context.go('/login');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Reset failed. Try logging in again.")),
        );
        context.go('/login');
      }
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Unexpected error. Please try again.")),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Forgot Password'),
        centerTitle: true,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight,
              ),
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 500),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: theme.cardTheme.color ?? theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: kElevationToShadow[theme.cardTheme.elevation?.toInt() ?? 2],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Reset Your Password',
                        style: textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _showResetPasswordForm
                            ? 'Enter your new password'
                            : 'Enter your email and name to verify your identity.',
                        style: textTheme.bodyLarge?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),

                      // Email
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        enabled: !_showResetPasswordForm,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.email, color: colorScheme.primary),
                          border: const OutlineInputBorder(),
                          errorText: _emailError ? 'Email is required' : null,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Name
                      if (!_showResetPasswordForm)
                        TextField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            labelText: 'Name',
                            prefixIcon: Icon(Icons.person, color: colorScheme.primary),
                            border: const OutlineInputBorder(),
                            errorText: _nameError ? 'Name is required' : null,
                          ),
                        ),

                      // Password
                      if (_showResetPasswordForm) ...[
                        const SizedBox(height: 16),
                        TextField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: 'New Password',
                            prefixIcon: Icon(Icons.lock, color: colorScheme.primary),
                            border: const OutlineInputBorder(),
                            errorText: _passwordError ? 'Password is required' : null,
                          ),
                        ),
                      ],

                      const SizedBox(height: 24),

                      // Button
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: FilledButton(
                          onPressed: _loading
                              ? null
                              : _showResetPasswordForm
                              ? _resetPassword
                              : _verifyUser,
                          style: FilledButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _loading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : Text(_showResetPasswordForm ? 'Reset Password' : 'Verify'),
                        ),
                      ),

                      const SizedBox(height: 16),

                      TextButton(
                        onPressed: _loading ? null : () => context.go('/login'),
                        child: const Text('Back to Login'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
