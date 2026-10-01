import 'dart:io';
import 'package:flutter/foundation.dart';

/// API Configuration
/// Contains endpoints and base URL mappings for the NestJS backend.
class ApiConstants {
  static const int port = 3000;
  static const String _envApiUrl = String.fromEnvironment('API_URL');

  /// Set your hosted cloud backend URL here when deployed (e.g. Render / Koyeb)
  static const String cloudBaseUrl = 'https://uniroom-2-0.onrender.com/api/v1';

  // Platform-specific base URL resolution:
  // - Hosted Cloud URL: if cloudBaseUrl or --dart-define=API_URL is set
  // - Android with ADB reverse tunnel: 127.0.0.1:3000
  // - Android Emulator: 10.0.2.2:3000
  // - Desktop / Web: localhost:3000
  static String get baseUrl {
    if (_envApiUrl.isNotEmpty) {
      return _envApiUrl;
    }
    if (cloudBaseUrl != null && cloudBaseUrl!.isNotEmpty) {
      return cloudBaseUrl!;
    }
    if (kIsWeb) {
      return 'http://localhost:$port/api/v1';
    } else if (Platform.isAndroid) {
      return 'http://127.0.0.1:$port/api/v1';
    } else {
      return 'http://localhost:$port/api/v1';
    }
  }

  // Auth Endpoints
  static String get register => '$baseUrl/auth/register';
  static String get verifyEmail => '$baseUrl/auth/verify-email';
  static String get resendVerification => '$baseUrl/auth/resend-verification';
  static String get login => '$baseUrl/auth/login';
  static String get refresh => '$baseUrl/auth/refresh';
  static String get forgotPassword => '$baseUrl/auth/forgot-password';
  static String get verifyResetPin => '$baseUrl/auth/verify-reset-pin';
  static String get resetPassword => '$baseUrl/auth/reset-password';
  static String get me => '$baseUrl/auth/me';
  static String get profile => '$baseUrl/auth/profile';

  // Metadata Endpoints
  static String get registrationOptions => '$baseUrl/meta/registration-options';

  // Schedules Endpoints
  static String get schedules => '$baseUrl/schedules';

  // Physical Rooms Endpoints
  static String get rooms => '$baseUrl/rooms';
  static String get freeRoomsNow => '$baseUrl/rooms/free-now';
  static String roomStatus(String roomId) => '$baseUrl/rooms/$roomId/status';

  // Schedule Overrides (Cancel / Reschedule for Today)
  static String cancelSlotToday(String slotId) => '$baseUrl/schedules/slots/$slotId/cancel-today';
  static String rescheduleSlotToday(String slotId) => '$baseUrl/schedules/slots/$slotId/reschedule-today';
  static String undoSlotOverrideToday(String slotId) => '$baseUrl/schedules/slots/$slotId/override-today';
}
