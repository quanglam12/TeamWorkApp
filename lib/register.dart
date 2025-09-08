import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'homepage.dart';
import 'package:teamworkapp/l10n/app_localizations.dart';
class RegisterInfoPage extends StatefulWidget {
  final String userId;

  const RegisterInfoPage({super.key, required this.userId});

  @override
  State<RegisterInfoPage> createState() => _RegisterInfoPageState();
}

class _RegisterInfoPageState extends State<RegisterInfoPage> {
  final _nameController = TextEditingController();
  bool _isLoading = false;

  Future<void> _saveInfo() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.nameRequired)),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // 🔹 Cập nhật thông tin vào Firestore
      await FirebaseFirestore.instance
          .collection("users")
          .doc(widget.userId)
          .set({
        "name": _nameController.text.trim(),
      }, SetOptions(merge: true));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(
              AppLocalizations.of(context)!.updateSuccessMessage)),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomePage(),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.errorMessage(e.toString()))),
      );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.completeProfile)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: AppLocalizations.of(context)!.displayName),
            ),
            const SizedBox(height: 30),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
              onPressed: _saveInfo,
              child: Text(AppLocalizations.of(context)!.confirm),
            ),
          ],
        ),
      ),
    );
  }
}
