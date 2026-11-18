import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hrms_test/core/theme/app_colors.dart';
import 'package:hrms_test/features/dashboard/provider/dashboard_provider.dart';
import 'package:intl/intl.dart';

class HistoryCard extends ConsumerWidget {
  const HistoryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final histAsync = ref.watch(attendanceHistoryProvider);
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 18, 20, 0),
            child: Text(
              'Recent Attendance',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.2,
                color: AppColors.text,
              ),
            ),
          ),
          histAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(20),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (_, __) => const Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                'Could not load attendance history',
                style: TextStyle(color: AppColors.text2),
              ),
            ),
            data: (records) {
              final last5 = records.reversed.take(5).toList();
              if (last5.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(20),
                  child: Text(
                    'No attendance records yet.',
                    style: TextStyle(color: AppColors.text3),
                  ),
                );
              }
              return Column(
                children: last5.asMap().entries.map((e) {
                  final isLast = e.key == last5.length - 1;
                  return Column(
                    children: [
                      _HistoryRow(e.value),
                      if (!isLast)
                        const Divider(
                          height: 1,
                          indent: 20,
                          endIndent: 20,
                          color: AppColors.border,
                        ),
                    ],
                  );
                }).toList(),
              );
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  final Map<String, dynamic> record;
  const _HistoryRow(this.record);

  String _fmt(String? iso) {
    if (iso == null) return '—';
    return DateFormat('h:mm a').format(DateTime.parse(iso));
  }

  String get _dateLabel {
    final now = DateTime.now();
    final d = DateTime.parse(record['date'] as String);
    final today = DateTime(now.year, now.month, now.day);
    final dayOf = DateTime(d.year, d.month, d.day);
    if (dayOf == today) return 'Today';
    if (dayOf == today.subtract(const Duration(days: 1))) return 'Yesterday';
    return DateFormat('EEE, MMM d').format(d);
  }

  @override
  Widget build(BuildContext context) {
    final checkIn = record['check_in'] as String?;
    final checkOut = record['check_out'] as String?;
    final status = record['status'] as String? ?? '';
    final isComplete = status == 'completed';

    Duration? dur;
    if (checkIn != null && checkOut != null) {
      dur = DateTime.parse(checkOut).difference(DateTime.parse(checkIn));
    }
    final durStr = dur != null
        ? '${dur.inHours}h ${dur.inMinutes.remainder(60).toString().padLeft(2, '0')}m'
        : null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _dateLabel,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.text,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  checkIn != null
                      ? '${_fmt(checkIn)} — ${_fmt(checkOut)}'
                      : 'No record',
                  style: const TextStyle(fontSize: 12, color: AppColors.text3),
                ),
              ],
            ),
          ),
          if (durStr != null)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Text(
                durStr,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.text2,
                ),
              ),
            ),
          isComplete
              ? _Badge(
                  label: 'Checked Out',
                  color: AppColors.accent,
                  soft: AppColors.accentSoft,
                )
              : _Badge(
                  label: 'Checked In',
                  color: AppColors.success,
                  soft: AppColors.successSoft,
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: soft,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.1,
            ),
          ),
        ],
      ),
    );
  }
}
