import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hrms_test/core/network/api_client.dart';
import 'package:hrms_test/core/storage/local_database.dart';
import 'package:hrms_test/data/services/connectivity_service.dart';
import 'package:hrms_test/data/services/location_service.dart';
import 'package:hrms_test/features/attendance/repositories/attendance_repository.dart';
import 'package:hrms_test/features/dashboard/model/employee_model.dart';
import 'package:hrms_test/features/dashboard/provider/dashboard_provider.dart';
import 'package:hrms_test/features/dashboard/view/dashboard_screen.dart';
import 'package:hrms_test/features/leave/repositories/leave_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class _TestLocationService extends LocationService {
  @override
  Future<Position> currentPosition() async {
    return Position(
      latitude: 10.0159,
      longitude: 76.3419,
      timestamp: DateTime(2026, 11, 17, 9, 0),
      accuracy: 0,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0,
      isMocked: false,
    );
  }

  @override
  double distance(double lat, double lng, double officeLat, double officeLng) {
    return 0;
  }
}

class _TestConnectivityService extends ConnectivityService {
  final bool online;
  _TestConnectivityService({this.online = true});

  @override
  Future<bool> get isOnline async => online;
}

class _RecordingApiClient extends ApiClient {
  final List<Map<String, dynamic>> posted = [];

  @override
  Future<Map<String, dynamic>> post(
    String path,
    Map<String, dynamic> body,
  ) async {
    posted.add({'path': path, 'body': Map<String, dynamic>.from(body)});
    return {'success': true, 'data': body};
  }
}

EmployeeModel _employee() {
  return const EmployeeModel(
    id: 101,
    name: 'Asif Khan',
    code: 'REBS001',
    department: 'Development',
    latitude: 10.0159,
    longitude: 76.3419,
    radius: 200,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  test('check-out without check-in is rejected', () async {
    final db = LocalDatabase.forTesting();
    final repo = AttendanceRepository(ApiClient(), db, _TestLocationService());

    await expectLater(
      repo.record('check_out', _employee()),
      throwsA(isA<Exception>()),
    );

    final events = await db.events();
    expect(events, isEmpty);
    await db.close();
  });

  test(
    'repeated attendance submission does not create duplicate server records',
    () async {
      final db = LocalDatabase.forTesting();
      final api = _RecordingApiClient();
      final repo = AttendanceRepository(api, db, _TestLocationService());

      await repo.record('check_in', _employee());
      await expectLater(
        repo.record('check_in', _employee()),
        throwsA(isA<Exception>()),
      );

      await repo.sync();
      expect(api.posted, hasLength(1));

      await repo.sync();
      expect(api.posted, hasLength(1));
      await db.close();
    },
  );

  test('pending attendance survives persistence and syncs in order', () async {
    final db = LocalDatabase.forTesting();
    final api = _RecordingApiClient();
    final repo = AttendanceRepository(api, db, _TestLocationService());

    await db.addEvent({
      'event_id': 'evt-1',
      'type': 'check_in',
      'timestamp': '2026-11-17T09:00:00.000',
      'latitude': 10.0159,
      'longitude': 76.3419,
      'sync_status': 'pending',
      'error_message': null,
    });
    await db.addEvent({
      'event_id': 'evt-2',
      'type': 'check_out',
      'timestamp': '2026-11-17T18:00:00.000',
      'latitude': 10.0159,
      'longitude': 76.3419,
      'sync_status': 'pending',
      'error_message': null,
    });

    expect((await db.getPendingSync()), hasLength(2));

    await repo.sync();
    expect(api.posted.map((e) => e['body']['type']).toList(), [
      'check_in',
      'check_out',
    ]);
    await db.close();
  });

  test('overlapping leave dates are rejected', () async {
    final db = LocalDatabase.forTesting();
    final repo = LeaveRepository(
      ApiClient(),
      db,
      _TestConnectivityService(online: true),
    );

    await expectLater(
      repo.submit(
        type: 'casual',
        start: DateTime(2026, 11, 19),
        end: DateTime(2026, 11, 22),
        reason: 'Need personal time off for family business.',
        balance: 5,
        existing: [
          {
            'status': 'pending',
            'start_date': '2026-11-20',
            'end_date': '2026-11-21',
          },
        ],
      ),
      throwsA(isA<Exception>()),
    );
    await db.close();
  });

  testWidgets('dashboard shows pending sync state', (
    WidgetTester tester,
  ) async {
    final employee = _employee();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          employeeProvider.overrideWith(
            (ref) => Future.delayed(
              const Duration(milliseconds: 200),
              () => employee,
            ),
          ),
          pendingSyncCountProvider.overrideWith((ref) => Future.value(3)),
        ],
        child: const MaterialApp(home: DashboardScreen()),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 300));
    expect(find.textContaining('3'), findsWidgets);
  });
}
