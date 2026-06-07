import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_animations.dart';
import '../../../data/repositories/patient_repository.dart';
import '../../../data/models/patient_model.dart';

// ── State ─────────────────────────────────────────────────────────────────────

class _PatientAdmissionState {
  final String patientId;
  final String patientName;
  final String folderNumber;
  bool isCancerCase;
  // Checklist items
  bool labsDone;
  bool fbcOrdered;
  bool bueCrOrdered;
  bool lftOrdered;           // cancer only
  bool clottingOrdered;      // cancer only
  bool cxrOrdered;           // cancer only
  bool gxmFormFilled;
  bool gxmSampleSent;
  bool consentSigned;
  bool examinationDone;
  bool redFlagsChecked;
  bool redFlagPresent;
  bool donationSlipCollected;
  bool theatreListConfirmed;
  bool bloodBankConfirmed;
  String notes;

  _PatientAdmissionState({
    required this.patientId,
    required this.patientName,
    required this.folderNumber,
    this.isCancerCase = false,
    this.labsDone = false,
    this.fbcOrdered = false,
    this.bueCrOrdered = false,
    this.lftOrdered = false,
    this.clottingOrdered = false,
    this.cxrOrdered = false,
    this.gxmFormFilled = false,
    this.gxmSampleSent = false,
    this.consentSigned = false,
    this.examinationDone = false,
    this.redFlagsChecked = false,
    this.redFlagPresent = false,
    this.donationSlipCollected = false,
    this.theatreListConfirmed = false,
    this.bloodBankConfirmed = false,
    this.notes = '',
  });

  int get totalItems {
    int base = 8; // labs, gxm x2, consent, exam, red flag, donation, end-of-day x2
    if (!labsDone) base += 2; // fbc + bue
    if (isCancerCase) base += 3; // lft + clotting + cxr
    return base;
  }

  int get completedItems {
    int done = 0;
    if (labsDone) done++;
    if (!labsDone) {
      if (fbcOrdered) done++;
      if (bueCrOrdered) done++;
    }
    if (isCancerCase) {
      if (lftOrdered) done++;
      if (clottingOrdered) done++;
      if (cxrOrdered) done++;
    }
    if (gxmFormFilled) done++;
    if (gxmSampleSent) done++;
    if (consentSigned) done++;
    if (examinationDone) done++;
    if (redFlagsChecked) done++;
    if (donationSlipCollected) done++;
    if (theatreListConfirmed) done++;
    if (bloodBankConfirmed) done++;
    return done;
  }

  double get progress => totalItems == 0 ? 0 : completedItems / totalItems;
  bool get isReadyForTheatre => progress >= 0.85;

  _PatientAdmissionState copyWith({
    bool? isCancerCase,
    bool? labsDone,
    bool? fbcOrdered,
    bool? bueCrOrdered,
    bool? lftOrdered,
    bool? clottingOrdered,
    bool? cxrOrdered,
    bool? gxmFormFilled,
    bool? gxmSampleSent,
    bool? consentSigned,
    bool? examinationDone,
    bool? redFlagsChecked,
    bool? redFlagPresent,
    bool? donationSlipCollected,
    bool? theatreListConfirmed,
    bool? bloodBankConfirmed,
    String? notes,
  }) {
    return _PatientAdmissionState(
      patientId: patientId,
      patientName: patientName,
      folderNumber: folderNumber,
      isCancerCase: isCancerCase ?? this.isCancerCase,
      labsDone: labsDone ?? this.labsDone,
      fbcOrdered: fbcOrdered ?? this.fbcOrdered,
      bueCrOrdered: bueCrOrdered ?? this.bueCrOrdered,
      lftOrdered: lftOrdered ?? this.lftOrdered,
      clottingOrdered: clottingOrdered ?? this.clottingOrdered,
      cxrOrdered: cxrOrdered ?? this.cxrOrdered,
      gxmFormFilled: gxmFormFilled ?? this.gxmFormFilled,
      gxmSampleSent: gxmSampleSent ?? this.gxmSampleSent,
      consentSigned: consentSigned ?? this.consentSigned,
      examinationDone: examinationDone ?? this.examinationDone,
      redFlagsChecked: redFlagsChecked ?? this.redFlagsChecked,
      redFlagPresent: redFlagPresent ?? this.redFlagPresent,
      donationSlipCollected: donationSlipCollected ?? this.donationSlipCollected,
      theatreListConfirmed: theatreListConfirmed ?? this.theatreListConfirmed,
      bloodBankConfirmed: bloodBankConfirmed ?? this.bloodBankConfirmed,
      notes: notes ?? this.notes,
    );
  }
}

// ── Main Screen ───────────────────────────────────────────────────────────────

class PreopAdmissionScreen extends ConsumerStatefulWidget {
  const PreopAdmissionScreen({super.key});

  @override
  ConsumerState<PreopAdmissionScreen> createState() =>
      _PreopAdmissionScreenState();
}

class _PreopAdmissionScreenState extends ConsumerState<PreopAdmissionScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;
  final List<_PatientAdmissionState> _patients = [];
  bool _protocolExpanded = false;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  void _addPatient(PatientModel p) {
    if (_patients.any((x) => x.patientId == p.id)) return;
    setState(() {
      _patients.add(_PatientAdmissionState(
        patientId: p.id,
        patientName: p.fullName,
        folderNumber: p.folderNumber,
      ));
    });
  }

  void _update(int i, _PatientAdmissionState updated) {
    setState(() => _patients[i] = updated);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Pre-Op Admission', style: TextStyle(fontSize: 16)),
            Text('Admission day checklist', style: TextStyle(fontSize: 12, color: Colors.white70)),
          ],
        ),
        bottom: TabBar(
          controller: _tabCtrl,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white54,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Admission Checklist'),
            Tab(text: 'Protocol'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _buildChecklist(),
          _buildProtocol(),
        ],
      ),
    );
  }

  // ── Tab 1: Checklist ──────────────────────────────────────────
  Widget _buildChecklist() {
    final patientsAsync = ref.watch(activePatientsProvider);

    return Column(
      children: [
        // ── End-of-day global tasks ──────────────────────────────
        Container(
          margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Row(children: [
              Icon(Icons.schedule, size: 16, color: AppColors.primary),
              SizedBox(width: 6),
              Text('Before leaving today',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary)),
            ]),
            const SizedBox(height: 6),
            _globalCheckItem(
              'Theatre list printed and sent',
              _patients.isNotEmpty && _patients.every((p) => p.theatreListConfirmed),
              'Pass by theatre — confirm printed list has been sent',
            ),
            _globalCheckItem(
              'Blood bank has list & samples confirmed',
              _patients.isNotEmpty && _patients.every((p) => p.bloodBankConfirmed),
              'Pass by blood bank — confirm they have the list and all samples',
            ),
          ]),
        ),

        // ── Add patients from ward ─────────────────────────────
        patientsAsync.when(
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
          data: (allPatients) {
            final surgical = allPatients
                .where((p) => !_patients.any((x) => x.patientId == p.id))
                .toList();
            if (surgical.isEmpty) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: OutlinedButton.icon(
                onPressed: () => _showAddPatientSheet(context, surgical),
                icon: const Icon(Icons.add, size: 16),
                label: Text(
                  'Add patient to checklist (${surgical.length} scheduled)',
                  style: const TextStyle(fontSize: 13),
                ),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(40),
                ),
              ),
            );
          },
        ),

        const SizedBox(height: 8),

        // ── Patient cards ─────────────────────────────────────
        Expanded(
          child: _patients.isEmpty
              ? _emptyState()
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                  itemCount: _patients.length,
                  itemBuilder: (_, i) => AnimatedMount(
                    delay: Duration(milliseconds: i * 60),
                    child: _PatientAdmissionCard(
                      state: _patients[i],
                      index: i,
                      onUpdate: (updated) => _update(i, updated),
                      onRemove: () => setState(() => _patients.removeAt(i)),
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _globalCheckItem(String label, bool done, String hint) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(children: [
        Icon(
          done ? Icons.check_circle : Icons.radio_button_unchecked,
          size: 18,
          color: done ? AppColors.success : AppColors.textMuted,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(label,
              style: TextStyle(
                fontSize: 13,
                color: done ? AppColors.textMuted : AppColors.textPrimary,
                decoration: done ? TextDecoration.lineThrough : null,
              )),
        ),
      ]),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.assignment_outlined,
            size: 52, color: AppColors.textMuted.withValues(alpha: 0.4)),
        const SizedBox(height: 16),
        const Text('No patients added yet',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
        const SizedBox(height: 6),
        const Text(
          'Add patients from tomorrow\'s theatre list\nto start tracking their admission checklist.',
          style: TextStyle(fontSize: 13, color: AppColors.textMuted),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        OutlinedButton.icon(
          onPressed: () => _showManualAddSheet(context),
          icon: const Icon(Icons.person_add_outlined, size: 16),
          label: const Text('Add manually'),
        ),
      ]),
    );
  }

  void _showAddPatientSheet(BuildContext context, List<PatientModel> patients) {
    showModalBottomSheet(
      context: context,
      builder: (_) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Add to checklist',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          ...patients.map((p) => ListTile(
                leading: const CircleAvatar(
                    child: Icon(Icons.person_outline, size: 18)),
                title: Text(p.fullName, style: const TextStyle(fontSize: 14)),
                subtitle: Text(p.folderNumber,
                    style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                onTap: () {
                  _addPatient(p);
                  Navigator.pop(context);
                },
              )),
        ],
      ),
    );
  }

  void _showManualAddSheet(BuildContext context) {
    final nameCtrl = TextEditingController();
    final folderCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsets.fromLTRB(
            16, 16, 16, MediaQuery.of(context).viewInsets.bottom + 16),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Add patient manually',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          TextFormField(
            controller: nameCtrl,
            decoration: const InputDecoration(labelText: 'Patient name', isDense: true),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: folderCtrl,
            decoration: const InputDecoration(labelText: 'Folder number', isDense: true),
          ),
          const SizedBox(height: 14),
          FilledButton(
            onPressed: () {
              if (nameCtrl.text.trim().isNotEmpty) {
                setState(() {
                  _patients.add(_PatientAdmissionState(
                    patientId: DateTime.now().millisecondsSinceEpoch.toString(),
                    patientName: nameCtrl.text.trim(),
                    folderNumber: folderCtrl.text.trim(),
                  ));
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(44)),
          ),
        ]),
      ),
    );
  }

  // ── Tab 2: Protocol ───────────────────────────────────────────
  Widget _buildProtocol() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _protocolCard(
          icon: Icons.phone_outlined,
          color: const Color(0xFF8E44AD),
          title: 'Patient Reminders (Weeks Before)',
          items: const [
            _ProtocolItem('Obtain theatre list for current and following week', isHeader: true),
            _ProtocolItem('Call patients 2 weeks before surgery'),
            _ProtocolItem('Call patients again 1 week before surgery'),
            _ProtocolItem('Remind: surgery date, admission date'),
            _ProtocolItem('Confirm attendance'),
            _ProtocolItem('Advise: report to ward EARLY in the morning on admission day — NOT in the evening'),
          ],
        ),
        const SizedBox(height: 12),
        _protocolCard(
          icon: Icons.local_hospital_outlined,
          color: AppColors.primary,
          title: 'Admission Day',
          items: const [
            _ProtocolItem('Review anaesthesia clearance form', isHeader: true),
            _ProtocolItem('Confirm all investigations done (FBC, BU/Cr, LFTs) and results available'),
            _ProtocolItem('Confirm blood donation — inspect donation slips & take photos'),
            _ProtocolItem('Send blood for grouping and cross-matching (fill GXM forms, add folder numbers, send to maternity blood bank)'),
            _ProtocolItem('Labs < 1 week old? If not — write FBC + BUE/Cr. Give Mr Wisdom\'s number for sample collection'),
            _ProtocolItem('Cancer patients: add LFT, clotting profile, and Chest X-ray'),
            _ProtocolItem('Check availability of pre-op, intra-op, and post-op drugs. Prescribe missing ones'),
            _ProtocolItem('Complete clerking, consent, and documentation'),
            _ProtocolItem('Examine every patient'),
            _ProtocolItem('Any red flags → call Dr Neequaye IMMEDIATELY'),
          ],
        ),
        const SizedBox(height: 12),
        _protocolCard(
          icon: Icons.wb_sunny_outlined,
          color: AppColors.warning,
          title: 'Day of Surgery',
          items: const [
            _ProtocolItem('Arrive on ward by 6:00 AM', isHeader: true),
            _ProtocolItem('Review all scheduled patients'),
            _ProtocolItem('Confirm investigations, blood availability, and consent'),
            _ProtocolItem('Ensure each patient has a functioning IV line with prescribed IV fluids/medications'),
            _ProtocolItem('Ensure nurses transfer patients to theatre by 7:00 AM'),
            _ProtocolItem('Confirm all notes, investigation results, and medications accompany the patient'),
            _ProtocolItem('Pass by theatre — confirm printed list has been sent'),
            _ProtocolItem('Pass by blood bank — confirm they have the list and all samples have been received'),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.danger.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.danger.withValues(alpha: 0.2)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Row(children: [
              Icon(Icons.warning_amber_rounded, color: AppColors.danger, size: 20),
              SizedBox(width: 8),
              Text('Key Contacts',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.danger)),
            ]),
            const SizedBox(height: 10),
            _contactRow('Mr. Wisdom', 'Lab samples — GXM, grouping & cross-matching'),
            _contactRow('Dr. Neequaye', 'Call immediately for any red flags'),
            _contactRow('Maternity Blood Bank', 'GXM forms + confirm sample receipt'),
          ]),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _contactRow(String name, String role) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Icon(Icons.person_outline, size: 16, color: AppColors.textMuted),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(fontSize: 13),
              children: [
                TextSpan(text: '$name — ',
                    style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                TextSpan(text: role,
                    style: const TextStyle(color: AppColors.textSecondary)),
              ],
            ),
          ),
        ),
      ]),
    );
  }

  Widget _protocolCard({
    required IconData icon,
    required Color color,
    required String title,
    required List<_ProtocolItem> items,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(title,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            ),
          ]),
          const SizedBox(height: 12),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Icon(
                      item.isHeader ? Icons.star_rounded : Icons.arrow_right_rounded,
                      size: 16,
                      color: item.isHeader ? color : AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      item.text,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textPrimary,
                        fontWeight: item.isHeader ? FontWeight.w600 : FontWeight.normal,
                        height: 1.4,
                      ),
                    ),
                  ),
                ]),
              )),
        ]),
      ),
    );
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }
}

// ── Patient Admission Card ────────────────────────────────────────────────────

class _PatientAdmissionCard extends StatefulWidget {
  const _PatientAdmissionCard({
    required this.state,
    required this.index,
    required this.onUpdate,
    required this.onRemove,
  });

  final _PatientAdmissionState state;
  final int index;
  final ValueChanged<_PatientAdmissionState> onUpdate;
  final VoidCallback onRemove;

  @override
  State<_PatientAdmissionCard> createState() => _PatientAdmissionCardState();
}

class _PatientAdmissionCardState extends State<_PatientAdmissionCard> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final s = widget.state;
    final progress = s.progress;
    final isReady = s.isReadyForTheatre;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isReady
              ? AppColors.success.withValues(alpha: 0.4)
              : AppColors.divider.withValues(alpha: 0.7),
          width: isReady ? 1.5 : 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Header ───────────────────────────────────────────
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  // Ready indicator
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isReady ? AppColors.success : AppColors.warning,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(s.patientName,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                      Text('Folder: ${s.folderNumber}',
                          style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                    ]),
                  ),
                  if (s.redFlagPresent)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.danger.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
                      ),
                      child: const Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.warning_rounded, size: 12, color: AppColors.danger),
                        SizedBox(width: 4),
                        Text('RED FLAG', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.danger)),
                      ]),
                    ),
                  const SizedBox(width: 8),
                  Icon(_expanded ? Icons.expand_less : Icons.expand_more,
                      color: AppColors.textMuted, size: 20),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, size: 18, color: AppColors.textMuted),
                    onSelected: (v) {
                      if (v == 'remove') widget.onRemove();
                      if (v == 'cancer') {
                        widget.onUpdate(s.copyWith(isCancerCase: !s.isCancerCase));
                      }
                    },
                    itemBuilder: (_) => [
                      PopupMenuItem(
                        value: 'cancer',
                        child: Row(children: [
                          Icon(s.isCancerCase ? Icons.check_box : Icons.check_box_outline_blank,
                              size: 18, color: AppColors.danger),
                          const SizedBox(width: 8),
                          const Text('Cancer case'),
                        ]),
                      ),
                      const PopupMenuItem(
                        value: 'remove',
                        child: Row(children: [
                          Icon(Icons.remove_circle_outline, size: 18, color: AppColors.danger),
                          SizedBox(width: 8),
                          Text('Remove'),
                        ]),
                      ),
                    ],
                  ),
                ]),
                const SizedBox(height: 8),
                // Progress bar
                Row(children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 5,
                        backgroundColor: AppColors.divider,
                        valueColor: AlwaysStoppedAnimation(
                          isReady ? AppColors.success : AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${(progress * 100).round()}%',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isReady ? AppColors.success : AppColors.primary,
                    ),
                  ),
                ]),
                if (s.isCancerCase)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.danger.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text('Cancer case — LFT, Clotting, CXR required',
                          style: TextStyle(fontSize: 11, color: AppColors.danger, fontWeight: FontWeight.w600)),
                    ),
                  ),
              ]),
            ),
          ),

          // ── Checklist (collapsible) ───────────────────────────
          if (_expanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                // LABS
                _sectionHeader('1. Laboratories'),
                _checkTile(
                  label: 'Labs are < 1 week old ✓',
                  checked: s.labsDone,
                  onChanged: (v) => widget.onUpdate(s.copyWith(labsDone: v)),
                ),
                if (!s.labsDone) ...[
                  _checkTile(
                    label: 'FBC ordered / given Mr Wisdom\'s number',
                    checked: s.fbcOrdered,
                    onChanged: (v) => widget.onUpdate(s.copyWith(fbcOrdered: v)),
                    indent: true,
                  ),
                  _checkTile(
                    label: 'BUE + Creatinine ordered',
                    checked: s.bueCrOrdered,
                    onChanged: (v) => widget.onUpdate(s.copyWith(bueCrOrdered: v)),
                    indent: true,
                  ),
                ],
                if (s.isCancerCase) ...[
                  _checkTile(
                    label: 'LFT ordered (cancer)',
                    checked: s.lftOrdered,
                    onChanged: (v) => widget.onUpdate(s.copyWith(lftOrdered: v)),
                    indent: true,
                    danger: true,
                  ),
                  _checkTile(
                    label: 'Clotting profile ordered (cancer)',
                    checked: s.clottingOrdered,
                    onChanged: (v) => widget.onUpdate(s.copyWith(clottingOrdered: v)),
                    indent: true,
                    danger: true,
                  ),
                  _checkTile(
                    label: 'Chest X-ray requested (cancer)',
                    checked: s.cxrOrdered,
                    onChanged: (v) => widget.onUpdate(s.copyWith(cxrOrdered: v)),
                    indent: true,
                    danger: true,
                  ),
                ],

                const SizedBox(height: 8),
                _sectionHeader('2. Blood'),
                _checkTile(
                  label: 'GXM form filled (folder number added)',
                  checked: s.gxmFormFilled,
                  onChanged: (v) => widget.onUpdate(s.copyWith(gxmFormFilled: v)),
                ),
                _checkTile(
                  label: 'Sample sent to maternity blood bank',
                  checked: s.gxmSampleSent,
                  onChanged: (v) => widget.onUpdate(s.copyWith(gxmSampleSent: v)),
                ),
                _checkTile(
                  label: 'Donation slip collected & photographed',
                  checked: s.donationSlipCollected,
                  onChanged: (v) => widget.onUpdate(s.copyWith(donationSlipCollected: v)),
                ),

                const SizedBox(height: 8),
                _sectionHeader('3. Clinical'),
                _checkTile(
                  label: 'Consent form signed',
                  checked: s.consentSigned,
                  onChanged: (v) => widget.onUpdate(s.copyWith(consentSigned: v)),
                ),
                _checkTile(
                  label: 'Patient examined',
                  checked: s.examinationDone,
                  onChanged: (v) => widget.onUpdate(s.copyWith(examinationDone: v)),
                ),
                _checkTile(
                  label: 'Red flags checked',
                  checked: s.redFlagsChecked,
                  onChanged: (v) => widget.onUpdate(s.copyWith(redFlagsChecked: v)),
                ),
                if (s.redFlagsChecked)
                  _checkTile(
                    label: 'RED FLAG PRESENT → Dr Neequaye called',
                    checked: s.redFlagPresent,
                    onChanged: (v) => widget.onUpdate(s.copyWith(redFlagPresent: v)),
                    indent: true,
                    danger: true,
                  ),

                const SizedBox(height: 8),
                _sectionHeader('4. Before leaving'),
                _checkTile(
                  label: 'Theatre — printed list sent ✓',
                  checked: s.theatreListConfirmed,
                  onChanged: (v) => widget.onUpdate(s.copyWith(theatreListConfirmed: v)),
                ),
                _checkTile(
                  label: 'Blood bank — list received & samples confirmed ✓',
                  checked: s.bloodBankConfirmed,
                  onChanged: (v) => widget.onUpdate(s.copyWith(bloodBankConfirmed: v)),
                ),

                // Notes
                const SizedBox(height: 12),
                TextFormField(
                  initialValue: s.notes,
                  maxLines: 2,
                  minLines: 1,
                  onChanged: (v) => widget.onUpdate(s.copyWith(notes: v)),
                  decoration: const InputDecoration(
                    hintText: 'Notes for this patient...',
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                  style: const TextStyle(fontSize: 13),
                ),
              ]),
            ),
          ],
        ],
      ),
    );
  }

  Widget _sectionHeader(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: AppColors.textMuted,
            letterSpacing: 0.5,
          )),
    );
  }

  Widget _checkTile({
    required String label,
    required bool checked,
    required ValueChanged<bool> onChanged,
    bool indent = false,
    bool danger = false,
  }) {
    return InkWell(
      onTap: () => onChanged(!checked),
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: EdgeInsets.fromLTRB(indent ? 16 : 0, 5, 0, 5),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(
            checked ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
            size: 20,
            color: checked
                ? (danger ? AppColors.danger : AppColors.success)
                : AppColors.textMuted,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: checked
                    ? AppColors.textMuted
                    : (danger ? AppColors.danger : AppColors.textPrimary),
                decoration: checked ? TextDecoration.lineThrough : null,
                fontWeight: danger && !checked ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

// ── Data class ────────────────────────────────────────────────────────────────

class _ProtocolItem {
  final String text;
  final bool isHeader;
  const _ProtocolItem(this.text, {this.isHeader = false});
}
