import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/enums.dart';
import '../../../data/models/patient_model.dart';
import '../../../data/models/surgical_readiness_model.dart';
import '../../../data/models/task_model.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/patient_repository.dart';
import '../providers/patient_detail_providers.dart';
import '../../../core/theme/app_animations.dart';
import '../../dashboard/providers/dashboard_providers.dart';
import '../../clinical/providers/clinical_providers.dart';
import '../../theatre/providers/theatre_readiness_providers.dart';

class PatientDetailScreen extends ConsumerWidget {
  const PatientDetailScreen({super.key, required this.patientId});

  final String patientId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final patientAsync = ref.watch(patientByIdProvider(patientId));

    return patientAsync.when(
      loading: () => const Scaffold(
          body: ShimmerList(count: 3)),
      error: (e, _) =>
          Scaffold(body: Center(child: Text('Error: $e'))),
      data: (patient) {
        if (patient == null) {
          return Scaffold(
              appBar: AppBar(),
              body: const Center(child: Text('Patient not found')));
        }
        return _PatientDetailView(patient: patient);
      },
    );
  }
}

class _PatientDetailView extends ConsumerWidget {
  const _PatientDetailView({required this.patient});

  final PatientModel patient;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: CustomScrollView(
        slivers: [
          // ── Header ──────────────────────────────────────────────
          SliverAppBar(
            pinned: true,
            expandedHeight: 140,
            backgroundColor: AppColors.primary,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
              title: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    patient.fullName,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700),
                  ),
                  Text(
                    '${patient.folderNumber}  ·  ${patient.ward.label}',
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 11),
                  ),
                ],
              ),
              background: Container(color: AppColors.primary),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.assignment_outlined, color: Colors.white),
                tooltip: 'Full Clerking',
                onPressed: () => context.push(
                  '/patients/${patient.id}/clerk',
                  extra: patient,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.rate_review_outlined, color: Colors.white),
                tooltip: 'Daily Review',
                onPressed: () => context.push(
                  '/patients/${patient.id}/review',
                  extra: patient,
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.white),
                onSelected: (v) async {
                  if (v == 'discharge') {
                    await _confirmDischarge(context, ref);
                  }
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                      value: 'discharge',
                      child: Text('Discharge Patient')),
                ],
              ),
            ],
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Info cards ─────────────────────────────────
                  AnimatedMount(
                    child: _InfoCard(patient: patient),
                  ),
                  const SizedBox(height: 16),

                  // ── Clinical flags ─────────────────────────────
                  AnimatedMount(
                    delay: const Duration(milliseconds: 60),
                    child: _ClinicalFlagsCard(patient: patient),
                  ),
                  const SizedBox(height: 16),

                  // ── Surgical readiness (if surgical case) ──────
                  AnimatedMount(
                    delay: const Duration(milliseconds: 120),
                    child: _SurgicalReadinessSection(patientId: patient.id),
                  ),
                  const SizedBox(height: 16),

                  // ── Post-op timeline ───────────────────────────
                  AnimatedMount(
                    delay: const Duration(milliseconds: 180),
                    child: _PostopTimelineSection(patientId: patient.id),
                  ),
                  const SizedBox(height: 16),

                  // ── Clinical record summary ─────────────────────
                  AnimatedMount(
                    delay: const Duration(milliseconds: 240),
                    child: _ClinicalRecordSummary(patient: patient),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDischarge(
      BuildContext context, WidgetRef ref) async {
    final notesCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Discharge Patient'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Discharge ${patient.fullName}?'),
            const SizedBox(height: 12),
            TextField(
              controller: notesCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Discharge notes (optional)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success),
              child: const Text('Discharge')),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final user =
          ref.read(currentUserProfileProvider).value;
      await ref.read(patientRepositoryProvider).dischargePatient(
            patientId: patient.id,
            dischargedBy: user?.id ?? '',
            notes: notesCtrl.text.trim().isEmpty
                ? null
                : notesCtrl.text.trim(),
          );
      ref.invalidate(activePatientsProvider);
      ref.invalidate(patientByIdProvider(patient.id));
      if (context.mounted) context.go('/patients');
    }
  }
}

// ── Info card ────────────────────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.patient});

  final PatientModel patient;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _CardHeader('Patient Information',
                Icons.person_outline_rounded),
            const SizedBox(height: 12),
            _InfoRow('Admission type', patient.admissionType.label),
            _InfoRow('Ward', patient.ward.label),
            _InfoRow('Admission date',
                DateFormat('EEE d MMM yyyy').format(patient.admissionDate)),
            _InfoRow('Days admitted', '${patient.daysAdmitted} day(s)'),
            if (patient.diagnosis != null)
              _InfoRow('Diagnosis', patient.diagnosis!),
            if (patient.edd != null)
              _InfoRow('EDD',
                  DateFormat('EEE d MMM yyyy').format(patient.edd!)),
            if (patient.parity != null)
              _InfoRow('Parity', patient.parity!),
          ],
        ),
      ),
    );
  }
}

// ── Clinical flags ───────────────────────────────────────────────────────────

class _ClinicalFlagsCard extends StatelessWidget {
  const _ClinicalFlagsCard({required this.patient});

  final PatientModel patient;

  @override
  Widget build(BuildContext context) {
    final flags = <_Flag>[];

    if (patient.hasAllergies) {
      flags.add(_Flag(
        icon: Icons.warning_amber_rounded,
        color: AppColors.danger,
        label: 'Allergies',
        value: patient.allergies!,
      ));
    }

    if (patient.previousCs) {
      flags.add(_Flag(
        icon: Icons.warning_amber_rounded,
        color: AppColors.warning,
        label: 'Previous C/S',
        value: 'Cytotec induction CONTRAINDICATED',
      ));
    }

    if (patient.isSickleCellRisk) {
      flags.add(_Flag(
        icon: Icons.bloodtype_rounded,
        color: AppColors.danger,
        label: 'Sickle Cell Disease',
        value:
            '${patient.sickleCellStatus.label} — monitor Hb, hydration, malaria',
      ));
    }

    if (flags.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(Icons.check_circle_rounded,
                  color: AppColors.success, size: 18),
              const SizedBox(width: 8),
              Text('No clinical flags',
                  style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _CardHeader('Clinical Flags', Icons.flag_rounded,
                color: AppColors.danger),
            const SizedBox(height: 12),
            ...flags.map((f) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(f.icon, size: 16, color: f.color),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(f.label,
                                style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: f.color)),
                            Text(f.value,
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}

class _Flag {
  const _Flag(
      {required this.icon,
      required this.color,
      required this.label,
      required this.value});
  final IconData icon;
  final Color color;
  final String label;
  final String value;
}

// ── Surgical readiness section — interactive ──────────────────────────────────

class _SurgicalReadinessSection extends ConsumerStatefulWidget {
  const _SurgicalReadinessSection({required this.patientId});
  final String patientId;

  @override
  ConsumerState<_SurgicalReadinessSection> createState() =>
      _SurgicalReadinessSectionState();
}

class _SurgicalReadinessSectionState
    extends ConsumerState<_SurgicalReadinessSection> {
  SurgicalReadinessModel? _local;
  bool _saving = false;
  bool _expanded = false;

  Future<void> _toggle(SurgicalReadinessModel updated) async {
    setState(() {
      _local = updated;
      _saving = true;
    });
    try {
      await ref.read(readinessActionsProvider).updateReadiness(updated);
      ref.invalidate(patientReadinessProvider(widget.patientId));
      ref.invalidate(theatreReadinessListProvider);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final readinessAsync = ref.watch(patientReadinessProvider(widget.patientId));

    return readinessAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (fetched) {
        if (fetched == null) return const SizedBox.shrink();

        // Sync from provider only when not mid-save
        if (!_saving) _local = fetched;
        final r = _local ?? fetched;

        final pct = r.readinessPct;
        final color = pct == 100
            ? AppColors.success
            : pct >= 70
                ? AppColors.warning
                : AppColors.danger;

        return Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(
              color: r.isTheatreReady
                  ? AppColors.success.withValues(alpha: 0.3)
                  : AppColors.divider.withValues(alpha: 0.5),
              width: r.isTheatreReady ? 1.5 : 0.5,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Header
              Row(children: [
                const Icon(Icons.medical_services_rounded,
                    size: 16, color: AppColors.primary),
                const SizedBox(width: 8),
                Text('Theatre Readiness',
                    style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                if (_saving)
                  const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2))
                else if (r.isTheatreReady)
                  const Icon(Icons.check_circle_rounded,
                      color: AppColors.success, size: 18),
              ]),
              const SizedBox(height: 12),

              // Animated progress bar + percentage
              Row(children: [
                Expanded(
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: pct / 100),
                    duration: const Duration(milliseconds: 450),
                    curve: Curves.easeOut,
                    builder: (_, val, __) => ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: val,
                        minHeight: 8,
                        backgroundColor: AppColors.divider,
                        valueColor: AlwaysStoppedAnimation(color),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: pct.toDouble()),
                  duration: const Duration(milliseconds: 450),
                  builder: (_, val, __) => Text(
                    '${val.round()}%',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: color),
                  ),
                ),
              ]),

              // ── Expanded checklist ─────────────────────────────
              if (_expanded) ...[
                const SizedBox(height: 14),
                const Divider(height: 1),
                const SizedBox(height: 10),
                _InlineTapRow(
                  label: 'Full clerking completed',
                  done: r.clerkingCompleted,
                  onTap: () => _toggle(r.copyWith(clerkingCompleted: !r.clerkingCompleted)),
                ),
                _InlineTapRow(
                  label: 'Anaesthetic review done',
                  done: r.anaestheticReview,
                  onTap: () => _toggle(r.copyWith(anaestheticReview: !r.anaestheticReview)),
                ),
                _InlineTapRow(
                  label: 'Cross match (GXM) completed',
                  done: r.gxmCompleted,
                  onTap: () => _toggle(r.copyWith(gxmCompleted: !r.gxmCompleted)),
                ),
                _InlineTapRow(
                  label: 'Consent signed',
                  done: r.consentSigned,
                  onTap: () => _toggle(r.copyWith(consentSigned: !r.consentSigned)),
                ),
                _InlineTapRow(
                  label: 'Medications purchased',
                  done: r.medicationsPurchased,
                  onTap: () => _toggle(r.copyWith(medicationsPurchased: !r.medicationsPurchased)),
                ),
                _InlineTapRow(
                  label: 'IV line set',
                  done: r.ivLineSet,
                  onTap: () => _toggle(r.copyWith(ivLineSet: !r.ivLineSet)),
                ),
                _InlineTapRow(
                  label: 'X-match fee paid',
                  done: r.xmatchFeePaid,
                  onTap: () => _toggle(r.copyWith(xmatchFeePaid: !r.xmatchFeePaid)),
                ),
                _InlineTapRow(
                  label: 'Blood confirmed in bank',
                  done: r.bloodAvailableInBank,
                  onTap: () => _toggle(r.copyWith(bloodAvailableInBank: !r.bloodAvailableInBank)),
                ),
                _InlineTapRow(
                  label: 'Consultant approved',
                  done: r.consultantApproved,
                  onTap: () => _toggle(r.copyWith(consultantApproved: !r.consultantApproved)),
                ),
                // Blood units stepper
                const SizedBox(height: 6),
                Row(children: [
                  Icon(
                    r.bloodUnitsDonated >= r.bloodUnitsRequired
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                    size: 18,
                    color: r.bloodUnitsDonated >= r.bloodUnitsRequired
                        ? AppColors.success
                        : AppColors.textMuted,
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text('Blood donated',
                        style: TextStyle(
                            fontSize: 13, color: AppColors.textPrimary)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline_rounded, size: 18),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    color: AppColors.textMuted,
                    onPressed: r.bloodUnitsDonated > 0
                        ? () => _toggle(r.copyWith(bloodUnitsDonated: r.bloodUnitsDonated - 1))
                        : null,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      '${r.bloodUnitsDonated}/${r.bloodUnitsRequired}',
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    color: AppColors.primary,
                    onPressed: () => _toggle(r.copyWith(bloodUnitsDonated: r.bloodUnitsDonated + 1)),
                  ),
                ]),
                const SizedBox(height: 6),
                TextButton(
                  onPressed: () => setState(() => _expanded = false),
                  style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                  child: const Text('Hide checklist',
                      style: TextStyle(fontSize: 12)),
                ),
              ] else ...[
                // ── Collapsed: outstanding list + expand button ──
                if (r.blockingItems.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  const Text('Outstanding:',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary)),
                  const SizedBox(height: 4),
                  ...r.blockingItems.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 3),
                      child: Row(children: [
                        const Icon(Icons.circle,
                            size: 5, color: AppColors.danger),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(item,
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textPrimary)),
                        ),
                      ]),
                    ),
                  ),
                ] else ...[
                  const SizedBox(height: 8),
                  const Row(children: [
                    Icon(Icons.check_circle_rounded,
                        color: AppColors.success, size: 16),
                    SizedBox(width: 6),
                    Text('Patient is theatre-ready',
                        style: TextStyle(
                            color: AppColors.success,
                            fontWeight: FontWeight.w600,
                            fontSize: 13)),
                  ]),
                ],
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () => setState(() => _expanded = true),
                  child: const Row(children: [
                    Icon(Icons.touch_app_outlined,
                        size: 14, color: AppColors.primary),
                    SizedBox(width: 4),
                    Text('Tap to update checklist',
                        style: TextStyle(
                            fontSize: 12,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600)),
                  ]),
                ),
              ],
            ]),
          ),
        );
      },
    );
  }
}

class _InlineTapRow extends StatelessWidget {
  const _InlineTapRow(
      {required this.label, required this.done, required this.onTap});
  final String label;
  final bool done;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 2),
        child: Row(children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Icon(
              done
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              key: ValueKey(done),
              size: 18,
              color: done ? AppColors.success : AppColors.textMuted,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontSize: 13,
                color: done ? AppColors.textMuted : AppColors.textPrimary,
                decoration: done ? TextDecoration.lineThrough : null,
              ),
              child: Text(label),
            ),
          ),
        ]),
      ),
    );
  }
}

// ── Post-op timeline ─────────────────────────────────────────────────────────

class _PostopTimelineSection extends ConsumerWidget {
  const _PostopTimelineSection({required this.patientId});

  final String patientId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync =
        ref.watch(patientPostopTasksProvider(patientId));

    return tasksAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (tasks) {
        if (tasks.isEmpty) return const SizedBox.shrink();

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _CardHeader(
                    'Post-Op Schedule', Icons.healing_rounded),
                const SizedBox(height: 16),
                ...tasks.asMap().entries.map((entry) {
                  final i = entry.key;
                  final task = entry.value;
                  final isLast = i == tasks.length - 1;
                  return _PostopTimelineTile(
                      task: task, isLast: isLast, ref: ref);
                }),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PostopTimelineTile extends StatelessWidget {
  const _PostopTimelineTile({
    required this.task,
    required this.isLast,
    required this.ref,
  });

  final PostopTaskModel task;
  final bool isLast;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final isDone = task.status == TaskStatus.completed;
    final isOverdue = task.isOverdue;
    final isToday = task.isDueToday;

    Color dotColor;
    if (isDone) {
      dotColor = AppColors.success;
    } else if (isOverdue) {
      dotColor = AppColors.danger;
    } else if (isToday) {
      dotColor = AppColors.warning;
    } else {
      dotColor = AppColors.textMuted;
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline spine
          SizedBox(
            width: 24,
            child: Column(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  margin: const EdgeInsets.only(top: 3),
                  decoration: BoxDecoration(
                    color: isDone ? dotColor : Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: dotColor, width: 2),
                  ),
                  child: isDone
                      ? const Icon(Icons.check,
                          size: 8, color: Colors.white)
                      : null,
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.only(top: 2),
                      color: AppColors.divider,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        DateFormat('EEE d MMM')
                            .format(task.dueDate),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: dotColor,
                        ),
                      ),
                      if (isOverdue && !isDone)
                        const Text('OVERDUE',
                            style: TextStyle(
                              fontSize: 10,
                              color: AppColors.danger,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            )),
                      if (isToday && !isDone)
                        const Text('TODAY',
                            style: TextStyle(
                              fontSize: 10,
                              color: AppColors.warning,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            )),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    task.description,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDone
                          ? AppColors.textSecondary
                          : AppColors.textPrimary,
                      decoration: isDone
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),
                  if (task.completedAt != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Completed ${DateFormat('d MMM, h:mm a').format(task.completedAt!)}',
                      style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.success),
                    ),
                  ],
                  if (!isDone && (isToday || isOverdue)) ...[
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: () =>
                          _completeTask(context, task, ref),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color:
                              AppColors.success.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                              color: AppColors.success
                                  .withOpacity(0.3)),
                        ),
                        child: const Text(
                          'Mark complete',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.success,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _completeTask(BuildContext context,
      PostopTaskModel task, WidgetRef ref) async {
    final notesCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Complete Task'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(task.description,
                style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary)),
            const SizedBox(height: 12),
            TextField(
              controller: notesCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                border: OutlineInputBorder(),
                hintText: 'e.g. Hb 11.2, wound clean',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success),
              child: const Text('Done')),
        ],
      ),
    );

    if (confirmed == true) {
      final user =
          ref.read(currentUserProfileProvider).value;
      await ref.read(taskActionsProvider).completePostopTask(
            task.id,
            user?.id ?? '',
            notes: notesCtrl.text.trim().isEmpty
                ? null
                : notesCtrl.text.trim(),
          );
      ref.invalidate(
          patientPostopTasksProvider(task.patientId));
    }
  }
}

// ── Shared widgets ────────────────────────────────────────────────────────────

class _CardHeader extends StatelessWidget {
  const _CardHeader(this.title, this.icon, {this.color});

  final String title;
  final IconData icon;
  final Color? color;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Icon(icon, size: 16, color: color ?? AppColors.primary),
          const SizedBox(width: 8),
          Text(title,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: color)),
        ],
      );
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 120,
              child: Text(label,
                  style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary)),
            ),
            Expanded(
              child: Text(value,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary)),
            ),
          ],
        ),
      );
}

// ── Clinical Record Summary ────────────────────────────────────────────────────
class _ClinicalRecordSummary extends ConsumerWidget {
  const _ClinicalRecordSummary({required this.patient});
  final PatientModel patient;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recordAsync = ref.watch(clinicalRecordProvider(patient.id));
    final reviewsAsync = ref.watch(patientReviewsProvider(patient.id));

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // ── Clerking status ──────────────────────────────────────
      recordAsync.when(
        loading: () => const SizedBox.shrink(),
        error: (_, __) => const SizedBox.shrink(),
        data: (record) {
          if (record == null) {
            return Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.warning.withValues(alpha: 0.25)),
              ),
              child: Row(children: [
                const Icon(Icons.assignment_outlined, color: AppColors.warning, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('No clerking on record',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.warning)),
                    const Text('Tap the clipboard icon above to start full clerking.',
                        style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                  ]),
                ),
              ]),
            );
          }

          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.success.withValues(alpha: 0.2)),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Icon(Icons.assignment_turned_in, color: AppColors.success, size: 20),
                const SizedBox(width: 8),
                const Text('Clerking on record',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.success)),
              ]),
              if (record.presentingComplaint != null && record.presentingComplaint!.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text('PC: ${record.presentingComplaint}',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
              if (record.impression != null && record.impression!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text('Dx: ${record.impression}',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
            ]),
          );
        },
      ),

      // ── Recent reviews ───────────────────────────────────────
      reviewsAsync.when(
        loading: () => const SizedBox.shrink(),
        error: (_, __) => const SizedBox.shrink(),
        data: (reviews) {
          if (reviews.isEmpty) return const SizedBox.shrink();
          final recent = reviews.take(3).toList();
          return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SizedBox(height: 12),
            const Text('Recent Reviews',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
            const SizedBox(height: 6),
            ...recent.map((r) => Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.divider),
              ),
              child: Row(children: [
                Expanded(
                  child: Text(
                    '${r.reviewType.toUpperCase().replaceAll('_', ' ')} — ${r.reviewDate}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                  ),
                ),
                if (r.plan != null && r.plan!.isNotEmpty)
                  Expanded(
                    flex: 2,
                    child: Text(r.plan!,
                        style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
              ]),
            )),
          ]);
        },
      ),
    ]);
  }
}
