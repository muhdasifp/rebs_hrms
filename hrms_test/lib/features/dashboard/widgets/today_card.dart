import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hrms_test/core/theme/app_colors.dart';
import 'package:hrms_test/features/attendance/providers/attendance_provider.dart';
import 'package:intl/intl.dart';

class TodayCard extends ConsumerWidget {
  const TodayCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(attendanceEventsProvider);

    return eventsAsync.when(
      loading: () => _CardShell(
        child: const Center(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: CircularProgressIndicator(),
          ),
        ),
      ),
      error: (_, __) => _CardShell(
        child: const Padding(
          padding: EdgeInsets.all(20),
          child: Text(
            'Could not load attendance',
            style: TextStyle(color: AppColors.text2),
          ),
        ),
      ),
      data: (events) {
        final today = DateTime.now().toIso8601String().substring(0, 10);
        final todayEvents = events
            .where(
              (e) =>
                  (e['timestamp'] as String).startsWith(today) &&
                  (e['sync_status'] as String) != 'rejected',
            )
            .toList();

        final checkInEvt = todayEvents
            .where((e) => e['type'] == 'check_in')
            .firstOrNull;
        final checkOutEvt = todayEvents
            .where((e) => e['type'] == 'check_out')
            .firstOrNull;

        final String statusLabel;
        final Color statusColor, statusSoft;
        if (checkOutEvt != null) {
          statusLabel = 'Checked Out';
          statusColor = AppColors.accent;
          statusSoft = AppColors.accentSoft;
        } else if (checkInEvt != null) {
          statusLabel = 'Checked In';
          statusColor = AppColors.success;
          statusSoft = AppColors.successSoft;
        } else {
          statusLabel = 'Not Checked In';
          statusColor = AppColors.warning;
          statusSoft = AppColors.warningSoft;
        }

        final checkInTime = checkInEvt != null
            ? DateTime.parse(checkInEvt['timestamp'] as String)
            : null;
        final checkOutTime = checkOutEvt != null
            ? DateTime.parse(checkOutEvt['timestamp'] as String)
            : null;
        final isPending = (checkInEvt?['sync_status'] as String?) == 'pending';

        return _CardShell(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Today's Attendance",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.2,
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isPending)
                          Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: Tooltip(
                              message: 'Pending sync',
                              child: Icon(
                                Icons.cloud_upload_outlined,
                                size: 14,
                                color: AppColors.warning,
                              ),
                            ),
                          ),
                        _Badge(
                          label: statusLabel,
                          color: statusColor,
                          soft: statusSoft,
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    _Metric(
                      label: 'Check-in',
                      value: checkInTime != null
                          ? DateFormat('h:mm a').format(checkInTime)
                          : '—',
                      icon: Icons.login_rounded,
                    ),
                    _Metric(
                      label: 'Check-out',
                      value: checkOutTime != null
                          ? DateFormat('h:mm a').format(checkOutTime)
                          : '—',
                      icon: Icons.logout_rounded,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CardShell extends StatelessWidget {
  final Widget child;
  const _CardShell({required this.child});
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: child,
    );
  }
}

class _Metric extends StatelessWidget {
  final String label, value;
  final IconData icon;
  const _Metric({required this.label, required this.value, required this.icon});
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.text3,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(icon, size: 15, color: AppColors.text2),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  value,
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.2,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color, soft;
  const _Badge({required this.label, required this.color, required this.soft});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: soft,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }
}
