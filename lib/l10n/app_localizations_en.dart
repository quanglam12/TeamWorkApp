// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Teamwork App';

  @override
  String get welcome => 'Welcome';

  @override
  String get settings => 'Settings';

  @override
  String get login => 'Login';

  @override
  String get logout => 'Logout';

  @override
  String get register => 'Register';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get name => 'Name';

  @override
  String get confirmPassword => 'Confirm Password';

  @override
  String get rememberPassword => 'Remember Password';

  @override
  String get authPromptSignUp => 'Don\'t have an account? Sign up';

  @override
  String get authPromptSignIn => 'Already have an account? Sign in';

  @override
  String get confirm => 'Confirm';

  @override
  String get theme => 'Theme';

  @override
  String get darkMode => 'Dark mode';

  @override
  String get fontSize => 'Font size';

  @override
  String get language => 'Language';

  @override
  String get english => 'English';

  @override
  String get vietnamese => 'Vietnamese';

  @override
  String get loginSuccess => 'Login successful!';

  @override
  String get loginFailed => 'Invalid email or password!';

  @override
  String get registerSuccess => 'Registration successful!';

  @override
  String get nameRequired => 'Please enter your name';

  @override
  String get emailRequired => 'Please enter your email';

  @override
  String get passwordRequired => 'Please enter your password';

  @override
  String get passwordMismatch => 'Passwords do not match';

  @override
  String get emailExists => 'Email already exists!';

  @override
  String get updateSuccessMessage => 'Information updated successfully!';

  @override
  String get completeProfile => 'Complete your personal information';

  @override
  String get displayName => 'Display name';

  @override
  String get systemTheme => 'System';

  @override
  String get lightTheme => 'Light';

  @override
  String get darkTheme => 'Dark';

  @override
  String errorMessage(String error) {
    return 'Error: $error';
  }
}
