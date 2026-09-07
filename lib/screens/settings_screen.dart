import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import '../widgets/motion.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
                      child: const _ProfileCard(),
                    ),
                    const SizedBox(height: 24),
                    FadeSlideIn(
                      delay: const Duration(milliseconds: 120),
                      child: const _SettingsGroup(
                        title: 'Vehicles',
                        rows: [
                          _SettingRowData(
                            icon: Icons.directions_car_outlined,
                            title: 'Manage vehicles',
                            subtitle: '1 vehicle · Toyota Camry',
                          ),
                          _SettingRowData(
                            icon: Icons.add_road_rounded,
                            title: 'Add vehicle',
                            subtitle: 'Track another car',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    FadeSlideIn(
                      delay: const Duration(milliseconds: 170),
                      child: const _SettingsGroup(
                        title: 'Preferences',
                        rows: [
                          _SettingRowData(
                            icon: Icons.notifications_outlined,
                            title: 'Reminders',
                            subtitle: 'Service & expense alerts',
                            trailing: _TogglePreview(value: true),
                          ),
                          _SettingRowData(
                            icon: Icons.attach_money_rounded,
                            title: 'Currency',
                            subtitle: 'USD (\$)',
                          ),
                          _SettingRowData(
                            icon: Icons.straighten_rounded,
                            title: 'Units',
                            subtitle: 'Miles · Gallons',
                          ),
                          _SettingRowData(
                            icon: Icons.palette_outlined,
                            title: 'Appearance',
                            subtitle: 'System default',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    FadeSlideIn(
                      delay: const Duration(milliseconds: 220),
                      child: const _SettingsGroup(
                        title: 'Data & support',
                        rows: [
                          _SettingRowData(
                            icon: Icons.cloud_upload_outlined,
                            title: 'Backup & export',
                            subtitle: 'CSV · PDF reports',
                          ),
                          _SettingRowData(
                            icon: Icons.lock_outline_rounded,
                            title: 'Privacy',
                            subtitle: 'Data stays on this device',
                          ),
                          _SettingRowData(
                            icon: Icons.help_outline_rounded,
                            title: 'Help & feedback',
                            subtitle: 'Guides and contact',
                          ),
                          _SettingRowData(
                            icon: Icons.info_outline_rounded,
                            title: 'About CarTrack',
                            subtitle: 'Version 1.0.0',
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
  const _ProfileCard();

  @override
  Widget build(BuildContext context) {
    return SurfacePanel(
      onTap: () {},
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
              'AR',
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
                  'Alex Rivera',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontSize: 18,
                      ),
                ),
                const SizedBox(height: 3),
                Text(
                  'alex@cartrack.app',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
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
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
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
      onTap: () {},
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

class _TogglePreview extends StatelessWidget {
  const _TogglePreview({required this.value});

  final bool value;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Switch.adaptive(
        value: value,
        onChanged: (_) {},
        activeThumbColor: Colors.white,
        activeTrackColor: AppColors.teal,
      ),
    );
  }
}
