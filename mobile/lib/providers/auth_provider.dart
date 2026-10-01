import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../models/registration_options_model.dart';
import '../services/auth_service.dart';

/// Authentication State Provider
/// Uses ChangeNotifier to manage user session, authentication status, and error states.
/// Notifies listening UI widgets whenever state changes occur.
class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  // Internal private state variables
  UserModel? _user;
  bool _isLoading = false;
  String? _errorMessage;
  String? _pendingEmail; // Email stored during OTP verification or password reset

  // Dynamic dropdown options (University -> Department -> Batch -> Section)
  RegistrationOptionsModel? _registrationOptions;
  bool _isLoadingOptions = false;

  // Public getters for UI consumption
  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get pendingEmail => _pendingEmail;
  bool get isAuthenticated => _user != null;

  RegistrationOptionsModel? get registrationOptions => _registrationOptions;
  bool get isLoadingOptions => _isLoadingOptions;

  /// Load registration metadata from backend API
  Future<void> loadRegistrationOptions({bool forceRefresh = false}) async {
    if (_registrationOptions != null && !forceRefresh) return;

    _isLoadingOptions = true;
    notifyListeners();

    try {
      _registrationOptions = await _authService.getRegistrationOptions();
    } catch (_) {
      _registrationOptions ??= RegistrationOptionsModel.fallback();
    } finally {
      _isLoadingOptions = false;
      notifyListeners();
    }
  }

  /// 1. Check existing session on app launch
  Future<void> checkAuthStatus() async {
    _setLoading(true);
    try {
      final savedUser = await _authService.getSavedUser();
      if (savedUser != null) {
        _user = savedUser;
        final freshProfile = await _authService.getProfile();
        if (freshProfile != null) {
          _user = freshProfile;
        }
      }
    } catch (_) {
      _user = null;
    } finally {
      _setLoading(false);
    }
  }

  /// 2. Register a new user
  Future<bool> register({
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
    _setLoading(true);
    _clearError();

    try {
      final res = await _authService.register(
        email: email,
        password: password,
        fullName: fullName,
        universityId: universityId,
        departmentId: departmentId,
        role: role,
        studentId: studentId,
        batch: batch,
        section: section,
        facultyId: facultyId,
      );

      _pendingEmail = res['email'] ?? email.trim().toLowerCase();
      return true;
    } catch (e) {
      _setError(e.toString().replaceAll('Exception: ', ''));
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// 3. Verify Email PIN
  Future<bool> verifyEmail(String pin) async {
    if (_pendingEmail == null) {
      _setError('Verification email not found. Please try again.');
      return false;
    }

    _setLoading(true);
    _clearError();

    try {
      final res = await _authService.verifyEmail(
        email: _pendingEmail!,
        pin: pin,
      );

      if (res['user'] != null) {
        _user = UserModel.fromJson(res['user']);
        _pendingEmail = null;
        return true;
      }
      return false;
    } catch (e) {
      _setError(e.toString().replaceAll('Exception: ', ''));
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// 4. Resend verification PIN
  Future<bool> resendVerificationPin() async {
    if (_pendingEmail == null) return false;

    _setLoading(true);
    _clearError();

    try {
      await _authService.resendVerificationPin(_pendingEmail!);
      return true;
    } catch (e) {
      _setError(e.toString().replaceAll('Exception: ', ''));
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// 5. User Login
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final res = await _authService.login(
        email: email,
        password: password,
      );

      if (res['user'] != null) {
        _user = UserModel.fromJson(res['user']);
        return true;
      }
      return false;
    } catch (e) {
      final msg = e.toString().replaceAll('Exception: ', '');
      if (msg.contains('not been verified yet') || msg.contains('verify')) {
        _pendingEmail = email.trim().toLowerCase();
      }
      _setError(msg);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// 6. Forgot Password Request
  Future<bool> forgotPassword(String email) async {
    _setLoading(true);
    _clearError();

    try {
      await _authService.forgotPassword(email);
      _pendingEmail = email.trim().toLowerCase();
      return true;
    } catch (e) {
      _setError(e.toString().replaceAll('Exception: ', ''));
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// 7. Verify Password Reset PIN
  Future<bool> verifyResetPin(String pin) async {
    if (_pendingEmail == null) return false;

    _setLoading(true);
    _clearError();

    try {
      await _authService.verifyResetPin(
        email: _pendingEmail!,
        pin: pin,
      );
      return true;
    } catch (e) {
      _setError(e.toString().replaceAll('Exception: ', ''));
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// 8. Set New Password
  Future<bool> resetPassword({
    required String pin,
    required String newPassword,
  }) async {
    if (_pendingEmail == null) return false;

    _setLoading(true);
    _clearError();

    try {
      await _authService.resetPassword(
        email: _pendingEmail!,
        pin: pin,
        newPassword: newPassword,
      );
      _pendingEmail = null;
      return true;
    } catch (e) {
      _setError(e.toString().replaceAll('Exception: ', ''));
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Update User Profile & Cohort (Section, Batch, Name, StudentId)
  Future<bool> updateProfile({
    String? fullName,
    String? studentId,
    String? departmentId,
    String? batch,
    String? section,
    String? facultyId,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final updated = await _authService.updateProfile(
        fullName: fullName,
        studentId: studentId,
        departmentId: departmentId,
        batch: batch,
        section: section,
        facultyId: facultyId,
      );
      _user = updated;
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString().replaceAll('Exception: ', ''));
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// 9. Logout
  Future<void> logout() async {
    _setLoading(true);
    await _authService.clearSession();
    _user = null;
    _pendingEmail = null;
    _setLoading(false);
  }

  /// Manually set pending email for OTP flows
  void setPendingEmail(String email) {
    _pendingEmail = email.trim().toLowerCase();
    notifyListeners();
  }

  // ===========================================================================
  // Private State Helpers
  // ===========================================================================
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String msg) {
    _errorMessage = msg;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  /// Clear any active error message
  void clearErrorMessage() {
    _errorMessage = null;
    notifyListeners();
  }
}
