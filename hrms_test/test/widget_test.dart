import 'package:flutter_test/flutter_test.dart';
import 'package:hrms_test/core/storage/local_database.dart';
import 'package:hrms_test/features/dashboard/model/employee_model.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  test('employee model reads Firestore-style office data', () {
    final employee = EmployeeModel.fromJson({
      'id': 'employee-1',
      'name': 'Asif Khan',
      'employee_code': 'REBS001',
      'department': 'Development',
      'office': {
        'latitude': 10.0159,
        'longitude': 76.3419,
        'allowed_radius': 200,
      },
    });

    expect(employee.id, 'employee-1');
    expect(employee.name, 'Asif Khan');
    expect(employee.radius, 200);
  });

  test('pending attendance survives local persistence', () async {
    final db = LocalDatabase.forTesting();

    await db.addEvent({
      'event_id': 'evt-1',
      'type': 'check_in',
      'timestamp': '2026-11-17T09:00:00.000',
      'latitude': 10.0159,
      'longitude': 76.3419,
      'sync_status': 'pending',
      'error_message': null,
    });

    expect(await db.pendingSyncCount(), 1);
    expect((await db.events(status: 'pending')), hasLength(1));

    await db.updateEvent('evt-1', 'synced');
    expect(await db.pendingSyncCount(), 0);
    await db.close();
  });
}
