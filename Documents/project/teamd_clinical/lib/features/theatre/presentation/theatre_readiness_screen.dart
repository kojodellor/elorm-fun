import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/surgical_readiness_model.dart';
import '../providers/theatre_readiness_providers.dart';
import '../../../core/theme/app_animations.dart';

class TheatreReadinessScreen extends ConsumerWidget {
  const TheatreReadinessScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch(theatreReadinessListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Theatre Readiness'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(theatreReadinessListProvider),
          ),
        ],
      ),
      body: dataAsync.when(
        loading: () => const ShimmerList(count: 3),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (items) {
          if (items.isEmpty) {
            return const Center(
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.medical_services_outlined,
                    size: 48, color: AppColors.textMuted),
                SizedBox(height: 12),
                Text('No theatre patients',
                    style: TextStyle(color: AppColors.textSecondary)),
              ]),
            );
          }

          final sorted = [...items]..sort((a, b) {
              if (a.readiness.isTheatreReady != b.readiness.isTheatreReady) {
                return a.readiness.isTheatreReady ? 1 : -1;
              }
              return a.readiness.readinessPct.compareTo(b.readiness.readinessPct);
            });

          final readyCount =
              items.where((i) => i.readiness.isTheatreReady).length;

          return Column(children: [
            _ReadinessSummaryBar(readyCount: readyCount, total: items.length),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: sorted.length,
                itemBuilder: (_, i) => AnimatedMount(
                  delay: Duration(milliseconds: i * 55),
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _ReadinessCard(item: sorted[i]),
                  ),
                ),
              ),
            ),
          ]);
        },
      ),
    );
  }
}

// ── Summary bar ───────────────────────────────────────────────────────────────

class _ReadinessSummaryBar extends StatelessWidget {
  const _ReadinessSummaryBar({required this.readyCount, required this.total});
  final int readyCount;
  final int total;

  @override
  Widget build(BuildContext context) {
    final pct = total == 0 ? 0.0 : readyCount / total;
    final color = pct == 1.0
        ? AppColors.success
        : pct >= 0.5
            ? AppColors.warning
            : AppColors.danger;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Theatre Ready', style: Theme.of(context).textTheme.titleMedium),
          Text('$readyCount of $total patients',
              style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w600, color: color)),
        ]),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: pct,
            minHeight: 8,
            backgroundColor: AppColors.divider,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ]),
    );
  }
}

// ── Patient readiness card — fully interactive ────────────────────────────────

class _ReadinessCard extends ConsumerStatefulWidget {
  const _ReadinessCard({required this.item});
  final TheatreReadinessItem item;

  @override
  ConsumerState<_ReadinessCard> createState() => _ReadinessCardState();
}

class _ReadinessCardState extends ConsumerState<_ReadinessCard> {
  late SurgicalReadinessModel _local;
  bool _saving = false;
  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    _local = widget.item.readiness;
  }

  @override
  void didUpdateWidget(_ReadinessCard old) {
    super.didUpdateWidget(old);
    // Only update from provider if not mid-save
    if (!_saving) _local = widget.item.readiness;
  }

  Future<void> _toggle(SurgicalReadinessModel updated) async {
    setState(() {
      _local = updated;
      _saving = true;
    });
    try {
      await ref.read(readinessActionsProvider).updateReadiness(updated);
      ref.invalidate(theatreReadinessListProvider);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = _local;
    final pct = r.readinessPct;
    final isReady = r.isTheatreReady;

    final statusColor = isReady
        ? AppColors.success
        : pct >= 70
            ? AppColors.warning
            : AppColors.danger;

    return Card(
      elevation: isReady ? 0 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: isReady
              ? AppColors.success.withValues(alpha: 0.35)
              : AppColors.divider.withValues(alpha: 0.5),
          width: isReady ? 1.5 : 0.5,
        ),
      ),
      child: Column(children: [
        // ── Header (always visible) ───────────────────────────────
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Row(children: [
              // Animated percentage badge
              _AnimatedBadge(pct: pct, color: statusColor),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(widget.item.patient.fullName,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600)),
                  Text(
                    'Folder: ${widget.item.patient.folderNumber}  ·  ${widget.item.patient.ward.label}',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary),
                  ),
                ]),
              ),
              if (_saving)
                const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2))
              else if (isReady)
                const Icon(Icons.check_circle_rounded, color: AppColors.success)
              else
                Icon(Icons.expand_more,
                    color: AppColors.textMuted,
                    size: 20),
            ]),
          ),
        ),

        // ── Animated progress bar ─────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 4),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: pct / 100),
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOut,
            builder: (_, value, __) => ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: value,
                minHeight: 6,
                backgroundColor: AppColors.divider,
                valueColor: AlwaysStoppedAnimation(statusColor),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),

        // ── Expandable checklist ──────────────────────────────────
        if (_expanded) ...[
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 16),
            child: Column(children: [
              _TapRow(
                label: 'Full clerking completed',
                done: r.clerkingCompleted,
                onTap: () => _toggle(r.copyWith(clerkingCompleted: !r.clerkingCompleted)),
              ),
              _TapRow(
                label: 'Anaesthetic review done',
                done: r.anaestheticReview,
                onTap: () => _toggle(r.copyWith(anaestheticReview: !r.anaestheticReview)),
              ),
              _TapRow(
                label: 'Cross match (GXM) completed',
                done: r.gxmCompleted,
                onTap: () => _toggle(r.copyWith(gxmCompleted: !r.gxmCompleted)),
              ),
              _TapRow(
                label: 'Consent signed',
                done: r.consentSigned,
                onTap: () => _toggle(r.copyWith(consentSigned: !r.consentSigned)),
              ),
              _TapRow(
                label: 'Medications purchased',
                done: r.medicationsPurchased,
                onTap: () => _toggle(r.copyWith(medicationsPurchased: !r.medicationsPurchased)),
              ),
              _TapRow(
                label: 'IV line set',
                done: r.ivLineSet,
                onTap: () => _toggle(r.copyWith(ivLineSet: !r.ivLineSet)),
              ),
              _TapRow(
                label: 'X-match fee paid',
                done: r.xmatchFeePaid,
                onTap: () => _toggle(r.copyWith(xmatchFeePaid: !r.xmatchFeePaid)),
              ),
              _TapRow(
                label: 'Blood confirmed in bank',
                done: r.bloodAvailableInBank,
                subtitle: 'Required: ${r.bloodUnitsRequired}  ·  Donated: ${r.bloodUnitsDonated}',
                onTap: () => _toggle(r.copyWith(bloodAvailableInBank: !r.bloodAvailableInBank)),
              ),
              // Hb — inline editable
              _HbInlineRow(
                hbValue: r.hbValue,
                hbDate: r.hbDate,
                acceptable: r.hbAcceptable,
                stale: r.hbStale,
                onChanged: (val, date) => _toggle(r.copyWith(hbValue: val, hbDate: date)),
              ),

              // Blood stepper
              const SizedBox(height: 4),
              _BloodStepperRow(
                required: r.bloodUnitsRequired,
                donated: r.bloodUnitsDonated,
                onChanged: (v) => _toggle(r.copyWith(
                  bloodUnitsDonated: v,
                  bloodAvailableInBank: v >= r.bloodUnitsRequired,
                )),
              ),
            ]),
          ),
        ] else ...[
          // Collapsed: show outstanding items as chips
          if (r.blockingItems.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
              child: Wrap(
                spacing: 6,
                runSpacing: 4,
                children: r.blockingItems.take(3).map((item) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.danger.withValues(alpha: 0.07),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                            color: AppColors.danger.withValues(alpha: 0.2)),
                      ),
                      child: Text(item,
                          style: const TextStyle(
                              fontSize: 11, color: AppColors.danger)),
                    )).toList(),
              ),
            ),
          // Tap to expand hint
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
            child: GestureDetector(
              onTap: () => setState(() => _expanded = true),
              child: Row(children: [
                const Icon(Icons.touch_app_outlined,
                    size: 14, color: AppColors.textMuted),
                const SizedBox(width: 4),
                Text(
                  isReady ? 'Tap to review checklist' : 'Tap to update checklist',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textMuted),
                ),
              ]),
            ),
          ),
        ],
      ]),
    );
  }
}

// ── Animated percentage badge ─────────────────────────────────────────────────

class _AnimatedBadge extends StatelessWidget {
  const _AnimatedBadge({required this.pct, required this.color});
  final int pct;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: pct.toDouble()),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOut,
      builder: (_, value, __) => Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          shape: BoxShape.circle,
          border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
        ),
        child: Center(
          child: Text(
            '${value.round()}%',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Tappable checklist row ────────────────────────────────────────────────────

class _TapRow extends StatelessWidget {
  const _TapRow({
    required this.label,
    required this.done,
    required this.onTap,
    this.subtitle,
  });

  final String label;
  final bool done;
  final VoidCallback onTap;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Icon(
              done ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
              key: ValueKey(done),
              size: 20,
              color: done ? AppColors.success : AppColors.textMuted,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  fontSize: 13,
                  color: done ? AppColors.textMuted : AppColors.textPrimary,
                  decoration: done ? TextDecoration.lineThrough : null,
                ),
                child: Text(label),
              ),
              if (subtitle != null)
                Text(subtitle!,
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textMuted)),
            ]),
          ),
        ]),
      ),
    );
  }
}

// ── Inline Hb row ─────────────────────────────────────────────────────────────

class _HbInlineRow extends StatefulWidget {
  const _HbInlineRow({
    required this.hbValue,
    required this.hbDate,
    required this.acceptable,
    required this.stale,
    required this.onChanged,
  });

  final double? hbValue;
  final DateTime? hbDate;
  final bool acceptable;
  final bool stale;
  final void Function(double? value, DateTime? date) onChanged;

  @override
  State<_HbInlineRow> createState() => _HbInlineRowState();
}

class _HbInlineRowState extends State<_HbInlineRow> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(
        text: widget.hbValue?.toStringAsFixed(1) ?? '');
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final done = widget.hbValue != null && widget.acceptable && !widget.stale;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      child: Row(children: [
        Icon(
          done ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
          size: 20,
          color: done ? AppColors.success : AppColors.textMuted,
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Text('Hb result',
              style: TextStyle(fontSize: 13, color: AppColors.textPrimary)),
        ),
        SizedBox(
          width: 72,
          child: TextFormField(
            controller: _ctrl,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            decoration: const InputDecoration(
              isDense: true,
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              suffixText: 'g/dl',
              suffixStyle: TextStyle(fontSize: 10),
            ),
            onFieldSubmitted: (v) {
              final parsed = double.tryParse(v);
              widget.onChanged(parsed, widget.hbDate ?? DateTime.now());
            },
          ),
        ),
        if (widget.hbValue != null && !widget.acceptable)
          const Padding(
            padding: EdgeInsets.only(left: 6),
            child: Icon(Icons.warning_amber_rounded,
                size: 16, color: AppColors.warning),
          ),
      ]),
    );
  }
}

// ── Blood stepper row ─────────────────────────────────────────────────────────

class _BloodStepperRow extends StatelessWidget {
  const _BloodStepperRow({
    required this.required,
    required this.donated,
    required this.onChanged,
  });

  final int required;
  final int donated;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final shortfall = (required - donated).clamp(0, required);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      child: Row(children: [
        Icon(
          donated >= required ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
          size: 20,
          color: donated >= required ? AppColors.success : AppColors.textMuted,
        ),
        const SizedBox(width: 12),
        const Text('Blood donated',
            style: TextStyle(fontSize: 13, color: AppColors.textPrimary)),
        const Spacer(),
        // Stepper
        IconButton(
          icon: const Icon(Icons.remove_circle_outline_rounded, size: 20),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          onPressed: donated > 0 ? () => onChanged(donated - 1) : null,
          color: AppColors.textMuted,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text('$donated / $required',
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w700)),
        ),
        IconButton(
          icon: const Icon(Icons.add_circle_outline_rounded, size: 20),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          onPressed: () => onChanged(donated + 1),
          color: AppColors.primary,
        ),
        if (shortfall > 0) ...[
          const SizedBox(width: 6),
          Text('$shortfall short',
              style: const TextStyle(fontSize: 11, color: AppColors.danger)),
        ],
      ]),
    );
  }
}
