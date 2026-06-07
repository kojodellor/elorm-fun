import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/patient_model.dart';
import '../models/enums.dart';
import '../supabase/supabase_client.dart';

final patientRepositoryProvider = Provider<PatientRepository>((ref) {
  return PatientRepository(ref.read(supabaseClientProvider));
});

/// Active (non-discharged) patients
final activePatientsProvider = FutureProvider<List<PatientModel>>((ref) {
  return ref.read(patientRepositoryProvider).getActivePatients();
});

/// Active patients filtered by ward
final patientsByWardProvider =
    FutureProvider.family<List<PatientModel>, WardLocation>((ref, ward) {
  return ref.read(patientRepositoryProvider).getPatientsByWard(ward);
});

class PatientRepository {
  PatientRepository(this._client);

  final SupabaseClient _client;

  Future<List<PatientModel>> getActivePatients() async {
    final data = await _client
        .from('patients')
        .select()
        .eq('is_discharged', false)
        .order('admission_date', ascending: false);
    return (data as List).map((m) => PatientModel.fromMap(m)).toList();
  }

  Future<List<PatientModel>> getPatientsByWard(WardLocation ward) async {
    final data = await _client
        .from('patients')
        .select()
        .eq('is_discharged', false)
        .eq('ward', ward.dbValue)
        .order('admission_date');
    return (data as List).map((m) => PatientModel.fromMap(m)).toList();
  }

  Future<PatientModel?> getPatient(String id) async {
    final data = await _client
        .from('patients')
        .select()
        .eq('id', id)
        .maybeSingle();
    if (data == null) return null;
    return PatientModel.fromMap(data);
  }

  Future<PatientModel> admitPatient(PatientModel patient) async {
    final data = await _client
        .from('patients')
        .insert(patient.toMap())
        .select()
        .single();
    return PatientModel.fromMap(data);
  }

  Future<PatientModel> updatePatient(PatientModel patient) async {
    final data = await _client
        .from('patients')
        .update(patient.toMap())
        .eq('id', patient.id)
        .select()
        .single();
    return PatientModel.fromMap(data);
  }

  Future<void> dischargePatient({
    required String patientId,
    required String dischargedBy,
    String? notes,
  }) async {
    await _client.from('patients').update({
      'is_discharged': true,
      'discharge_date': DateTime.now().toIso8601String().split('T').first,
      'discharge_notes': notes,
    }).eq('id', patientId);
  }

  /// Real-time stream of active patients for a specific ward
  Stream<List<PatientModel>> watchPatientsByWard(WardLocation ward) {
    return _client
        .from('patients')
        .stream(primaryKey: ['id'])
        .eq('ward', ward.dbValue)
        .map((data) => data
            .where((m) => m['is_discharged'] == false)
            .map((m) => PatientModel.fromMap(m as Map<String, dynamic>))
            .toList());
  }
}
