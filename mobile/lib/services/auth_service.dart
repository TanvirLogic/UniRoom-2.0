import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/api_constants.dart';
import '../models/user_model.dart';
import '../models/registration_options_model.dart';

/// Authentication Service
/// Handles network HTTP requests (GET, POST) to the NestJS backend
/// and securely persists auth tokens and session data in SharedPreferences.
class AuthService {
  // Keys used for local persistent storage in SharedPreferences
  static const String _keyAccessToken = 'auth_access_token';
  static const String _keyRefreshToken = 'auth_refresh_token';
  static const String _keyUserData = 'auth_user_data';

  /// 1. Register a new user account
  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String fullName,
    required String universityId,
    required String departmentId,
    required String role,
    String? studentId,
    String? batch,
    String? section,
    String? facultyId,
  }) async {
    final url = Uri.parse(ApiConstants.register);

    final body = {
      'email': email.trim().toLowerCase(),
      'password': password,
      'fullName': fullName.trim(),
      'universityId': universityId,
      'departmentId': departmentId,
      'role': role,
      if (studentId != null && studentId.trim().isNotEmpty) 'studentId': studentId.trim(),
      if (batch != null && batch.trim().isNotEmpty) 'batch': batch.trim(),
      if (section != null && section.trim().isNotEmpty) 'section': section.trim().toUpperCase(),
      if (facultyId != null && facultyId.trim().isNotEmpty) 'facultyId': facultyId.trim().toUpperCase(),
    };

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    return _handleResponse(response);
  }

  /// 2. Verify Email via 6-digit PIN
  Future<Map<String, dynamic>> verifyEmail({
    required String email,
    required String pin,
  }) async {
    final url = Uri.parse(ApiConstants.verifyEmail);

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email.trim().toLowerCase(),
        'pin': pin.trim(),
      }),
    );

    final data = _handleResponse(response);

    // Save user session upon successful email verification
    if (data['accessToken'] != null && data['user'] != null) {
      final user = UserModel.fromJson(data['user']);
      await saveSession(
        accessToken: data['accessToken'],
        refreshToken: data['refreshToken'] ?? '',
        user: user,
      );
    }

    return data;
  }

  /// 3. Request a new verification PIN (Resend PIN)
  Future<Map<String, dynamic>> resendVerificationPin(String email) async {
    final url = Uri.parse(ApiConstants.resendVerification);

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email.trim().toLowerCase()}),
    );

    return _handleResponse(response);
  }

  /// 4. Authenticate / Login user
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final url = Uri.parse(ApiConstants.login);

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email.trim().toLowerCase(),
        'password': password,
      }),
    );

    final data = _handleResponse(response);

    // Save tokens and user profile upon successful login
    if (data['accessToken'] != null && data['user'] != null) {
      final user = UserModel.fromJson(data['user']);
      await saveSession(
        accessToken: data['accessToken'],
        refreshToken: data['refreshToken'] ?? '',
        user: user,
      );
    }

    return data;
  }

  /// 5. Request password reset PIN
  Future<Map<String, dynamic>> forgotPassword(String email) async {
    final url = Uri.parse(ApiConstants.forgotPassword);

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email.trim().toLowerCase()}),
    );

    return _handleResponse(response);
  }

  /// 6. Validate password reset PIN
  Future<Map<String, dynamic>> verifyResetPin({
    required String email,
    required String pin,
  }) async {
    final url = Uri.parse(ApiConstants.verifyResetPin);

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email.trim().toLowerCase(),
        'pin': pin.trim(),
      }),
    );

    return _handleResponse(response);
  }

  /// 7. Set new password with valid reset PIN
  Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String pin,
    required String newPassword,
  }) async {
    final url = Uri.parse(ApiConstants.resetPassword);

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email.trim().toLowerCase(),
        'pin': pin.trim(),
        'newPassword': newPassword,
      }),
    );

    return _handleResponse(response);
  }

  /// 8. Fetch current authenticated profile (/me)
  Future<UserModel?> getProfile() async {
    var token = await getAccessToken();
    if (token == null) return null;

    final url = Uri.parse(ApiConstants.me);
    var response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 401) {
      final freshToken = await refreshToken();
      if (freshToken != null) {
        response = await http.get(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $freshToken',
          },
        );
      }
    }

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      final rawData = decoded is Map<String, dynamic> && decoded.containsKey('data')
          ? decoded['data']
          : decoded;
      final user = UserModel.fromJson(rawData);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyUserData, jsonEncode(user.toJson()));
      return user;
    }
    return null;
  }

  /// 9. Fetch dynamic registration options (Universities, Departments, Batches, Sections)
  Future<RegistrationOptionsModel> getRegistrationOptions() async {
    try {
      final url = Uri.parse(ApiConstants.registrationOptions);
      final response = await http.get(
        url,
        headers: {'Content-Type': 'application/json'},
      );

      final data = _handleResponse(response);
      return RegistrationOptionsModel.fromJson(data);
    } catch (_) {
      // Return local fallback on network failure or offline state
      return RegistrationOptionsModel.fallback();
    }
  }

  // ===========================================================================
  // Local Session & Storage Helpers
  // ===========================================================================

  /// Persist session tokens and user data in local storage
  Future<void> saveSession({
    required String accessToken,
    required String refreshToken,
    required UserModel user,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyAccessToken, accessToken);
    await prefs.setString(_keyRefreshToken, refreshToken);
    await prefs.setString(_keyUserData, jsonEncode(user.toJson()));
  }

  /// Update User Academic Profile (Section, Batch, Name, StudentId)
  Future<UserModel> updateProfile({
    String? fullName,
    String? studentId,
    String? departmentId,
    String? batch,
    String? section,
    String? facultyId,
  }) async {
    var token = await getAccessToken();
    if (token == null) throw Exception('Authentication token missing. Please log in.');

    final url = Uri.parse(ApiConstants.profile);
    final body = {
      if (fullName != null && fullName.trim().isNotEmpty) 'fullName': fullName.trim(),
      if (studentId != null && studentId.trim().isNotEmpty) 'studentId': studentId.trim(),
      if (departmentId != null && departmentId.trim().isNotEmpty) 'departmentId': departmentId.trim(),
      if (batch != null && batch.trim().isNotEmpty) 'batch': batch.trim(),
      if (section != null && section.trim().isNotEmpty) 'section': section.trim().toUpperCase(),
      if (facultyId != null && facultyId.trim().isNotEmpty) 'facultyId': facultyId.trim().toUpperCase(),
    };

    var response = await http.patch(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode == 401) {
      final freshToken = await refreshToken();
      if (freshToken != null) {
        response = await http.patch(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $freshToken',
          },
          body: jsonEncode(body),
        );
      }
    }

    final data = _handleResponse(response);
    final updatedUser = UserModel.fromJson(data);

    // Update local persistent user data
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUserData, jsonEncode(updatedUser.toJson()));

    return updatedUser;
  }

  /// Check if a JWT token is expired or close to expiring (within 60 seconds)
  static bool isTokenExpired(String? token) {
    if (token == null || token.isEmpty) return true;
    try {
      final parts = token.split('.');
      if (parts.length != 3) return true;
      String payload = parts[1];
      switch (payload.length % 4) {
        case 2:
          payload += '==';
          break;
        case 3:
          payload += '=';
          break;
      }
      final decodedBytes = base64Url.decode(payload);
      final decodedString = utf8.decode(decodedBytes);
      final map = jsonDecode(decodedString);
      if (map is Map<String, dynamic> && map.containsKey('exp')) {
        final exp = map['exp'] as int;
        final expiryDate = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
        return DateTime.now().isAfter(expiryDate.subtract(const Duration(seconds: 60)));
      }
      return false;
    } catch (_) {
      return true;
    }
  }

  Future<String?>? _refreshFuture;

  /// Exchange stored refresh token for a fresh token pair
  Future<String?> refreshToken() async {
    if (_refreshFuture != null) {
      return _refreshFuture;
    }
    _refreshFuture = _performTokenRefresh();
    try {
      return await _refreshFuture;
    } finally {
      _refreshFuture = null;
    }
  }

  Future<String?> _performTokenRefresh() async {
    final prefs = await SharedPreferences.getInstance();
    final currentRefreshToken = prefs.getString(_keyRefreshToken);
    if (currentRefreshToken == null || currentRefreshToken.isEmpty) {
      return null;
    }

    try {
      final url = Uri.parse(ApiConstants.refresh);
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': currentRefreshToken}),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(response.body);
        final rawData = decoded is Map<String, dynamic> && decoded.containsKey('data')
            ? decoded['data']
            : decoded;

        if (rawData is Map<String, dynamic> && rawData.containsKey('accessToken')) {
          final newAccessToken = rawData['accessToken'] as String;
          await prefs.setString(_keyAccessToken, newAccessToken);

          if (rawData.containsKey('refreshToken') && rawData['refreshToken'] != null) {
            await prefs.setString(_keyRefreshToken, rawData['refreshToken'] as String);
          }
          if (rawData.containsKey('user') && rawData['user'] is Map<String, dynamic>) {
            await prefs.setString(_keyUserData, jsonEncode(rawData['user']));
          }
          return newAccessToken;
        }
      }
    } catch (_) {
      // Network or parsing error during refresh
    }
    return null;
  }

  /// Retrieve stored JWT access token, automatically refreshing if expired
  Future<String?> getAccessToken({bool forceRefresh = false}) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_keyAccessToken);

    if (forceRefresh || token == null || isTokenExpired(token)) {
      final freshToken = await refreshToken();
      if (freshToken != null) {
        return freshToken;
      }
    }

    return prefs.getString(_keyAccessToken);
  }

  /// Retrieve stored user profile
  Future<UserModel?> getSavedUser() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_keyUserData);
    if (jsonStr == null) return null;
    try {
      final map = jsonDecode(jsonStr);
      return UserModel.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  /// Clear all local session tokens (Logout)
  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyAccessToken);
    await prefs.remove(_keyRefreshToken);
    await prefs.remove(_keyUserData);
  }

  // ===========================================================================
  // HTTP Response Handler
  // ===========================================================================
  Map<String, dynamic> _handleResponse(http.Response response) {
    Map<String, dynamic> body = {};
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        body = decoded;
      }
    } catch (_) {
      throw Exception('Invalid server response (Status: ${response.statusCode})');
    }

    // Unpack data if wrapped by backend TransformInterceptor
    final payload = body.containsKey('data') && body['data'] is Map<String, dynamic>
        ? body['data'] as Map<String, dynamic>
        : body;

    // Success response (HTTP 200 or 201)
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return payload;
    }

    // Error response extraction
    String errorMsg = 'An unexpected error occurred. Please try again.';
    if (body['message'] != null) {
      if (body['message'] is List) {
        errorMsg = (body['message'] as List).join(', ');
      } else {
        errorMsg = body['message'].toString();
      }
    } else if (body['error'] != null) {
      errorMsg = body['error'].toString();
    }

    throw Exception(errorMsg);
  }
}
