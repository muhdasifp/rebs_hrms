import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:hrms_test/core/network/api_client.dart';
import 'package:hrms_test/core/storage/local_database.dart';
import 'package:hrms_test/data/services/connectivity_service.dart';

class LeaveRepository {
  final ApiClient api;
  final LocalDatabase db;
  final ConnectivityService connectivity;

  LeaveRepository(this.api, this.db, this.connectivity);

  Future<List<Map<String, dynamic>>> requests() async {
    try {
      final online = await connectivity.isOnline;
      if (online) {
        final items = List<Map<String, dynamic>>.from(
          (await api.get('/leave/requests'))['data'],
        );
        await db.cache('leave_requests', jsonEncode(items));
        return items;
      } else {
        return _fromLocal();
      }
    } on DioException {
      return _fromLocal();
    }
  }

  Future<List<Map<String, dynamic>>> _fromLocal() async {
    final cached = await db.readCache('leave_requests');
    return cached != null
        ? List<Map<String, dynamic>>.from(jsonDecode(cached))
        : [];
  }

  Future<void> submit({
    required String type,
    required DateTime start,
    required DateTime end,
    required String reason,
    required int balance,
    required List<Map<String, dynamic>> existing,
  }) async {
    final today = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );
    final first = DateTime(start.year, start.month, start.day);
    final last = DateTime(end.year, end.month, end.day);

    if (first.isBefore(today)) {
      throw Exception('Start date cannot be in the past.');
    }
    if (last.isBefore(first)) {
      throw Exception('End date must not precede start date.');
    }

    final nonWs = reason.trim().replaceAll(RegExp(r'\s+'), '');
    if (nonWs.length < 10) {
      throw Exception(
        'Reason must have at least 10 non-whitespace characters.',
      );
    }

    final days = last.difference(first).inDays + 1;
    if (days > balance) {
      throw Exception(
        'Insufficient leave balance ($days requested, $balance available).',
      );
    }

    final from = first.toIso8601String().substring(0, 10);
    final to = last.toIso8601String().substring(0, 10);

    final overlap = existing.any(
      (item) =>
          ['pending', 'approved'].contains(item['status']) &&
          from.compareTo(item['end_date'].toString()) <= 0 &&
          to.compareTo(item['start_date'].toString()) >= 0,
    );
    if (overlap) throw Exception('Leave dates overlap an existing request.');

    if (!await connectivity.isOnline) {
      throw Exception(
        'Leave submission requires an internet connection.',
      );
    }

    try {
      await api.post('/leave/requests', {
        'type': type,
        'start_date': from,
        'end_date': to,
        'reason': reason.trim(),
      });
    } on DioException catch (e) {
      final data = e.response?.data;
      if (e.response?.statusCode == 422 && data != null) {
        final msg = data['message']?.toString() ?? 'Validation failed';
        final errors = data['errors'] as Map<String, dynamic>?;
        if (errors != null && errors.isNotEmpty) {
          final detail = errors.values.first;
          final errMsg = detail is List
              ? detail.first.toString()
              : detail.toString();
          throw Exception('$msg: $errMsg');
        }
        throw Exception(msg);
      }
      rethrow;
    }
  }
}
