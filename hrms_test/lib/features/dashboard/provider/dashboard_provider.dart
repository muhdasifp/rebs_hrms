import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hrms_test/data/providers/app_providers.dart';
import 'package:hrms_test/features/dashboard/model/employee_model.dart';
import 'package:hrms_test/features/dashboard/repository/dashboard_repository.dart';

final dashboardRepositoryProvider = Provider(
  (ref) => DashboardRepository(
    ref.read(firestoreProvider),
    ref.read(databaseProvider),
  ),
);
final employeeProvider = FutureProvider<EmployeeModel>(
  (ref) => ref.read(dashboardRepositoryProvider).employee(),
);
final attendanceHistoryProvider = FutureProvider<List<Map<String, dynamic>>>(
  (ref) => ref.read(dashboardRepositoryProvider).attendance(),
);
final leaveBalanceProvider = FutureProvider<Map<String, dynamic>>(
  (ref) => ref.read(dashboardRepositoryProvider).leaveBalance(),
);
final pendingSyncCountProvider = FutureProvider<int>(
  (ref) => ref.read(databaseProvider).pendingSyncCount(),
);
