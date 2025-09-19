import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';

import 'homepage.dart';
import 'settings_page.dart';
import 'constants.dart';
import 'auth_provider.dart';

import 'l10n/app_localizations.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}
class _AuthPageState extends State<AuthPage> {

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nameController = TextEditingController();
  bool _obscurePassword = true;
  String _passwordStrength = "";
  Color _passwordStrengthColor = Colors.red;
  String? _emailError;
  String? _passwordError;
  String? _nameError;
  String? _confirmPasswordError;
  String _passwordHint = "";


  bool _isLogin = true; // true = login, false = register
  bool _rememberMe = false;

  Future<void> _submit() async {
    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();
      final name = _nameController.text.trim();
      if (_isLogin) {
        if (password.isEmpty) {
          setState(() {
            _passwordError = AppLocalizations.of(context)!.passwordRequired;
          });
          return;
        } else {
          _passwordError = null;
        }
        // 🔹 Login qua API Laravel
        final url = Uri.parse('${AppConstants.apiBaseUrl}/api/login');
        final response = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'email': email, 'password': password}),
        );

        if (response.statusCode != 200) {
          if (mounted) {
            final data = jsonDecode(utf8.decode(response.bodyBytes));
            final errorMessage = data['error'] ?? 'Có lỗi xảy ra';
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(
                  AppLocalizations.of(context)!.errorMessage(errorMessage))),
            );
          }
          return;
        }

        final data = jsonDecode(response.body);
        final token = data['token'];
        final userid = data['user']?['id'];

        if (mounted) {
          final auth = Provider.of<AuthProvider>(context, listen: false);
          await auth.login(token, userid, rememberMe: _rememberMe);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.welcome)),
          );

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => HomePage()),
          );
        }
      } else {
        if (!_isLogin &&
            _passwordStrength == AppLocalizations.of(context)!.weak) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.passwordWeak),
            ),
          );
          return;
        }
        // 🔹 Register qua API Laravel
        if (password != _confirmPasswordController.text.trim()) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(AppLocalizations.of(context)!.passwordMismatch)),
          );
          return;
        }

        if (name.isEmpty) {
          setState(() {
            _nameError = AppLocalizations.of(context)!.nameRequired;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.nameRequired)),
          );
          return;
        }
        final url = Uri.parse('${AppConstants.apiBaseUrl}/api/register');
        final response = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'email': email,
            'password': password,
            'name': name,
          }),
        );

        if (response.statusCode != 200) {
          if (mounted) {
            final data = jsonDecode(utf8.decode(response.bodyBytes));
            final errorMessage = data['error'] ?? 'Có lỗi xảy ra';
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(
                  AppLocalizations.of(context)!.errorMessage(errorMessage))),
            );
          }
          return;
        }

        final data = jsonDecode(response.body);
        final token = data['token'];
        final userid = data['user']?['id'];
        if (mounted) {
          final auth = Provider.of<AuthProvider>(context, listen: false);
          await auth.login(token, userid, rememberMe: false);
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.welcome)),
          );

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => HomePage(),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(
              AppLocalizations.of(context)!.errorMessage(e.toString()))),
        );
      }
    }
  }

  void checkPasswordStrength(String password) {
    if (password.isEmpty) {
      setState(() {
        _passwordError = AppLocalizations.of(context)!.passwordRequired;
        _passwordStrength = "";
        _passwordStrengthColor = Colors.red;
        _passwordHint = "";
      });
      return;
    }
    _passwordError = null;
    // Nếu <6 ký tự → mặc định yếu
    if (password.length < 6) {
      setState(() {
        _passwordStrength = AppLocalizations.of(context)!.weak;
        _passwordStrengthColor = Colors.red;
        _passwordHint = AppLocalizations.of(context)!.passwordHint;
      });
      return;
    }

    final hasUppercase = password.contains(RegExp(r'[A-Z]'));
    final hasLowercase = password.contains(RegExp(r'[a-z]'));
    final hasDigit = password.contains(RegExp(r'\d'));
    final hasSpecialChar = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));

    int score = 0;
    if (hasUppercase) score++;
    if (hasLowercase) score++;
    if (hasDigit) score++;
    if (hasSpecialChar) score++;

    if (score <= 2) {
      _passwordStrength = AppLocalizations.of(context)!.weak;
      _passwordStrengthColor = Colors.red;
      _passwordHint = AppLocalizations.of(context)!.passwordHint;
    } else if (score == 3) {
      _passwordStrength = AppLocalizations.of(context)!.medium;
      _passwordStrengthColor = Colors.orange;
      _passwordHint = AppLocalizations.of(context)!.passwordHint;
    } else if (score == 4) {
      _passwordStrength = AppLocalizations.of(context)!.strong;
      _passwordStrengthColor = Colors.green;
      _passwordHint = "";
    }

    setState(() {});
  }
  void _validateConfirmPassword(String confirmPassword) {
    final password = _passwordController.text.trim();

    setState(() {
        if (confirmPassword != password) {
        _confirmPasswordError =
            AppLocalizations.of(context)!.passwordMismatch;
      } else {
        _confirmPasswordError = null;
      }
    });
  }

  void _validateName(String name){
    if (name.isEmpty) {
      setState(() {
        _nameError = AppLocalizations.of(context)!.nameRequired;
      });
    }
    else {
      setState(() {
        _nameError = null;
      });
    }
  }

  void _validateEmail(String email) {
    // regex email cơ bản
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    setState(() {
        if (!emailRegex.hasMatch(email)) {
        _emailError = AppLocalizations.of(context)!.invalidEmail;
      } else {
        _emailError = null;
      }
    });
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;


    return Scaffold(
      backgroundColor: cs.surface, // màu nền theo theme
      appBar: AppBar(
        title: Text(
          _isLogin
              ? AppLocalizations.of(context)!.login
              : AppLocalizations.of(context)!.register,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            color: Theme.of(context).colorScheme.onSurface,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsPage()),
              );
            },
          ),
        ],
        backgroundColor: cs.surface,
        elevation: 0,
        foregroundColor: cs.primary,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 350),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: cs.primary,
                    child: Icon(Icons.lock_outline,
                        size: 32, color: cs.onPrimary),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _isLogin
                        ? AppLocalizations.of(context)!.login
                        : AppLocalizations.of(context)!.register,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: cs.primary,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Display name khi register
                  if (!_isLogin) ...[
                    TextField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText:
                        AppLocalizations.of(context)!.displayName,
                        errorText: _nameError,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onChanged: _validateName,
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Email
                  TextField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.email,
                      errorText: _emailError,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onChanged: _validateEmail,
                  ),
                  const SizedBox(height: 16),

                  // Password
                  TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.password,
                      errorText: _passwordError,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                    onChanged: checkPasswordStrength,
                  ),

                  if (!_isLogin) ...[
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _passwordStrength,
                              style: TextStyle(color: _passwordStrengthColor),
                            ),
                            if (_passwordHint.isNotEmpty)
                              Text(
                                _passwordHint,
                                style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _confirmPasswordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText:
                        AppLocalizations.of(context)!.confirmPassword,
                        errorText: _confirmPasswordError,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onChanged: _validateConfirmPassword,
                    ),
                    const SizedBox(height: 16),
                  ],

                  if (_isLogin)
                    Row(
                      children: [
                        Checkbox(
                          value: _rememberMe,
                          onChanged: (val) {
                            setState(() {
                              _rememberMe = val ?? false;
                            });
                          },
                        ),
                        Text(
                          AppLocalizations.of(context)!.rememberPassword,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  const SizedBox(height: 20),

                  // Nút submit
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: cs.primary,
                        foregroundColor: cs.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        _isLogin
                            ? AppLocalizations.of(context)!.login
                            : AppLocalizations.of(context)!.register,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  TextButton(
                    onPressed: () {
                      setState(() {
                        _isLogin = !_isLogin;
                      });
                    },
                    child: Text(
                      _isLogin
                          ? AppLocalizations.of(context)!.authPromptSignUp
                          : AppLocalizations.of(context)!.authPromptSignIn,
                      style: TextStyle(
                        color: cs.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}