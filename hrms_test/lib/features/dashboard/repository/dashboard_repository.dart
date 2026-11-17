import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:hrms_test/core/network/api_client.dart';
import 'package:hrms_test/core/storage/local_database.dart';
import 'package:hrms_test/features/dashboard/model/employee_model.dart';

class DashboardRepository {
  final ApiClient api;
  final LocalDatabase db;
  DashboardRepository(this.api, this.db);

  Future<EmployeeModel> employee() async {
    try {
      final data = (await api.get('/employee/me'))['data'];
      await db.cache('employee', jsonEncode(data));
      return EmployeeModel.fromJson(Map<String, dynamic>.from(data));
    } on DioException {
      final value = await db.readCache('employee');
      if (value == null) rethrow;
      return EmployeeModel.fromJson(jsonDecode(value));
    }
  }

  Future<List<Map<String, dynamic>>> attendance() async {
    final month = DateTime.now().toIso8601String().substring(0, 7);
    try {
      final data = List<Map<String, dynamic>>.from(
        (await api.get('/attendance', query: {'month': month}))['data'],
      );
      await db.cache('attendance_$month', jsonEncode(data));
      return data;
    } on DioException {
      final value = await db.readCache('attendance_$month');
      if (value == null) rethrow;
      return List<Map<String, dynamic>>.from(jsonDecode(value));
    }
  }

  Future<Map<String, dynamic>> leaveBalance() async {
    try {
      final data = Map<String, dynamic>.from(
        (await api.get('/leave/balance'))['data'],
      );
      await db.cache('leave_balance', jsonEncode(data));
      return data;
    } on DioException {
      final value = await db.readCache('leave_balance');
      if (value == null) rethrow;
      return Map<String, dynamic>.from(jsonDecode(value));
    }
  }
}
