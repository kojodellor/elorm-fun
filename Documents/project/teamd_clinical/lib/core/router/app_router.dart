import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/supabase/supabase_client.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/patients/presentation/patient_list_screen.dart';
import '../../features/patients/presentation/patient_detail_screen.dart';
import '../../features/patients/presentation/admit_patient_screen.dart';
import '../../features/theatre/presentation/theatre_list_screen.dart';
import '../../features/theatre/presentation/theatre_readiness_screen.dart';
import '../../features/handover/presentation/handover_screen.dart';
import '../../features/roster/presentation/duty_roster_screen.dart';
import '../../features/team/presentation/team_screen.dart';
import '../../features/tools/presentation/tools_hub_screen.dart';
import '../../features/clinical/presentation/full_clerk_screen.dart';
import '../../features/clinical/presentation/daily_review_screen.dart';
import '../../data/models/patient_model.dart';
import '../../features/tools/presentation/quick_clerk_screen.dart';
import '../../features/tools/presentation/procedure_notes_screen.dart';
import '../../features/tools/presentation/postop_checklist_screen.dart';
import '../../features/tools/presentation/duty_guide_screen.dart';
import '../../features/tools/presentation/investigation_ref_screen.dart';
import '../../features/tools/presentation/preop_admission_screen.dart';
import '../shell/app_shell.dart';

class Routes {
  static const login = '/login';
  static const dashboard = '/dashboard';
  static const patients = '/patients';
  static const admitPatient = '/patients/admit';
  static const patientDetail = '/patients/:id';
  static const patientClerk = '/patients/:id/clerk';
  static const patientReview = '/patients/:id/review';
  static const theatre = '/theatre';
  static const theatreReadiness = '/theatre/readiness';
  static const handover = '/handover';
  static const roster = '/roster';
  static const team = '/team';
  static const tools = '/tools';
  static const toolsClerk = '/tools/clerk';
  static const toolsProcedure = '/tools/procedure-notes';
  static const toolsPostop = '/tools/postop';
  static const toolsDuty = '/tools/duty-guide';
  static const toolsInvestigations = '/tools/investigations';
  static const toolsPreop = '/tools/preop';
}

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: Routes.dashboard,
    redirect: (context, state) {
      final isLoggedIn = ref.read(authRepositoryProvider).isSignedIn;
      final loc = state.matchedLocation;
      final isAuthRoute = loc == Routes.login;
      if (!isLoggedIn && !isAuthRoute) return Routes.login;
      if (isLoggedIn && isAuthRoute) return Routes.dashboard;
      return null;
    },
    refreshListenable: GoRouterRefreshStream(
      ref.watch(authStateProvider.stream),
    ),
    routes: [
      GoRoute(
        path: Routes.login,
        builder: (_, __) => const LoginScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: Routes.dashboard,
            builder: (_, __) => const DashboardScreen(),
          ),
          GoRoute(
            path: Routes.patients,
            builder: (_, __) => const PatientListScreen(),
            routes: [
              GoRoute(
                path: 'admit',
                builder: (_, __) => const AdmitPatientScreen(),
              ),
              GoRoute(
                path: ':id',
                builder: (_, state) => PatientDetailScreen(
                    patientId: state.pathParameters['id']!),
                routes: [
                  GoRoute(
                    path: 'clerk',
                    builder: (_, state) => FullClerkScreen(
                      patient: state.extra as PatientModel,
                    ),
                  ),
                  GoRoute(
                    path: 'review',
                    builder: (_, state) => DailyReviewScreen(
                      patient: state.extra as PatientModel,
                    ),
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: Routes.theatre,
            builder: (_, __) => const TheatreListScreen(),
            routes: [
              GoRoute(
                path: 'readiness',
                builder: (_, __) => const TheatreReadinessScreen(),
              ),
            ],
          ),
          GoRoute(
            path: Routes.handover,
            builder: (_, __) => const HandoverScreen(),
          ),
          GoRoute(
            path: Routes.roster,
            builder: (_, __) => const DutyRosterScreen(),
          ),
          GoRoute(
            path: Routes.team,
            builder: (_, __) => const TeamScreen(),
          ),
          GoRoute(
            path: Routes.tools,
            builder: (_, __) => const ToolsHubScreen(),
            routes: [
              GoRoute(
                path: 'clerk',
                builder: (_, __) => const QuickClerkScreen(),
              ),
              GoRoute(
                path: 'procedure-notes',
                builder: (_, __) => const ProcedureNotesScreen(),
              ),
              GoRoute(
                path: 'postop',
                builder: (_, __) => const PostOpChecklistScreen(),
              ),
              GoRoute(
                path: 'duty-guide',
                builder: (_, __) => const DutyGuideScreen(),
              ),
              GoRoute(
                path: 'investigations',
                builder: (_, __) => const InvestigationRefScreen(),
              ),
              GoRoute(
                path: 'preop',
                builder: (_, __) => const PreopAdmissionScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text('Page not found: ${state.error}')),
    ),
  );
});

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _sub = stream.listen((_) => notifyListeners());
  }
  late final dynamic _sub;

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}
