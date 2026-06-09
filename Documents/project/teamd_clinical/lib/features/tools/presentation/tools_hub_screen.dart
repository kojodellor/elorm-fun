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
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.05,
        ),
        itemCount: tools.length,
        itemBuilder: (context, i) {
          final t = tools[i];
          return AnimatedMount(
            delay: Duration(milliseconds: i * 60),
            child: TapCard(
              onTap: () => context.push(t.route),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: t.color.withValues(alpha: 0.15),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: t.color.withValues(alpha: 0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: t.color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(t.icon, color: t.color, size: 22),
                    ),
                    const Spacer(),
                    Text(
                      t.title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      t.subtitle,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
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
