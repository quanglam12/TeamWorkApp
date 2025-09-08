import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bcrypt/bcrypt.dart';


import 'register.dart';
import 'homepage.dart';
import 'settings_page.dart';

import 'package:teamworkapp/l10n/app_localizations.dart';



class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLogin = true; // true = login, false = register
  bool _rememberMe = false; // ghi nhớ đăng nhập

  Future<void> _submit() async {
    try {
      final usersRef = FirebaseFirestore.instance.collection("users");

      if (_isLogin) {
        // 🔹 Đăng nhập: tìm user theo email + password
        final snapshot = await usersRef
            .where("email", isEqualTo: _emailController.text.trim())
            .get();

        if (snapshot.docs.isEmpty) {
          // email chưa tồn tại
        } else {
          final user = snapshot.docs.first.data();
          final storedHash = user["password"];

          final isPasswordCorrect = BCrypt.checkpw(
            _passwordController.text.trim(),
            storedHash,
          );

          if (!isPasswordCorrect) {
            // Sai mật khẩu
          } else {
            // Đăng nhập thành công
          }
        }


        // Ghi nhớ đăng nhập
        if (_rememberMe) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool("rememberMe", true);
          await prefs.setString("email", _emailController.text.trim());
          await prefs.setString("password", _passwordController.text.trim());
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

      } else {
        // 🔹 Đăng ký: kiểm tra mật khẩu khớp
        if (_passwordController.text.trim() !=
            _confirmPasswordController.text.trim()) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.passwordMismatch)),
          );
          return;
        }

        // 🔹 Kiểm tra email có tồn tại chưa
        final snapshot = await usersRef
            .where("email", isEqualTo: _emailController.text.trim())
            .get();
        if (mounted) {
          if (snapshot.docs.isNotEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(AppLocalizations.of(context)!.emailExists)),
            );
            return;
          }
        }
        final hashedPassword = BCrypt.hashpw(_passwordController.text.trim(), BCrypt.gensalt());
        // 🔹 Nếu email chưa có → tạo user tạm
        final newUser = await usersRef.add({
          "email": _emailController.text.trim(),
          "password": hashedPassword,
          "name": "",
          "avturl": "",
          "groups": [],
        });

        // 🔹 Chuyển sang màn hình nhập thêm thông tin
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => RegisterInfoPage(userId: newUser.id),
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


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isLogin ? AppLocalizations.of(context)!.login : AppLocalizations.of(context)!.register),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsPage()),
              );
            },
          ),
        ],
      ),

      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextField(
                controller: _emailController,
                decoration: InputDecoration(labelText: AppLocalizations.of(context)!.email),
              ),
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(labelText: AppLocalizations.of(context)!.password),
                obscureText: true,
              ),
              if (!_isLogin) // chỉ hiện khi Đăng ký
                TextField(
                  controller: _confirmPasswordController,
                  decoration:
                  InputDecoration(labelText: AppLocalizations.of(context)!.confirmPassword),
                  obscureText: true,
                ),
              const SizedBox(height: 10),

              // Ghi nhớ đăng nhập chỉ hiện ở màn hình Login
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
                    Text(AppLocalizations.of(context)!.rememberPassword,
                      style: Theme.of(context).textTheme.bodyMedium,),
                  ],
                ),

              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submit,
                child: Text(_isLogin ? AppLocalizations.of(context)!.login : AppLocalizations.of(context)!.register),
              ),
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
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
