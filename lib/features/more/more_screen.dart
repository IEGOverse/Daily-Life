import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('More')),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          _MoreSection(
            children: [
              _MoreRow(
                icon: Icons.person_outline,
                title: 'Profile',
                subtitle: 'Activus User',
                onTap: () {},
              ),
            ],
          ),
          const SizedBox(height: 16),
          _MoreSection(
            children: [
              _MoreRow(
                icon: Icons.settings_outlined,
                title: 'Settings',
                subtitle: 'Notifications & reminders',
                onTap: () => context.push('/reminders'),
              ),
              _MoreRow(
                icon: Icons.sync_outlined,
                title: 'Data & Sync',
                subtitle: 'Local only — no cloud',
                onTap: () {},
              ),
              _MoreRow(
                icon: Icons.dark_mode_outlined,
                title: 'Theme',
                subtitle: 'Dark (default)',
                onTap: () {},
              ),
            ],
          ),
          const SizedBox(height: 16),
          _MoreSection(
            children: [
              _MoreRow(
                icon: Icons.help_outline,
                title: 'Help & Support',
                subtitle: 'Assistance and guidance',
                onTap: () {},
              ),
              _MoreRow(
                icon: Icons.info_outline,
                title: 'About Activus',
                subtitle: 'Version 1.0.0',
                onTap: () => _showAboutDialog(context),
              ),
            ],
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About Activus'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Activus',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 4),
            Text(
              'Personal Life Operating System',
              style: TextStyle(color: ActivusColors.textSecondary),
            ),
            SizedBox(height: 16),
            Text(
              'Version 1.0.0',
              style: TextStyle(color: ActivusColors.textSecondary),
            ),
            SizedBox(height: 8),
            Text(
              'All data stays on your device. Nothing is uploaded or shared.',
              style: TextStyle(color: ActivusColors.textSecondary),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class _MoreSection extends StatelessWidget {
  final List<Widget> children;

  const _MoreSection({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: ActivusColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ActivusColors.border, width: 1),
      ),
      child: Column(children: children),
    );
  }
}

class _MoreRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _MoreRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: ActivusColors.surfaceAlt,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 20, color: ActivusColors.textSecondary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      color: ActivusColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              size: 20,
              color: ActivusColors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }
}
