import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../data/models/duty_assignment_model.dart';
import '../../../data/models/task_model.dart';
import '../../../data/supabase/supabase_client.dart';

// ── Today's duty ─────────────────────────────────────────────────────────────

final todaysDutyProvider =
    FutureProvider.family<DutyAssignmentModel?, String>((ref, userId) async {
  final client = ref.read(supabaseClientProvider);
  final today = DateTime.now().toIso8601String().split('T').first;

  final data = await client
      .from('duty_assignments')
      .select('*, users!duty_assignments_user_id_fkey(full_name, role)')
      .eq('user_id', userId)
      .eq('duty_date', today)
      .maybeSingle();

  if (data == null) return null;
  return DutyAssignmentModel.fromMap(data);
});

// ── Dashboard stats ──────────────────────────────────────────────────────────

class DashboardStats {
  const DashboardStats({
    required this.activePatients,
    required this.sameDayPatients,
    required this.overdueTasks,
    required this.theatreReady,
    required this.theatreTotal,
  });
  final int activePatients;
  final int sameDayPatients;
  final int overdueTasks;
  final int theatreReady;
  final int theatreTotal;
}

final dashboardStatsProvider =
    FutureProvider.family<DashboardStats, String>((ref, userId) async {
  final client = ref.read(supabaseClientProvider);
  final today = DateTime.now().toIso8601String().split('T').first;

  // Active inpatients count (non same-day)
  final patients = await client
      .from('patients')
      .select('id')
      .eq('is_discharged', false)
      .eq('is_same_day', false);

  // Same-day patients
  final sameDayPatients = await client
      .from('patients')
      .select('id')
      .eq('is_discharged', false)
      .eq('is_same_day', true);

  // Overdue tasks (pending + past due_at)
  final overdue = await client
      .from('tasks')
      .select('id')
      .eq('assigned_to', userId)
      .eq('status', 'pending')
      .lt('due_at', DateTime.now().toIso8601String());

  // Theatre readiness for today's list
  final theatreCases = await client
      .from('theatre_cases')
      .select('id, theatre_lists!inner(theatre_date)')
      .eq('theatre_lists.theatre_date', today)
      .isFilter('outcome', null);

  // Cases with 100% readiness
  final readyCases = await client
      .from('surgical_readiness_scores')
      .select('patient_id')
      .eq('readiness_pct', 100);

  final theatrePatientIds =
      (theatreCases as List).map((c) => c['id'] as String).toSet();
  final readyPatientIds =
      (readyCases as List).map((c) => c['patient_id'] as String).toSet();
  final readyCount =
      readyPatientIds.intersection(theatrePatientIds).length;

  return DashboardStats(
    activePatients: (patients as List).length,
    sameDayPatients: (sameDayPatients as List).length,
    overdueTasks: (overdue as List).length,
    theatreReady: readyCount,
    theatreTotal: theatrePatientIds.length,
  );
});

// ── Task queries ─────────────────────────────────────────────────────────────

final overdueTasksProvider =
    FutureProvider.family<List<TaskModel>, String>((ref, userId) async {
  final client = ref.read(supabaseClientProvider);
  final data = await client
      .from('tasks')
      .select('*, patients(full_name)')
      .eq('assigned_to', userId)
      .eq('status', 'pending')
      .lt('due_at', DateTime.now().toIso8601String())
      .order('due_at');
  return (data as List).map((m) => TaskModel.fromMap(m as Map<String, dynamic>)).toList();
});

final dueTodayTasksProvider =
    FutureProvider.family<List<TaskModel>, String>((ref, userId) async {
  final client = ref.read(supabaseClientProvider);
  final now = DateTime.now();
  final endOfDay =
      DateTime(now.year, now.month, now.day, 23, 59, 59).toIso8601String();

  final data = await client
      .from('tasks')
      .select('*, patients(full_name)')
      .eq('assigned_to', userId)
      .eq('status', 'pending')
      .gte('due_at', now.toIso8601String())
      .lte('due_at', endOfDay)
      .order('due_at');
  return (data as List).map((m) => TaskModel.fromMap(m as Map<String, dynamic>)).toList();
});

final postopDueTodayProvider =
    FutureProvider<List<PostopTaskModel>>((ref) async {
  final client = ref.read(supabaseClientProvider);
  final today = DateTime.now().toIso8601String().split('T').first;

  final data = await client
      .from('postop_tasks')
      .select('*, patients(full_name)')
      .eq('status', 'pending')
      .lte('due_date', today)
      .order('due_date');
  return (data as List).map((m) => PostopTaskModel.fromMap(m as Map<String, dynamic>)).toList();
});

// ── Task actions ─────────────────────────────────────────────────────────────

final taskActionsProvider = Provider<TaskActions>((ref) {
  return TaskActions(ref.read(supabaseClientProvider));
});

class TaskActions {
  TaskActions(this._client);
  final SupabaseClient _client;

  Future<void> completeTask(String taskId, String userId) async {
    await _client.from('tasks').update({
      'status': 'completed',
      'completed_by': userId,
      'completed_at': DateTime.now().toIso8601String(),
    }).eq('id', taskId);
  }

  Future<void> completePostopTask(String taskId, String userId,
      {String? notes}) async {
    await _client.from('postop_tasks').update({
      'status': 'completed',
      'completed_by': userId,
      'completed_at': DateTime.now().toIso8601String(),
      'notes': notes,
    }).eq('id', taskId);
  }
}
