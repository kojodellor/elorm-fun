import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/models/task_model.dart';
import '../providers/dashboard_providers.dart';
import '../../../core/theme/app_animations.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProfileProvider);
    final today = DateTime.now();

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: userAsync.when(
        loading: () => const ShimmerList(count: 4),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (user) {
          if (user == null) return const SizedBox.shrink();
          return CustomScrollView(
            slivers: [
              // ── App bar ────────────────────────────────────────────────
              SliverAppBar(
                pinned: true,
                expandedHeight: 120,
                backgroundColor: AppColors.primary,
                flexibleSpace: FlexibleSpaceBar(
                  titlePadding:
                      const EdgeInsets.fromLTRB(20, 0, 20, 14),
                  title: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _greeting(today.hour),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      Text(
                        user.fullName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  background: Container(color: AppColors.primary),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.medical_services_outlined,
                        color: Colors.white70),
                    tooltip: 'Clinical Tools',
                    onPressed: () => context.push(Routes.tools),
                  ),
                  IconButton(
                    icon: const Icon(Icons.group_outlined,
                        color: Colors.white70),
                    tooltip: 'Team',
                    onPressed: () => context.go(Routes.team),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: CircleAvatar(
                      backgroundColor: Colors.white.withOpacity(0.15),
                      radius: 18,
                      child: Text(
                        user.initials,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Date + duty assignment ───────────────────────
                      AnimatedMount(
                        child: _DutyCard(userId: user.id, today: today),
                      ),
                      const SizedBox(height: 16),

                      // ── Critical alerts ──────────────────────────────
                      AnimatedMount(
                        delay: const Duration(milliseconds: 60),
                        child: _CriticalAlerts(today: today),
                      ),
                      const SizedBox(height: 16),

                      // ── Stats row ────────────────────────────────────
                      AnimatedMount(
                        delay: const Duration(milliseconds: 120),
                        child: _StatsRow(userId: user.id, today: today),
                      ),
                      const SizedBox(height: 20),

                      // ── Overdue tasks ────────────────────────────────
                      AnimatedMount(
                        delay: const Duration(milliseconds: 180),
                        child: _SectionHeader(
                          title: 'Overdue',
                          icon: Icons.warning_amber_rounded,
                          iconColor: AppColors.danger,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Overdue tasks list
              _OverdueTasksList(userId: user.id),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                  child: _SectionHeader(
                    title: 'Due Today',
                    icon: Icons.today_rounded,
                    iconColor: AppColors.warning,
                  ),
                ),
              ),

              // Due today list
              _DueTodayList(userId: user.id),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                  child: _SectionHeader(
                    title: 'Post-Op Reviews Due',
                    icon: Icons.healing_rounded,
                    iconColor: AppColors.primaryLight,
                  ),
                ),
              ),

              // Post-op tasks due today
              _PostopDueList(),

              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          );
        },
      ),
    );
  }

  String _greeting(int hour) {
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }
}

// ── Duty card ───────────────────────────────────────────────────────────────

class _DutyCard extends ConsumerWidget {
  const _DutyCard({required this.userId, required this.today});

  final String userId;
  final DateTime today;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dutyAsync = ref.watch(todaysDutyProvider(userId));
    final dateLabel = DateFormat('EEEE, d MMMM').format(today);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: dutyAsync.when(
          loading: () => const ShimmerBlock(height: 48),
          error: (_, __) => Text('Could not load duty',
              style: Theme.of(context).textTheme.bodyMedium),
          data: (duty) {
            if (duty == null) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(dateLabel,
                      style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 4),
                  Text('No duty assigned today',
                      style: Theme.of(context).textTheme.titleMedium),
                ],
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(dateLabel,
                        style: Theme.of(context).textTheme.bodyMedium),
                    if (duty.is24HrDuty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.danger.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          '24-HR DUTY',
                          style: TextStyle(
                            color: AppColors.danger,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  duty.dutyRole.label,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppColors.primary,
                      ),
                ),
                if (duty.location != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined,
                          size: 14, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        duty.location!.label,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(width: 12),
                      const Icon(Icons.access_time_rounded,
                          size: 14, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        duty.shiftLabel,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

// ── Critical alerts (time-based) ────────────────────────────────────────────

class _CriticalAlerts extends StatelessWidget {
  const _CriticalAlerts({required this.today});

  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final alerts = <_Alert>[];

    // Ring theatre deadline: 8:00 AM on theatre days (Tue/Wed)
    if ((today.weekday == DateTime.tuesday ||
            today.weekday == DateTime.wednesday) &&
        now.hour < 8) {
      final minutesLeft = (DateTime(now.year, now.month, now.day, 8, 0)
              .difference(now)
              .inMinutes);
      alerts.add(_Alert(
        icon: Icons.phone_in_talk_rounded,
        color: AppColors.danger,
        title: 'Ring theatre before 8:00 AM',
        subtitle: '$minutesLeft min remaining — brief consultant & anaesthetist',
      ));
    }

    // Theatre list deadline: 12 noon on Monday
    if (today.weekday == DateTime.monday && now.hour < 12) {
      final minutesLeft = (DateTime(now.year, now.month, now.day, 12, 0)
              .difference(now)
              .inMinutes);
      alerts.add(_Alert(
        icon: Icons.assignment_late_rounded,
        color: AppColors.warning,
        title: 'Theatre list due in ${minutesLeft}min',
        subtitle: 'Send to dept. secretary by 12:00 noon',
      ));
    }

    if (alerts.isEmpty) return const SizedBox.shrink();

    return Column(
      children: alerts
          .map((a) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _AlertTile(alert: a),
              ))
          .toList(),
    );
  }
}

class _Alert {
  const _Alert(
      {required this.icon,
      required this.color,
      required this.title,
      required this.subtitle});
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
}

class _AlertTile extends StatelessWidget {
  const _AlertTile({required this.alert});

  final _Alert alert;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: alert.color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: alert.color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(alert.icon, color: alert.color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(alert.title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: alert.color,
                    )),
                Text(alert.subtitle,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Stats row ────────────────────────────────────────────────────────────────

class _StatsRow extends ConsumerWidget {
  const _StatsRow({required this.userId, required this.today});

  final String userId;
  final DateTime today;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(dashboardStatsProvider(userId));

    return statsAsync.when(
      loading: () => const SizedBox(height: 76, child: ShimmerBlock(height: 76)),
      error: (_, __) => const SizedBox.shrink(),
      data: (stats) => Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          _StatChip(
            label: 'Inpatients',
            value: stats.activePatients.toString(),
            icon: Icons.bed_rounded,
            color: AppColors.primary,
            onTap: () => context.go(Routes.patients),
          ),
          _StatChip(
            label: 'Same Day',
            value: stats.sameDayPatients.toString(),
            icon: Icons.wb_sunny_outlined,
            color: const Color(0xFFF39C12),
            onTap: () => context.go(Routes.patients),
          ),
          _StatChip(
            label: 'Overdue',
            value: stats.overdueTasks.toString(),
            icon: Icons.warning_amber_rounded,
            color: stats.overdueTasks > 0 ? AppColors.danger : AppColors.success,
          ),
          _StatChip(
            label: 'Theatre Ready',
            value: '${stats.theatreReady}/${stats.theatreTotal}',
            icon: Icons.medical_services_rounded,
            color: stats.theatreReady == stats.theatreTotal
                ? AppColors.success
                : AppColors.warning,
            onTap: () => context.go(Routes.theatreReadiness),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
    this.onTap,
  });

  final String label;
  final String value;
  final Color color;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.of(context).size.width;
    final chipW = (screenW - 32 - 10) / 2; // 2 per row with padding

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: chipW,
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.18)),
        ),
        child: Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(value,
                  style: TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w800, color: color)),
              Text(label,
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textSecondary, height: 1.3)),
            ]),
          ),
          if (onTap != null)
            Icon(Icons.chevron_right_rounded, color: color.withValues(alpha: 0.5), size: 16),
        ]),
      ),
    );
  }
}

// ── Section header ───────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(
      {required this.title, required this.icon, required this.iconColor});

  final String title;
  final IconData icon;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: iconColor),
        const SizedBox(width: 6),
        Text(title, style: Theme.of(context).textTheme.titleMedium),
      ],
    );
  }
}

// ── Overdue tasks ────────────────────────────────────────────────────────────

class _OverdueTasksList extends ConsumerWidget {
  const _OverdueTasksList({required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(overdueTasksProvider(userId));

    return tasksAsync.when(
      loading: () => SliverToBoxAdapter(
          child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: List.generate(2, (_) => const ShimmerCard())),
      )),
      error: (_, __) => const SliverToBoxAdapter(child: SizedBox.shrink()),
      data: (tasks) {
        if (tasks.isEmpty) {
          return SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: _EmptyState(
                icon: Icons.check_circle_outline_rounded,
                message: 'No overdue tasks',
                color: AppColors.success,
              ),
            ),
          );
        }
        return SliverList.builder(
          itemCount: tasks.length,
          itemBuilder: (_, i) => AnimatedMount(
            delay: Duration(milliseconds: i * 55),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
              child: _TaskTile(task: tasks[i], onComplete: () async {
                await ref
                    .read(taskActionsProvider)
                    .completeTask(tasks[i].id, userId);
                ref.invalidate(overdueTasksProvider);
              }),
            ),
          ),
        );
      },
    );
  }
}

// ── Due today ────────────────────────────────────────────────────────────────

class _DueTodayList extends ConsumerWidget {
  const _DueTodayList({required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(dueTodayTasksProvider(userId));

    return tasksAsync.when(
      loading: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
      error: (_, __) => const SliverToBoxAdapter(child: SizedBox.shrink()),
      data: (tasks) {
        if (tasks.isEmpty) {
          return SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: _EmptyState(
                  icon: Icons.event_available_rounded,
                  message: 'No tasks due today',
                  color: AppColors.textMuted),
            ),
          );
        }
        return SliverList.builder(
          itemCount: tasks.length,
          itemBuilder: (_, i) => AnimatedMount(
            delay: Duration(milliseconds: i * 55),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
              child: _TaskTile(task: tasks[i], onComplete: () async {
                await ref
                    .read(taskActionsProvider)
                    .completeTask(tasks[i].id, userId);
                ref.invalidate(dueTodayTasksProvider);
              }),
            ),
          ),
        );
      },
    );
  }
}

// ── Post-op due ──────────────────────────────────────────────────────────────

class _PostopDueList extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(postopDueTodayProvider);

    return tasksAsync.when(
      loading: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
      error: (_, __) => const SliverToBoxAdapter(child: SizedBox.shrink()),
      data: (tasks) {
        if (tasks.isEmpty) {
          return SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: _EmptyState(
                  icon: Icons.check_circle_outline_rounded,
                  message: 'No post-op reviews due today',
                  color: AppColors.textMuted),
            ),
          );
        }
        return SliverList.builder(
          itemCount: tasks.length,
          itemBuilder: (_, i) => AnimatedMount(
            delay: Duration(milliseconds: i * 55),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
              child: _PostopTaskTile(task: tasks[i]),
            ),
          ),
        );
      },
    );
  }
}

// ── Task tile ────────────────────────────────────────────────────────────────

class _TaskTile extends StatelessWidget {
  const _TaskTile({required this.task, required this.onComplete});

  final TaskModel task;
  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context) {
    final isOverdue = task.isOverdue;
    final accentColor = isOverdue ? AppColors.danger : AppColors.warning;

    return Card(
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: accentColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            _iconForCategory(task.category),
            color: accentColor,
            size: 18,
          ),
        ),
        title: Text(
          task.title,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (task.patientName != null)
              Text(task.patientName!,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary)),
            if (task.dueAt != null)
              Text(
                isOverdue
                    ? 'Overdue · ${_formatTime(task.dueAt!)}'
                    : 'Due ${_formatTime(task.dueAt!)}',
                style: TextStyle(
                  fontSize: 11,
                  color: isOverdue ? AppColors.danger : AppColors.warning,
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.check_circle_outline_rounded),
          color: AppColors.success,
          onPressed: onComplete,
        ),
      ),
    );
  }

  IconData _iconForCategory(TaskCategory cat) => switch (cat) {
        TaskCategory.preOp => Icons.assignment_rounded,
        TaskCategory.postOp => Icons.healing_rounded,
        TaskCategory.bloodBank => Icons.water_drop_rounded,
        TaskCategory.theatrePrep => Icons.medical_services_rounded,
        TaskCategory.investigation => Icons.biotech_rounded,
        TaskCategory.wardRound => Icons.people_rounded,
        TaskCategory.handover => Icons.swap_horiz_rounded,
        TaskCategory.duty => Icons.schedule_rounded,
      };

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    if (dt.day == now.day) return DateFormat('h:mm a').format(dt);
    return DateFormat('EEE h:mm a').format(dt);
  }
}

// ── Post-op task tile ────────────────────────────────────────────────────────

class _PostopTaskTile extends StatelessWidget {
  const _PostopTaskTile({required this.task});

  final PostopTaskModel task;

  @override
  Widget build(BuildContext context) {
    final isOverdue = task.isOverdue;

    return Card(
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.primaryLight.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.healing_rounded,
              color: AppColors.primaryLight, size: 18),
        ),
        title: Text(
          task.patientName ?? 'Patient',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          task.description,
          style: const TextStyle(
              fontSize: 12, color: AppColors.textSecondary),
          maxLines: 2,
        ),
        trailing: isOverdue
            ? const Icon(Icons.warning_amber_rounded,
                color: AppColors.danger, size: 18)
            : null,
      ),
    );
  }
}

// ── Empty state ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState(
      {required this.icon, required this.message, required this.color});

  final IconData icon;
  final String message;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Text(message,
              style: TextStyle(
                  fontSize: 13, color: color, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
