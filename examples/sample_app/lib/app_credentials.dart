/// Offline credentials holder for the ConvoKit sample app.
class AppCredentials {
  AppCredentials._();

  static const String _defaultAppId = '';
  static const String _defaultRegion = '';
  static const String _defaultAuthKey = '';

  static String _appId = _defaultAppId;
  static String _region = _defaultRegion;
  static String _authKey = _defaultAuthKey;

  static String get appId => _appId;
  static String get region => _region;
  static String get authKey => _authKey;

  static bool get hasValidCredentials =>
      _appId.isNotEmpty && _region.isNotEmpty && _authKey.isNotEmpty;

  static String? get adminHost => null;
  static String? get clientHost => null;

  static Future<void> loadSavedCredentials() async {
    // Offline mode: credentials stay in memory.
  }

  static void setCredentials({
    required String appId,
    required String region,
    required String authKey,
  }) {
    _appId = appId;
    _region = region;
    _authKey = authKey;
  }
}
