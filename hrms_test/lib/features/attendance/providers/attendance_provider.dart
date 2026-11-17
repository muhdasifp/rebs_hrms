import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hrms_test/data/providers/app_providers.dart';
import 'package:hrms_test/features/attendance/repositories/attendance_repository.dart';
import 'package:hrms_test/features/dashboard/provider/dashboard_provider.dart';

final attendanceRepositoryProvider = Provider(
  (ref) => AttendanceRepository(
    ref.read(apiProvider),
    ref.read(databaseProvider),
    ref.read(locationProvider),
  ),
);
final attendanceEventsProvider = FutureProvider(
  (ref) => ref.read(databaseProvider).events(),
);
final attendanceActionsProvider = Provider((ref) => AttendanceActions(ref));

class AttendanceActions {
  final Ref ref;
  AttendanceActions(this.ref);

  Future<void> record(String type) async {
    final employee = await ref.read(employeeProvider.future);
    await ref.read(attendanceRepositoryProvider).record(type, employee);
    ref.invalidate(attendanceEventsProvider);
  }

  Future<void> syncPending() async {
    await ref.read(attendanceRepositoryProvider).sync();
    ref.invalidate(attendanceEventsProvider);
    ref.invalidate(attendanceHistoryProvider);
    ref.invalidate(pendingSyncCountProvider);
  }
}
