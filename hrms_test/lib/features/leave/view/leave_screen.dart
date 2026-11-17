import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hrms_test/core/theme/app_colors.dart';
import 'package:hrms_test/features/leave/providers/leave_provider.dart';
import 'package:intl/intl.dart';

class LeaveScreen extends ConsumerStatefulWidget {
  const LeaveScreen({super.key});

  @override
  ConsumerState<LeaveScreen> createState() => _LeaveScreenState();
}

class _LeaveScreenState extends ConsumerState<LeaveScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          'Leave',
          style: TextStyle(
            color: AppColors.text,
            fontSize: 18,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.3,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.text2),
            onPressed: () => ref.invalidate(leaveRequestsProvider),
          ),
        ],
        bottom: TabBar(
          controller: _tab,
          labelColor: AppColors.accent,
          unselectedLabelColor: AppColors.text3,
          indicatorColor: AppColors.accent,
          indicatorWeight: 2,
          tabs: const [Tab(text: 'My Requests'), Tab(text: 'Apply')],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: [
          _RequestsTab(),
          _ApplyTab(onSubmitted: () => _tab.animateTo(0)),
        ],
      ),
    );
  }
}

class _RequestsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestsAsync = ref.watch(leaveRequestsProvider);
    return requestsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.wifi_off_rounded,
              size: 40,
              color: AppColors.text3,
            ),
            const SizedBox(height: 12),
            const Text(
              'Could not load requests',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              e.toString(),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: AppColors.text2),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => ref.invalidate(leaveRequestsProvider),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
      data: (requests) {
        if (requests.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.beach_access_rounded,
                  size: 48,
                  color: AppColors.text3,
                ),
                SizedBox(height: 12),
                Text(
                  'No leave requests yet.',
                  style: TextStyle(color: AppColors.text2, fontSize: 15),
                ),
              ],
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
          itemCount: requests.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, i) => _RequestCard(requests[i]),
        );
      },
    );
  }
}

class _RequestCard extends StatelessWidget {
  final Map<String, dynamic> req;
  const _RequestCard(this.req);

  @override
  Widget build(BuildContext context) {
    final status = req['status'] as String? ?? 'pending';
    final type = (req['type'] as String? ?? '').toLowerCase();

    Color statusColor, statusSoft;
    String statusLabel;
    switch (status) {
      case 'approved':
        statusColor = AppColors.success;
        statusSoft = AppColors.successSoft;
        statusLabel = 'Approved';
      case 'rejected':
        statusColor = Colors.red;
        statusSoft = const Color(0xFFFFF1F0);
        statusLabel = 'Rejected';
      default:
        statusColor = AppColors.warning;
        statusSoft = AppColors.warningSoft;
        statusLabel = 'Pending';
    }

    final String start = req['start_date'] as String? ?? '';
    final String end = req['end_date'] as String? ?? '';
    final int days = (req['days'] as int?) ?? 1;

    String fmtDate(String d) {
      try {
        return DateFormat('MMM d, yyyy').format(DateTime.parse(d));
      } catch (_) {
        return d;
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.accentSoft,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  type == 'sick' ? 'Sick' : 'Casual',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.accent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusSoft,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    fontSize: 12,
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(
                Icons.calendar_today_rounded,
                size: 13,
                color: AppColors.text3,
              ),
              const SizedBox(width: 6),
              Text(
                '${fmtDate(start)} — ${fmtDate(end)}',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.text,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Text(
                '$days day${days > 1 ? 's' : ''}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.text2,
                ),
              ),
            ],
          ),
          if (req['reason'] != null &&
              (req['reason'] as String).isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              req['reason'] as String,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.text2,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ApplyTab extends ConsumerStatefulWidget {
  final VoidCallback onSubmitted;
  const _ApplyTab({required this.onSubmitted});

  @override
  ConsumerState<_ApplyTab> createState() => _ApplyTabState();
}

class _ApplyTabState extends ConsumerState<_ApplyTab> {
  String _type = 'casual';
  DateTime? _startDate;
  DateTime? _endDate;
  final _reasonCtrl = TextEditingController();
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _reasonCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isStart}) async {
    final now = DateTime.now();
    final initial =
        isStart ? (_startDate ?? now) : (_endDate ?? _startDate ?? now);
    final first = initial.isBefore(now) ? now : initial;
    final picked = await showDatePicker(
      context: context,
      initialDate: first,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.accent,
            onPrimary: Colors.white,
            surface: AppColors.surface,
            onSurface: AppColors.text,
          ),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _startDate = picked;
        if (_endDate != null && _endDate!.isBefore(picked)) _endDate = null;
      } else {
        _endDate = picked;
      }
      _error = null;
    });
  }

  Future<void> _submit() async {
    if (_startDate == null || _endDate == null) {
      setState(() => _error = 'Please select start and end dates');
      return;
    }
    final reason = _reasonCtrl.text;
    final nonWs = reason.trim().replaceAll(RegExp(r'\s+'), '');
    if (nonWs.length < 10) {
      setState(
        () => _error = 'Reason must have at least 10 non-whitespace characters',
      );
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await ref.read(leaveActionsProvider).submit(
            type: _type,
            start: _startDate!,
            end: _endDate!,
            reason: reason,
          );
      if (!mounted) return;
      _reasonCtrl.clear();
      setState(() {
        _startDate = null;
        _endDate = null;
        _submitting = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Leave request submitted',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.success,
        ),
      );
      widget.onSubmitted();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _submitting = false;
      });
    }
  }

  String _fmt(DateTime? d) =>
      d == null ? 'Select date' : DateFormat('EEE, MMM d, yyyy').format(d);

  @override
  Widget build(BuildContext context) {
    final days =
        (_startDate != null && _endDate != null)
            ? _endDate!.difference(_startDate!).inDays + 1
            : null;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            children: [
              _SectionLabel('Leave Type'),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _TypeChip(
                      label: 'Casual',
                      icon: Icons.wb_sunny_outlined,
                      selected: _type == 'casual',
                      onTap: () => setState(() => _type = 'casual'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _TypeChip(
                      label: 'Sick',
                      icon: Icons.local_hospital_outlined,
                      selected: _type == 'sick',
                      onTap: () => setState(() => _type = 'sick'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              _SectionLabel('Duration'),
              const SizedBox(height: 10),
              _DateField(
                label: 'Start date',
                value: _fmt(_startDate),
                hasValue: _startDate != null,
                onTap: () => _pickDate(isStart: true),
              ),
              const SizedBox(height: 12),
              _DateField(
                label: 'End date',
                value: _fmt(_endDate),
                hasValue: _endDate != null,
                onTap: () => _pickDate(isStart: false),
              ),
              if (days != null) ...[
                const SizedBox(height: 12),
                Text(
                  '$days day(s)',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.accent,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
              const SizedBox(height: 28),
              _SectionLabel('Reason'),
              const SizedBox(height: 10),
              TextField(
                controller: _reasonCtrl,
                maxLines: 4,
                maxLength: 200,
                style: const TextStyle(
                  fontSize: 15,
                  color: AppColors.text,
                  height: 1.4,
                ),
                decoration: InputDecoration(
                  hintText: 'Briefly describe the reason for leave…',
                  hintStyle: const TextStyle(
                    color: AppColors.text3,
                    fontSize: 14,
                  ),
                  filled: true,
                  fillColor: AppColors.surface,
                  contentPadding: const EdgeInsets.all(16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                      color: AppColors.accent,
                      width: 1.5,
                    ),
                  ),
                  counterStyle: const TextStyle(
                    fontSize: 11,
                    color: AppColors.text3,
                  ),
                ),
                onChanged: (_) {
                  if (_error != null) setState(() => _error = null);
                },
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.red,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              onPressed: _submitting ? null : _submit,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppColors.accent.withValues(
                  alpha: 0.5,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: _submitting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Submit Request',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.2,
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.text2,
        letterSpacing: 0.2,
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  const _TypeChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: selected ? AppColors.accentSoft : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.accent : AppColors.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 22,
              color: selected ? AppColors.accent : AppColors.text3,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: selected ? AppColors.accent : AppColors.text2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  final String label, value;
  final bool hasValue;
  final VoidCallback onTap;
  const _DateField({
    required this.label,
    required this.value,
    required this.hasValue,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_rounded,
              size: 18,
              color: hasValue ? AppColors.accent : AppColors.text3,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.text3,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: hasValue ? AppColors.text : AppColors.text3,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.text3,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
