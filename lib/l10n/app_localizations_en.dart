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
  String get read_later_error => 'Cannot mark as read, try again later';

  @override
  String get mark_all_as_read => 'Mark all as read';

  @override
  String get no => 'No';

  @override
  String get edit_group => 'Edit group';

  @override
  String get save_changes => 'Save changes';

  @override
  String get update_role_success => 'Role updated successfully';

  @override
  String get change_role => 'Change role';

  @override
  String get remove_member => 'Remove member';

  @override
  String get add_member => 'Add member';

  @override
  String get role_member => 'Member';

  @override
  String get role_manager => 'Manager';

  @override
  String get role_admin => 'Admin';

  @override
  String get delete_this_member => 'Delete this member';

  @override
  String get add_new_member => 'Add new member';

  @override
  String get cancel => 'Cancel';

  @override
  String get add => 'Add';

  @override
  String get add_success => 'Added successfully';

  @override
  String get confirm_delete => 'Confirm deletion';

  @override
  String confirm_delete_member_message(Object userName) {
    return 'Are you sure you want to delete $userName from the group?';
  }

  @override
  String get delete => 'Delete';

  @override
  String get delete_member_success => 'Member deleted successfully';

  @override
  String change_role_for_member(Object memberName) {
    return 'Change role for $memberName';
  }

  @override
  String get confirm_delete_group => 'Confirm group deletion';

  @override
  String get confirm_delete_group_message => 'Are you sure you want to delete the group? All data will be lost.';

  @override
  String get enter_confirmation_code_to_delete => 'Enter the correct confirmation code below to delete the group:';

  @override
  String get enter_confirmation_code => 'Enter confirmation code';

  @override
  String get invalid_confirmation_code => 'Invalid confirmation code';

  @override
  String get group_deleted_successfully => 'Group deleted successfully';

  @override
  String get delete_group => 'Delete group';

  @override
  String get confirm_leave_group => 'Confirm leaving group';

  @override
  String get confirm_leave_group_message => 'Are you sure you want to leave the group?';

  @override
  String get enter_confirmation_code_to_leave => 'Enter the correct confirmation code below to leave the group:';

  @override
  String get leave_group_success => 'You have left the group successfully';

  @override
  String get leave_group => 'Leave group';

  @override
  String get total_members => 'Total members';

  @override
  String get member_list => 'Member list';

  @override
  String get role => 'Role:';

  @override
  String get create_new_task => 'Create new task';

  @override
  String get title => 'Title';

  @override
  String get description_label => 'Description';

  @override
  String get priority_high => 'High';

  @override
  String get priority_medium => 'Medium';

  @override
  String get priority_low => 'Low';

  @override
  String get priority => 'Priority';

  @override
  String get no_deadline_selected => 'No deadline selected';

  @override
  String get deadline => 'Deadline:';

  @override
  String get select_deadline => 'Select deadline';

  @override
  String get create => 'Create';

  @override
  String get edit_task => 'Edit task';

  @override
  String get task_title => 'Title';

  @override
  String get task_description => 'Description';

  @override
  String get task_priority => 'Priority';

  @override
  String get task_assignee => 'Assignee';

  @override
  String get task_list => 'Task list';

  @override
  String get create_new_task_action => 'Create new task';

  @override
  String get no_tasks_found => 'No tasks found.';

  @override
  String get no_title => 'No title';

  @override
  String get status => 'Status:';

  @override
  String get file_uploaded => 'File uploaded';

  @override
  String get upload_file => 'Upload file';

  @override
  String get select_file => 'Select file';

  @override
  String get file_name_optional => 'File name (optional)';

  @override
  String get upload => 'Upload';

  @override
  String get file_list => 'File list';

  @override
  String get no_attachments => 'No attachments yet';

  @override
  String get type_message_placeholder => 'Type a message...';

  @override
  String get attachments => 'Attachments';

  @override
  String get comment_placeholder => 'Enter a comment...';

  @override
  String get no_comments => 'No comments yet';

  @override
  String get comments => 'Comments';

  @override
  String get assignee => 'Assignee';

  @override
  String get progress => 'Progress';

  @override
  String get no_description => 'No description';

  @override
  String get task_details => 'Task details';

  @override
  String get send_comment_failed => 'Failed to send comment';

  @override
  String get storage_permission_denied => 'Storage permission denied';

  @override
  String get download_start => 'Download started';

  @override
  String get downloading => 'Downloading';

  @override
  String get download_completed => 'Downloaded';

  @override
  String get download_failed => 'File download failed';

  @override
  String get file_not_found => 'File not found';

  @override
  String get image_not_displayed => 'Image cannot be displayed';

  @override
  String get file_type_not_supported => 'This file type is not supported for display';

  @override
  String get dashboard => 'Dash board';

  @override
  String errorMessage(String error) {
    return 'Error: $error';
  }
}
