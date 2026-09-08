import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../profile/profile_providers.dart';
import '../profile/profile_repository.dart';

class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final displayName = ref.watch(displayNameProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Lainnya')),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          _MoreSection(
            children: [
              _MoreRow(
                icon: Icons.person_outline,
                title: 'Profil',
                subtitle:
                    displayName.value ?? ProfileRepository.defaultDisplayName,
                onTap: () => context.push('/profile'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _MoreSection(
            children: [
              _MoreRow(
                icon: Icons.settings_outlined,
                title: 'Pengaturan',
                subtitle: 'Notifikasi & pengingat',
                onTap: () => context.push('/reminders'),
              ),
              _MoreRow(
                icon: Icons.sync_outlined,
                title: 'Data & Sinkronisasi',
                subtitle: 'Hanya lokal — tanpa cloud',
                onTap: () {},
              ),
              _MoreRow(
                icon: Icons.dark_mode_outlined,
                title: 'Tema',
                subtitle: 'Gelap (bawaan)',
                onTap: () {},
              ),
            ],
          ),
          const SizedBox(height: 16),
          _MoreSection(
            children: [
              _MoreRow(
                icon: Icons.help_outline,
                title: 'Bantuan & Dukungan',
                subtitle: 'Bantuan dan panduan',
                onTap: () {},
              ),
              _MoreRow(
                icon: Icons.info_outline,
                title: 'Tentang Activus',
                subtitle: 'Versi 1.0.0',
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
        title: const Text('Tentang Activus'),
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
              'Sistem Operasi Kehidupan Pribadi',
              style: TextStyle(color: ActivusColors.textSecondary),
            ),
            SizedBox(height: 16),
            Text(
              'Versi 1.0.0',
              style: TextStyle(color: ActivusColors.textSecondary),
            ),
            SizedBox(height: 8),
            Text(
              'Semua data tersimpan di perangkat Anda. Tidak ada yang diunggah atau dibagikan.',
              style: TextStyle(color: ActivusColors.textSecondary),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Tutup'),
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
