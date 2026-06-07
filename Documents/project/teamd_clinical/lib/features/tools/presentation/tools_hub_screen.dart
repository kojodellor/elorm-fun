import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_animations.dart';

class ToolsHubScreen extends StatelessWidget {
  const ToolsHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tools = [
      _Tool(
        icon: Icons.edit_note_rounded,
        title: 'Quick Clerk',
        subtitle: 'OBx & Gynae reception notes',
        color: AppColors.primary,
        route: '/tools/clerk',
      ),
      _Tool(
        icon: Icons.description_rounded,
        title: 'Procedure Notes',
        subtitle: 'C/S, TAH, myomectomy templates',
        color: AppColors.success,
        route: '/tools/procedure-notes',
      ),
      _Tool(
        icon: Icons.checklist_rounded,
        title: 'Post-Op Checklist',
        subtitle: 'Day-by-day post-op care',
        color: const Color(0xFFE67E22),
        route: '/tools/postop',
      ),
      _Tool(
        icon: Icons.today_rounded,
        title: 'Daily Duty Guide',
        subtitle: 'What to do today by role',
        color: const Color(0xFF8E44AD),
        route: '/tools/duty-guide',
      ),
      _Tool(
        icon: Icons.biotech_rounded,
        title: 'Investigations',
        subtitle: 'Normal ranges & what to order',
        color: const Color(0xFF2980B9),
        route: '/tools/investigations',
      ),
      _Tool(
        icon: Icons.medical_services_rounded,
        title: 'Pre-Op Admission',
        subtitle: 'Admission checklist & protocol',
        color: const Color(0xFFE74C3C),
        route: '/tools/preop',
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Clinical Tools')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: tools.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, i) {
          final t = tools[i];
          return AnimatedMount(
            delay: Duration(milliseconds: i * 55),
            child: TapCard(
              onTap: () => context.push(t.route),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.divider.withOpacity(0.7),
                    width: 0.5,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: t.color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(t.icon, color: t.color, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            t.title,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            t.subtitle,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded,
                        color: AppColors.textMuted, size: 20),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Tool {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final String route;
  const _Tool({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.route,
  });
}
