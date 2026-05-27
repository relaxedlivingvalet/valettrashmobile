import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Quick link between Owner dashboard and Admin Portal (same login session).
class OwnerAdminSwitchBar extends StatelessWidget {
  const OwnerAdminSwitchBar({
    super.key,
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.onTap,
    this.leadingIcon = Icons.chevron_right,
  });

  final String label;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final VoidCallback onTap;
  final IconData leadingIcon;

  @override
  Widget build(BuildContext context) {
    final c = context.roleColors;
    return Material(
      color: c.surface1,
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: c.border)),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: accent, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: c.textPrimary,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 11,
                        color: c.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(leadingIcon, color: c.textMuted, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
