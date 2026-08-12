import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/deductions_tracker.dart';
import '../providers/auth_provider.dart';
import '../services/deductions_tracker_service.dart';
import '../utils/app_theme.dart';
import '../utils/number_formatter.dart';

class DeductionsTrackerScreen extends StatefulWidget {
  const DeductionsTrackerScreen({super.key});

  @override
  State<DeductionsTrackerScreen> createState() =>
      _DeductionsTrackerScreenState();
}

class _DeductionsTrackerScreenState extends State<DeductionsTrackerScreen> {
  late final DeductionsTrackerService _service;
  late final String _staffId;

  DeductionsTracker? _data;
  bool _isLoading = true;
  String? _error;
  int? _selectedYear;
  int? _expandedIndex; // which deduction card is expanded

  // Category UI config
  static const _catConfig = {
    'statutory': (label: 'Statutory', color: Color(0xFF1565C0), icon: Icons.account_balance_outlined),
    'loans':     (label: 'Loans',     color: Color(0xFFB71C1C), icon: Icons.credit_card_outlined),
    'union':     (label: 'Union',     color: Color(0xFF4A148C), icon: Icons.groups_outlined),
    'health':    (label: 'Health',    color: Color(0xFF1B5E20), icon: Icons.health_and_safety_outlined),
    'other':     (label: 'Other',     color: Color(0xFF37474F), icon: Icons.label_outline),
  };

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    _staffId = auth.user?.id ?? '';
    _service = DeductionsTrackerService(auth.token ?? '');
    _load();
  }

  Future<void> _load({int? year}) async {
    setState(() { _isLoading = true; _error = null; _expandedIndex = null; });
    try {
      final data = await _service.getTracker(staffId: _staffId, year: year);
      setState(() {
        _data = data;
        _selectedYear = data.year;
      });
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
        title: const Text('Deductions Tracker', style: TextStyle(color: Colors.white)),
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

  // ── Error ──────────────────────────────────────────────────────────────────
  Widget _buildError() => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 12),
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _load, child: const Text('Retry')),
          ]),
        ),
      );

  // ── Main content ───────────────────────────────────────────────────────────
  Widget _buildContent() {
    final d = _data!;
    return RefreshIndicator(
      onRefresh: () => _load(year: _selectedYear),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildYearSelector(d),
          const SizedBox(height: 16),
          _buildSummaryRow(d.summary),
          const SizedBox(height: 16),
          _buildCategoryPills(d),
          const SizedBox(height: 16),
          _buildDeductionsList(d),
        ],
      ),
    );
  }

  // ── Year selector ──────────────────────────────────────────────────────────
  Widget _buildYearSelector(DeductionsTracker d) => Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(children: [
            const Icon(Icons.calendar_today_outlined,
                color: AppTheme.primaryColor, size: 18),
            const SizedBox(width: 10),
            const Text('Year:', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButton<int>(
                value: _selectedYear,
                isExpanded: true,
                underline: const SizedBox.shrink(),
                items: d.availableYears
                    .map((y) => DropdownMenuItem(value: y, child: Text(y.toString())))
                    .toList(),
                onChanged: (y) {
                  if (y != null && y != _selectedYear) _load(year: y);
                },
              ),
            ),
            Text('${d.summary.deductionCount} types',
                style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          ]),
        ),
      );

  // ── Summary row ────────────────────────────────────────────────────────────
  Widget _buildSummaryRow(DeductionSummary s) => Row(children: [
        Expanded(child: _summaryCard(
          'Annual Gross',
          s.annualGross,
          Icons.arrow_upward,
          Colors.blue[700]!,
        )),
        const SizedBox(width: 10),
        Expanded(child: _summaryCard(
          'Total Deducted',
          s.totalDeductions,
          Icons.arrow_downward,
          Colors.red[700]!,
        )),
        const SizedBox(width: 10),
        Expanded(child: _summaryCard(
          'Net Pay',
          s.annualGross - s.totalDeductions,
          Icons.account_balance_wallet_outlined,
          Colors.green[700]!,
        )),
      ]);

  Widget _summaryCard(String label, double amount, IconData icon, Color color) =>
      Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Expanded(
                child: Text(label,
                    style: TextStyle(color: Colors.grey[600], fontSize: 10),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ),
            ]),
            const SizedBox(height: 5),
            Text(NumberFormatter.formatCurrency(amount),
                style: TextStyle(
                    color: color, fontWeight: FontWeight.bold, fontSize: 12),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ]),
        ),
      );

  // ── Category pills ─────────────────────────────────────────────────────────
  Widget _buildCategoryPills(DeductionsTracker d) {
    final s = d.summary;
    final cats = [
      ('statutory', s.categoryTotals.statutory),
      ('loans',     s.categoryTotals.loans),
      ('union',     s.categoryTotals.union),
      ('health',    s.categoryTotals.health),
      ('other',     s.categoryTotals.other),
    ].where((c) => c.$2 > 0).toList();

    if (cats.isEmpty) return const SizedBox.shrink();

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('By Category',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: cats.map((c) {
              final cfg = _catConfig[c.$1]!;
              final pct = s.totalDeductions > 0
                  ? (c.$2 / s.totalDeductions * 100).toStringAsFixed(0)
                  : '0';
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: cfg.color.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: cfg.color.withOpacity(0.3)),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(cfg.icon, size: 14, color: cfg.color),
                  const SizedBox(width: 6),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(cfg.label,
                        style: TextStyle(
                            color: cfg.color,
                            fontWeight: FontWeight.bold,
                            fontSize: 11)),
                    Text(
                      '${NumberFormatter.formatCurrency(c.$2)}  ($pct%)',
                      style: TextStyle(color: cfg.color, fontSize: 10),
                    ),
                  ]),
                ]),
              );
            }).toList(),
          ),
        ]),
      ),
    );
  }

  // ── Deductions list ────────────────────────────────────────────────────────
  Widget _buildDeductionsList(DeductionsTracker d) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('All Deductions',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 10),
          ...d.deductions.asMap().entries.map((entry) =>
              _buildDeductionCard(entry.value, entry.key, d.summary.annualGross)),
        ],
      );

  Widget _buildDeductionCard(DeductionItem ded, int index, double annualGross) {
    final cfg = _catConfig[ded.category] ?? _catConfig['other']!;
    final isExpanded = _expandedIndex == index;
    final nonZeroMonths = ded.monthly.where((m) => m.amount > 0).toList();

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => setState(
          () => _expandedIndex = isExpanded ? null : index,
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Header row
            Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: cfg.color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(cfg.icon, size: 18, color: cfg.color),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(ded.description,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 13)),
                Text(
                  '${cfg.label}  ·  ${ded.monthsActive} month${ded.monthsActive == 1 ? '' : 's'}  ·  avg ${NumberFormatter.formatCurrency(ded.avgMonthly)}/mo',
                  style: TextStyle(color: Colors.grey[600], fontSize: 11),
                ),
              ])),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text(NumberFormatter.formatCurrency(ded.annualTotal),
                    style: TextStyle(
                        color: cfg.color,
                        fontWeight: FontWeight.bold,
                        fontSize: 14)),
                Text('${ded.pctOfGross}% of gross',
                    style: TextStyle(color: Colors.grey[500], fontSize: 10)),
              ]),
              const SizedBox(width: 8),
              Icon(
                isExpanded ? Icons.expand_less : Icons.expand_more,
                color: Colors.grey[400],
              ),
            ]),

            // Progress bar showing pct of total deductions
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: annualGross > 0 ? ded.annualTotal / annualGross : 0,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(cfg.color.withOpacity(0.6)),
                minHeight: 4,
              ),
            ),

            // Expanded: monthly bar chart
            if (isExpanded && nonZeroMonths.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 14),
              Text('Monthly Breakdown — ${_data!.year}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 12)),
              const SizedBox(height: 12),
              SizedBox(
                height: 140,
                child: _buildMiniBarChart(ded, cfg.color),
              ),
              const SizedBox(height: 8),
              // Monthly amounts in a compact grid
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: nonZeroMonths.map((mo) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: cfg.color.withOpacity(0.07),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(_shortMonth(mo.month),
                        style: TextStyle(color: Colors.grey[600], fontSize: 9)),
                    Text(NumberFormatter.formatCurrency(mo.amount),
                        style: TextStyle(
                            color: cfg.color,
                            fontWeight: FontWeight.bold,
                            fontSize: 11)),
                  ]),
                )).toList(),
              ),
            ],
          ]),
        ),
      ),
    );
  }

  Widget _buildMiniBarChart(DeductionItem ded, Color color) {
    final months = ded.monthly;
    if (months.isEmpty) return const SizedBox.shrink();

    final maxVal = months.map((m) => m.amount).reduce((a, b) => a > b ? a : b);
    if (maxVal == 0) return const SizedBox.shrink();

    return BarChart(BarChartData(
      alignment: BarChartAlignment.spaceAround,
      maxY: maxVal * 1.2,
      barGroups: months.asMap().entries.map((entry) {
        final i = entry.key;
        final mo = entry.value;
        return BarChartGroupData(x: i, barRods: [
          BarChartRodData(
            toY: mo.amount,
            color: mo.amount > 0 ? color : Colors.grey[300]!,
            width: months.length > 8 ? 12 : 18,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
          ),
        ]);
      }).toList(),
      titlesData: FlTitlesData(
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (v, _) {
              final idx = v.toInt();
              if (idx >= months.length) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  _shortMonth(months[idx].month),
                  style: const TextStyle(fontSize: 8),
                ),
              );
            },
          ),
        ),
        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      gridData: const FlGridData(show: false),
      borderData: FlBorderData(show: false),
    ));
  }

  String _shortMonth(String label) {
    // "January" → "Jan", "January 2026" → "Jan"
    return label.split(' ').first.substring(0, 3);
  }
}
