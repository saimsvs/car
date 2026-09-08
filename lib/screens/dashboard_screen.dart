import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../data/app_store.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import '../widgets/motion.dart';
import 'add_entry_sheet.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
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
                    FadeSlideIn(child: _TopBar(store: store)),
                    const SizedBox(height: 22),
                    FadeSlideIn(
                      delay: const Duration(milliseconds: 80),
                      child: _VehicleHero(store: store),
                    ),
                    const SizedBox(height: 20),
                    FadeSlideIn(
                      delay: const Duration(milliseconds: 140),
                      child: _QuickMetrics(store: store),
                    ),
                    const SizedBox(height: 28),
                    FadeSlideIn(
                      delay: const Duration(milliseconds: 200),
                      child: SectionHeader(
                        title: 'Upcoming care',
                        actionLabel: 'See all',
                        onAction: () => _showRemindersSheet(context, store),
                      ),
                    ),
                    const SizedBox(height: 12),
                    FadeSlideIn(
                      delay: const Duration(milliseconds: 240),
                      child: _UpcomingList(store: store),
                    ),
                    const SizedBox(height: 28),
                    FadeSlideIn(
                      delay: const Duration(milliseconds: 280),
                      child: SectionHeader(
                        title: 'Recent expenses',
                        actionLabel: 'See all',
                        onAction: () => _showExpensesSheet(context, store),
                      ),
                    ),
                    const SizedBox(height: 12),
                    FadeSlideIn(
                      delay: const Duration(milliseconds: 320),
                      child: _ExpenseList(store: store),
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

void _showRemindersSheet(BuildContext context, AppStore store) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.surfaceElevated,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) {
      final items = store.openReminders();
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Upcoming care', style: Theme.of(ctx).textTheme.titleLarge),
              const SizedBox(height: 12),
              if (items.isEmpty)
                const Text('No open reminders.')
              else
                ...items.map(
                  (r) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(r.title),
                    subtitle: Text('Due in ${r.daysLeft} days'),
                    trailing: TextButton(
                      onPressed: () async {
                        await store.completeReminder(r.id);
                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                      child: const Text('Done'),
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    },
  );
}

void _showExpensesSheet(BuildContext context, AppStore store) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surfaceElevated,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) {
      final items = store.logsForVehicle();
      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (_, controller) => ListView(
          controller: controller,
          padding: const EdgeInsets.all(20),
          children: [
            Text('All expenses', style: Theme.of(ctx).textTheme.titleLarge),
            const SizedBox(height: 8),
            ...items.map(
              (e) => ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(e.title),
                subtitle: Text(
                  '${e.category} · ${DateFormat.yMMMd().format(e.date)}',
                ),
                trailing: Text(store.money(e.amount)),
              ),
            ),
          ],
        ),
      );
    },
  );
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.store});

  final AppStore store;

  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;
    final hello = hour < 12
        ? 'Good morning'
        : hour < 17
            ? 'Good afternoon'
            : 'Good evening';
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'CARTRACK',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2.4,
                  color: AppColors.tealDeep,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$hello, ${store.prefs.displayName}',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontSize: 24,
                      letterSpacing: -0.5,
                    ),
              ),
            ],
          ),
        ),
        Material(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () {
              final n = store.openReminders().length;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    n == 0
                        ? 'No reminders due'
                        : '$n reminder${n == 1 ? '' : 's'} open',
                  ),
                ),
              );
            },
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.line),
              ),
              child: const Icon(Icons.notifications_none_rounded, size: 22),
            ),
          ),
        ),
      ],
    );
  }
}

class _VehicleHero extends StatefulWidget {
  const _VehicleHero({required this.store});

  final AppStore store;

  @override
  State<_VehicleHero> createState() => _VehicleHeroState();
}

class _VehicleHeroState extends State<_VehicleHero> {
  late final PageController _pageController;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    final store = widget.store;
    final idx = store.vehicles.indexWhere((v) => v.id == store.activeVehicleId);
    _page = idx < 0 ? 0 : idx;
    _pageController = PageController(initialPage: _page);
  }

  @override
  void didUpdateWidget(covariant _VehicleHero oldWidget) {
    super.didUpdateWidget(oldWidget);
    final store = widget.store;
    final idx = store.vehicles.indexWhere((v) => v.id == store.activeVehicleId);
    if (idx >= 0 && idx != _page && _pageController.hasClients) {
      _page = idx;
      _pageController.jumpToPage(idx);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    final vehicles = store.vehicles;

    if (vehicles.isEmpty) {
      return _heroCard(
        title: 'No vehicle',
        subtitle: 'Tap the car button to add one',
        odo: '—',
        health: '—',
        next: '—',
        badge: 'GARAGE',
        pageIndex: 0,
        pageCount: 0,
      );
    }

    return Column(
      children: [
        SizedBox(
          height: 232,
          child: PageView.builder(
            controller: _pageController,
            itemCount: vehicles.length,
            onPageChanged: (i) async {
              setState(() => _page = i);
              await store.setActiveVehicle(vehicles[i].id);
            },
            itemBuilder: (context, index) {
              final v = vehicles[index];
              final open = store.openReminders(v.id);
              final next =
                  open.isEmpty ? 'None' : '${open.first.daysLeft} days';
              final odo =
                  '${NumberFormat('#,###').format(v.mileage)}${store.prefs.useMiles ? ' mi' : ' km'}';
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: _heroCard(
                  title: v.name,
                  subtitle: v.subtitle,
                  odo: odo,
                  health: open.any((e) => e.daysLeft <= 7) ? 'Due soon' : 'Good',
                  next: next,
                  badge: vehicles.length == 1
                      ? 'PRIMARY VEHICLE'
                      : 'VEHICLE ${index + 1} OF ${vehicles.length}',
                  pageIndex: index,
                  pageCount: vehicles.length,
                  showSwipeHint: vehicles.length > 1,
                ),
              );
            },
          ),
        ),
        if (vehicles.length > 1) ...[
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < vehicles.length; i++)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: i == _page ? 18 : 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: i == _page ? AppColors.tealDeep : AppColors.line,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _heroCard({
    required String title,
    required String subtitle,
    required String odo,
    required String health,
    required String next,
    required String badge,
    required int pageIndex,
    required int pageCount,
    bool showSwipeHint = false,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF15324A), Color(0xFF0F766E)],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withValues(alpha: 0.28),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Flexible(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    badge,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.dmSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (showSwipeHint)
                Icon(
                  Icons.swipe_rounded,
                  color: Colors.white.withValues(alpha: 0.55),
                  size: 20,
                )
              else
                Icon(
                  Icons.directions_car_filled_rounded,
                  color: Colors.white.withValues(alpha: 0.9),
                  size: 26,
                ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.outfit(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: -0.6,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  color: Colors.white.withValues(alpha: 0.72),
                  height: 1.2,
                ),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(child: _HeroStat(label: 'Odometer', value: odo)),
              Container(
                width: 1,
                height: 34,
                color: Colors.white.withValues(alpha: 0.18),
              ),
              Expanded(child: _HeroStat(label: 'Health', value: health)),
              Container(
                width: 1,
                height: 34,
                color: Colors.white.withValues(alpha: 0.18),
              ),
              Expanded(child: _HeroStat(label: 'Next service', value: next)),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.dmSans(
              fontSize: 11,
              color: Colors.white.withValues(alpha: 0.55),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickMetrics extends StatelessWidget {
  const _QuickMetrics({required this.store});

  final AppStore store;

  @override
  Widget build(BuildContext context) {
    final mpg = store.averageMpg();
    return Row(
      children: [
        Expanded(
          child: _MetricTile(
            icon: Icons.payments_outlined,
            label: 'This month',
            value: store.money(store.spendInMonth(DateTime.now())),
            tint: AppColors.tealSoft,
            iconColor: AppColors.tealDeep,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _MetricTile(
            icon: Icons.local_gas_station_outlined,
            label: 'Avg. MPG',
            value: mpg == null ? '—' : mpg.toStringAsFixed(1),
            tint: AppColors.navySoft,
            iconColor: AppColors.navy,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _MetricTile(
            icon: Icons.build_circle_outlined,
            label: 'Open tasks',
            value: '${store.openReminders().length}',
            tint: AppColors.amberSoft,
            iconColor: AppColors.amber,
          ),
        ),
      ],
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.tint,
    required this.iconColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color tint;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return SurfacePanel(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: tint,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(height: 14),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _UpcomingList extends StatelessWidget {
  const _UpcomingList({required this.store});

  final AppStore store;

  @override
  Widget build(BuildContext context) {
    final items = store.openReminders().take(3).toList();
    if (items.isEmpty) {
      return SurfacePanel(
        onTap: () => showAddEntrySheet(context),
        child: Text(
          'No upcoming reminders. Tap the car button to log service.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }

    return Column(
      children: [
        for (final item in items) ...[
          SurfacePanel(
            onTap: () async {
              await store.completeReminder(item.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${item.title} marked done')),
                );
              }
            },
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: item.daysLeft <= 14
                        ? AppColors.amberSoft
                        : AppColors.tealSoft,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.opacity_rounded,
                    color: item.daysLeft <= 14
                        ? AppColors.amber
                        : AppColors.teal,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        item.dueMileage == null
                            ? 'Due in ${item.daysLeft} days'
                            : 'Due in ${item.daysLeft} days · ${NumberFormat('#,###').format(item.dueMileage)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: item.daysLeft <= 14
                        ? AppColors.amberSoft
                        : AppColors.tealSoft,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    item.daysLeft <= 14 ? 'Soon' : 'Scheduled',
                    style: GoogleFonts.dmSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: item.daysLeft <= 14
                          ? AppColors.amber
                          : AppColors.teal,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _ExpenseList extends StatelessWidget {
  const _ExpenseList({required this.store});

  final AppStore store;

  @override
  Widget build(BuildContext context) {
    final items = store.logsForVehicle().take(5).toList();
    if (items.isEmpty) {
      return SurfacePanel(
        onTap: () => showAddEntrySheet(context),
        child: Text(
          'No expenses yet. Tap to add one.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }

    IconData iconFor(ExpenseLog e) => switch (e.kind) {
          LogKind.fuel => Icons.local_gas_station,
          LogKind.service => Icons.handyman_outlined,
          LogKind.income => Icons.trending_up_rounded,
          LogKind.expense => Icons.water_drop_outlined,
        };

    return SurfacePanel(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) const Divider(indent: 70, endIndent: 16),
            ListTile(
              onTap: () => showAddEntrySheet(context),
              onLongPress: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Delete entry?'),
                    content: Text(items[i].title),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                );
                if (ok == true) await store.deleteLog(items[i].id);
              },
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
              leading: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(iconFor(items[i]), color: AppColors.inkSoft, size: 20),
              ),
              title: Text(
                items[i].title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontSize: 15,
                    ),
              ),
              subtitle: Text(
                '${items[i].category} · ${DateFormat.MMMd().format(items[i].date)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              trailing: Text(
                store.money(items[i].amount),
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
