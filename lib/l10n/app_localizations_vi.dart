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
  String get avatar => 'Ảnh đại diện';

  @override
  String get passwordHint => 'Nên có chữ hoa, chữ thường, số và ký tự đặc biệt';

  @override
  String get confirmPassword => 'Xác nhận mật khẩu';

  @override
  String get rememberPassword => 'Nhớ mật khẩu';

  @override
  String get authPromptSignUp => 'Chưa có tài khoản? Đăng ký';

  @override
  String get authPromptSignIn => 'Đã có tài khoản? Đăng nhập';

  @override
  String get invalidEmail => 'Email không hợp lệ';

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
  String get setDefault => 'Đặt lại mặc định';

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
  String get updateSuccessMessage => 'Cập nhật thành công!';

  @override
  String get updatePasswordSuccess => 'Cập nhật mật khẩu thành công!';

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
  String get editProfile => 'Chính sửa thông tin';

  @override
  String get passwordWeak => 'Mật khẩu quá yếu. Vui lòng nhập mật khẩu mạnh hơn.';

  @override
  String get notLoggedIn => 'Bạn chưa đăng nhập';

  @override
  String get weak => 'Yếu';

  @override
  String get medium => 'Trung bình';

  @override
  String get strong => 'Mạnh';

  @override
  String get chooseAvatar => 'Chọn\nảnh\nđại diện';

  @override
  String get phone => 'Số điện thoại';

  @override
  String get address => 'Địa chỉ';

  @override
  String get dob => 'Ngày tháng năm sinh';

  @override
  String get job => 'Chức vụ / Nghề nghiệp';

  @override
  String get oldPassword => 'Mật khẩu cũ';

  @override
  String get newPassword => 'Mật khẩu mới';

  @override
  String get confirmNewPassword => 'Nhập lại mật khẩu mới';

  @override
  String get changePassword => 'Đổi mật khẩu';

  @override
  String get cannotLoadUserInfo => 'Không thể tải thông tin người dùng';

  @override
  String get save => 'Lưu';

  @override
  String get loading => 'Đang tải...';

  @override
  String get createdBy => 'Tạo bởi';

  @override
  String get task => 'Nhiệm vụ';

  @override
  String get files => 'Tài liệu';

  @override
  String get information => 'Thông tin';

  @override
  String get notification => 'Thông báo';

  @override
  String get close => 'Đóng';

  @override
  String get message => 'Tin nhắn';

  @override
  String get group_name_cannot_be_empty => 'Tên nhóm không được để trống';

  @override
  String get group_created_successfully => 'Tạo nhóm thành công';

  @override
  String get group_name => 'Tên nhóm *';

  @override
  String get description_optional => 'Mô tả (có thể bỏ trống)';

  @override
  String get create_group => 'Tạo Nhóm';

  @override
  String get group_list => 'Danh sách nhóm';

  @override
  String get create_new_group => 'Tạo nhóm mới';

  @override
  String get members => 'thành viên';

  @override
  String get editGroup => 'Chỉnh sửa nhóm';

  @override
  String get manageMembers => 'Quản lý thành viên';

  @override
  String get pinGroup => 'Ghim nhóm';

  @override
  String get deleteGroup => 'Xóa nhóm';

  @override
  String get memberList => 'Danh sách thành viên';

  @override
  String get leaveGroup => 'Rời nhóm';

  @override
  String errorMessage(String error) {
    return 'Lỗi: $error';
  }
}
