import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/patient_model.dart';
import '../../../data/models/enums.dart';
import '../providers/clinical_providers.dart';

class DailyReviewScreen extends ConsumerStatefulWidget {
  const DailyReviewScreen({super.key, required this.patient});
  final PatientModel patient;

  @override
  ConsumerState<DailyReviewScreen> createState() => _DailyReviewScreenState();
}

class _DailyReviewScreenState extends ConsumerState<DailyReviewScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;
  bool _saving = false;

  // ── Common ────────────────────────────────────────────────────
  final _complaintCtrl = TextEditingController();
  final _pulseCtrl = TextEditingController();
  final _bpCtrl = TextEditingController();
  final _rrCtrl = TextEditingController();
  final _spo2Ctrl = TextEditingController();
  final _tempCtrl = TextEditingController();
  final _planCtrl = TextEditingController();
  final _investigationsCtrl = TextEditingController();
  final _generatedNoteCtrl = TextEditingController();

  // ── Obstetric specific ─────────────────────────────────────────
  final _sfhCtrl = TextEditingController();
  final _fhrCtrl = TextEditingController();
  String _fetalMovement = 'Good';
  String _contractions = 'None';
  String _liquor = 'Clear';
  String _bleeding = 'None';

  // ── Post-Op specific ──────────────────────────────────────────
  int _postopDay = 1;
  bool _bowelSoundsPresent = false;
  bool _catheterRemoved = false;
  bool _oralIntakeStarted = false;
  bool _ivAntibioticsSwitched = false;
  bool _woundInspected = false;
  bool _woundGood = false;

  // ── Gynae specific ────────────────────────────────────────────
  final _vagBleedCtrl = TextEditingController();
  final _abdExamCtrl = TextEditingController();
  String _reviewType = 'obstetric';

  bool get _isGynae => widget.patient.admissionType == AdmissionType.gynaecology;

  @override
  void initState() {
    super.initState();
    _reviewType = _isGynae ? 'gynae' : 'obstetric';
    _tabCtrl = TabController(length: _isGynae ? 2 : 3, vsync: this);
    _tabCtrl.addListener(_generateNote);
  }

  void _generateNote() {
    final buf = StringBuffer();
    final today = DateFormat('dd/MM/yyyy').format(DateTime.now());

    if (_reviewType == 'postop_day${_postopDay}' || _reviewType.startsWith('postop')) {
      buf.writeln('Post-Op Day $_postopDay Review — $today\n');
    } else {
      buf.writeln('${_reviewType == 'obstetric' ? 'Obstetric' : 'Gynaecology'} Ward Review — $today\n');
    }

    if (_complaintCtrl.text.isNotEmpty) {
      buf.writeln('Complaints: ${_complaintCtrl.text}\n');
    }

    // Vitals
    if (_pulseCtrl.text.isNotEmpty || _bpCtrl.text.isNotEmpty) {
      buf.write('Vitals: ');
      if (_pulseCtrl.text.isNotEmpty) buf.write('P ${_pulseCtrl.text} bpm, ');
      if (_bpCtrl.text.isNotEmpty) buf.write('BP ${_bpCtrl.text} mmHg, ');
      if (_rrCtrl.text.isNotEmpty) buf.write('RR ${_rrCtrl.text} cpm, ');
      if (_spo2Ctrl.text.isNotEmpty) buf.write('SpO2 ${_spo2Ctrl.text}%, ');
      if (_tempCtrl.text.isNotEmpty) buf.write('T ${_tempCtrl.text}°C');
      buf.write('\n\n');
    }

    if (_reviewType == 'obstetric') {
      buf.write('Obstetric: ');
      if (_sfhCtrl.text.isNotEmpty) buf.write('SFH ${_sfhCtrl.text} cm, ');
      if (_fhrCtrl.text.isNotEmpty) buf.write('FHR ${_fhrCtrl.text} bpm, ');
      buf.write('FM $_fetalMovement, Liquor $_liquor, Bleeding $_bleeding, Ctx $_contractions\n\n');
    }

    if (_reviewType.startsWith('postop') || _reviewType == 'svd') {
      buf.writeln('Post-Op Status:');
      buf.writeln('- Bowel sounds: ${_bowelSoundsPresent ? 'Present' : 'Absent'}');
      buf.writeln('- Oral intake: ${_oralIntakeStarted ? 'Started' : 'Not yet started'}');
      buf.writeln('- Catheter: ${_catheterRemoved ? 'Removed' : 'In situ'}');
      buf.writeln('- IV antibiotics: ${_ivAntibioticsSwitched ? 'Switched to oral' : 'Continuing IV'}');
      buf.writeln('- Wound: ${_woundInspected ? (_woundGood ? 'Inspected — healing well' : 'Inspected — concerns noted') : 'Not inspected'}');
      buf.write('\n');
    }

    if (_investigationsCtrl.text.isNotEmpty) {
      buf.writeln('Investigations: ${_investigationsCtrl.text}\n');
    }

    if (_planCtrl.text.isNotEmpty) {
      buf.writeln('Plan:\n${_planCtrl.text}');
    }

    setState(() => _generatedNoteCtrl.text = buf.toString().trim());
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    _generateNote();
    try {
      final data = <String, dynamic>{
        'patient_id': widget.patient.id,
        'review_type': _reviewType,
        'review_date': DateTime.now().toIso8601String().split('T').first,
        if (_complaintCtrl.text.isNotEmpty) 'complaints': _complaintCtrl.text,
        'vitals': {
          'pulse': _pulseCtrl.text,
          'bp': _bpCtrl.text,
          'rr': _rrCtrl.text,
          'spo2': _spo2Ctrl.text,
          'temp': _tempCtrl.text,
        },
        if (_reviewType == 'obstetric') ...{
          'sfh': _sfhCtrl.text,
          'fhr': _fhrCtrl.text,
          'fetal_movement': _fetalMovement,
          'contractions': _contractions,
          'liquor': _liquor,
          'bleeding': _bleeding,
        },
        if (_reviewType.startsWith('postop') || _reviewType == 'svd') ...{
          'postop_day': _postopDay,
          'bowel_sounds_present': _bowelSoundsPresent,
          'catheter_removed': _catheterRemoved,
          'oral_intake_started': _oralIntakeStarted,
          'iv_antibiotics_switched': _ivAntibioticsSwitched,
          'wound_inspected': _woundInspected,
        },
        if (_investigationsCtrl.text.isNotEmpty) 'investigations': _investigationsCtrl.text,
        if (_planCtrl.text.isNotEmpty) 'plan': _planCtrl.text,
        'generated_note': _generatedNoteCtrl.text,
      };

      await ref.read(clinicalActionsProvider).saveReview(data);
      ref.invalidate(patientReviewsProvider(widget.patient.id));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Review saved'), backgroundColor: AppColors.success),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Daily Review', style: TextStyle(fontSize: 16)),
          Text(widget.patient.fullName,
              style: const TextStyle(fontSize: 12, color: Colors.white70)),
        ]),
        bottom: TabBar(
          controller: _tabCtrl,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white54,
          indicatorColor: Colors.white,
          tabs: _isGynae
              ? const [Tab(text: 'Review'), Tab(text: 'Note Preview')]
              : const [Tab(text: 'Review'), Tab(text: 'Post-Op'), Tab(text: 'Note Preview')],
        ),
        actions: [
          _saving
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)))
              : TextButton(
                  onPressed: _save,
                  child: const Text('Save', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                ),
        ],
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _buildMainReview(),
          if (!_isGynae) _buildPostOp(),
          _buildNotePreview(),
        ],
      ),
    );
  }

  Widget _buildMainReview() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Review type selector
        _card('Review Type', [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (!_isGynae) ...[
                _typeChip('Obstetric Review', 'obstetric'),
                _typeChip('Post-Op Day 1', 'postop_day1'),
                _typeChip('Post-Op Day 2', 'postop_day2'),
                _typeChip('Post-Op Day 3', 'postop_day3'),
                _typeChip('SVD Review', 'svd'),
              ] else ...[
                _typeChip('Gynae Ward Round', 'gynae'),
                _typeChip('Post-Op Day 1', 'postop_day1'),
                _typeChip('Post-Op Day 2', 'postop_day2'),
                _typeChip('Post-Op Day 3', 'postop_day3'),
              ],
            ],
          ),
        ]),

        _card('Complaints', [
          _multilineField('Any new complaints?', _complaintCtrl),
        ]),

        _card('Vitals', [
          Row(children: [
            Expanded(child: _field('Pulse (bpm)', _pulseCtrl)),
            const SizedBox(width: 8),
            Expanded(child: _field('BP (mmHg)', _bpCtrl)),
          ]),
          Row(children: [
            Expanded(child: _field('RR (cpm)', _rrCtrl)),
            const SizedBox(width: 8),
            Expanded(child: _field('SpO2 (%)', _spo2Ctrl)),
          ]),
          _field('Temperature (°C)', _tempCtrl),
        ]),

        if (_reviewType == 'obstetric')
          _card('Obstetric Assessment', [
            Row(children: [
              Expanded(child: _field('SFH (cm)', _sfhCtrl)),
              const SizedBox(width: 8),
              Expanded(child: _field('FHR (bpm)', _fhrCtrl)),
            ]),
            _dropdownRow('Fetal Movement', _fetalMovement,
                ['Good', 'Reduced', 'Absent'], (v) => setState(() { _fetalMovement = v!; _generateNote(); })),
            _dropdownRow('Contractions', _contractions,
                ['None', 'Irregular', 'Regular', 'Frequent'],
                (v) => setState(() { _contractions = v!; _generateNote(); })),
            _dropdownRow('Liquor', _liquor,
                ['Clear', 'Meconium-stained', 'Blood-stained', 'Scanty', 'Absent'],
                (v) => setState(() { _liquor = v!; _generateNote(); })),
            _dropdownRow('Bleeding', _bleeding,
                ['None', 'Spotting', 'Mild', 'Moderate', 'Heavy'],
                (v) => setState(() { _bleeding = v!; _generateNote(); })),
          ]),

        if (_isGynae)
          _card('Gynaecology Examination', [
            _multilineField('Abdominal examination', _abdExamCtrl),
            _multilineField('Vaginal bleeding / discharge', _vagBleedCtrl),
          ]),

        _card('Investigations', [
          _multilineField('Investigation results', _investigationsCtrl),
        ]),

        _card('Plan', [
          _multilineField('Today\'s management plan', _planCtrl),
        ]),
      ],
    );
  }

  Widget _buildPostOp() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _card('Post-Op Day', [
          Row(
            children: List.generate(5, (i) {
              final day = i + 1;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text('Day $day'),
                  selected: _postopDay == day,
                  onSelected: (_) => setState(() { _postopDay = day; _generateNote(); }),
                  selectedColor: AppColors.primary.withValues(alpha: 0.15),
                ),
              );
            }),
          ),
        ]),
        _card('Post-Op Checklist', [
          _checkItem('Bowel sounds present', _bowelSoundsPresent,
              (v) => setState(() { _bowelSoundsPresent = v; _generateNote(); })),
          _checkItem('Oral intake started', _oralIntakeStarted,
              (v) => setState(() { _oralIntakeStarted = v; _generateNote(); })),
          _checkItem('Catheter removed', _catheterRemoved,
              (v) => setState(() { _catheterRemoved = v; _generateNote(); })),
          _checkItem('IV antibiotics switched to oral', _ivAntibioticsSwitched,
              (v) => setState(() { _ivAntibioticsSwitched = v; _generateNote(); })),
          _checkItem('Wound inspected', _woundInspected,
              (v) => setState(() { _woundInspected = v; _generateNote(); })),
          if (_woundInspected)
            _checkItem('Wound healing well', _woundGood,
                (v) => setState(() { _woundGood = v; _generateNote(); })),
        ]),
      ],
    );
  }

  Widget _buildNotePreview() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('Generated Note',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.primary)),
                TextButton.icon(
                  onPressed: _generateNote,
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Refresh', style: TextStyle(fontSize: 13)),
                ),
              ]),
              const SizedBox(height: 10),
              TextFormField(
                controller: _generatedNoteCtrl,
                maxLines: null,
                style: const TextStyle(fontSize: 13, height: 1.6, fontFamily: 'monospace'),
                decoration: const InputDecoration(
                  isDense: true,
                  contentPadding: EdgeInsets.all(12),
                  border: OutlineInputBorder(),
                ),
              ),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _typeChip(String label, String value) {
    final selected = _reviewType == value;
    return GestureDetector(
      onTap: () => setState(() {
        _reviewType = value;
        if (value.startsWith('postop')) _postopDay = int.tryParse(value.split('day').last) ?? 1;
        _generateNote();
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary.withValues(alpha: 0.12) : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? AppColors.primary : AppColors.divider),
        ),
        child: Text(label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: selected ? FontWeight.w700 : FontWeight.normal,
              color: selected ? AppColors.primary : AppColors.textSecondary,
            )),
      ),
    );
  }

  Widget _checkItem(String label, bool value, ValueChanged<bool> onChanged) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(children: [
          Icon(
            value ? Icons.check_circle : Icons.radio_button_unchecked,
            color: value ? AppColors.success : AppColors.textMuted,
            size: 22,
          ),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(fontSize: 14)),
        ]),
      ),
    );
  }

  Widget _card(String title, List<Widget> children) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.primary)),
          const SizedBox(height: 10),
          ...children,
        ]),
      ),
    );
  }

  Widget _field(String label, TextEditingController ctrl) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextFormField(
        controller: ctrl,
        onChanged: (_) => _generateNote(),
        decoration: InputDecoration(
          labelText: label,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
        style: const TextStyle(fontSize: 14),
      ),
    );
  }

  Widget _multilineField(String label, TextEditingController ctrl) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextFormField(
        controller: ctrl,
        maxLines: 3,
        minLines: 2,
        onChanged: (_) => _generateNote(),
        decoration: InputDecoration(
          labelText: label,
          isDense: true,
          alignLabelWithHint: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
        style: const TextStyle(fontSize: 14),
      ),
    );
  }

  Widget _dropdownRow(String label, String value, List<String> items, ValueChanged<String?> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(children: [
        SizedBox(
          width: 110,
          child: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
        ),
        Expanded(
          child: DropdownButtonFormField<String>(
            value: value,
            items: items.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 13)))).toList(),
            onChanged: onChanged,
            isDense: true,
            decoration: const InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
        ),
      ]),
    );
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    for (final c in [_complaintCtrl, _pulseCtrl, _bpCtrl, _rrCtrl, _spo2Ctrl,
      _tempCtrl, _planCtrl, _investigationsCtrl, _generatedNoteCtrl,
      _sfhCtrl, _fhrCtrl, _vagBleedCtrl, _abdExamCtrl]) {
      c.dispose();
    }
    super.dispose();
  }
}
