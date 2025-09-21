import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_vi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('vi')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Teamwork App'**
  String get appTitle;

  /// No description provided for @welcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get welcome;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @register.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get register;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @avatar.
  ///
  /// In en, this message translates to:
  /// **'Avatar'**
  String get avatar;

  /// No description provided for @passwordHint.
  ///
  /// In en, this message translates to:
  /// **'Should include uppercase, lowercase, numbers, and special characters'**
  String get passwordHint;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// No description provided for @rememberPassword.
  ///
  /// In en, this message translates to:
  /// **'Remember Password'**
  String get rememberPassword;

  /// No description provided for @authPromptSignUp.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? Sign up'**
  String get authPromptSignUp;

  /// No description provided for @authPromptSignIn.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Sign in'**
  String get authPromptSignIn;

  /// No description provided for @invalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Invalid Email'**
  String get invalidEmail;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark mode'**
  String get darkMode;

  /// No description provided for @fontSize.
  ///
  /// In en, this message translates to:
  /// **'Font size'**
  String get fontSize;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @setDefault.
  ///
  /// In en, this message translates to:
  /// **'Set default'**
  String get setDefault;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @vietnamese.
  ///
  /// In en, this message translates to:
  /// **'Vietnamese'**
  String get vietnamese;

  /// No description provided for @loginSuccess.
  ///
  /// In en, this message translates to:
  /// **'Login successful!'**
  String get loginSuccess;

  /// No description provided for @loginFailed.
  ///
  /// In en, this message translates to:
  /// **'Invalid email or password!'**
  String get loginFailed;

  /// No description provided for @registerSuccess.
  ///
  /// In en, this message translates to:
  /// **'Registration successful!'**
  String get registerSuccess;

  /// No description provided for @nameRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter your name'**
  String get nameRequired;

  /// No description provided for @emailRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter your email'**
  String get emailRequired;

  /// No description provided for @passwordRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter your password'**
  String get passwordRequired;

  /// No description provided for @passwordMismatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordMismatch;

  /// No description provided for @emailExists.
  ///
  /// In en, this message translates to:
  /// **'Email already exists!'**
  String get emailExists;

  /// No description provided for @updateSuccessMessage.
  ///
  /// In en, this message translates to:
  /// **'Updated successfully!'**
  String get updateSuccessMessage;

  /// No description provided for @updatePasswordSuccess.
  ///
  /// In en, this message translates to:
  /// **'Updated password successfully!'**
  String get updatePasswordSuccess;

  /// No description provided for @completeProfile.
  ///
  /// In en, this message translates to:
  /// **'Complete your personal information'**
  String get completeProfile;

  /// No description provided for @displayName.
  ///
  /// In en, this message translates to:
  /// **'Display name'**
  String get displayName;

  /// No description provided for @systemTheme.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get systemTheme;

  /// No description provided for @lightTheme.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get lightTheme;

  /// No description provided for @darkTheme.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get darkTheme;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get editProfile;

  /// No description provided for @passwordWeak.
  ///
  /// In en, this message translates to:
  /// **'Password is too weak. Please enter a stronger password.'**
  String get passwordWeak;

  /// No description provided for @notLoggedIn.
  ///
  /// In en, this message translates to:
  /// **'You are not logged in'**
  String get notLoggedIn;

  /// No description provided for @weak.
  ///
  /// In en, this message translates to:
  /// **'Weak'**
  String get weak;

  /// No description provided for @medium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get medium;

  /// No description provided for @strong.
  ///
  /// In en, this message translates to:
  /// **'Strong'**
  String get strong;

  /// No description provided for @chooseAvatar.
  ///
  /// In en, this message translates to:
  /// **'Choose\navatar'**
  String get chooseAvatar;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phone;

  /// No description provided for @address.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get address;

  /// No description provided for @dob.
  ///
  /// In en, this message translates to:
  /// **'Date of Birth'**
  String get dob;

  /// No description provided for @job.
  ///
  /// In en, this message translates to:
  /// **'Position / Occupation'**
  String get job;

  /// No description provided for @oldPassword.
  ///
  /// In en, this message translates to:
  /// **'Old Password'**
  String get oldPassword;

  /// No description provided for @newPassword.
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get newPassword;

  /// No description provided for @confirmNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm New Password'**
  String get confirmNewPassword;

  /// No description provided for @changePassword.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get changePassword;

  /// No description provided for @cannotLoadUserInfo.
  ///
  /// In en, this message translates to:
  /// **'Cannot load user information'**
  String get cannotLoadUserInfo;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @createdBy.
  ///
  /// In en, this message translates to:
  /// **'Created by'**
  String get createdBy;

  /// No description provided for @task.
  ///
  /// In en, this message translates to:
  /// **'Task'**
  String get task;

  /// No description provided for @files.
  ///
  /// In en, this message translates to:
  /// **'Files'**
  String get files;

  /// No description provided for @information.
  ///
  /// In en, this message translates to:
  /// **'Information'**
  String get information;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @notification.
  ///
  /// In en, this message translates to:
  /// **'Notification'**
  String get notification;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @message.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get message;

  /// No description provided for @group_name_cannot_be_empty.
  ///
  /// In en, this message translates to:
  /// **'Group name cannot be empty'**
  String get group_name_cannot_be_empty;

  /// No description provided for @group_created_successfully.
  ///
  /// In en, this message translates to:
  /// **'Group created successfully'**
  String get group_created_successfully;

  /// No description provided for @group_name.
  ///
  /// In en, this message translates to:
  /// **'Group Name *'**
  String get group_name;

  /// No description provided for @description_optional.
  ///
  /// In en, this message translates to:
  /// **'Description (optional)'**
  String get description_optional;

  /// No description provided for @create_group.
  ///
  /// In en, this message translates to:
  /// **'Create Group'**
  String get create_group;

  /// No description provided for @group_list.
  ///
  /// In en, this message translates to:
  /// **'Group List'**
  String get group_list;

  /// No description provided for @create_new_group.
  ///
  /// In en, this message translates to:
  /// **'Create New Group'**
  String get create_new_group;

  /// No description provided for @members.
  ///
  /// In en, this message translates to:
  /// **'Members'**
  String get members;

  /// No description provided for @editGroup.
  ///
  /// In en, this message translates to:
  /// **'Edit group'**
  String get editGroup;

  /// No description provided for @manageMembers.
  ///
  /// In en, this message translates to:
  /// **'Manage members'**
  String get manageMembers;

  /// No description provided for @pinGroup.
  ///
  /// In en, this message translates to:
  /// **'Pin group'**
  String get pinGroup;

  /// No description provided for @deleteGroup.
  ///
  /// In en, this message translates to:
  /// **'Delete group'**
  String get deleteGroup;

  /// No description provided for @memberList.
  ///
  /// In en, this message translates to:
  /// **'Member list'**
  String get memberList;

  /// No description provided for @leaveGroup.
  ///
  /// In en, this message translates to:
  /// **'Leave Group'**
  String get leaveGroup;

  /// No description provided for @read_later_error.
  ///
  /// In en, this message translates to:
  /// **'Cannot mark as read, try again later'**
  String get read_later_error;

  /// No description provided for @mark_all_as_read.
  ///
  /// In en, this message translates to:
  /// **'Mark all as read'**
  String get mark_all_as_read;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @edit_group.
  ///
  /// In en, this message translates to:
  /// **'Edit group'**
  String get edit_group;

  /// No description provided for @save_changes.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get save_changes;

  /// No description provided for @update_role_success.
  ///
  /// In en, this message translates to:
  /// **'Role updated successfully'**
  String get update_role_success;

  /// No description provided for @change_role.
  ///
  /// In en, this message translates to:
  /// **'Change role'**
  String get change_role;

  /// No description provided for @remove_member.
  ///
  /// In en, this message translates to:
  /// **'Remove member'**
  String get remove_member;

  /// No description provided for @add_member.
  ///
  /// In en, this message translates to:
  /// **'Add member'**
  String get add_member;

  /// No description provided for @role_member.
  ///
  /// In en, this message translates to:
  /// **'Member'**
  String get role_member;

  /// No description provided for @role_manager.
  ///
  /// In en, this message translates to:
  /// **'Manager'**
  String get role_manager;

  /// No description provided for @role_admin.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get role_admin;

  /// No description provided for @delete_this_member.
  ///
  /// In en, this message translates to:
  /// **'Delete this member'**
  String get delete_this_member;

  /// No description provided for @add_new_member.
  ///
  /// In en, this message translates to:
  /// **'Add new member'**
  String get add_new_member;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @add_success.
  ///
  /// In en, this message translates to:
  /// **'Added successfully'**
  String get add_success;

  /// No description provided for @confirm_delete.
  ///
  /// In en, this message translates to:
  /// **'Confirm deletion'**
  String get confirm_delete;

  /// No description provided for @confirm_delete_member_message.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete {userName} from the group?'**
  String confirm_delete_member_message(Object userName);

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @delete_member_success.
  ///
  /// In en, this message translates to:
  /// **'Member deleted successfully'**
  String get delete_member_success;

  /// No description provided for @change_role_for_member.
  ///
  /// In en, this message translates to:
  /// **'Change role for {memberName}'**
  String change_role_for_member(Object memberName);

  /// No description provided for @confirm_delete_group.
  ///
  /// In en, this message translates to:
  /// **'Confirm group deletion'**
  String get confirm_delete_group;

  /// No description provided for @confirm_delete_group_message.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete the group? All data will be lost.'**
  String get confirm_delete_group_message;

  /// No description provided for @enter_confirmation_code_to_delete.
  ///
  /// In en, this message translates to:
  /// **'Enter the correct confirmation code below to delete the group:'**
  String get enter_confirmation_code_to_delete;

  /// No description provided for @enter_confirmation_code.
  ///
  /// In en, this message translates to:
  /// **'Enter confirmation code'**
  String get enter_confirmation_code;

  /// No description provided for @invalid_confirmation_code.
  ///
  /// In en, this message translates to:
  /// **'Invalid confirmation code'**
  String get invalid_confirmation_code;

  /// No description provided for @group_deleted_successfully.
  ///
  /// In en, this message translates to:
  /// **'Group deleted successfully'**
  String get group_deleted_successfully;

  /// No description provided for @delete_group.
  ///
  /// In en, this message translates to:
  /// **'Delete group'**
  String get delete_group;

  /// No description provided for @confirm_leave_group.
  ///
  /// In en, this message translates to:
  /// **'Confirm leaving group'**
  String get confirm_leave_group;

  /// No description provided for @confirm_leave_group_message.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to leave the group?'**
  String get confirm_leave_group_message;

  /// No description provided for @enter_confirmation_code_to_leave.
  ///
  /// In en, this message translates to:
  /// **'Enter the correct confirmation code below to leave the group:'**
  String get enter_confirmation_code_to_leave;

  /// No description provided for @leave_group_success.
  ///
  /// In en, this message translates to:
  /// **'You have left the group successfully'**
  String get leave_group_success;

  /// No description provided for @leave_group.
  ///
  /// In en, this message translates to:
  /// **'Leave group'**
  String get leave_group;

  /// No description provided for @total_members.
  ///
  /// In en, this message translates to:
  /// **'Total members'**
  String get total_members;

  /// No description provided for @member_list.
  ///
  /// In en, this message translates to:
  /// **'Member list'**
  String get member_list;

  /// No description provided for @role.
  ///
  /// In en, this message translates to:
  /// **'Role:'**
  String get role;

  /// No description provided for @create_new_task.
  ///
  /// In en, this message translates to:
  /// **'Create new task'**
  String get create_new_task;

  /// No description provided for @title.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get title;

  /// No description provided for @description_label.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description_label;

  /// No description provided for @priority_high.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get priority_high;

  /// No description provided for @priority_medium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get priority_medium;

  /// No description provided for @priority_low.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get priority_low;

  /// No description provided for @priority.
  ///
  /// In en, this message translates to:
  /// **'Priority'**
  String get priority;

  /// No description provided for @no_deadline_selected.
  ///
  /// In en, this message translates to:
  /// **'No deadline selected'**
  String get no_deadline_selected;

  /// No description provided for @deadline.
  ///
  /// In en, this message translates to:
  /// **'Deadline:'**
  String get deadline;

  /// No description provided for @select_deadline.
  ///
  /// In en, this message translates to:
  /// **'Select deadline'**
  String get select_deadline;

  /// No description provided for @create.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// No description provided for @edit_task.
  ///
  /// In en, this message translates to:
  /// **'Edit task'**
  String get edit_task;

  /// No description provided for @task_title.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get task_title;

  /// No description provided for @task_description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get task_description;

  /// No description provided for @task_priority.
  ///
  /// In en, this message translates to:
  /// **'Priority'**
  String get task_priority;

  /// No description provided for @task_assignee.
  ///
  /// In en, this message translates to:
  /// **'Assignee'**
  String get task_assignee;

  /// No description provided for @task_list.
  ///
  /// In en, this message translates to:
  /// **'Task list'**
  String get task_list;

  /// No description provided for @create_new_task_action.
  ///
  /// In en, this message translates to:
  /// **'Create new task'**
  String get create_new_task_action;

  /// No description provided for @no_tasks_found.
  ///
  /// In en, this message translates to:
  /// **'No tasks found.'**
  String get no_tasks_found;

  /// No description provided for @no_title.
  ///
  /// In en, this message translates to:
  /// **'No title'**
  String get no_title;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status:'**
  String get status;

  /// No description provided for @file_uploaded.
  ///
  /// In en, this message translates to:
  /// **'File uploaded'**
  String get file_uploaded;

  /// No description provided for @upload_file.
  ///
  /// In en, this message translates to:
  /// **'Upload file'**
  String get upload_file;

  /// No description provided for @select_file.
  ///
  /// In en, this message translates to:
  /// **'Select file'**
  String get select_file;

  /// No description provided for @file_name_optional.
  ///
  /// In en, this message translates to:
  /// **'File name (optional)'**
  String get file_name_optional;

  /// No description provided for @upload.
  ///
  /// In en, this message translates to:
  /// **'Upload'**
  String get upload;

  /// No description provided for @file_list.
  ///
  /// In en, this message translates to:
  /// **'File list'**
  String get file_list;

  /// No description provided for @no_attachments.
  ///
  /// In en, this message translates to:
  /// **'No attachments yet'**
  String get no_attachments;

  /// No description provided for @type_message_placeholder.
  ///
  /// In en, this message translates to:
  /// **'Type a message...'**
  String get type_message_placeholder;

  /// No description provided for @attachments.
  ///
  /// In en, this message translates to:
  /// **'Attachments'**
  String get attachments;

  /// No description provided for @comment_placeholder.
  ///
  /// In en, this message translates to:
  /// **'Enter a comment...'**
  String get comment_placeholder;

  /// No description provided for @no_comments.
  ///
  /// In en, this message translates to:
  /// **'No comments yet'**
  String get no_comments;

  /// No description provided for @comments.
  ///
  /// In en, this message translates to:
  /// **'Comments'**
  String get comments;

  /// No description provided for @assignee.
  ///
  /// In en, this message translates to:
  /// **'Assignee'**
  String get assignee;

  /// No description provided for @progress.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get progress;

  /// No description provided for @no_description.
  ///
  /// In en, this message translates to:
  /// **'No description'**
  String get no_description;

  /// No description provided for @task_details.
  ///
  /// In en, this message translates to:
  /// **'Task details'**
  String get task_details;

  /// No description provided for @send_comment_failed.
  ///
  /// In en, this message translates to:
  /// **'Failed to send comment'**
  String get send_comment_failed;

  /// No description provided for @storage_permission_denied.
  ///
  /// In en, this message translates to:
  /// **'Storage permission denied'**
  String get storage_permission_denied;

  /// No description provided for @download_start.
  ///
  /// In en, this message translates to:
  /// **'Download started'**
  String get download_start;

  /// No description provided for @downloading.
  ///
  /// In en, this message translates to:
  /// **'Downloading'**
  String get downloading;

  /// No description provided for @download_completed.
  ///
  /// In en, this message translates to:
  /// **'Downloaded'**
  String get download_completed;

  /// No description provided for @download_failed.
  ///
  /// In en, this message translates to:
  /// **'File download failed'**
  String get download_failed;

  /// No description provided for @file_not_found.
  ///
  /// In en, this message translates to:
  /// **'File not found'**
  String get file_not_found;

  /// No description provided for @image_not_displayed.
  ///
  /// In en, this message translates to:
  /// **'Image cannot be displayed'**
  String get image_not_displayed;

  /// No description provided for @file_type_not_supported.
  ///
  /// In en, this message translates to:
  /// **'This file type is not supported for display'**
  String get file_type_not_supported;

  /// Display generic error message with parameter
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String errorMessage(String error);
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'vi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'vi': return AppLocalizationsVi();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
