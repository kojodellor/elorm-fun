import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../data/models/clinical_record_model.dart';
import '../../../data/supabase/supabase_client.dart';
import '../../../data/repositories/auth_repository.dart';

// ── Clinical Record Providers ────────────────────────────────────────────────

final clinicalRecordProvider =
    FutureProvider.family<ClinicalRecord?, String>((ref, patientId) async {
  final client = ref.read(supabaseClientProvider);
  final data = await client
      .from('clinical_records')
      .select()
      .eq('patient_id', patientId)
      .order('created_at', ascending: false)
      .limit(1)
      .maybeSingle();
  if (data == null) return null;
  return ClinicalRecord.fromMap(data);
});

final patientReviewsProvider =
    FutureProvider.family<List<PatientReview>, String>((ref, patientId) async {
  final client = ref.read(supabaseClientProvider);
  final data = await client
      .from('patient_reviews')
      .select()
      .eq('patient_id', patientId)
      .order('review_date', ascending: false)
      .order('created_at', ascending: false);
  return (data as List)
      .map((e) => PatientReview.fromMap(e as Map<String, dynamic>))
      .toList();
});

final theatreReadinessProvider =
    FutureProvider.family<TheatreReadinessChecklist?, String>((ref, patientId) async {
  final client = ref.read(supabaseClientProvider);
  final data = await client
      .from('theatre_readiness_checklist')
      .select()
      .eq('patient_id', patientId)
      .order('created_at', ascending: false)
      .limit(1)
      .maybeSingle();
  if (data == null) return null;
  return TheatreReadinessChecklist.fromMap(data);
});

// ── Clinical Actions ─────────────────────────────────────────────────────────

final clinicalActionsProvider = Provider<ClinicalActions>((ref) {
  return ClinicalActions(
    ref.read(supabaseClientProvider),
    ref,
  );
});

class ClinicalActions {
  ClinicalActions(this._client, this._ref);
  final SupabaseClient _client;
  final Ref _ref;

  String? get _userId =>
      _ref.read(authRepositoryProvider).currentAuthUser?.id;

  Future<ClinicalRecord> saveClinicalRecord(Map<String, dynamic> data) async {
    final payload = {
      ...data,
      'created_by': _userId,
    };

    // Check if record exists
    final existing = await _client
        .from('clinical_records')
        .select('id')
        .eq('patient_id', data['patient_id'] as String)
        .maybeSingle();

    Map<String, dynamic> result;
    if (existing != null) {
      result = await _client
          .from('clinical_records')
          .update({...payload, 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', existing['id'] as String)
          .select()
          .single();
    } else {
      result = await _client
          .from('clinical_records')
          .insert(payload)
          .select()
          .single();
    }
    return ClinicalRecord.fromMap(result);
  }

  Future<PatientReview> saveReview(Map<String, dynamic> data) async {
    final result = await _client
        .from('patient_reviews')
        .insert({...data, 'created_by': _userId})
        .select()
        .single();
    return PatientReview.fromMap(result);
  }

  Future<TheatreReadinessChecklist> upsertReadiness(
      String patientId, Map<String, dynamic> updates) async {
    final existing = await _client
        .from('theatre_readiness_checklist')
        .select('id')
        .eq('patient_id', patientId)
        .maybeSingle();

    Map<String, dynamic> result;
    if (existing != null) {
      result = await _client
          .from('theatre_readiness_checklist')
          .update({...updates, 'updated_by': _userId, 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', existing['id'] as String)
          .select()
          .single();
    } else {
      result = await _client
          .from('theatre_readiness_checklist')
          .insert({...updates, 'patient_id': patientId})
          .select()
          .single();
    }
    return TheatreReadinessChecklist.fromMap(result);
  }
}
