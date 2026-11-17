import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hrms_test/data/providers/app_providers.dart';
import 'package:hrms_test/features/dashboard/provider/dashboard_provider.dart';
import 'package:hrms_test/features/leave/repositories/leave_repository.dart';

final leaveRepositoryProvider = Provider(
  (ref) => LeaveRepository(
    ref.read(apiProvider),
    ref.read(databaseProvider),
    ref.read(connectivityProvider),
  ),
);
final leaveRequestsProvider = FutureProvider<List<Map<String, dynamic>>>(
  (ref) => ref.read(leaveRepositoryProvider).requests(),
);
final leaveActionsProvider = Provider((ref) => LeaveActions(ref));

class LeaveActions {
  final Ref ref;
  LeaveActions(this.ref);

  Future<void> submit({
    required String type,
    required DateTime start,
    required DateTime end,
    required String reason,
  }) async {
    final balance = await ref.read(leaveBalanceProvider.future);
    final requests = await ref.read(leaveRequestsProvider.future);
    await ref.read(leaveRepositoryProvider).submit(
      type: type,
      start: start,
      end: end,
      reason: reason,
      balance: (balance[type] as num).toInt(),
      existing: requests,
    );
    ref.invalidate(leaveRequestsProvider);
    ref.invalidate(leaveBalanceProvider);
  }
}
