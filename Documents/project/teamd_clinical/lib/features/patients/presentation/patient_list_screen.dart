import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/patient_model.dart';
import '../../../data/models/enums.dart';
import '../../../data/repositories/patient_repository.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_animations.dart';

class PatientListScreen extends ConsumerStatefulWidget {
  const PatientListScreen({super.key});

  @override
  ConsumerState<PatientListScreen> createState() => _PatientListScreenState();
}

class _PatientListScreenState extends ConsumerState<PatientListScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  WardLocation? _wardFilter;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<PatientModel> _filterPatients(List<PatientModel> patients) {
    var list = patients;
    if (_wardFilter != null) {
      list = list.where((p) => p.ward == _wardFilter).toList();
    }
    if (_query.isNotEmpty) {
      list = list
          .where((p) =>
              p.fullName.toLowerCase().contains(_query) ||
              p.folderNumber.toLowerCase().contains(_query) ||
              (p.diagnosis?.toLowerCase().contains(_query) ?? false))
          .toList();
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final inpatientsAsync = ref.watch(activePatientsProvider);
    final sameDayAsync = ref.watch(sameDayPatientsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Patients'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(54),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Search name or folder number…',
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded, size: 18),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _query = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.divider),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.divider),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                ),
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go(Routes.admitPatient),
        icon: const Icon(Icons.person_add_rounded),
        label: const Text('Admit'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(activePatientsProvider);
          ref.invalidate(sameDayPatientsProvider);
        },
        child: CustomScrollView(
          slivers: [
            // ── Ward filter chips ──────────────────────────────────────
            SliverToBoxAdapter(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                child: Row(children: [
                  _WardChip(
                    label: 'All',
                    selected: _wardFilter == null,
                    onTap: () => setState(() => _wardFilter = null),
                  ),
                  const SizedBox(width: 6),
                  ...WardLocation.values.map((w) => Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: _WardChip(
                          label: w.label,
                          selected: _wardFilter == w,
                          onTap: () => setState(
                              () => _wardFilter = _wardFilter == w ? null : w),
                        ),
                      )),
                ]),
              ),
            ),

            // ── Same Day section ───────────────────────────────────────
            sameDayAsync.when(
              loading: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
              error: (_, __) => const SliverToBoxAdapter(child: SizedBox.shrink()),
              data: (sameDayPatients) {
                final filtered = _filterPatients(sameDayPatients);
                if (filtered.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());
                return SliverToBoxAdapter(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      child: Row(children: [
                        Container(
                          width: 8, height: 8,
                          decoration: const BoxDecoration(
                              color: Color(0xFFF39C12), shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 8),
                        Text('Same Day (${filtered.length})',
                            style: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w800,
                                color: Color(0xFFF39C12), letterSpacing: 0.5)),
                      ]),
                    ),
                    ...filtered.asMap().entries.map((e) => AnimatedMount(
                          delay: Duration(milliseconds: e.key * 55),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                            child: _SameDayCard(patient: e.value),
                          ),
                        )),
                    const Padding(
                        padding: EdgeInsets.fromLTRB(16, 4, 16, 0),
                        child: Divider()),
                  ]),
                );
              },
            ),

            // ── Inpatients ─────────────────────────────────────────────
            inpatientsAsync.when(
              loading: () => const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator())),
              error: (e, _) =>
                  SliverFillRemaining(child: Center(child: Text('Error: $e'))),
              data: (patients) {
                final filtered = _filterPatients(patients);

                if (filtered.isEmpty && _query.isEmpty && _wardFilter == null) {
                  return const SliverFillRemaining(
                    child: Center(
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(Icons.people_outline_rounded, size: 48, color: AppColors.textMuted),
                        SizedBox(height: 12),
                        Text('No inpatients', style: TextStyle(color: AppColors.textSecondary)),
                        SizedBox(height: 4),
                        Text('Tap Admit to add a patient',
                            style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                      ]),
                    ),
                  );
                }

                if (filtered.isEmpty) {
                  return SliverFillRemaining(
                    child: Center(
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        const Icon(Icons.search_off_rounded, size: 40, color: AppColors.textMuted),
                        const SizedBox(height: 12),
                        Text(
                          _query.isNotEmpty
                              ? 'No patients matching "$_query"'
                              : 'No patients in ${_wardFilter?.label}',
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                        ),
                      ]),
                    ),
                  );
                }

                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) {
                        if (i == 0) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(children: [
                              const Icon(Icons.bed_rounded, size: 14, color: AppColors.textMuted),
                              const SizedBox(width: 6),
                              Text('Inpatients (${filtered.length})',
                                  style: const TextStyle(
                                      fontSize: 12, fontWeight: FontWeight.w700,
                                      color: AppColors.textSecondary, letterSpacing: 0.4)),
                            ]),
                          );
                        }
                        return AnimatedMount(
                          delay: Duration(milliseconds: i * 45),
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _PatientCard(patient: filtered[i - 1]),
                          ),
                        );
                      },
                      childCount: filtered.length + 1,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ── Ward chip ────────────────────────────────────────────────────────────────

class _WardChip extends StatelessWidget {
  const _WardChip({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? AppColors.primary : AppColors.divider),
        ),
        child: Text(label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : AppColors.textSecondary,
            )),
      ),
    );
  }
}

// ── Same Day Card ─────────────────────────────────────────────────────────────

class _SameDayCard extends ConsumerWidget {
  const _SameDayCard({required this.patient});
  final PatientModel patient;

  static const _visitLabels = {
    'walk_in': 'Walk-in',
    'emergency': 'Emergency',
    'procedure': 'Day Procedure',
    'review': 'Review',
    'other': 'Other',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final label = _visitLabels[patient.visitType] ?? 'Same Day';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF39C12).withValues(alpha: 0.3)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        onTap: () => context.go('/patients/${patient.id}'),
        leading: Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFFF39C12).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.wb_sunny_outlined, color: Color(0xFFF39C12), size: 20),
        ),
        title: Text(patient.fullName,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        subtitle: Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFF39C12).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(label,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFFF39C12))),
          ),
          const SizedBox(width: 6),
          Text(patient.folderNumber,
              style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
        ]),
        trailing: TextButton(
          onPressed: () => _closeVisitSheet(context, ref),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.success,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: const Text('Close Visit', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
        ),
      ),
    );
  }

  void _closeVisitSheet(BuildContext context, WidgetRef ref) {
    final visitTypeCtrl = ValueNotifier<String>(patient.visitType ?? 'walk_in');
    final noteCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(Icons.check_circle_outline, color: AppColors.success),
            const SizedBox(width: 8),
            Expanded(child: Text('Close visit — ${patient.fullName}',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700))),
          ]),
          const SizedBox(height: 4),
          Text('Folder: ${patient.folderNumber}',
              style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
          const SizedBox(height: 16),
          const Text('What type of visit was this?',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          ValueListenableBuilder<String>(
            valueListenable: visitTypeCtrl,
            builder: (_, selected, __) => Wrap(
              spacing: 8, runSpacing: 8,
              children: {
                'walk_in': 'Walk-in', 'emergency': 'Emergency',
                'procedure': 'Day Procedure', 'review': 'Review', 'other': 'Other',
              }.entries.map((e) {
                final isSel = selected == e.key;
                return GestureDetector(
                  onTap: () => visitTypeCtrl.value = e.key,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSel ? AppColors.primary.withValues(alpha: 0.1) : AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: isSel ? AppColors.primary : AppColors.divider),
                    ),
                    child: Text(e.value, style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSel ? FontWeight.w700 : FontWeight.normal,
                        color: isSel ? AppColors.primary : AppColors.textSecondary)),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: noteCtrl, maxLines: 3, minLines: 2,
            decoration: const InputDecoration(
              labelText: 'What was done / outcome',
              hintText: 'e.g. Review of lab results, counselled, prescribed medication',
              alignLabelWithHint: true, isDense: true,
            ),
            style: const TextStyle(fontSize: 13),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(patientRepositoryProvider).closeVisit(
                    patientId: patient.id,
                    visitType: visitTypeCtrl.value,
                    visitNote: noteCtrl.text.trim(),
                  );
              ref.invalidate(sameDayPatientsProvider);
              ref.invalidate(activePatientsProvider);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('Visit closed for ${patient.fullName}'),
                  backgroundColor: AppColors.success,
                ));
              }
            },
            style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(44), backgroundColor: AppColors.success),
            child: const Text('Close & Discharge'),
          ),
        ]),
      ),
    );
  }
}

// ── Inpatient Card ────────────────────────────────────────────────────────────

class _PatientCard extends StatelessWidget {
  const _PatientCard({required this.patient});
  final PatientModel patient;

  @override
  Widget build(BuildContext context) {
    final hasRisk = patient.hasAllergies || patient.isSickleCellRisk || patient.previousCs;

    return TapCard(
      onTap: () => context.go('/patients/${patient.id}'),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: hasRisk
                ? AppColors.warning.withValues(alpha: 0.35)
                : AppColors.divider.withValues(alpha: 0.6),
            width: hasRisk ? 1.2 : 0.5,
          ),
        ),
        child: Row(children: [
          // Avatar
          CircleAvatar(
            radius: 22,
            backgroundColor: patient.admissionType == AdmissionType.obstetrics
                ? AppColors.primaryLight.withValues(alpha: 0.12)
                : AppColors.accent.withValues(alpha: 0.12),
            child: Text(
              patient.fullName[0].toUpperCase(),
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: patient.admissionType == AdmissionType.obstetrics
                    ? AppColors.primaryLight
                    : AppColors.accent,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Info
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(
                  child: Text(patient.fullName,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                ),
                if (patient.hasAllergies)
                  _RiskDot(color: AppColors.danger, tooltip: 'Allergies'),
                if (patient.isSickleCellRisk)
                  _RiskDot(color: AppColors.warning, tooltip: 'Sickle cell risk'),
                if (patient.previousCs)
                  _RiskDot(color: AppColors.warning, tooltip: 'Previous C/S'),
              ]),
              const SizedBox(height: 3),
              Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Text(patient.ward.label,
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                ),
                const SizedBox(width: 6),
                if (patient.diagnosis != null)
                  Expanded(
                    child: Text(patient.diagnosis!,
                        style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
              ]),
            ]),
          ),

          const SizedBox(width: 8),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(patient.folderNumber,
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.w500)),
            const SizedBox(height: 2),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: patient.daysAdmitted > 7
                    ? AppColors.warning.withValues(alpha: 0.1)
                    : AppColors.surface,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text('Day ${patient.daysAdmitted}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: patient.daysAdmitted > 7 ? AppColors.warning : AppColors.textSecondary,
                  )),
            ),
          ]),
        ]),
      ),
    );
  }
}

class _RiskDot extends StatelessWidget {
  const _RiskDot({required this.color, required this.tooltip});
  final Color color;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Container(
        width: 8, height: 8,
        margin: const EdgeInsets.only(left: 4),
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
  }
}
