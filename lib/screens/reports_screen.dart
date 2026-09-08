import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../data/app_store.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import '../widgets/motion.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  int _periodIndex = 1; // Month default

  (DateTime, DateTime) _range() {
    final now = DateTime.now();
    final end = DateTime(now.year, now.month, now.day, 23, 59, 59);
    switch (_periodIndex) {
      case 0:
        return (now.subtract(const Duration(days: 7)), end);
      case 2:
        return (DateTime(now.year, now.month - 2, 1), end);
      case 3:
        return (DateTime(now.year - 1, now.month, now.day), end);
      case 1:
      default:
        return (DateTime(now.year, now.month, 1), end);
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final range = _range();
    final total = store.spendInRange(range.$1, range.$2);
    final cats = store.categoryTotals(range.$1, range.$2);
    final fuel = cats['Fuel'] ?? 0;
    final service = (cats['Service'] ?? 0) +
        (cats['Oil'] ?? 0) +
        (cats['Tires'] ?? 0) +
        (cats['Brakes'] ?? 0) +
        (cats['Inspection'] ?? 0);
    final other = total - fuel - service;
    final prevStart = range.$1.subtract(range.$2.difference(range.$1));
    final prevTotal = store.spendInRange(prevStart, range.$1);
    final delta = prevTotal == 0 ? 0.0 : ((total - prevTotal) / prevTotal) * 100;
    final months = store.lastSixMonthTotals();
    final maxM = months.fold<double>(1, math.max);
    final monthLabels = List.generate(6, (i) {
      final d = DateTime(DateTime.now().year, DateTime.now().month - (5 - i));
      return DateFormat.MMM().format(d);
    });
    final mpg = store.averageMpg();
    final cpd = store.costPerDistance();

    final catList = <(String, double, Color, String)>[];
    final palette = [
      AppColors.teal,
      AppColors.navy,
      AppColors.amber,
      AppColors.coral,
    ];
    var pi = 0;
    final sorted = cats.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    for (final e in sorted.take(4)) {
      final pct = total <= 0 ? 0.0 : e.value / total;
      catList.add((e.key, pct, palette[pi % palette.length], store.money(e.value)));
      pi++;
    }
    if (catList.isEmpty) {
      catList.add(('None', 1, AppColors.line, store.money(0)));
    }

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
                    const SizedBox(height: 20),
                    FadeSlideIn(
                      delay: const Duration(milliseconds: 70),
                      child: _PeriodSelector(
                        selected: _periodIndex,
                        onSelect: (i) => setState(() => _periodIndex = i),
                      ),
                    ),
                    const SizedBox(height: 18),
                    FadeSlideIn(
                      delay: const Duration(milliseconds: 120),
                      child: _SpendOverview(
                        total: store.money(total),
                        delta: delta,
                        fuel: store.money(fuel),
                        service: store.money(service < 0 ? 0 : service),
                        other: store.money(other < 0 ? 0 : other),
                      ),
                    ),
                    const SizedBox(height: 18),
                    FadeSlideIn(
                      delay: const Duration(milliseconds: 170),
                      child: _MonthlyBars(
                        labels: monthLabels,
                        values: months.map((e) => e / maxM).toList(),
                      ),
                    ),
                    const SizedBox(height: 18),
                    FadeSlideIn(
                      delay: const Duration(milliseconds: 220),
                      child: _CategoryBreakdown(categories: catList),
                    ),
                    const SizedBox(height: 18),
                    FadeSlideIn(
                      delay: const Duration(milliseconds: 270),
                      child: _InsightRow(
                        mpg: mpg == null ? '—' : mpg.toStringAsFixed(1),
                        economyLabel:
                            store.prefs.useMiles ? 'Avg MPG' : 'Avg km/L',
                        costPer: cpd == null ? '—' : store.money(cpd),
                        unit: store.prefs.useMiles ? 'mile' : 'km',
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
          'Reports',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontSize: 28,
                letterSpacing: -0.6,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          'Spending patterns and vehicle insights',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
}

class _PeriodSelector extends StatelessWidget {
  const _PeriodSelector({required this.selected, required this.onSelect});

  final int selected;
  final ValueChanged<int> onSelect;

  static const periods = ['Week', 'Month', 'Quarter', 'Year'];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: periods.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final isSelected = index == selected;
          return GestureDetector(
            onTap: () => onSelect(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 18),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.ink
                    : AppColors.surfaceElevated.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: isSelected ? AppColors.ink : AppColors.line,
                ),
              ),
              child: Text(
                periods[index],
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : AppColors.inkSoft,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SpendOverview extends StatelessWidget {
  const _SpendOverview({
    required this.total,
    required this.delta,
    required this.fuel,
    required this.service,
    required this.other,
  });

  final String total;
  final double delta;
  final String fuel;
  final String service;
  final String other;

  @override
  Widget build(BuildContext context) {
    final down = delta <= 0;
    return SurfacePanel(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'TOTAL SPENT',
            style: GoogleFonts.dmSans(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.3,
              color: AppColors.muted,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                total,
                style: GoogleFonts.outfit(
                  fontSize: 40,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                  letterSpacing: -1.2,
                  height: 1,
                ),
              ),
              const SizedBox(width: 12),
              Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: down ? AppColors.tealSoft : AppColors.coralSoft,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${down ? '↓' : '↑'} ${delta.abs().toStringAsFixed(1)}%',
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: down ? AppColors.tealDeep : AppColors.coral,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'vs previous period · ${DateFormat.yMMMM().format(DateTime.now())}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _MiniStat(label: 'Fuel', value: fuel)),
              Expanded(child: _MiniStat(label: 'Service', value: service)),
              Expanded(child: _MiniStat(label: 'Other', value: other)),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.ink,
          ),
        ),
      ],
    );
  }
}

class _MonthlyBars extends StatelessWidget {
  const _MonthlyBars({required this.labels, required this.values});

  final List<String> labels;
  final List<double> values;

  @override
  Widget build(BuildContext context) {
    return SurfacePanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Monthly trend',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            'Last 6 months of total expenses',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 22),
          SizedBox(
            height: 140,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var i = 0; i < labels.length; i++) ...[
                  if (i > 0) const SizedBox(width: 10),
                  Expanded(
                    child: _BarColumn(
                      label: labels[i],
                      heightFactor: values[i].clamp(0.05, 1.0),
                      highlight: i == labels.length - 1,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BarColumn extends StatelessWidget {
  const _BarColumn({
    required this.label,
    required this.heightFactor,
    required this.highlight,
  });

  final String label;
  final double heightFactor;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Expanded(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: FractionallySizedBox(
              heightFactor: heightFactor,
              widthFactor: 1,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: highlight
                        ? const [AppColors.tealDeep, AppColors.teal]
                        : [
                            AppColors.line,
                            AppColors.line.withValues(alpha: 0.55),
                          ],
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 11,
            fontWeight: highlight ? FontWeight.w700 : FontWeight.w500,
            color: highlight ? AppColors.ink : AppColors.muted,
          ),
        ),
      ],
    );
  }
}

class _CategoryBreakdown extends StatelessWidget {
  const _CategoryBreakdown({required this.categories});

  final List<(String, double, Color, String)> categories;

  @override
  Widget build(BuildContext context) {
    return SurfacePanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'By category',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              SizedBox(
                width: 96,
                height: 96,
                child: CustomPaint(
                  painter: _RingPainter(
                    segments: categories
                        .map((c) => (c.$2 <= 0 ? 0.01 : c.$2, c.$3))
                        .toList(growable: false),
                  ),
                  child: Center(
                    child: Text(
                      '100%',
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  children: [
                    for (final c in categories) ...[
                      _CategoryRow(
                        label: c.$1,
                        amount: c.$4,
                        color: c.$3,
                        percent: c.$2,
                      ),
                      const SizedBox(height: 10),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({
    required this.label,
    required this.amount,
    required this.color,
    required this.percent,
  });

  final String label;
  final String amount;
  final Color color;
  final double percent;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.inkSoft,
                  fontSize: 13,
                ),
          ),
        ),
        Text(
          amount,
          style: GoogleFonts.dmSans(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.ink,
          ),
        ),
      ],
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.segments});

  final List<(double, Color)> segments;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;
    const stroke = 12.0;
    final rect = Rect.fromCircle(center: center, radius: radius - stroke / 2);

    var start = -math.pi / 2;
    for (final segment in segments) {
      final sweep = segment.$1 * math.pi * 2;
      final paint = Paint()
        ..color = segment.$2
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.butt;
      canvas.drawArc(rect, start, sweep - 0.04, false, paint);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) => true;
}

class _InsightRow extends StatelessWidget {
  const _InsightRow({
    required this.mpg,
    required this.economyLabel,
    required this.costPer,
    required this.unit,
  });

  final String mpg;
  final String economyLabel;
  final String costPer;
  final String unit;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _InsightCard(
            title: economyLabel,
            value: mpg,
            subtitle: 'From fuel logs',
            icon: Icons.speed_rounded,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _InsightCard(
            title: 'Cost / $unit',
            value: costPer,
            subtitle: 'This history',
            icon: Icons.route_rounded,
          ),
        ),
      ],
    );
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String value;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SurfacePanel(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.tealDeep),
          const SizedBox(height: 12),
          Text(title, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 11),
          ),
        ],
      ),
    );
  }
}
