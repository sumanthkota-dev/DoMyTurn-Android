import 'dart:math';

import 'package:domyturn/features/auth/data/repositories/user_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:logger/logger.dart';
import 'package:multiavatar/multiavatar.dart';
import '../../../../shared/service/app_local_notification_service.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/models/register_request.dart';

final logger = Logger(printer: PrettyPrinter());

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _userNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _mobileController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  final AuthRepository _authRepository = AuthRepository();
  final UserRepository userRepository = UserRepository();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final cardWidth = constraints.maxWidth * 0.95;

            return Center(
              child: SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: cardWidth.clamp(300, 600), // clamp for min and max width safety
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Card(
                        elevation: theme.cardTheme.elevation ?? 3,
                        color: theme.cardTheme.color,
                        shape: theme.cardTheme.shape ??
                            RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                        shadowColor: theme.cardTheme.shadowColor ?? Colors.black12,
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: _buildForm(theme),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () => context.go('/login'),
                        child: const Text("Already have an account? Login"),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildForm(ThemeData theme) {
    final colorScheme = theme.colorScheme;

    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Register',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _userNameController,
            decoration: const InputDecoration(
              labelText: 'User Name',
              prefixIcon: Icon(Icons.person_outline),
              border: OutlineInputBorder(),
            ),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9 ]')),
            ],
            validator: (value) {
              if (value == null || value.trim().isEmpty) return 'Enter your name';
              if (!RegExp(r'^[a-zA-Z0-9 ]+$').hasMatch(value)) {
                return 'No special characters allowed';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(Icons.email_outlined),
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.emailAddress,
            validator: (value) =>
            value == null || value.isEmpty ? 'Enter your email' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _mobileController,
            decoration: const InputDecoration(
              labelText: 'Mobile Number',
              prefixIcon: Icon(Icons.phone_android_outlined),
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.phone,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            validator: (value) {
              if (value == null || value.isEmpty) return 'Enter your mobile number';
              if (!RegExp(r'^\d+$').hasMatch(value)) {
                return 'Mobile number must be digits only';
              }
              return null;
            },
          ),
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              labelText: 'Password',
              prefixIcon: const Icon(Icons.lock_outline),
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
            ),
            validator: (value) =>
            value != null && value.length < 6 ? 'Min 6 characters' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _confirmPasswordController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Confirm Password',
              prefixIcon: Icon(Icons.lock_reset_outlined),
              border: OutlineInputBorder(),
            ),
            validator: (value) =>
            value != _passwordController.text ? 'Passwords do not match' : null,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : FilledButton.icon(
              onPressed: _register,
              icon: const Icon(Icons.app_registration),
              label: const Text('Register'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _register() async {
    final seed = _userNameController.text.trim() + Random().nextInt(9999).toString();
    final avatarSvg = multiavatar(seed);
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isLoading = true);

      final request = RegisterRequest(
        userName: _userNameController.text.trim(),
        email: _emailController.text.trim(),
        mobile: _mobileController.text.trim(),
        password: _passwordController.text,
        avatarSvg: avatarSvg,
      );

      final result = await _authRepository.registerUser(request);

      setState(() => _isLoading = false);

      if (result && mounted) {
        await userRepository.sendFcmToken();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registration Success')),
        );
        context.go('/otp?email=${_emailController.text.trim()}&sent=true');
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registration failed')),
        );
      }
    }
  }

  @override
  void dispose() {
    _userNameController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
