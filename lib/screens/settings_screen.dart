import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/app_store.dart';
import '../data/backup_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import '../widgets/motion.dart';
import 'privacy_policy_screen.dart';
import 'vehicle_actions.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final v = store.activeVehicle;
    final nameParts = store.prefs.displayName
        .trim()
        .split(RegExp(r'\s+'))
        .where((e) => e.isNotEmpty)
        .take(2);
    final initials = nameParts.isEmpty
        ? 'CT'
        : nameParts.map((e) => e[0].toUpperCase()).join();

    return AtmosphericBackground(
      child: SafeArea(
        bottom: false,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FadeSlideIn(child: _Header()),
                    const SizedBox(height: 22),
                    FadeSlideIn(
                      delay: const Duration(milliseconds: 70),
                      child: _ProfileCard(
                        initials: initials,
                        name: store.prefs.displayName,
                        email: store.prefs.email.isEmpty
                            ? 'Tap to edit profile'
                            : store.prefs.email,
                        onTap: () => _editProfile(context, store),
                      ),
                    ),
                    const SizedBox(height: 24),
                    FadeSlideIn(
                      delay: const Duration(milliseconds: 120),
                      child: _SettingsGroup(
                        title: 'Vehicles',
                        rows: [
                          _SettingRowData(
                            icon: Icons.directions_car_outlined,
                            title: 'Manage vehicles',
                            subtitle: v == null
                                ? 'No vehicles'
                                : '${store.vehicles.length} vehicle${store.vehicles.length == 1 ? '' : 's'} · ${v.name}',
                            onTap: () => _manageVehicles(context, store),
                          ),
                          _SettingRowData(
                            icon: Icons.add_road_rounded,
                            title: 'Add vehicle',
                            subtitle: 'Track another car',
                            onTap: () => showAddVehicleDialog(context),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    FadeSlideIn(
                      delay: const Duration(milliseconds: 170),
                      child: _SettingsGroup(
                        title: 'Preferences',
                        rows: [
                          _SettingRowData(
                            icon: Icons.notifications_outlined,
                            title: 'Reminders',
                            subtitle: 'Service & expense alerts',
                            trailing: Switch.adaptive(
                              value: store.prefs.remindersEnabled,
                              onChanged: (v) => store.setRemindersEnabled(v),
                              activeThumbColor: Colors.white,
                              activeTrackColor: AppColors.teal,
                            ),
                          ),
                          _SettingRowData(
                            icon: Icons.attach_money_rounded,
                            title: 'Currency',
                            subtitle: store.prefs.currency,
                            onTap: () => _pickCurrency(context, store),
                          ),
                          _SettingRowData(
                            icon: Icons.straighten_rounded,
                            title: 'Units',
                            subtitle: store.prefs.useMiles
                                ? 'Miles · Gallons'
                                : 'Kilometers · Liters',
                            onTap: () async {
                              final p = store.prefs;
                              p.useMiles = !p.useMiles;
                              await store.updatePrefs(p);
                            },
                          ),
                          _SettingRowData(
                            icon: Icons.palette_outlined,
                            title: 'Appearance',
                            subtitle: 'System default',
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Light theme is active'),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    FadeSlideIn(
                      delay: const Duration(milliseconds: 220),
                      child: _SettingsGroup(
                        title: 'Data & support',
                        rows: [
                          _SettingRowData(
                            icon: Icons.cloud_upload_outlined,
                            title: 'Backup & export',
                            subtitle: 'Backup to Drive · restore from file',
                            onTap: () => BackupService.showBackupSheet(context),
                          ),
                          _SettingRowData(
                            icon: Icons.lock_outline_rounded,
                            title: 'Privacy',
                            subtitle: 'Data stays on this device',
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => const PrivacyPolicyScreen(),
                              ),
                            ),
                          ),
                          _SettingRowData(
                            icon: Icons.help_outline_rounded,
                            title: 'Help & feedback',
                            subtitle: 'Guides and contact',
                            onTap: () async {
                              final uri = Uri.parse(
                                'mailto:support@forgetech.dev?subject=CarTrack%20Help',
                              );
                              if (await canLaunchUrl(uri)) {
                                await launchUrl(uri);
                              }
                            },
                          ),
                          _SettingRowData(
                            icon: Icons.info_outline_rounded,
                            title: 'About CarTrack',
                            subtitle: 'Version 1.0.0',
                            onTap: () {
                              showAboutDialog(
                                context: context,
                                applicationName: 'CarTrack',
                                applicationVersion: '1.0.0',
                                applicationLegalese: '© ForgeTech',
                                children: const [
                                  SizedBox(height: 12),
                                  Text(
                                    'Local-first car maintenance tracker. Backup to Google Drive anytime.',
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    FadeSlideIn(
                      delay: const Duration(milliseconds: 270),
                      child: Center(
                        child: Text(
                          'Built for smarter ownership',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ),
                    const SizedBox(height: 110),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _editProfile(BuildContext context, AppStore store) async {
  final name = TextEditingController(text: store.prefs.displayName);
  final email = TextEditingController(text: store.prefs.email);
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Edit profile'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(controller: name, decoration: const InputDecoration(labelText: 'Name')),
          TextField(controller: email, decoration: const InputDecoration(labelText: 'Email')),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
        TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
      ],
    ),
  );
  if (ok == true) {
    final p = store.prefs;
    p.displayName = name.text.trim().isEmpty ? 'Driver' : name.text.trim();
    p.email = email.text.trim();
    await store.updatePrefs(p);
  }
}

Future<void> _pickCurrency(BuildContext context, AppStore store) async {
  const options = ['USD', 'EUR', 'GBP', 'PKR', 'INR'];
  final picked = await showModalBottomSheet<String>(
    context: context,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final c in options)
            ListTile(
              title: Text(c),
              trailing: store.prefs.currency == c
                  ? const Icon(Icons.check, color: AppColors.teal)
                  : null,
              onTap: () => Navigator.pop(ctx, c),
            ),
        ],
      ),
    ),
  );
  if (picked != null) {
    final p = store.prefs;
    p.currency = picked;
    await store.updatePrefs(p);
  }
}

Future<void> _manageVehicles(BuildContext context, AppStore store) async {
  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.surfaceElevated,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => Consumer<AppStore>(
      builder: (ctx, store, _) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Manage vehicles',
                      style: Theme.of(ctx).textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    onPressed: () => showVehicleEditor(ctx),
                    icon: const Icon(Icons.add_rounded),
                    tooltip: 'Add vehicle',
                    color: AppColors.tealDeep,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              for (final v in store.vehicles)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    Icons.directions_car_filled_rounded,
                    color: v.id == store.activeVehicleId
                        ? AppColors.teal
                        : AppColors.muted,
                  ),
                  title: Text(v.name),
                  subtitle: Text(
                    v.id == store.activeVehicleId
                        ? '${v.subtitle} · Active'
                        : v.subtitle,
                  ),
                  onTap: () async {
                    await store.setActiveVehicle(v.id);
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: () => showVehicleEditor(ctx, vehicle: v),
                        icon: const Icon(Icons.edit_outlined),
                        tooltip: 'Edit vehicle',
                      ),
                      IconButton(
                        onPressed: () => confirmDeleteVehicle(ctx, v),
                        icon: const Icon(Icons.delete_outline_rounded),
                        color: AppColors.coral,
                        tooltip: 'Delete vehicle',
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Settings',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontSize: 28,
                letterSpacing: -0.6,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          'Profile, vehicles, and app preferences',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.initials,
    required this.name,
    required this.email,
    required this.onTap,
  });

  final String initials;
  final String name;
  final String email;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SurfacePanel(
      onTap: onTap,
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.navy, AppColors.tealDeep],
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              initials,
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontSize: 18,
                      ),
                ),
                const SizedBox(height: 3),
                Text(email, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
        ],
      ),
    );
  }
}

class _SettingRowData {
  const _SettingRowData({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.title, required this.rows});

  final String title;
  final List<_SettingRowData> rows;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text(
            title.toUpperCase(),
            style: GoogleFonts.dmSans(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.3,
              color: AppColors.muted,
            ),
          ),
        ),
        SurfacePanel(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (var i = 0; i < rows.length; i++) ...[
                if (i > 0) const Divider(indent: 62, endIndent: 16),
                _SettingsTile(data: rows[i]),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({required this.data});

  final _SettingRowData data;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: data.onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(data.icon, size: 20, color: AppColors.inkSoft),
      ),
      title: Text(
        data.title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 15),
      ),
      subtitle: Text(
        data.subtitle,
        style: Theme.of(context).textTheme.bodySmall,
      ),
      trailing: data.trailing ??
          const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
    );
  }
}
