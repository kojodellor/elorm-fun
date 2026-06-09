import '../../core/constants/app_constants.dart';

class SurgicalReadinessModel {
  const SurgicalReadinessModel({
    required this.id,
    required this.patientId,
    this.clerkingCompleted = false,
    this.clerkingCompletedBy,
    this.clerkingCompletedAt,
    this.anaestheticReview = false,
    this.anaestheticReviewedAt,
    this.bloodUnitsRequired = AppConstants.bloodUnitsMajor,
    this.bloodUnitsDonated = 0,
    this.gxmRequested = false,
    this.gxmCompleted = false,
    this.bloodAvailableInBank = false,
    this.bloodConfirmedAt,
    this.hbValue,
    this.hbDate,
    this.otherLabsComplete = false,
    this.consentSigned = false,
    this.medicationsPurchased = false,
    this.ivLineSet = false,
    this.xmatchFeePaid = false,
    this.anaestheticInstructionsEffected = false,
    this.consultantApproved = false,
    this.consultantApprovedBy,
    this.consultantApprovedAt,
    this.bloodInTheatre = false,
    this.bloodInTheatreAt,
    this.notes,
    this.lastUpdatedBy,
    required this.updatedAt,
  });

  final String id;
  final String patientId;

  // Clerking
  final bool clerkingCompleted;
  final String? clerkingCompletedBy;
  final DateTime? clerkingCompletedAt;

  // Anaesthetic
  final bool anaestheticReview;
  final DateTime? anaestheticReviewedAt;

  // Blood
  final int bloodUnitsRequired;
  final int bloodUnitsDonated;
  final bool gxmRequested;
  final bool gxmCompleted;
  final bool bloodAvailableInBank;
  final DateTime? bloodConfirmedAt;

  // Labs
  final double? hbValue;
  final DateTime? hbDate;
  final bool otherLabsComplete;

  // Pre-op
  final bool consentSigned;
  final bool medicationsPurchased;
  final bool ivLineSet;
  final bool xmatchFeePaid;
  final bool anaestheticInstructionsEffected;

  // Approval
  final bool consultantApproved;
  final String? consultantApprovedBy;
  final DateTime? consultantApprovedAt;

  // Theatre morning
  final bool bloodInTheatre;
  final DateTime? bloodInTheatreAt;

  final String? notes;
  final String? lastUpdatedBy;
  final DateTime updatedAt;

  // ── Computed ──────────────────────────────────────────────────────────────

  bool get hbAcceptable =>
      hbValue != null && hbValue! >= AppConstants.minPreOpHb;

  bool get hbStale =>
      hbDate != null &&
      DateTime.now().difference(hbDate!).inDays > 7;

  int get bloodDonationShortfall =>
      (bloodUnitsRequired - bloodUnitsDonated).clamp(0, bloodUnitsRequired);

  /// Returns readiness score as a value 0–100
  int get readinessPct {
    final items = [
      clerkingCompleted,
      anaestheticReview,
      gxmCompleted,
      hbValue != null,
      hbAcceptable,
      consentSigned,
      medicationsPurchased,
      ivLineSet,
      xmatchFeePaid,
      bloodAvailableInBank,
    ];
    final completed = items.where((v) => v).length;
    return ((completed / items.length) * 100).round();
  }

  /// Returns human-readable list of outstanding items
  List<String> get blockingItems {
    return [
      if (!clerkingCompleted) 'Full clerking',
      if (!anaestheticReview) 'Anaesthetic review',
      if (!gxmCompleted) 'Cross match (GXM)',
      if (hbValue == null) 'Hb result missing',
      if (hbValue != null && !hbAcceptable)
        'Hb ${hbValue!.toStringAsFixed(1)} g/dl — below 10',
      if (hbStale) 'Hb result > 1 week old — repeat needed',
      if (bloodDonationShortfall > 0)
        'Blood donation: $bloodDonationShortfall unit(s) short',
      if (!consentSigned) 'Consent form',
      if (!medicationsPurchased) 'Medications not purchased',
      if (!ivLineSet) 'IV line',
      if (!xmatchFeePaid) 'X-match fee',
      if (!bloodAvailableInBank) 'Blood not confirmed in bank',
    ];
  }

  bool get isTheatreReady => blockingItems.isEmpty;

  factory SurgicalReadinessModel.fromMap(Map<String, dynamic> map) =>
      SurgicalReadinessModel(
        id: map['id'] as String,
        patientId: map['patient_id'] as String,
        clerkingCompleted: map['clerking_completed'] as bool? ?? false,
        clerkingCompletedBy: map['clerking_completed_by'] as String?,
        clerkingCompletedAt: map['clerking_completed_at'] != null
            ? DateTime.parse(map['clerking_completed_at'] as String)
            : null,
        anaestheticReview: map['anaesthetic_review'] as bool? ?? false,
        anaestheticReviewedAt: map['anaesthetic_reviewed_at'] != null
            ? DateTime.parse(map['anaesthetic_reviewed_at'] as String)
            : null,
        bloodUnitsRequired:
            map['blood_units_required'] as int? ?? AppConstants.bloodUnitsMajor,
        bloodUnitsDonated: map['blood_units_donated'] as int? ?? 0,
        gxmRequested: map['gxm_requested'] as bool? ?? false,
        gxmCompleted: map['gxm_completed'] as bool? ?? false,
        bloodAvailableInBank: map['blood_available_in_bank'] as bool? ?? false,
        bloodConfirmedAt: map['blood_confirmed_at'] != null
            ? DateTime.parse(map['blood_confirmed_at'] as String)
            : null,
        hbValue: (map['hb_value'] as num?)?.toDouble(),
        hbDate: map['hb_date'] != null
            ? DateTime.parse(map['hb_date'] as String)
            : null,
        otherLabsComplete: map['other_labs_complete'] as bool? ?? false,
        consentSigned: map['consent_signed'] as bool? ?? false,
        medicationsPurchased: map['medications_purchased'] as bool? ?? false,
        ivLineSet: map['iv_line_set'] as bool? ?? false,
        xmatchFeePaid: map['xmatch_fee_paid'] as bool? ?? false,
        anaestheticInstructionsEffected:
            map['anaesthetic_instructions_effected'] as bool? ?? false,
        consultantApproved: map['consultant_approved'] as bool? ?? false,
        consultantApprovedBy: map['consultant_approved_by'] as String?,
        consultantApprovedAt: map['consultant_approved_at'] != null
            ? DateTime.parse(map['consultant_approved_at'] as String)
            : null,
        bloodInTheatre: map['blood_in_theatre'] as bool? ?? false,
        bloodInTheatreAt: map['blood_in_theatre_at'] != null
            ? DateTime.parse(map['blood_in_theatre_at'] as String)
            : null,
        notes: map['notes'] as String?,
        lastUpdatedBy: map['last_updated_by'] as String?,
        updatedAt: DateTime.parse(map['updated_at'] as String),
      );

  Map<String, dynamic> toMap() => {
        'patient_id': patientId,
        'clerking_completed': clerkingCompleted,
        'clerking_completed_by': clerkingCompletedBy,
        'clerking_completed_at': clerkingCompletedAt?.toIso8601String(),
        'anaesthetic_review': anaestheticReview,
        'anaesthetic_reviewed_at': anaestheticReviewedAt?.toIso8601String(),
        'blood_units_required': bloodUnitsRequired,
        'blood_units_donated': bloodUnitsDonated,
        'gxm_requested': gxmRequested,
        'gxm_completed': gxmCompleted,
        'blood_available_in_bank': bloodAvailableInBank,
        'blood_confirmed_at': bloodConfirmedAt?.toIso8601String(),
        'hb_value': hbValue,
        'hb_date': hbDate?.toIso8601String().split('T').first,
        'other_labs_complete': otherLabsComplete,
        'consent_signed': consentSigned,
        'medications_purchased': medicationsPurchased,
        'iv_line_set': ivLineSet,
        'xmatch_fee_paid': xmatchFeePaid,
        'anaesthetic_instructions_effected': anaestheticInstructionsEffected,
        'consultant_approved': consultantApproved,
        'consultant_approved_by': consultantApprovedBy,
        'consultant_approved_at': consultantApprovedAt?.toIso8601String(),
        'blood_in_theatre': bloodInTheatre,
        'blood_in_theatre_at': bloodInTheatreAt?.toIso8601String(),
        'notes': notes,
        'last_updated_by': lastUpdatedBy,
      };

  SurgicalReadinessModel copyWith({
    bool? clerkingCompleted,
    String? clerkingCompletedBy,
    DateTime? clerkingCompletedAt,
    bool? anaestheticReview,
    DateTime? anaestheticReviewedAt,
    int? bloodUnitsRequired,
    int? bloodUnitsDonated,
    bool? gxmRequested,
    bool? gxmCompleted,
    bool? bloodAvailableInBank,
    DateTime? bloodConfirmedAt,
    double? hbValue,
    DateTime? hbDate,
    bool? otherLabsComplete,
    bool? consentSigned,
    bool? medicationsPurchased,
    bool? ivLineSet,
    bool? xmatchFeePaid,
    bool? anaestheticInstructionsEffected,
    bool? consultantApproved,
    String? consultantApprovedBy,
    DateTime? consultantApprovedAt,
    bool? bloodInTheatre,
    DateTime? bloodInTheatreAt,
    String? notes,
    String? lastUpdatedBy,
  }) =>
      SurgicalReadinessModel(
        id: id,
        patientId: patientId,
        clerkingCompleted: clerkingCompleted ?? this.clerkingCompleted,
        clerkingCompletedBy: clerkingCompletedBy ?? this.clerkingCompletedBy,
        clerkingCompletedAt: clerkingCompletedAt ?? this.clerkingCompletedAt,
        anaestheticReview: anaestheticReview ?? this.anaestheticReview,
        anaestheticReviewedAt:
            anaestheticReviewedAt ?? this.anaestheticReviewedAt,
        bloodUnitsRequired: bloodUnitsRequired ?? this.bloodUnitsRequired,
        bloodUnitsDonated: bloodUnitsDonated ?? this.bloodUnitsDonated,
        gxmRequested: gxmRequested ?? this.gxmRequested,
        gxmCompleted: gxmCompleted ?? this.gxmCompleted,
        bloodAvailableInBank: bloodAvailableInBank ?? this.bloodAvailableInBank,
        bloodConfirmedAt: bloodConfirmedAt ?? this.bloodConfirmedAt,
        hbValue: hbValue ?? this.hbValue,
        hbDate: hbDate ?? this.hbDate,
        otherLabsComplete: otherLabsComplete ?? this.otherLabsComplete,
        consentSigned: consentSigned ?? this.consentSigned,
        medicationsPurchased: medicationsPurchased ?? this.medicationsPurchased,
        ivLineSet: ivLineSet ?? this.ivLineSet,
        xmatchFeePaid: xmatchFeePaid ?? this.xmatchFeePaid,
        anaestheticInstructionsEffected: anaestheticInstructionsEffected ??
            this.anaestheticInstructionsEffected,
        consultantApproved: consultantApproved ?? this.consultantApproved,
        consultantApprovedBy: consultantApprovedBy ?? this.consultantApprovedBy,
        consultantApprovedAt: consultantApprovedAt ?? this.consultantApprovedAt,
        bloodInTheatre: bloodInTheatre ?? this.bloodInTheatre,
        bloodInTheatreAt: bloodInTheatreAt ?? this.bloodInTheatreAt,
        notes: notes ?? this.notes,
        lastUpdatedBy: lastUpdatedBy ?? this.lastUpdatedBy,
        updatedAt: DateTime.now(),
      );
}
