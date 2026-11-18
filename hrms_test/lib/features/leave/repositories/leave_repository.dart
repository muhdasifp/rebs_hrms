import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hrms_test/core/storage/local_database.dart';

class LeaveRepository {
  final FirebaseFirestore firestore;
  final LocalDatabase db;

  LeaveRepository(this.firestore, this.db);

  Future<List<Map<String, dynamic>>> requests() async {
    try {
      final snapshot = await firestore
          .collection('leave_requests')
          .orderBy('created_at', descending: true)
          .get();
      final items = snapshot.docs.map((doc) {
        final data = Map<String, dynamic>.from(doc.data());
        final createdAt = data['created_at'];
        if (createdAt is Timestamp) {
          data['created_at'] = createdAt.toDate().toIso8601String();
        } else if (createdAt != null) {
          data['created_at'] = createdAt.toString();
        }
        return {...data, 'request_id': doc.id};
      }).toList();
      await db.cache('leave_requests', jsonEncode(items));
      return items;
    } catch (_) {
      final cached = await db.readCache('leave_requests');
      return cached == null
          ? []
          : List<Map<String, dynamic>>.from(jsonDecode(cached));
    }
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

    await firestore.collection('leave_requests').add({
      'type': type,
      'start_date': from,
      'end_date': to,
      'reason': reason.trim(),
      'days': days,
      'status': 'pending',
      'created_at': FieldValue.serverTimestamp(),
    });
  }
}
