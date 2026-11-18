import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hrms_test/core/theme/app_colors.dart';
import 'package:hrms_test/data/services/location_service.dart';
import 'package:hrms_test/features/attendance/providers/attendance_provider.dart';
import 'package:hrms_test/features/dashboard/provider/dashboard_provider.dart';
import 'package:intl/intl.dart';

class AttendanceScreen extends ConsumerStatefulWidget {
  const AttendanceScreen({super.key});

  @override
  ConsumerState<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends ConsumerState<AttendanceScreen> {
  bool _isProcessing = false;
  bool _isSyncing = false;
  final LocationService _locationService = LocationService();

  Future<void> _onAction(String type) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    try {
      await ref.read(attendanceActionsProvider).record(type);
      ref.invalidate(attendanceEventsProvider);
      ref.invalidate(pendingSyncCountProvider);
      if (!mounted) return;
      _showSnack(
        type == 'check_in'
            ? 'Checked in successfully'
            : 'Checked out successfully',
        type == 'check_in' ? AppColors.success : AppColors.accent,
      );
    } catch (e) {
      if (!mounted) return;
      await _handleAttendanceException(e, type);
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _handleAttendanceException(Object error, String type) async {
    String title = 'Attendance Failed';
    String message = error.toString().replaceFirst('Exception: ', '');
    String? actionText;
    VoidCallback? onAction;

    if (error is LocationServiceDisabledException) {
      title = 'GPS Disabled';
      message =
          'Your device location is turned off. '
          'Please enable GPS to mark attendance.';

      actionText = 'Open Location Settings';

      onAction = () async {
        Navigator.pop(context);
        await _locationService.openLocationSettings();
      };
    } else if (error is LocationPermissionDeniedException) {
      title = 'Location Permission Required';
      message =
          'Location permission is required to mark attendance. '
          'Please allow location access.';

      actionText = 'Try Again';

      onAction = () {
        Navigator.pop(context);
        _onAction(type);
      };
    } else if (error is LocationPermissionPermanentlyDeniedException) {
      title = 'Permission Permanently Denied';
      message =
          'Location permission has been permanently denied. '
          'Please enable it from app settings.';

      actionText = 'Open App Settings';

      onAction = () async {
        Navigator.pop(context);
        await _locationService.openAppSettings();
      };
    } else if (error is LocationPermissionUnavailableException) {
      title = 'Location Permission Unavailable';
      message =
          'Unable to determine location permission status. '
          'Please check your device settings.';
    } else if (error is LocationTimeoutException) {
      title = 'Location Timeout';
      message =
          'Unable to get your current location. '
          'Please check your GPS and try again.';

      actionText = 'Retry';

      onAction = () {
        Navigator.pop(context);
        _onAction(type);
      };
    } else if (error is LocationFetchException) {
      title = 'Location Error';
      message = error.toString();
    }

    if (!mounted) return;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: AppColors.text,
          ),
        ),
        content: Text(
          message,
          style: const TextStyle(color: AppColors.text2, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.text3),
            ),
          ),
          if (actionText != null)
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
              ),
              onPressed: onAction == null ? null : () => onAction!(),
              child: Text(actionText),
            ),
        ],
      ),
    );
  }

  Future<void> _onSync() async {
    if (_isSyncing) return;
    setState(() => _isSyncing = true);
    try {
      await ref.read(attendanceActionsProvider).syncPending();
      ref.invalidate(attendanceEventsProvider);
      ref.invalidate(pendingSyncCountProvider);
      ref.invalidate(attendanceHistoryProvider);
      if (!mounted) return;
      _showSnack('Sync complete', AppColors.success);
    } catch (e) {
      if (!mounted) return;
      _showError(
        'Sync failed: ${e.toString().replaceFirst('Exception: ', '')}',
      );
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }
  }

  void _showSnack(String msg, Color bg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w500)),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        backgroundColor: bg,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showError(String msg) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Action Failed',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        content: Text(msg, style: const TextStyle(color: AppColors.text2)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: AppColors.accent)),
          ),
        ],
      ),
    );
  }

  String _duration(DateTime? checkIn, DateTime? checkOut) {
    if (checkIn == null) return '—';
    final end = checkOut ?? DateTime.now();
    final d = end.difference(checkIn);
    return '${d.inHours}h ${d.inMinutes.remainder(60).toString().padLeft(2, '0')}m';
  }

  @override
  Widget build(BuildContext context) {
    final eventsAsync = ref.watch(attendanceEventsProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          'Attendance',
          style: TextStyle(
            color: AppColors.text,
            fontSize: 18,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.3,
          ),
        ),
        actions: [
          IconButton(
            icon: _isSyncing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.accent,
                    ),
                  )
                : const Icon(Icons.sync_rounded, color: AppColors.text2),
            tooltip: 'Sync Now',
            onPressed: _isSyncing ? null : _onSync,
          ),
        ],
      ),
      body: eventsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text(
            e.toString(),
            style: const TextStyle(color: AppColors.text2),
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

          final checkInEvt = todayEvents.isEmpty
              ? null
              : todayEvents.firstWhere(
                  (e) => e['type'] == 'check_in',
                  orElse: () => <String, dynamic>{},
                );
          final checkOutEvt = todayEvents.isEmpty
              ? null
              : todayEvents.firstWhere(
                  (e) => e['type'] == 'check_out',
                  orElse: () => <String, dynamic>{},
                );

          final hasCheckIn = checkInEvt != null && checkInEvt.isNotEmpty;
          final hasCheckOut = checkOutEvt != null && checkOutEvt.isNotEmpty;

          final checkedIn = hasCheckIn;
          final checkedOut = hasCheckOut;

          final checkInTime = hasCheckIn
              ? DateTime.parse(checkInEvt['timestamp'] as String)
              : null;
          final checkOutTime = hasCheckOut
              ? DateTime.parse(checkOutEvt['timestamp'] as String)
              : null;

          final String statusLabel;
          final Color statusColor, statusSoft;
          if (checkedOut) {
            statusLabel = 'Checked Out';
            statusColor = AppColors.accent;
            statusSoft = AppColors.accentSoft;
          } else if (checkedIn) {
            statusLabel = 'Checked In';
            statusColor = AppColors.success;
            statusSoft = AppColors.successSoft;
          } else {
            statusLabel = 'Not Checked In';
            statusColor = AppColors.warning;
            statusSoft = AppColors.warningSoft;
          }

          final pendingEvents = events
              .where((e) => e['sync_status'] == 'pending')
              .toList();
          final rejectedEvents = events
              .where((e) => e['sync_status'] == 'rejected')
              .toList();

          final buttonColor = checkedOut
              ? AppColors.text3
              : checkedIn
              ? AppColors.accent
              : AppColors.success;

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
              child: Column(
                children: [
                  const Spacer(flex: 1),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: statusSoft,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: statusColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          statusLabel,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  GestureDetector(
                    onTap: checkedOut
                        ? null
                        : () => _onAction(checkedIn ? 'check_out' : 'check_in'),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      width: 160,
                      height: 160,
                      decoration: BoxDecoration(
                        color: buttonColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: buttonColor.withValues(alpha: 0.35),
                            blurRadius: 24,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: _isProcessing
                          ? const Center(
                              child: SizedBox(
                                width: 28,
                                height: 28,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              ),
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  checkedOut
                                      ? Icons.check_circle_rounded
                                      : checkedIn
                                      ? Icons.logout_rounded
                                      : Icons.login_rounded,
                                  color: Colors.white,
                                  size: 36,
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  checkedOut
                                      ? 'Completed'
                                      : checkedIn
                                      ? 'Check Out'
                                      : 'Check In',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 48),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        _TimeCol(
                          label: 'Check-in',
                          value: checkInTime != null
                              ? DateFormat('h:mm a').format(checkInTime)
                              : '—',
                        ),
                        Container(
                          width: 1,
                          height: 36,
                          color: AppColors.border,
                        ),
                        _TimeCol(
                          label: 'Check-out',
                          value: checkOutTime != null
                              ? DateFormat('h:mm a').format(checkOutTime)
                              : '—',
                        ),
                        Container(
                          width: 1,
                          height: 36,
                          color: AppColors.border,
                        ),
                        _TimeCol(
                          label: 'Duration',
                          value: _duration(checkInTime, checkOutTime),
                        ),
                      ],
                    ),
                  ),
                  if (pendingEvents.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _SyncBanner(
                      pendingCount: pendingEvents.length,
                      onSync: _onSync,
                      isSyncing: _isSyncing,
                    ),
                  ],
                  if (rejectedEvents.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF1F0),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.red.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.error_outline_rounded,
                            size: 16,
                            color: Colors.red,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${rejectedEvents.length} event(s) rejected: '
                              '${rejectedEvents.last['error_message'] ?? 'Unknown error'}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.red,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const Spacer(flex: 2),
                  Text(
                    checkedOut
                        ? "You have completed today's attendance"
                        : checkedIn
                        ? 'Tap the button when you finish work'
                        : 'Tap the button to start your workday',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.text3,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SyncBanner extends StatelessWidget {
  final int pendingCount;
  final VoidCallback onSync;
  final bool isSyncing;
  const _SyncBanner({
    required this.pendingCount,
    required this.onSync,
    required this.isSyncing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.warningSoft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.cloud_upload_outlined,
            size: 16,
            color: AppColors.warning,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$pendingCount pending',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.warning,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          GestureDetector(
            onTap: isSyncing ? null : onSync,
            child: Text(
              isSyncing ? 'Syncing...' : 'Sync Now',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.accent,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimeCol extends StatelessWidget {
  final String label, value;
  const _TimeCol({required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.text3,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.text,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }
}
