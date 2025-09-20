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
  String get avatar => 'Avatar';

  @override
  String get passwordHint => 'Should include uppercase, lowercase, numbers, and special characters';

  @override
  String get confirmPassword => 'Confirm Password';

  @override
  String get rememberPassword => 'Remember Password';

  @override
  String get authPromptSignUp => 'Don\'t have an account? Sign up';

  @override
  String get authPromptSignIn => 'Already have an account? Sign in';

  @override
  String get invalidEmail => 'Invalid Email';

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
  String get setDefault => 'Set default';

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
  String get updateSuccessMessage => 'Updated successfully!';

  @override
  String get updatePasswordSuccess => 'Updated password successfully!';

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
  String get editProfile => 'Edit profile';

  @override
  String get passwordWeak => 'Password is too weak. Please enter a stronger password.';

  @override
  String get notLoggedIn => 'You are not logged in';

  @override
  String get weak => 'Weak';

  @override
  String get medium => 'Medium';

  @override
  String get strong => 'Strong';

  @override
  String get chooseAvatar => 'Choose\navatar';

  @override
  String get phone => 'Phone';

  @override
  String get address => 'Address';

  @override
  String get dob => 'Date of Birth';

  @override
  String get job => 'Position / Occupation';

  @override
  String get oldPassword => 'Old Password';

  @override
  String get newPassword => 'New Password';

  @override
  String get confirmNewPassword => 'Confirm New Password';

  @override
  String get changePassword => 'Change Password';

  @override
  String get cannotLoadUserInfo => 'Cannot load user information';

  @override
  String get save => 'Save';

  @override
  String get loading => 'Loading...';

  @override
  String get createdBy => 'Created by';

  @override
  String get task => 'Task';

  @override
  String get files => 'Files';

  @override
  String get information => 'Information';

  @override
  String get description => 'Description';

  @override
  String get notification => 'Notification';

  @override
  String get close => 'Close';

  @override
  String get message => 'Message';

  @override
  String get group_name_cannot_be_empty => 'Group name cannot be empty';

  @override
  String get group_created_successfully => 'Group created successfully';

  @override
  String get group_name => 'Group Name *';

  @override
  String get description_optional => 'Description (optional)';

  @override
  String get create_group => 'Create Group';

  @override
  String get group_list => 'Group List';

  @override
  String get create_new_group => 'Create New Group';

  @override
  String get members => 'Members';

  @override
  String get editGroup => 'Edit group';

  @override
  String get manageMembers => 'Manage members';

  @override
  String get pinGroup => 'Pin group';

  @override
  String get deleteGroup => 'Delete group';

  @override
  String get memberList => 'Member list';

  @override
  String get leaveGroup => 'Leave Group';

  @override
  String errorMessage(String error) {
    return 'Error: $error';
  }
}
