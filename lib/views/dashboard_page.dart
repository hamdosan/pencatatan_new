import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../controllers/expense_controller.dart';
import 'widgets/formatters.dart';
import 'widgets/month_selector.dart';

const _chartAnim = Duration(milliseconds: 450);
const _chartCurve = Curves.easeOutCubic;

/// Tab "Home": ringkasan dan grafik pengeluaran.
class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.watch<ExpenseController>();
    if (c.error != null) return Center(child: Text(c.error!));

    return LayoutBuilder(builder: (context, constraints) {
      final wide = constraints.maxWidth >= 720;
      final charts = <Widget>[
        _ChartCard(
          title: 'Pengeluaran harian',
          child: _DailyBarChart(controller: c),
        ),
        _ChartCard(
          title: 'Per kategori',
          child: _CategoryPieChart(controller: c),
        ),
      ];

      return ListView(
        padding: const EdgeInsets.only(bottom: 88),
        children: [
          MonthSelector(controller: c),
          if (c.isLoading)
            const Padding(
              padding: EdgeInsets.all(48),
              child: Center(child: CircularProgressIndicator()),
            )
          else ...[
            _StatRow(controller: c),
            if (wide)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [for (final w in charts) Expanded(child: w)],
                  ),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Column(children: charts),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: _ChartCard(
                title: 'Tren ${ExpenseController.trendMonths} bulan',
                child: _TrendLineChart(controller: c),
              ),
            ),
          ],
        ],
      );
    });
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({required this.controller});
  final ExpenseController controller;

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final now = DateTime.now();
    final daysCounted = c.isCurrentMonth ? now.day : c.dailyTotals.length;
    final avg = daysCounted == 0 ? 0 : c.totalAmount ~/ daysCounted;

    final stats = [
      ('Total', formatRupiah(c.totalAmount), Icons.account_balance_wallet),
      ('Rata-rata/hari', formatRupiah(avg), Icons.today),
      ('Transaksi', '${c.expenses.length}', Icons.receipt_long),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
      child: Row(
        children: [
          for (final (label, value, icon) in stats)
            Expanded(
              child: Card(
                margin: const EdgeInsets.all(4),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(icon,
                          size: 20,
                          color: Theme.of(context).colorScheme.primary),
                      const SizedBox(height: 8),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          value,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Text(label,
                          style: Theme.of(context).textTheme.labelSmall),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(4),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

class _EmptyChart extends StatelessWidget {
  const _EmptyChart();

  @override
  Widget build(BuildContext context) => const SizedBox(
        height: 180,
        child: Center(child: Text('Belum ada data')),
      );
}

/// Label ringkas: 1.500.000 -> 1,5jt; 25.000 -> 25rb.
String _compact(num v) {
  if (v >= 1000000) {
    return '${NumberFormat('#,##0.#', 'id_ID').format(v / 1000000)}jt';
  }
  if (v >= 1000) return '${(v / 1000).round()}rb';
  return v.toStringAsFixed(0);
}

/// Batas atas sumbu Y yang "bulat" agar garis bantu rapi.
double _niceMax(int max) {
  if (max <= 0) return 1;
  final mag = math.pow(10, (math.log(max) / math.ln10).floor()).toDouble();
  for (final step in [1, 2, 2.5, 5, 10]) {
    if (step * mag >= max) return step * mag;
  }
  return 10 * mag;
}

class _DailyBarChart extends StatelessWidget {
  const _DailyBarChart({required this.controller});
  final ExpenseController controller;

  @override
  Widget build(BuildContext context) {
    final daily = controller.dailyTotals;
    if (daily.every((v) => v == 0)) return const _EmptyChart();

    final scheme = Theme.of(context).colorScheme;
    final maxY = _niceMax(daily.reduce(math.max));

    return SizedBox(
      height: 200,
      child: BarChart(
        duration: _chartAnim,
        curve: _chartCurve,
        BarChartData(
          maxY: maxY,
          alignment: BarChartAlignment.spaceBetween,
          barGroups: [
            for (var i = 0; i < daily.length; i++)
              BarChartGroupData(x: i + 1, barRods: [
                BarChartRodData(
                  toY: daily[i].toDouble(),
                  color: scheme.primary,
                  width: 5,
                  borderRadius: BorderRadius.circular(2),
                ),
              ]),
          ],
          gridData: FlGridData(
            drawVerticalLine: false,
            horizontalInterval: maxY / 4,
            getDrawingHorizontalLine: (_) => FlLine(
              color: scheme.outlineVariant,
              strokeWidth: 1,
              dashArray: [4, 4],
            ),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(),
            rightTitles: const AxisTitles(),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                interval: maxY / 4,
                getTitlesWidget: (v, meta) => SideTitleWidget(
                  meta: meta,
                  child: Text(_compact(v),
                      style: Theme.of(context).textTheme.labelSmall),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 24,
                getTitlesWidget: (v, meta) {
                  final d = v.toInt();
                  final show = d == 1 || d % 5 == 0;
                  return SideTitleWidget(
                    meta: meta,
                    child: Text(show ? '$d' : '',
                        style: Theme.of(context).textTheme.labelSmall),
                  );
                },
              ),
            ),
          ),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => scheme.inverseSurface,
              getTooltipItem: (group, groupIndex, rod, rodIndex) => BarTooltipItem(
                'Tgl ${group.x}\n${formatRupiah(rod.toY)}',
                TextStyle(color: scheme.onInverseSurface, fontSize: 12),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryPieChart extends StatefulWidget {
  const _CategoryPieChart({required this.controller});
  final ExpenseController controller;

  @override
  State<_CategoryPieChart> createState() => _CategoryPieChartState();
}

class _CategoryPieChartState extends State<_CategoryPieChart> {
  int _touched = -1;

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final data = c.totalByCategory;
    if (data.isEmpty) return const _EmptyChart();

    final total = c.totalAmount;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      children: [
        SizedBox(
          height: 180,
          child: PieChart(
            duration: _chartAnim,
            curve: _chartCurve,
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 44,
              pieTouchData: PieTouchData(
                touchCallback: (event, response) {
                  final i = (!event.isInterestedForInteractions ||
                          response?.touchedSection == null)
                      ? -1
                      : response!.touchedSection!.touchedSectionIndex;
                  if (i != _touched) setState(() => _touched = i);
                },
              ),
              sections: [
                for (var i = 0; i < data.length; i++)
                  () {
                    final cat = c.categoryOf(data[i].key);
                    final pct = total == 0 ? 0 : data[i].value * 100 / total;
                    final touched = i == _touched;
                    return PieChartSectionData(
                      value: data[i].value.toDouble(),
                      color: Color(cat?.colorValue ?? 0xFF607D8B),
                      radius: touched ? 52 : 44,
                      title: pct >= 8 ? '${pct.round()}%' : '',
                      titleStyle: textTheme.labelSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  }(),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 6,
          children: [
            for (final e in data)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: Color(
                          c.categoryOf(e.key)?.colorValue ?? 0xFF607D8B),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${c.categoryOf(e.key)?.name ?? '-'} · ${_compact(e.value)}',
                    style: textTheme.labelMedium,
                  ),
                ],
              ),
          ],
        ),
      ],
    );
  }
}

class _TrendLineChart extends StatelessWidget {
  const _TrendLineChart({required this.controller});
  final ExpenseController controller;

  @override
  Widget build(BuildContext context) {
    final trend = controller.monthlyTrend;
    if (trend.every((t) => t.$2 == 0)) return const _EmptyChart();

    final scheme = Theme.of(context).colorScheme;
    final labelStyle = Theme.of(context).textTheme.labelSmall;
    final maxY = _niceMax(trend.map((t) => t.$2).reduce(math.max));

    return SizedBox(
      height: 200,
      child: LineChart(
        duration: _chartAnim,
        curve: _chartCurve,
        LineChartData(
          minY: 0,
          maxY: maxY,
          minX: 0,
          maxX: (trend.length - 1).toDouble(),
          lineBarsData: [
            LineChartBarData(
              spots: [
                for (var i = 0; i < trend.length; i++)
                  FlSpot(i.toDouble(), trend[i].$2.toDouble()),
              ],
              isCurved: true,
              preventCurveOverShooting: true,
              color: scheme.primary,
              barWidth: 3,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    scheme.primary.withValues(alpha: 0.3),
                    scheme.primary.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ],
          gridData: FlGridData(
            drawVerticalLine: false,
            horizontalInterval: maxY / 4,
            getDrawingHorizontalLine: (_) => FlLine(
              color: scheme.outlineVariant,
              strokeWidth: 1,
              dashArray: [4, 4],
            ),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(),
            rightTitles: const AxisTitles(),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                interval: maxY / 4,
                getTitlesWidget: (v, meta) => SideTitleWidget(
                  meta: meta,
                  child: Text(_compact(v), style: labelStyle),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                reservedSize: 24,
                getTitlesWidget: (v, meta) {
                  final i = v.toInt();
                  if (i < 0 || i >= trend.length || v != i.toDouble()) {
                    return const SizedBox.shrink();
                  }
                  return SideTitleWidget(
                    meta: meta,
                    child: Text(
                      DateFormat('MMM', 'id_ID').format(trend[i].$1),
                      style: labelStyle,
                    ),
                  );
                },
              ),
            ),
          ),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => scheme.inverseSurface,
              getTooltipItems: (spots) => [
                for (final s in spots)
                  LineTooltipItem(
                    '${formatMonth(trend[s.x.toInt()].$1)}\n${formatRupiah(s.y)}',
                    TextStyle(color: scheme.onInverseSurface, fontSize: 12),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
