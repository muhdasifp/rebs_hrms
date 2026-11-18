import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hrms_test/core/storage/local_database.dart';
import 'package:hrms_test/features/dashboard/model/employee_model.dart';

class DashboardRepository {
  final FirebaseFirestore firestore;
  final LocalDatabase db;

  DashboardRepository(this.firestore, this.db);

  Future<EmployeeModel> employee() async {
    try {
      final snapshot = await firestore.collection('employees').limit(1).get();
      if (snapshot.docs.isEmpty) {
        throw Exception('No employee found in Firebase.');
      }
      final data = {
        ...snapshot.docs.first.data(),
        'id': snapshot.docs.first.id,
      };
      await db.cache('employee', jsonEncode(data));
      return EmployeeModel.fromJson(data);
    } catch (_) {
      final value = await db.readCache('employee');
      if (value == null) rethrow;
      return EmployeeModel.fromJson(jsonDecode(value));
    }
  }

  Future<List<Map<String, dynamic>>> attendance() async {
    final month = DateTime.now().toIso8601String().substring(0, 7);
    try {
      final snapshot = await firestore
          .collection('attendance')
          .where('date', isGreaterThanOrEqualTo: '$month-01')
          .where('date', isLessThan: _nextMonth(month))
          .orderBy('date')
          .get();
      final data = snapshot.docs.map((doc) {
        final value = doc.data();
        value['id'] = doc.id;
        return value;
      }).toList();
      await db.cache('attendance_$month', jsonEncode(data));
      return data;
    } catch (_) {
      final value = await db.readCache('attendance_$month');
      if (value == null) rethrow;
      return List<Map<String, dynamic>>.from(jsonDecode(value));
    }
  }

  Future<Map<String, dynamic>> leaveBalance() async {
    try {
      final snapshot = await firestore
          .collection('leave_balances')
          .limit(1)
          .get();
      if (snapshot.docs.isEmpty) {
        throw Exception('Leave balance not configured in Firebase.');
      }
      final data = snapshot.docs.first.data();
      await db.cache('leave_balance', jsonEncode(data));
      return data;
    } catch (_) {
      final value = await db.readCache('leave_balance');
      if (value == null) rethrow;
      return Map<String, dynamic>.from(jsonDecode(value));
    }
  }

  String _nextMonth(String month) {
    final parts = month.split('-');
    final date = DateTime(int.parse(parts[0]), int.parse(parts[1]) + 1, 1);
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-01';
  }
}
