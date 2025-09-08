// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class AppLocalizationsVi extends AppLocalizations {
  AppLocalizationsVi([String locale = 'vi']) : super(locale);

  @override
  String get appTitle => 'Ứng dụng Teamwork';

  @override
  String get welcome => 'Chào mừng';

  @override
  String get settings => 'Cài đặt';

  @override
  String get login => 'Đăng nhập';

  @override
  String get logout => 'Đăng xuất';

  @override
  String get register => 'Đăng ký';

  @override
  String get email => 'Email';

  @override
  String get password => 'Mật khẩu';

  @override
  String get name => 'Họ và tên';

  @override
  String get confirmPassword => 'Xác nhận mật khẩu';

  @override
  String get rememberPassword => 'Nhớ mật khẩu';

  @override
  String get authPromptSignUp => 'Chưa có tài khoản? Đăng ký';

  @override
  String get authPromptSignIn => 'Đã có tài khoản? Đăng nhập';

  @override
  String get confirm => 'Xác nhận';

  @override
  String get theme => 'Giao diện';

  @override
  String get darkMode => 'Chế độ tối';

  @override
  String get fontSize => 'Kích thước chữ';

  @override
  String get language => 'Ngôn ngữ';

  @override
  String get english => 'Tiếng Anh';

  @override
  String get vietnamese => 'Tiếng Việt';

  @override
  String get loginSuccess => 'Đăng nhập thành công!';

  @override
  String get loginFailed => 'Email hoặc mật khẩu không đúng!';

  @override
  String get registerSuccess => 'Đăng ký thành công!';

  @override
  String get nameRequired => 'Vui lòng nhập tên';

  @override
  String get emailRequired => 'Vui lòng nhập email';

  @override
  String get passwordRequired => 'Vui lòng nhập mật khẩu';

  @override
  String get passwordMismatch => 'Mật khẩu không khớp';

  @override
  String get emailExists => 'Email đã tồn tại!';

  @override
  String get updateSuccessMessage => 'Cập nhật thông tin thành công!';

  @override
  String get completeProfile => 'Hoàn tất thông tin cá nhân';

  @override
  String get displayName => 'Tên hiển thị';

  @override
  String get systemTheme => 'Hệ thống';

  @override
  String get lightTheme => 'Sáng';

  @override
  String get darkTheme => 'Tối';

  @override
  String errorMessage(String error) {
    return 'Lỗi: $error';
  }
}
