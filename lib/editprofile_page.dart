import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import 'auth_provider.dart';
import 'constants.dart';

import 'l10n/app_localizations.dart';


class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _dobController = TextEditingController();
  final _jobController = TextEditingController();

  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _rePasswordController = TextEditingController();

  String? _avturl;
  File? _avatar;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _pickAvatar() async {
    final pickedFile =
    await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _avatar = File(pickedFile.path);
      });
    }
  }

  /// Gửi thông tin + ảnh đại diện trong một lần bấm Lưu
  Future<void> _updateProfile() async {
    final auth = context.read<AuthProvider>();
    final token = auth.token;

    if (token == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.notLoggedIn)));
      return;
    }

    setState(() => _loading = true);

    try {
      // Nếu có ảnh đại diện thì dùng MultipartRequest để gửi cả file + field
      if (_avatar != null) {
        final request = http.MultipartRequest(
          'POST',
          Uri.parse('${AppConstants.apiBaseUrl}/api/profile/update'),
        );
        request.headers['Accept'] = 'application/json';
        request.headers['Authorization'] = 'Bearer $token';
        request.fields['name'] = _nameController.text;
        request.fields['phone'] = _phoneController.text;
        request.fields['address'] = _addressController.text;
        request.fields['email'] = _emailController.text;
        request.fields['dob'] = _dobController.text;
        request.fields['job'] = _jobController.text;
        request.files.add(
          await http.MultipartFile.fromPath('avatar', _avatar!.path),
        );

        final streamedResponse = await request.send();
        final response = await http.Response.fromStream(streamedResponse);

        if (response.statusCode == 200) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(
                    AppLocalizations.of(context)!.updateSuccessMessage)));
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(
                    AppLocalizations.of(context)!.errorMessage(
                        response.body))));
          }
        }
      } else {
        // Không có ảnh → gửi JSON bình thường
        final response = await http.post(
          Uri.parse('${AppConstants.apiBaseUrl}/api/profile/update'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: '''
          {
            "name": "${_nameController.text}",
            "email": "${_emailController.text}",
            "phone": "${_phoneController.text}",
            "address": "${_addressController.text}",
            "dob": "${_dobController.text}",
            "job": "${_jobController.text}"
          }
          ''',
        );

        if (response.statusCode == 200) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(
                    AppLocalizations.of(context)!.updateSuccessMessage)));
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(
                    AppLocalizations.of(context)!.errorMessage(
                        response.body))));
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(
            AppLocalizations.of(context)!.errorMessage(e.toString()))));
      }
    }

    setState(() => _loading = false);
  }

  Future<void> _changePassword() async {
    final auth = context.read<AuthProvider>();
    final token = auth.token;

    if (token == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.notLoggedIn)));
      return;
    }

    if (_newPasswordController.text != _rePasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(AppLocalizations.of(context)!.passwordMismatch)));
      return;
    }

    setState(() => _loading = true);

    try {
      final response = await http.post(
        Uri.parse('${AppConstants.apiBaseUrl}/api/profile/change-password'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: '''
        {
          "old_password": "${_oldPasswordController.text}",
          "new_password": "${_newPasswordController.text}"
        }
        ''',
      );

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(
                  AppLocalizations.of(context)!.updatePasswordSuccess)));
          _oldPasswordController.clear();
          _newPasswordController.clear();
          _rePasswordController.clear();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(
                  AppLocalizations.of(context)!.errorMessage(response.body))));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(
            AppLocalizations.of(context)!.errorMessage(e.toString()))));
      }
    }

    setState(() => _loading = false);
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.grey.shade200,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    );
  }

  Future<void> _loadUserProfile() async {
    setState(() => _loading = true);
    try {
      // Lấy token từ AuthProvider
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final token = auth.token;
      if (token == null) return;

      final url = Uri.parse(
          '${AppConstants.apiBaseUrl}/api/me'); // endpoint lấy profile
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        Map<String, dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        Map<String, dynamic> user = data['user'];

        // Gán dữ liệu vào TextEditingController nếu khác null
        if (user['name'] != null) _nameController.text = user['name'];
        if (user['email'] != null) _emailController.text = user['email'];
        if (user['phone'] != null) _phoneController.text = user['phone'];
        if (user['address'] != null) _addressController.text = user['address'];
        if (user['dob'] != null) _dobController.text = user['dob'];
        if (user['job'] != null) _jobController.text = user['job'];
        if (user['avturl'] != null) {
          String fullavturl = '${AppConstants
              .apiBaseUrl}/storage/${user['avturl']}';
          setState(() {
            _avturl = fullavturl; // tạo biến state _avturl
          });
        }
        setState(() {}); // update UI
      } else {
        // handle lỗi nếu cần
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(
                AppLocalizations.of(context)!.cannotLoadUserInfo)),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(
            AppLocalizations.of(context)!.errorMessage(e.toString()))));
      }
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: cs.primary, // dùng màu primary theo theme
        centerTitle: true,
        title: Text(
          AppLocalizations.of(context)!.editProfile,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: cs.onPrimary, // chữ tương phản
          ),
        ),
      ),
      body: AbsorbPointer(
        absorbing: _loading,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _pickAvatar,
                    child: CircleAvatar(
                      radius: 48,
                      backgroundColor: cs.surfaceContainerHighest,
                      backgroundImage: _avatar != null
                          ? FileImage(_avatar!) as ImageProvider
                          : (_avturl != null && _avturl!.isNotEmpty
                          ? NetworkImage(_avturl!)
                          : null),
                      child: (_avatar == null &&
                          (_avturl == null || _avturl!.isEmpty))
                          ? Icon(Icons.camera_alt,
                          size: 40, color: cs.onSurfaceVariant)
                          : null,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // TextFields
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.displayName,
                    ).copyWith(
                      border: const OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.email,
                    ).copyWith(
                      border: const OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _phoneController,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.phone,
                    ).copyWith(
                      border: const OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _addressController,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.address,
                    ).copyWith(
                      border: const OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _dobController,
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.dob,
                    ).copyWith(
                      border: const OutlineInputBorder(),
                      isDense: true,
                      suffixIcon: const Icon(Icons.calendar_today),
                    ),
                    onTap: () async {
                      FocusScope.of(context).requestFocus(FocusNode());
                      DateTime? pickedDate = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(1900),
                        lastDate: DateTime.now(),
                      );
                      if (pickedDate != null) {
                        _dobController.text =
                            pickedDate
                                .toIso8601String()
                                .split('T')
                                .first;
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _jobController,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.job,
                    ).copyWith(
                      border: const OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Nút lưu
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: cs.primary,
                        foregroundColor: cs.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.zero,
                        ),
                      ),
                      onPressed: _updateProfile,
                      child: _loading
                          ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                          : Text(
                        AppLocalizations.of(context)!.save,
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: cs.onPrimary,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Đổi mật khẩu
                  TextField(
                    controller: _oldPasswordController,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.oldPassword,
                    ).copyWith(
                      border: const OutlineInputBorder(),
                      isDense: true,
                    ),
                    obscureText: true,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _newPasswordController,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.newPassword,
                    ).copyWith(
                      border: const OutlineInputBorder(),
                      isDense: true,
                    ),
                    obscureText: true,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _rePasswordController,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.confirmNewPassword,
                    ).copyWith(
                      border: const OutlineInputBorder(),
                      isDense: true,
                    ),
                    obscureText: true,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: cs.primary,
                        foregroundColor: cs.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.zero,
                        ),
                      ),
                      onPressed: _changePassword,
                      child: _loading
                          ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                          : Text(
                        AppLocalizations.of(context)!.changePassword,
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: cs.onPrimary,
                        ),
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