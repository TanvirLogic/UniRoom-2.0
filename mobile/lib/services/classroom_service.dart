import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/api_constants.dart';
import '../models/classroom_notice_model.dart';
import 'auth_service.dart';

class ClassroomService {
  static final ClassroomService _instance = ClassroomService._internal();
  factory ClassroomService() => _instance;
  ClassroomService._internal();

  final AuthService _authService = AuthService();

  String _cacheKey(String courseCode) =>
      'uniroom_cached_classroom_notices_${courseCode.trim().toUpperCase()}';

  /// Fetch published notices for a course classroom
  Future<List<ClassroomNoticeModel>> fetchNotices({
    required String courseCode,
    String? department,
    String? batch,
    String? section,
  }) async {
    final cleanCode = courseCode.trim().toUpperCase();
    final prefs = await SharedPreferences.getInstance();

    List<ClassroomNoticeModel> cachedNotices = [];
    final cachedStr = prefs.getString(_cacheKey(cleanCode));
    if (cachedStr != null && cachedStr.isNotEmpty) {
      try {
        final List decoded = jsonDecode(cachedStr);
        cachedNotices = decoded
            .map((item) => ClassroomNoticeModel.fromJson(Map<String, dynamic>.from(item)))
            .toList();
      } catch (_) {}
    }

    try {
      final token = await _authService.getAccessToken();
      if (token != null) {
        final queryParams = <String, String>{
          'courseCode': cleanCode,
        };
        if (department != null && department.isNotEmpty) {
          queryParams['department'] = department;
        }
        if (batch != null && batch.isNotEmpty) {
          queryParams['batch'] = batch;
        }
        if (section != null && section.isNotEmpty) {
          queryParams['section'] = section;
        }

        final uri = Uri.parse(ApiConstants.classroomNotices).replace(
          queryParameters: queryParams,
        );

        final response = await http.get(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ).timeout(const Duration(seconds: 10));

        if (response.statusCode >= 200 && response.statusCode < 300) {
          final decoded = jsonDecode(response.body);
          final List list = decoded is Map && decoded.containsKey('data')
              ? decoded['data']
              : (decoded is List ? decoded : []);

          final liveNotices = list
              .map((item) => ClassroomNoticeModel.fromJson(Map<String, dynamic>.from(item)))
              .toList();

          // Persist live notices to local storage for offline view
          await prefs.setString(
            _cacheKey(cleanCode),
            jsonEncode(liveNotices.map((n) => n.toJson()).toList()),
          );

          return liveNotices;
        }
      }
    } catch (e) {
      debugPrint('[ClassroomService] Notice fetch error (falling back to cache): $e');
    }

    return cachedNotices;
  }

  /// Publish a new classroom notice and trigger FCM push alerts
  Future<ClassroomNoticeModel> postNotice({
    required String courseCode,
    required String title,
    required String content,
    String? targetCohort,
    String? department,
    String? batch,
    String? section,
  }) async {
    final token = await _authService.getAccessToken();
    if (token == null) {
      throw Exception('User is not authenticated');
    }

    final body = {
      'courseCode': courseCode.trim().toUpperCase(),
      'title': title.trim(),
      'content': content.trim(),
      if (targetCohort != null) 'targetCohort': targetCohort.trim(),
      if (department != null) 'department': department.trim(),
      if (batch != null) 'batch': batch.trim(),
      if (section != null) 'section': section.trim(),
    };

    final response = await http.post(
      Uri.parse(ApiConstants.classroomNotices),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    ).timeout(const Duration(seconds: 12));

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final decoded = jsonDecode(response.body);
      final data = decoded is Map && decoded.containsKey('data') ? decoded['data'] : decoded;
      final createdNotice = ClassroomNoticeModel.fromJson(Map<String, dynamic>.from(data));

      // Append to local cache
      final prefs = await SharedPreferences.getInstance();
      final existing = await fetchNotices(courseCode: courseCode);
      existing.removeWhere((n) => n.id == createdNotice.id);
      existing.insert(0, createdNotice);
      await prefs.setString(
        _cacheKey(courseCode),
        jsonEncode(existing.map((n) => n.toJson()).toList()),
      );

      return createdNotice;
    } else {
      String errMsg = 'Failed to post notice (${response.statusCode})';
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map && decoded.containsKey('message')) {
          errMsg = decoded['message'].toString();
        }
      } catch (_) {}
      throw Exception(errMsg);
    }
  }

  /// Delete a classroom notice
  Future<bool> deleteNotice(String noticeId, String courseCode) async {
    final token = await _authService.getAccessToken();
    if (token == null) {
      throw Exception('User is not authenticated');
    }

    final response = await http.delete(
      Uri.parse(ApiConstants.classroomNoticeDetail(noticeId)),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode >= 200 && response.statusCode < 300) {
      // Remove from cache
      final prefs = await SharedPreferences.getInstance();
      final existing = await fetchNotices(courseCode: courseCode);
      existing.removeWhere((n) => n.id == noticeId);
      await prefs.setString(
        _cacheKey(courseCode),
        jsonEncode(existing.map((n) => n.toJson()).toList()),
      );
      return true;
    }
    return false;
  }
}
