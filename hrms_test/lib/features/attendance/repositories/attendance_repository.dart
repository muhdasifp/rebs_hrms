import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hrms_test/core/storage/local_database.dart';
import 'package:hrms_test/data/services/location_service.dart';
import 'package:hrms_test/features/dashboard/model/employee_model.dart';
import 'package:uuid/uuid.dart';

class AttendanceRepository {
  final FirebaseFirestore firestore;
  final LocalDatabase db;
  final LocationService location;

  AttendanceRepository(this.firestore, this.db, this.location);

  Future<void> record(String type, EmployeeModel employee) async {
    if (type != 'check_in' && type != 'check_out') {
      throw Exception('Invalid attendance event.');
    }

    final position = await location.currentPosition();
    final distance = location.distance(
      position.latitude,
      position.longitude,
      employee.latitude,
      employee.longitude,
    );
    if (distance > employee.radius) {
      throw Exception(
        'You are ${distance.toStringAsFixed(0)} metres from office. '
        'Allowed radius: ${employee.radius.toInt()} metres.',
      );
    }

    final now = DateTime.now();
    final date = now.toIso8601String().substring(0, 10);
    final checkedIn = await db.hasEvent(date, 'check_in');
    final checkedOut = await db.hasEvent(date, 'check_out');

    if (type == 'check_in' && checkedIn) {
      throw Exception('Already checked in today.');
    }
    if (type == 'check_out' && !checkedIn) {
      throw Exception('Check in before check out.');
    }
    if (type == 'check_out' && checkedOut) {
      throw Exception('Already checked out today.');
    }

    await db.addEvent({
      'event_id': const Uuid().v4(),
      'type': type,
      'timestamp': now.toIso8601String(),
      'latitude': position.latitude,
      'longitude': position.longitude,
      'sync_status': 'pending',
      'error_message': null,
    });
  }

  Future<void> sync() async {
    final pending = await db.events(status: 'pending');
    for (final event in pending) {
      final id = event['event_id'] as String;
      try {
        await firestore.collection('attendance_events').doc(id).set({
          'event_id': id,
          'type': event['type'],
          'timestamp': event['timestamp'],
          'latitude': event['latitude'],
          'longitude': event['longitude'],
        });
        await db.updateEvent(id, 'synced');
      } on FirebaseException catch (e) {
        await db.updateEvent(
          id,
          'rejected',
          e.message ?? 'Rejected by Firebase',
        );
      } catch (_) {
        break;
      }
    }
  }
}
