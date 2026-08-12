import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/earnings_history.dart';
import '../providers/auth_provider.dart';
import '../services/earnings_history_service.dart';
import '../utils/app_theme.dart';
import '../utils/number_formatter.dart';

class EarningsHistoryScreen extends StatefulWidget {
  const EarningsHistoryScreen({super.key});

  @override
  State<EarningsHistoryScreen> createState() => _EarningsHistoryScreenState();
}

class _EarningsHistoryScreenState extends State<EarningsHistoryScreen> {
  late final EarningsHistoryService _service;
  EarningsHistory? _data;
  bool _isLoading = true;
  String? _error;
  int? _touchedIndex;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    _service = EarningsHistoryService(auth.token ?? '');
    _load(auth.user?.id ?? '');
  }

  Future<void> _load(String staffId) async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final data = await _service.getHistory(staffId);
      setState(() => _data = data);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Earnings History', style: TextStyle(color: Colors.white)),
        backgroundColor: AppTheme.primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError()
              : _buildContent(),
    );
  }

  Widget _buildError() => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 12),
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                final auth = context.read<AuthProvider>();
                _load(auth.user?.id ?? '');
              },
              child: const Text('Retry'),
            ),
          ]),
        ),
      );

  Widget _buildContent() {
    final d = _data!;
    return RefreshIndicator(
      onRefresh: () async {
        final auth = context.read<AuthProvider>();
        await _load(auth.user?.id ?? '');
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildEmployeeHeader(d),
          const SizedBox(height: 16),
          _buildCareerStatCards(d.careerStats),
          const SizedBox(height: 16),
          _buildChart(d),
          const SizedBox(height: 16),
          _buildAnnualTable(d),
        ],
      ),
    );
  }

  // ── Employee header ────────────────────────────────────────────────────────
  Widget _buildEmployeeHeader(EarningsHistory d) {
    final emp = d.employee;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(children: [
        CircleAvatar(
          radius: 26,
          backgroundColor: Colors.white.withOpacity(0.2),
          child: Text(
            emp.name.isNotEmpty ? emp.name[0].toUpperCase() : 'S',
            style: const TextStyle(
                color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(emp.name,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15)),
            Text(emp.department,
                style: const TextStyle(color: Colors.white70, fontSize: 12)),
            Text(
              '${emp.salaryType}'
              '${emp.employmentDate != null ? '  ·  Joined ${emp.employmentDate}' : ''}',
              style: const TextStyle(color: Colors.white60, fontSize: 11),
            ),
          ]),
        ),
      ]),
    );
  }

  // ── Career stat cards ──────────────────────────────────────────────────────
  Widget _buildCareerStatCards(CareerStats s) {
    return Column(children: [
      // Row 1: total gross + total net
      Row(children: [
        Expanded(child: _statCard(
          'Career Gross',
          NumberFormatter.formatCurrency(s.totalGrossCareer),
          Icons.trending_up,
          Colors.blue[700]!,
          subtitle: '${s.totalYearsOnRecord} year${s.totalYearsOnRecord == 1 ? '' : 's'} on record',
        )),
        const SizedBox(width: 10),
        Expanded(child: _statCard(
          'Career Net',
          NumberFormatter.formatCurrency(s.totalNetCareer),
          Icons.account_balance_wallet_outlined,
          Colors.green[700]!,
          subtitle: 'After all deductions',
        )),
      ]),
      const SizedBox(height: 10),
      // Row 2: career growth + best year
      Row(children: [
        Expanded(child: _statCard(
          'Salary Growth',
          s.careerGrowthPct != null
              ? '${s.careerGrowthPct! >= 0 ? '+' : ''}${s.careerGrowthPct!.toStringAsFixed(1)}%'
              : 'N/A',
          Icons.show_chart,
          s.careerGrowthPct != null && s.careerGrowthPct! >= 0
              ? Colors.teal[700]!
              : Colors.red[600]!,
          subtitle: '${s.firstYearOnRecord} → ${s.latestYear}',
        )),
        const SizedBox(width: 10),
        Expanded(child: _statCard(
          'Best Year',
          s.bestYear.toString(),
          Icons.emoji_events_outlined,
          Colors.amber[700]!,
          subtitle: NumberFormatter.formatCurrency(s.bestYearGross),
        )),
      ]),
    ]);
  }

  Widget _statCard(String label, String value, IconData icon, Color color,
      {String? subtitle}) =>
      Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(label,
                    style: TextStyle(color: Colors.grey[600], fontSize: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ),
            ]),
            const SizedBox(height: 6),
            Text(value,
                style: TextStyle(
                    color: color, fontWeight: FontWeight.bold, fontSize: 14),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Text(subtitle,
                  style: TextStyle(color: Colors.grey[500], fontSize: 10),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ],
          ]),
        ),
      );

  // ── Bar chart ──────────────────────────────────────────────────────────────
  Widget _buildChart(EarningsHistory d) {
    final years = d.annualBreakdown;
    if (years.isEmpty) return const SizedBox.shrink();

    final maxGross = years.map((y) => y.gross).reduce((a, b) => a > b ? a : b);
    final maxY = maxGross * 1.15;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Row(children: [
            Icon(Icons.bar_chart, color: AppTheme.primaryColor, size: 20),
            SizedBox(width: 8),
            Text('Annual Gross Earnings',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          ]),
          const SizedBox(height: 4),
          Text('Tap a bar to see details',
              style: TextStyle(color: Colors.grey[500], fontSize: 11)),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: BarChart(BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxY,
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final y = years[group.x];
                    return BarTooltipItem(
                      '${y.year}\n${NumberFormatter.formatCurrency(y.gross)}',
                      const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold),
                    );
                  },
                ),
                touchCallback: (event, response) {
                  setState(() {
                    _touchedIndex = response?.spot?.touchedBarGroupIndex;
                  });
                },
              ),
              barGroups: years.asMap().entries.map((entry) {
                final i = entry.key;
                final y = entry.value;
                final isTouched = i == _touchedIndex;
                final isBest =
                    y.year == d.careerStats.bestYear;
                final color = isTouched
                    ? Colors.amber[600]!
                    : isBest
                        ? Colors.amber[400]!
                        : AppTheme.primaryColor;

                return BarChartGroupData(x: i, barRods: [
                  BarChartRodData(
                    toY: y.gross,
                    color: color,
                    width: years.length > 8 ? 14 : 22,
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(4)),
                    backDrawRodData: BackgroundBarChartRodData(
                      show: true,
                      toY: maxY,
                      color: Colors.grey[100],
                    ),
                  ),
                ]);
              }).toList(),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (v, _) {
                      final idx = v.toInt();
                      if (idx >= years.length) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          years[idx].year.toString(),
                          style: const TextStyle(fontSize: 9),
                        ),
                      );
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 52,
                    getTitlesWidget: (v, _) => Text(
                      _shortAmount(v),
                      style: const TextStyle(fontSize: 8),
                    ),
                  ),
                ),
                rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (_) =>
                    const FlLine(color: Color(0xFFEEEEEE), strokeWidth: 1),
              ),
              borderData: FlBorderData(show: false),
            )),
          ),
          const SizedBox(height: 10),
          // Legend
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            _chartLegend(Colors.amber[400]!, 'Best Year'),
            const SizedBox(width: 16),
            _chartLegend(AppTheme.primaryColor, 'Other Years'),
          ]),

          // Touched year detail
          if (_touchedIndex != null &&
              _touchedIndex! < years.length) ...[
            const SizedBox(height: 14),
            _buildTouchedYearDetail(years[_touchedIndex!]),
          ],
        ]),
      ),
    );
  }

  Widget _chartLegend(Color color, String label) => Row(children: [
        Container(
            width: 12,
            height: 12,
            decoration:
                BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11)),
      ]);

  Widget _buildTouchedYearDetail(EarningsYear y) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withOpacity(0.07),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.primaryColor.withOpacity(0.2)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${y.year} Details',
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
          const SizedBox(height: 8),
          Row(children: [
            _miniStat('Gross', NumberFormatter.formatCurrency(y.gross),
                Colors.blue[700]!),
            _miniStat('Deductions',
                NumberFormatter.formatCurrency(y.deductions), Colors.red[600]!),
            _miniStat(
                'Net', NumberFormatter.formatCurrency(y.net), Colors.green[700]!),
          ]),
          const SizedBox(height: 6),
          Row(children: [
            _miniStat('Months Paid', '${y.monthsPaid}', Colors.grey[700]!),
            _miniStat('Avg Monthly',
                NumberFormatter.formatCurrency(y.avgMonthlyGross),
                Colors.purple[700]!),
            if (y.growthPct != null)
              _miniStat(
                'YoY Growth',
                '${y.growthPct! >= 0 ? '+' : ''}${y.growthPct!.toStringAsFixed(1)}%',
                y.growthPct! >= 0 ? Colors.teal[700]! : Colors.red[600]!,
              ),
          ]),
        ]),
      );

  Widget _miniStat(String label, String value, Color color) => Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 10)),
          Text(value,
              style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ]),
      );

  // ── Annual table ───────────────────────────────────────────────────────────
  Widget _buildAnnualTable(EarningsHistory d) => Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Row(children: [
              Icon(Icons.table_rows_outlined,
                  color: AppTheme.primaryColor, size: 20),
              SizedBox(width: 8),
              Text('Year-by-Year Breakdown',
                  style:
                      TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            ]),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowHeight: 36,
                dataRowMinHeight: 44,
                dataRowMaxHeight: 44,
                columnSpacing: 14,
                headingTextStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                    color: AppTheme.primaryColor),
                columns: const [
                  DataColumn(label: Text('Year')),
                  DataColumn(label: Text('Mths'), numeric: true),
                  DataColumn(label: Text('Gross'), numeric: true),
                  DataColumn(label: Text('Net'), numeric: true),
                  DataColumn(label: Text('YoY'), numeric: true),
                ],
                rows: d.annualBreakdown.reversed.map((y) {
                  final isBest = y.year == d.careerStats.bestYear;
                  return DataRow(
                    color: isBest
                        ? WidgetStateProperty.all(Colors.amber[50])
                        : null,
                    cells: [
                      DataCell(Row(children: [
                        Text(y.year.toString(),
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: isBest
                                    ? Colors.amber[700]
                                    : null)),
                        if (isBest) ...[
                          const SizedBox(width: 4),
                          Icon(Icons.star,
                              size: 12, color: Colors.amber[600]),
                        ],
                      ])),
                      DataCell(Text('${y.monthsPaid}',
                          style: const TextStyle(fontSize: 12))),
                      DataCell(Text(
                          NumberFormatter.formatCurrency(y.gross),
                          style: const TextStyle(fontSize: 12))),
                      DataCell(Text(
                          NumberFormatter.formatCurrency(y.net),
                          style: TextStyle(
                              fontSize: 12,
                              color: Colors.green[700],
                              fontWeight: FontWeight.w500))),
                      DataCell(y.growthPct != null
                          ? _growthChip(y.growthPct!)
                          : const Text('—',
                              style: TextStyle(color: Colors.grey))),
                    ],
                  );
                }).toList(),
              ),
            ),
          ]),
        ),
      );

  Widget _growthChip(double pct) {
    final positive = pct >= 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: positive ? Colors.green[50] : Colors.red[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: positive ? Colors.green.shade200 : Colors.red.shade200),
      ),
      child: Text(
        '${positive ? '+' : ''}${pct.toStringAsFixed(1)}%',
        style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: positive ? Colors.green[700] : Colors.red[600]),
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  String _shortAmount(double v) {
    if (v >= 1000000) return '₦${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '₦${(v / 1000).toStringAsFixed(0)}K';
    return '₦${v.toStringAsFixed(0)}';
  }
}
