class AppConstants {
  static String _ngrokId = "b5e012b7cce2";

  static String get ngrokId => _ngrokId;

  static void setNgrokId(String id) {
    _ngrokId = id;
  }

  static String get apiBaseUrl => "https://$_ngrokId.ngrok-free.app";
}
