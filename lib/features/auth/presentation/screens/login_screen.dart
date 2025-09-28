import 'package:domyturn/core/session/app_session.dart';
import 'package:domyturn/core/storage/secure_storage_service.dart';
import 'package:domyturn/shared/utils/global_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:domyturn/features/auth/data/repositories/user_repository.dart';
import 'package:logger/logger.dart';
import '../../data/repositories/auth_repository.dart';

final Logger logger = Logger(printer: PrettyPrinter());

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}


class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthRepository _authRepo = AuthRepository();
  final UserRepository _userRepo = UserRepository();
  bool _obscurePassword = true;
  bool _emailError = false;
  bool _passwordError = false;
  bool _loading = false;

  Future<void> _login() async {
    setState(() {
      _emailError = _emailController.text.trim().isEmpty;
      _passwordError = _passwordController.text.trim().isEmpty;
    });

    if (_emailError || _passwordError) return;

    setState(() => _loading = true);

    final success = await _authRepo.loginUser(
      _emailController.text.trim(),
      _passwordController.text.trim(),
    );

    if (!mounted) return;

    if (success) {
      final userId = AppSession.instance.userId;
      if (userId == null) return;
      logger.i("userid : $userId");
      final authUser = await _authRepo.isUserVerified(userId);
      await _userRepo.sendFcmToken();

      if (authUser == null) {
        GlobalScaffold.showSnackbar("User data not found",type: SnackbarType.error);
        setState(() => _loading = false);
        return;
      }

      if (!authUser.isVerified) {
        GoRouter.of(context).go('/otp?email=${Uri.encodeComponent(authUser.email)}');
      } else {
        final isInHome = await _userRepo.isUserInHome();
        GlobalScaffold.showSnackbar("Login successful",type: SnackbarType.success);
        GoRouter.of(context).go(isInHome ? '/dashboard' : '/create-or-join-home');
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Welcome",
                  style: textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  "Please sign in to continue",
                  style: textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 32),
                Card(
                  elevation: theme.cardTheme.elevation,
                  shape: theme.cardTheme.shape,
                  color: theme.cardTheme.color,
                  shadowColor: theme.cardTheme.shadowColor,
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: 'Email',
                            border: const OutlineInputBorder(),
                            prefixIcon: Icon(Icons.email_outlined, color: colorScheme.primary),
                            errorText: _emailError ? "Email is required" : null,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            border: const OutlineInputBorder(),
                            prefixIcon: Icon(Icons.lock_outline, color: colorScheme.primary),
                            errorText: _passwordError ? "Password is required" : null,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                color: colorScheme.primary,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: FilledButton(
                            onPressed: _loading ? null : _login,
                            style: FilledButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _loading
                                ? const CircularProgressIndicator(color: Colors.white)
                                : const Text("Login"),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () => context.go('/forgot-password'),
                          child: const Text(
                            "Forgot Password?",
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => context.go('/register'),
                  child: const Text("Don't have an account? Register"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
