import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/patient_model.dart';
import '../../../data/models/enums.dart';
import '../providers/clinical_providers.dart';

class FullClerkScreen extends ConsumerStatefulWidget {
  const FullClerkScreen({super.key, required this.patient});
  final PatientModel patient;

  @override
  ConsumerState<FullClerkScreen> createState() => _FullClerkScreenState();
}

class _FullClerkScreenState extends ConsumerState<FullClerkScreen>
    with TickerProviderStateMixin {
  late final TabController _tabCtrl;
  bool _saving = false;

  // ── Demographics ────────────────────────────────────────────
  final _lmpCtrl = TextEditingController();
  final _eddLmpCtrl = TextEditingController();
  final _eddScanCtrl = TextEditingController();
  final _gaCtrl = TextEditingController();
  final _occupationCtrl = TextEditingController();
  final _pcCtrl = TextEditingController();
  final _hpcCtrl = TextEditingController();

  // ── ODQ ─────────────────────────────────────────────────────
  final Map<String, bool> _odq = {
    'LAP': false, 'LOL': false, 'FFM': false,
    'Vaginal Bleeding': false, 'Colour of Liquor': false,
    'Odour': false, 'Headache': false, 'Nausea': false,
    'Vomiting': false, 'Blurred Vision': false,
    'Epigastric Pain': false, 'Facial Oedema': false,
    'Pedal Oedema': false, 'Dizziness': false,
    'Palpitations': false, 'Easy Fatigue': false,
    'Dysuria': false, 'Frequency': false,
    'Polyuria': false, 'Polydipsia': false,
    'Reduced Fetal Movement': false,
    '24 Hour Diet Recall': false,
  };
  final List<Map<String, dynamic>> _odqCustom = [];
  final _customOdqCtrl = TextEditingController();

  // ── Systemic Inquiry ─────────────────────────────────────────
  final Map<String, Map<String, bool>> _systemic = {
    'Cardiovascular': {'Chest Pain': false, 'PND': false, 'Orthopnoea': false, 'Palpitations': false},
    'Respiratory': {'Cough': false, 'Sputum': false, 'Dyspnoea': false, 'Asthma': false},
    'Gastrointestinal': {'Nausea': false, 'Vomiting': false, 'Diarrhoea': false, 'Constipation': false, 'Anorexia': false},
    'Neurological': {'Headache': false, 'Vertigo': false, 'Blurred Vision': false},
    'Genitourinary': {'Dysuria': false, 'Frequency': false, 'Urgency': false, 'Nocturia': false, 'Polyuria': false, 'Discharge': false},
    'Musculoskeletal': {'Back Pain': false, 'Waist Pain': false, 'Muscle Pain': false},
  };

  // ── OBx History ──────────────────────────────────────────────
  final List<Map<String, TextEditingController>> _obxHistory = [];
  final _bookingGaCtrl = TextEditingController();

  // ── Booking Labs ─────────────────────────────────────────────
  String _g6pd = 'No Defect';
  String _sickling = 'Negative';
  String _vdrl = 'Negative';
  String _retroviral = 'Negative';
  String _hepB = 'Negative';
  final _bloodGroupCtrl = TextEditingController();
  final _bookingBpCtrl = TextEditingController();
  final _bookingHbCtrl = TextEditingController();

  // ── Gynae History ────────────────────────────────────────────
  // Menstrual
  final _menarche = TextEditingController();
  String _cycleRegularity = 'Regular';
  final _cycleLength = TextEditingController(text: '28');
  final _flow = TextEditingController();
  bool _dysmenorrhoea = false;
  bool _menorrhagia = false;
  bool _clots = false;
  final _padsPerDay = TextEditingController();
  // Sexual
  final _ageAtCoitarche = TextEditingController();
  final _numberOfPartners = TextEditingController();
  bool _dyspareunia = false;
  bool _stiHistory = false;
  // Contraceptive
  final _currentMethod = TextEditingController();
  final _previousMethods = TextEditingController();
  final _reasonStopping = TextEditingController();

  // ── PMHX ─────────────────────────────────────────────────────
  final Map<String, bool> _pmhx = {
    'HTN': false, 'DM': false, 'SCD': false, 'Asthma': false,
    'Cardiac Disease': false, 'Renal Disease': false, 'Thyroid Disease': false,
  };
  final _prevAdmCtrl = TextEditingController();
  final _prevBtCtrl = TextEditingController();
  final _prevSurgCtrl = TextEditingController();
  final _currentMedsCtrl = TextEditingController();
  final _herbalMedsCtrl = TextEditingController();
  final _allergiesCtrl = TextEditingController();

  // ── Family History ───────────────────────────────────────────
  final Map<String, bool> _fhx = {
    'SCD': false, 'HTN': false, 'DM': false, 'Asthma': false,
    'Cancer': false, 'Twin Pregnancies': false,
  };
  final _fhxOtherCtrl = TextEditingController();

  // ── Social History ────────────────────────────────────────────
  String _maritalStatus = 'Married';
  final _spouseOccupation = TextEditingController();
  final _spouseEducation = TextEditingController();
  final _occCtrl = TextEditingController();
  String _educationLevel = 'Secondary';
  bool _alcohol = false;
  bool _smoking = false;
  String _religion = '';
  bool _acceptsBlood = true;
  final _nhisCtrl = TextEditingController();

  // ── Examination ───────────────────────────────────────────────
  // General
  String _pallor = 'Not Pale';
  bool _jaundice = false;
  bool _cyanosis = false;
  bool _oedema = false;
  bool _respiratory_distress = false;
  // Vitals
  final _pulseCtrl = TextEditingController();
  final _bpCtrl = TextEditingController();
  final _rrCtrl = TextEditingController();
  final _spo2Ctrl = TextEditingController();
  final _tempCtrl = TextEditingController();
  // Abdomen (OBx)
  final _sfhCtrl = TextEditingController();
  final _lieCtrl = TextEditingController();
  final _presentationCtrl = TextEditingController();
  final _fhrCtrl = TextEditingController();
  final _veCtrl = TextEditingController();
  final _sseCtrl = TextEditingController();
  // Abdomen (Gynae)
  final _abdExamCtrl = TextEditingController();
  final _vagExamCtrl = TextEditingController();

  // ── Assessment ────────────────────────────────────────────────
  final _impressionCtrl = TextEditingController();
  final _planCtrl = TextEditingController();

  bool get _isGynae =>
      widget.patient.admissionType == AdmissionType.gynaecology;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(
      length: _isGynae ? 7 : 7,
      vsync: this,
    );
    _loadExisting();
  }

  Future<void> _loadExisting() async {
    final record = await ref.read(clinicalRecordProvider(widget.patient.id).future);
    if (record != null && mounted) {
      _prefillFromRecord(record.toMap());
    }
  }

  void _prefillFromRecord(Map<String, dynamic> r) {
    setState(() {
      if (r['lmp'] != null) _lmpCtrl.text = r['lmp'] as String;
      if (r['edd_lmp'] != null) _eddLmpCtrl.text = r['edd_lmp'] as String;
      if (r['edd_scan'] != null) _eddScanCtrl.text = r['edd_scan'] as String;
      if (r['gestational_age'] != null) _gaCtrl.text = r['gestational_age'] as String;
      if (r['occupation'] != null) _occupationCtrl.text = r['occupation'] as String;
      if (r['presenting_complaint'] != null) _pcCtrl.text = r['presenting_complaint'] as String;
      if (r['hpc'] != null) _hpcCtrl.text = r['hpc'] as String;
      if (r['impression'] != null) _impressionCtrl.text = r['impression'] as String;
      if (r['plan'] != null) _planCtrl.text = r['plan'] as String;

      if (r['odq'] != null) {
        final odqMap = r['odq'] as Map<String, dynamic>;
        for (final k in _odq.keys) {
          if (odqMap.containsKey(k)) _odq[k] = odqMap[k] == true;
        }
      }
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final data = {
        'patient_id': widget.patient.id,
        'record_type': _isGynae ? 'gynae' : 'obs',
        if (_lmpCtrl.text.isNotEmpty) 'lmp': _lmpCtrl.text,
        if (_eddLmpCtrl.text.isNotEmpty) 'edd_lmp': _eddLmpCtrl.text,
        if (_eddScanCtrl.text.isNotEmpty) 'edd_scan': _eddScanCtrl.text,
        if (_gaCtrl.text.isNotEmpty) 'gestational_age': _gaCtrl.text,
        if (_occupationCtrl.text.isNotEmpty) 'occupation': _occupationCtrl.text,
        if (_pcCtrl.text.isNotEmpty) 'presenting_complaint': _pcCtrl.text,
        if (_hpcCtrl.text.isNotEmpty) 'hpc': _hpcCtrl.text,
        'odq': _odq,
        'odq_custom': _odqCustom,
        'systemic_inquiry': _systemic,
        'obstetric_history': _obxHistory.map((p) => {
              'outcome': p['outcome']!.text,
              'mode': p['mode']!.text,
              'sex': p['sex']!.text,
              'status': p['status']!.text,
              'complications': p['complications']!.text,
            }).toList(),
        if (_bookingGaCtrl.text.isNotEmpty) 'booking_ga': _bookingGaCtrl.text,
        'g6pd': _g6pd,
        'sickling': _sickling,
        'vdrl': _vdrl,
        'retroviral': _retroviral,
        'hep_b': _hepB,
        if (_bloodGroupCtrl.text.isNotEmpty) 'blood_group': _bloodGroupCtrl.text,
        if (_bookingBpCtrl.text.isNotEmpty) 'booking_bp': _bookingBpCtrl.text,
        if (_bookingHbCtrl.text.isNotEmpty) 'booking_hb': _bookingHbCtrl.text,
        'menstrual_history': {
          'menarche': _menarche.text,
          'cycle_regularity': _cycleRegularity,
          'cycle_length': _cycleLength.text,
          'flow': _flow.text,
          'dysmenorrhoea': _dysmenorrhoea,
          'menorrhagia': _menorrhagia,
          'clots': _clots,
          'pads_per_day': _padsPerDay.text,
        },
        'sexual_history': {
          'age_at_coitarche': _ageAtCoitarche.text,
          'number_of_partners': _numberOfPartners.text,
          'dyspareunia': _dyspareunia,
          'sti_history': _stiHistory,
        },
        'contraceptive_history': {
          'current_method': _currentMethod.text,
          'previous_methods': _previousMethods.text,
          'reason_stopping': _reasonStopping.text,
        },
        'pmhx': _pmhx,
        if (_prevAdmCtrl.text.isNotEmpty) 'prev_admissions': _prevAdmCtrl.text,
        if (_prevBtCtrl.text.isNotEmpty) 'prev_bt': _prevBtCtrl.text,
        if (_prevSurgCtrl.text.isNotEmpty) 'prev_surgeries': _prevSurgCtrl.text,
        if (_currentMedsCtrl.text.isNotEmpty) 'current_medications': _currentMedsCtrl.text,
        if (_herbalMedsCtrl.text.isNotEmpty) 'herbal_medications': _herbalMedsCtrl.text,
        if (_allergiesCtrl.text.isNotEmpty) 'allergies': _allergiesCtrl.text,
        'family_history': {
          ..._fhx,
          if (_fhxOtherCtrl.text.isNotEmpty) 'other': _fhxOtherCtrl.text,
        },
        'social_history': {
          'marital_status': _maritalStatus,
          'spouse_occupation': _spouseOccupation.text,
          'spouse_education': _spouseEducation.text,
          'occupation': _occCtrl.text,
          'education_level': _educationLevel,
          'alcohol': _alcohol,
          'smoking': _smoking,
          'religion': _religion,
          'accepts_blood': _acceptsBlood,
          'nhis': _nhisCtrl.text,
        },
        'examination': {
          'general': {
            'pallor': _pallor,
            'jaundice': _jaundice,
            'cyanosis': _cyanosis,
            'oedema': _oedema,
            'respiratory_distress': _respiratory_distress,
          },
          'vitals': {
            'pulse': _pulseCtrl.text,
            'bp': _bpCtrl.text,
            'rr': _rrCtrl.text,
            'spo2': _spo2Ctrl.text,
            'temp': _tempCtrl.text,
          },
          if (!_isGynae) 'obstetric': {
            'sfh': _sfhCtrl.text,
            'lie': _lieCtrl.text,
            'presentation': _presentationCtrl.text,
            'fhr': _fhrCtrl.text,
            've': _veCtrl.text,
            'sse': _sseCtrl.text,
          },
          if (_isGynae) 'gynae': {
            'abdomen': _abdExamCtrl.text,
            'vaginal': _vagExamCtrl.text,
          },
        },
        if (_impressionCtrl.text.isNotEmpty) 'impression': _impressionCtrl.text,
        if (_planCtrl.text.isNotEmpty) 'plan': _planCtrl.text,
      };

      await ref.read(clinicalActionsProvider).saveClinicalRecord(data);

      // Mark theatre readiness: full clerking done
      await ref.read(clinicalActionsProvider).upsertReadiness(
        widget.patient.id,
        {'full_clerking_done': true},
      );

      ref.invalidate(clinicalRecordProvider(widget.patient.id));
      ref.invalidate(theatreReadinessProvider(widget.patient.id));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Clinical record saved'),
            backgroundColor: AppColors.success,
          ),
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Full Clerking', style: TextStyle(fontSize: 16)),
            Text(widget.patient.fullName,
                style: const TextStyle(fontSize: 12, color: Colors.white70)),
          ],
        ),
        bottom: TabBar(
          controller: _tabCtrl,
          isScrollable: true,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white54,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Demographics'),
            Tab(text: 'History'),
            Tab(text: 'Systemic'),
            Tab(text: 'PMHX / Social'),
            Tab(text: 'Examination'),
            Tab(text: 'Investigations'),
            Tab(text: 'Assessment'),
          ],
        ),
        actions: [
          _saving
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  ),
                )
              : TextButton(
                  onPressed: _save,
                  child: const Text('Save', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                ),
        ],
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _buildDemographics(),
          _buildHistory(),
          _buildSystemic(),
          _buildPmhxSocial(),
          _buildExamination(),
          _buildInvestigations(),
          _buildAssessment(),
        ],
      ),
    );
  }

  // ── TAB 1: Demographics ───────────────────────────────────────
  Widget _buildDemographics() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _card('Patient', [
          _readOnlyField('Name', widget.patient.fullName),
          _readOnlyField('Folder No.', widget.patient.folderNumber),
          _readOnlyField('Admission Type', _isGynae ? 'Gynaecology' : 'Obstetrics'),
          _field('Occupation', _occupationCtrl),
        ]),
        if (!_isGynae)
          _card('Obstetric Dates', [
            _field('LMP', _lmpCtrl, hint: 'DD/MM/YYYY'),
            _field('EDD from LMP', _eddLmpCtrl, hint: 'DD/MM/YYYY'),
            _field('EDD from Scan', _eddScanCtrl, hint: 'DD/MM/YYYY'),
            _field('Gestational Age', _gaCtrl, hint: 'e.g. 36W+2D'),
          ]),
        _card('Presenting Complaint', [
          _field('PC', _pcCtrl),
          _multilineField('HPC', _hpcCtrl),
        ]),
        if (!_isGynae) _buildOdq(),
        if (_isGynae) _buildGynaeOdq(),
      ],
    );
  }

  Widget _buildOdq() {
    return _card('Obstetric Directed Questions', [
      Wrap(
        spacing: 6,
        runSpacing: 6,
        children: _odq.entries.map((e) => _symptomChip(e.key, e.value, (v) {
              setState(() => _odq[e.key] = v);
            })).toList(),
      ),
      const SizedBox(height: 12),
      // Custom items
      if (_odqCustom.isNotEmpty) ...[
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: _odqCustom.asMap().entries.map((e) {
            return _symptomChip(
              e.value['label'] as String,
              e.value['value'] as bool,
              (v) => setState(() => _odqCustom[e.key]['value'] = v),
              removable: true,
              onRemove: () => setState(() => _odqCustom.removeAt(e.key)),
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
      ],
      Row(
        children: [
          Expanded(
            child: TextFormField(
              controller: _customOdqCtrl,
              decoration: const InputDecoration(
                hintText: 'Add custom question...',
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              style: const TextStyle(fontSize: 13),
              onFieldSubmitted: (_) => _addCustomOdq(),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: AppColors.primary),
            onPressed: _addCustomOdq,
          ),
        ],
      ),
    ]);
  }

  void _addCustomOdq() {
    final text = _customOdqCtrl.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _odqCustom.add({'label': text, 'value': false});
      _customOdqCtrl.clear();
    });
  }

  Widget _buildGynaeOdq() {
    final gynaeOdq = {
      'BPV': false, 'Menorrhagia': false, 'PCB': false, 'PMB': false,
      'Dysmenorrhoea': false, 'Dyspareunia': false, 'LAP': false,
      'Vaginal Discharge': false, 'Feeling of Mass': false,
      'Frequency': false, 'Dysuria': false, 'Weight Loss': false, 'Fever': false,
    };
    return _card('Gynaecological Directed Questions', [
      Wrap(
        spacing: 6,
        runSpacing: 6,
        children: gynaeOdq.keys.map((k) => _symptomChip(
          k, _odq[k] ?? false,
          (v) => setState(() => _odq[k] = v),
        )).toList(),
      ),
    ]);
  }

  // ── TAB 2: History ────────────────────────────────────────────
  Widget _buildHistory() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (!_isGynae) _buildObxHistory(),
        // Menstrual, sexual & contraceptive history appear for ALL patients
        _buildMenstrualHistory(),
        _buildSexualHistory(),
        _buildContraceptiveHistory(),
      ],
    );
  }

  Widget _buildObxHistory() {
    return _card('Past Obstetric History', [
      ..._obxHistory.asMap().entries.map((entry) {
        final i = entry.key;
        final p = entry.value;
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('G${i + 1}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              IconButton(
                icon: const Icon(Icons.remove_circle_outline, size: 18, color: AppColors.danger),
                onPressed: () => setState(() => _obxHistory.removeAt(i)),
                padding: EdgeInsets.zero, constraints: const BoxConstraints(),
              ),
            ]),
            Row(children: [
              Expanded(child: _field('Year/Outcome', p['outcome']!)),
              const SizedBox(width: 8),
              Expanded(child: _field('Mode', p['mode']!)),
            ]),
            Row(children: [
              Expanded(child: _field('Sex M/F', p['sex']!)),
              const SizedBox(width: 8),
              Expanded(child: _field('Status', p['status']!)),
            ]),
            _field('Complications', p['complications']!),
          ]),
        );
      }),
      TextButton.icon(
        onPressed: () => setState(() {
          _obxHistory.add({
            'outcome': TextEditingController(),
            'mode': TextEditingController(text: 'SVD'),
            'sex': TextEditingController(),
            'status': TextEditingController(text: 'Baby alive and well'),
            'complications': TextEditingController(text: 'No complications'),
          });
        }),
        icon: const Icon(Icons.add, size: 16),
        label: const Text('Add pregnancy', style: TextStyle(fontSize: 13)),
      ),
      _field('Index pregnancy booking GA', _bookingGaCtrl),
      const Divider(),
      const Text('Booking Labs', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.primary)),
      const SizedBox(height: 8),
      _dropdownRow('G6PD', _g6pd, ['No Defect', 'Defect'], (v) => setState(() => _g6pd = v!)),
      _dropdownRow('Sickling', _sickling, ['Negative', 'AS', 'SS', 'SC'], (v) => setState(() => _sickling = v!)),
      _dropdownRow('VDRL', _vdrl, ['Negative', 'Reactive'], (v) => setState(() => _vdrl = v!)),
      _dropdownRow('Retroviral', _retroviral, ['Negative', 'Positive'], (v) => setState(() => _retroviral = v!)),
      _dropdownRow('Hep B', _hepB, ['Negative', 'Positive'], (v) => setState(() => _hepB = v!)),
      Row(children: [
        Expanded(child: _field('Blood Group', _bloodGroupCtrl)),
        const SizedBox(width: 8),
        Expanded(child: _field('Booking BP', _bookingBpCtrl)),
      ]),
      _field('Booking Hb', _bookingHbCtrl),
    ]);
  }

  Widget _buildMenstrualHistory() {
    return _card('Menstrual History', [
      _field('Age at Menarche', _menarche),
      _dropdownRow('Cycle Regularity', _cycleRegularity, ['Regular', 'Irregular', 'Oligomenorrhoea', 'Amenorrhoea'],
          (v) => setState(() => _cycleRegularity = v!)),
      Row(children: [
        Expanded(child: _field('Cycle Length (days)', _cycleLength)),
        const SizedBox(width: 8),
        Expanded(child: _field('Pads/Day', _padsPerDay)),
      ]),
      _field('Flow description', _flow),
      Wrap(spacing: 8, children: [
        _toggleChip('Dysmenorrhoea', _dysmenorrhoea, (v) => setState(() => _dysmenorrhoea = v)),
        _toggleChip('Menorrhagia', _menorrhagia, (v) => setState(() => _menorrhagia = v)),
        _toggleChip('Clots', _clots, (v) => setState(() => _clots = v)),
      ]),
    ]);
  }

  Widget _buildSexualHistory() {
    return _card('Sexual History', [
      Row(children: [
        Expanded(child: _field('Age at Coitarche', _ageAtCoitarche)),
        const SizedBox(width: 8),
        Expanded(child: _field('No. of Partners', _numberOfPartners)),
      ]),
      Wrap(spacing: 8, children: [
        _toggleChip('Dyspareunia', _dyspareunia, (v) => setState(() => _dyspareunia = v)),
        _toggleChip('STI History', _stiHistory, (v) => setState(() => _stiHistory = v)),
      ]),
    ]);
  }

  Widget _buildContraceptiveHistory() {
    return _card('Contraceptive History', [
      _field('Current Method', _currentMethod),
      _field('Previous Methods', _previousMethods),
      _field('Reason for Stopping', _reasonStopping),
    ]);
  }

  // ── TAB 3: Systemic Inquiry ───────────────────────────────────
  Widget _buildSystemic() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: _systemic.entries.map((system) {
        return _card(system.key, [
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: system.value.entries.map((e) => _symptomChip(e.key, e.value, (v) {
                  setState(() => _systemic[system.key]![e.key] = v);
                })).toList(),
          ),
        ]);
      }).toList(),
    );
  }

  // ── TAB 4: PMHX / Family / Social ────────────────────────────
  Widget _buildPmhxSocial() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _card('Past Medical History', [
          Wrap(
            spacing: 6, runSpacing: 6,
            children: _pmhx.entries.map((e) => _toggleChip(e.key, e.value, (v) => setState(() => _pmhx[e.key] = v))).toList(),
          ),
          const SizedBox(height: 8),
          _field('Previous admissions', _prevAdmCtrl),
          _field('Previous blood transfusions', _prevBtCtrl),
          _field('Previous surgeries', _prevSurgCtrl),
          _field('Current medications', _currentMedsCtrl),
          _field('Herbal medications', _herbalMedsCtrl),
          _field('Allergies (NKDA if none)', _allergiesCtrl),
        ]),
        _card('Family History', [
          const Text('Illnesses that run in the family:',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6, runSpacing: 6,
            children: _fhx.entries.map((e) => _toggleChip(e.key, e.value, (v) => setState(() => _fhx[e.key] = v))).toList(),
          ),
          const SizedBox(height: 8),
          _field('Other', _fhxOtherCtrl),
        ]),
        _card('Social History', [
          _dropdownRow('Marital Status', _maritalStatus,
              ['Single', 'Married', 'Divorced', 'Widowed', 'Cohabitating'],
              (v) => setState(() => _maritalStatus = v!)),
          if (_maritalStatus == 'Married' || _maritalStatus == 'Cohabitating') ...[
            _field('Spouse Occupation', _spouseOccupation),
            _field('Spouse Education', _spouseEducation),
          ],
          _field('Occupation', _occCtrl),
          _dropdownRow('Education Level', _educationLevel,
              ['None', 'Primary', 'Secondary', 'Tertiary', 'Vocational'],
              (v) => setState(() => _educationLevel = v!)),
          _field('NHIS Number', _nhisCtrl),
          _field('Religion', TextEditingController(text: _religion)
            ..addListener(() {})),
          Wrap(spacing: 8, children: [
            _toggleChip('Alcohol', _alcohol, (v) => setState(() => _alcohol = v)),
            _toggleChip('Smoking', _smoking, (v) => setState(() => _smoking = v)),
            _toggleChip('Accepts Blood', _acceptsBlood, (v) => setState(() => _acceptsBlood = v)),
          ]),
        ]),
      ],
    );
  }

  // ── TAB 5: Examination ────────────────────────────────────────
  Widget _buildExamination() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _card('General Examination', [
          _dropdownRow('Pallor', _pallor,
              ['Not Pale', 'Pale +', 'Pale ++', 'Pale +++'],
              (v) => setState(() => _pallor = v!)),
          Wrap(spacing: 8, runSpacing: 4, children: [
            _toggleChip('Jaundiced', _jaundice, (v) => setState(() => _jaundice = v)),
            _toggleChip('Cyanosed', _cyanosis, (v) => setState(() => _cyanosis = v)),
            _toggleChip('Pedal Oedema', _oedema, (v) => setState(() => _oedema = v)),
            _toggleChip('Resp. Distress', _respiratory_distress, (v) => setState(() => _respiratory_distress = v)),
          ]),
          const SizedBox(height: 8),
          _generatedExamText(),
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
        if (!_isGynae)
          _card('Obstetric Abdomen', [
            Row(children: [
              Expanded(child: _field('SFH (cm)', _sfhCtrl)),
              const SizedBox(width: 8),
              Expanded(child: _field('Lie', _lieCtrl)),
            ]),
            Row(children: [
              Expanded(child: _field('Presentation', _presentationCtrl)),
              const SizedBox(width: 8),
              Expanded(child: _field('FHR (bpm)', _fhrCtrl)),
            ]),
            _field('VE', _veCtrl),
            _field('SSE', _sseCtrl),
          ]),
        if (_isGynae)
          _card('Abdominal & Vaginal Exam', [
            _multilineField('Abdominal examination', _abdExamCtrl),
            _multilineField('Vaginal examination', _vagExamCtrl),
          ]),
        _card('Auto-Generated Exam Text', [
          SelectableText(
            _buildExamNote(),
            style: const TextStyle(fontSize: 13, fontFamily: 'monospace', height: 1.5, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: _buildExamNote()));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Copied'), backgroundColor: AppColors.success),
              );
            },
            icon: const Icon(Icons.copy, size: 16),
            label: const Text('Copy', style: TextStyle(fontSize: 13)),
          ),
        ]),
      ],
    );
  }

  Widget _generatedExamText() {
    final parts = <String>[
      'Adult ${_isGynae ? 'female' : 'female'}.',
      'Looks well.',
      if (!_respiratory_distress) 'Not in obvious respiratory distress.',
      'Well hydrated.',
      'Afebrile.',
      _pallor == 'Not Pale' ? 'Not pale.' : '$_pallor.',
      if (!_jaundice) 'Anicteric.' else 'Jaundiced.',
      if (!_oedema) 'No pedal oedema.' else 'Pedal oedema present.',
    ];
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.success.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.success.withOpacity(0.2)),
      ),
      child: Text(parts.join(' '),
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.5)),
    );
  }

  String _buildExamNote() {
    final buf = StringBuffer();
    buf.write('Adult female. Looks well. ');
    if (!_respiratory_distress) buf.write('Not in obvious respiratory distress. ');
    buf.write('Well hydrated. Afebrile. ');
    buf.write(_pallor == 'Not Pale' ? 'Not pale. ' : '$_pallor. ');
    buf.write(_jaundice ? 'Jaundiced. ' : 'Anicteric. ');
    buf.write(_oedema ? 'Pedal oedema present.\n\n' : 'No pedal oedema.\n\n');

    if (_pulseCtrl.text.isNotEmpty || _bpCtrl.text.isNotEmpty) {
      buf.write('CVS: ');
      if (_pulseCtrl.text.isNotEmpty) buf.write('P ${_pulseCtrl.text} bpm. ');
      if (_bpCtrl.text.isNotEmpty) buf.write('BP ${_bpCtrl.text} mmHg. ');
      buf.write('HS I and II heard. No murmurs.\n\n');
    }

    if (_rrCtrl.text.isNotEmpty || _spo2Ctrl.text.isNotEmpty) {
      buf.write('RESP: ');
      if (_rrCtrl.text.isNotEmpty) buf.write('RR ${_rrCtrl.text} cpm. ');
      if (_spo2Ctrl.text.isNotEmpty) buf.write('SpO2 ${_spo2Ctrl.text}%. ');
      buf.write('AE adequate. BS vesicular.\n\n');
    }

    if (!_isGynae) {
      buf.write('ABD: Full, soft, MWR, non-tender. ');
      if (_sfhCtrl.text.isNotEmpty) buf.write('SFH ${_sfhCtrl.text} cm. ');
      if (_lieCtrl.text.isNotEmpty) buf.write('Lie ${_lieCtrl.text}. ');
      if (_presentationCtrl.text.isNotEmpty) buf.write('Presentation ${_presentationCtrl.text}. ');
      if (_fhrCtrl.text.isNotEmpty) buf.write('FHR ${_fhrCtrl.text} bpm.\n\n');
      if (_veCtrl.text.isNotEmpty) buf.write('VE: ${_veCtrl.text}\n\n');
    } else if (_abdExamCtrl.text.isNotEmpty) {
      buf.write('ABD: ${_abdExamCtrl.text}\n\n');
      if (_vagExamCtrl.text.isNotEmpty) buf.write('VE: ${_vagExamCtrl.text}\n\n');
    }

    buf.write('CNS: Conscious and alert.');
    return buf.toString().trim();
  }

  // ── TAB 6: Investigations ─────────────────────────────────────
  Widget _buildInvestigations() {
    return _InvestigationTab(patientId: widget.patient.id);
  }

  // ── TAB 7: Assessment ─────────────────────────────────────────
  Widget _buildAssessment() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _card('Impression / Diagnosis', [
          _multilineField('Impression', _impressionCtrl),
        ]),
        _card('Plan', [
          _multilineField('Management plan', _planCtrl),
        ]),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: _saving ? null : _save,
          icon: const Icon(Icons.save_rounded),
          label: Text(_saving ? 'Saving...' : 'Save Clinical Record'),
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
        ),
        const SizedBox(height: 80),
      ],
    );
  }

  // ── Helpers ───────────────────────────────────────────────────
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

  Widget _field(String label, TextEditingController ctrl, {String? hint}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextFormField(
        controller: ctrl,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
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
        maxLines: 4,
        minLines: 2,
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

  Widget _readOnlyField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(children: [
        SizedBox(
          width: 100,
          child: Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
        ),
        Expanded(
          child: Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        ),
      ]),
    );
  }

  Widget _dropdownRow(String label, String value, List<String> items, ValueChanged<String?> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(children: [
        SizedBox(
          width: 90,
          child: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
        ),
        Expanded(
          child: DropdownButtonFormField<String>(
            value: value,
            items: items.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 13)))).toList(),
            onChanged: onChanged,
            isDense: true,
            decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
          ),
        ),
      ]),
    );
  }

  Widget _symptomChip(String label, bool value, ValueChanged<bool> onChanged,
      {bool removable = false, VoidCallback? onRemove}) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Container(
        padding: EdgeInsets.fromLTRB(8, 4, removable ? 4 : 8, 4),
        decoration: BoxDecoration(
          color: value ? AppColors.danger.withOpacity(0.12) : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: value ? AppColors.danger.withOpacity(0.4) : AppColors.divider,
          ),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(
            '$label${value ? ' +' : ' −'}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: value ? AppColors.danger : AppColors.textMuted,
            ),
          ),
          if (removable) ...[
            const SizedBox(width: 2),
            GestureDetector(
              onTap: onRemove,
              child: const Icon(Icons.close, size: 14, color: AppColors.textMuted),
            ),
          ],
        ]),
      ),
    );
  }

  Widget _toggleChip(String label, bool value, ValueChanged<bool> onChanged) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: value ? AppColors.primary.withOpacity(0.1) : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: value ? AppColors.primary.withOpacity(0.4) : AppColors.divider),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: value ? AppColors.primary : AppColors.textMuted,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    for (final c in [_lmpCtrl, _eddLmpCtrl, _eddScanCtrl, _gaCtrl, _occupationCtrl,
      _pcCtrl, _hpcCtrl, _customOdqCtrl, _bookingGaCtrl, _bloodGroupCtrl,
      _bookingBpCtrl, _bookingHbCtrl, _menarche, _cycleLength, _flow, _padsPerDay,
      _ageAtCoitarche, _numberOfPartners, _currentMethod, _previousMethods,
      _reasonStopping, _prevAdmCtrl, _prevBtCtrl, _prevSurgCtrl, _currentMedsCtrl,
      _herbalMedsCtrl, _allergiesCtrl, _fhxOtherCtrl, _spouseOccupation,
      _spouseEducation, _occCtrl, _nhisCtrl, _pulseCtrl, _bpCtrl, _rrCtrl,
      _spo2Ctrl, _tempCtrl, _sfhCtrl, _lieCtrl, _presentationCtrl, _fhrCtrl,
      _veCtrl, _sseCtrl, _abdExamCtrl, _vagExamCtrl, _impressionCtrl, _planCtrl]) {
      c.dispose();
    }
    for (final p in _obxHistory) {
      for (final c in p.values) c.dispose();
    }
    super.dispose();
  }
}

// ── Investigation Tab ─────────────────────────────────────────────────────────
class _InvestigationTab extends ConsumerStatefulWidget {
  const _InvestigationTab({required this.patientId});
  final String patientId;

  @override
  ConsumerState<_InvestigationTab> createState() => _InvestigationTabState();
}

class _InvestigationTabState extends ConsumerState<_InvestigationTab> {
  String _selectedType = 'FBC';
  final Map<String, TextEditingController> _fields = {};
  final List<Map<String, dynamic>> _savedInvestigations = [];

  static const _invTypes = {
    'FBC': ['Hb', 'WBC', 'Platelets', 'MCV', 'MCH', 'Neutrophils', 'Lymphocytes'],
    'BUE/Cr': ['Na', 'K', 'Cl', 'Urea', 'Creatinine', 'eGFR'],
    'LFT': ['Total Bilirubin', 'Direct Bilirubin', 'AST', 'ALT', 'ALP', 'GGT', 'Total Protein', 'Albumin'],
    'Uric Acid': ['Uric Acid'],
    'FBS': ['FBS'],
    'Clotting': ['Bedside Clotting Time', 'PT', 'aPTT', 'Fibrinogen'],
    'Other': ['Result'],
  };

  @override
  void initState() {
    super.initState();
    _initFields();
  }

  void _initFields() {
    _fields.clear();
    for (final f in _invTypes[_selectedType] ?? []) {
      _fields[f] = TextEditingController();
    }
  }

  void _addInvestigation() {
    final values = <String, String>{};
    for (final e in _fields.entries) {
      if (e.value.text.isNotEmpty) values[e.key] = e.value.text;
    }
    if (values.isEmpty) return;
    setState(() {
      _savedInvestigations.add({
        'type': _selectedType,
        'values': values,
        'date': DateTime.now().toIso8601String().split('T').first,
      });
      _initFields();
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Add Investigation',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.primary)),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _selectedType,
                items: _invTypes.keys.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (v) => setState(() {
                  _selectedType = v!;
                  _initFields();
                }),
                decoration: const InputDecoration(labelText: 'Investigation type', isDense: true),
              ),
              const SizedBox(height: 12),
              ...(_invTypes[_selectedType] ?? []).map((f) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: TextFormField(
                      controller: _fields[f],
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: f,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        suffixText: _getUnit(f),
                      ),
                      style: const TextStyle(fontSize: 14),
                    ),
                  )),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _addInvestigation,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add', style: TextStyle(fontSize: 13)),
              ),
            ]),
          ),
        ),

        if (_savedInvestigations.isNotEmpty) ...[
          const SizedBox(height: 8),
          const Text('Captured Investigations',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          ..._savedInvestigations.map((inv) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Text(inv['type'] as String,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.primary)),
                      Text(inv['date'] as String,
                          style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                    ]),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: (inv['values'] as Map<String, String>).entries.map((e) {
                        return _LabValueChip(label: e.key, value: e.value);
                      }).toList(),
                    ),
                  ]),
                ),
              )),
        ],
      ],
    );
  }

  String _getUnit(String field) {
    const units = {
      'Hb': 'g/dL', 'WBC': '×10⁹/L', 'Platelets': '×10⁹/L', 'MCV': 'fL', 'MCH': 'pg',
      'Na': 'mmol/L', 'K': 'mmol/L', 'Cl': 'mmol/L', 'Urea': 'mmol/L',
      'Creatinine': 'μmol/L', 'eGFR': 'mL/min',
      'Total Bilirubin': 'μmol/L', 'Direct Bilirubin': 'μmol/L',
      'AST': 'U/L', 'ALT': 'U/L', 'ALP': 'U/L', 'GGT': 'U/L',
      'Total Protein': 'g/L', 'Albumin': 'g/L', 'Uric Acid': 'μmol/L',
      'FBS': 'mmol/L', 'Bedside Clotting Time': 'min',
    };
    return units[field] ?? '';
  }

  @override
  void dispose() {
    for (final c in _fields.values) c.dispose();
    super.dispose();
  }
}

class _LabValueChip extends StatelessWidget {
  const _LabValueChip({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.06),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.primary.withOpacity(0.15)),
      ),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 12),
          children: [
            TextSpan(text: '$label: ', style: const TextStyle(color: AppColors.textSecondary)),
            TextSpan(text: value, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          ],
        ),
      ),
    );
  }
}
