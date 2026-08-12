import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/payslip_comparison.dart';
import '../providers/auth_provider.dart';
import '../services/payslip_comparison_service.dart';
import '../utils/app_theme.dart';
import '../utils/number_formatter.dart';

class PayslipComparisonScreen extends StatefulWidget {
  const PayslipComparisonScreen({super.key});

  @override
  State<PayslipComparisonScreen> createState() =>
      _PayslipComparisonScreenState();
}

class _PayslipComparisonScreenState extends State<PayslipComparisonScreen> {
  late final PayslipComparisonService _service;
  late final String _staffId;

  List<AvailablePeriod> _periods = [];
  AvailablePeriod? _selected1;
  AvailablePeriod? _selected2;

  PayslipComparison? _result;
  bool _loadingPeriods = true;
  bool _comparing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    _staffId = auth.user?.id ?? '';
    _service = PayslipComparisonService(auth.token ?? '');
    _loadPeriods();
  }

  Future<void> _loadPeriods() async {
    setState(() { _loadingPeriods = true; _error = null; });
    try {
      final periods = await _service.getPeriods(_staffId);
      setState(() {
        _periods = periods;
        // Default: compare two most recent months
        if (periods.length >= 2) {
          _selected1 = periods[1]; // second most recent = "from"
          _selected2 = periods[0]; // most recent = "to"
        }
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loadingPeriods = false);
    }
  }

  Future<void> _compare() async {
    if (_selected1 == null || _selected2 == null) return;
    setState(() { _comparing = true; _error = null; _result = null; });
    try {
      final result = await _service.compare(
        staffId: _staffId,
        periodId1: _selected1!.periodId,
        periodId2: _selected2!.periodId,
      );
      setState(() => _result = result);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _comparing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Payslip Comparison',
            style: TextStyle(color: Colors.white)),
        backgroundColor: AppTheme.primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _loadingPeriods
          ? const Center(child: CircularProgressIndicator())
          : _error != null && _periods.isEmpty
              ? _buildError()
              : _buildBody(),
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
            ElevatedButton(onPressed: _loadPeriods, child: const Text('Retry')),
          ]),
        ),
      );

  // ── Body ───────────────────────────────────────────────────────────────────
  Widget _buildBody() => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildPeriodSelector(),
          if (_comparing) ...[
            const SizedBox(height: 24),
            const Center(child: CircularProgressIndicator()),
            const SizedBox(height: 12),
            const Center(child: Text('Comparing payslips...')),
          ],
          if (_error != null && _result == null) ...[
            const SizedBox(height: 16),
            _buildInlineError(),
          ],
          if (_result != null) ...[
            const SizedBox(height: 20),
            _buildSummaryCards(_result!),
            const SizedBox(height: 16),
            _buildDiffSection(
              'Earnings',
              Icons.arrow_upward,
              Colors.blue[700]!,
              _result!.earningsDiff,
              _result!.period1.label,
              _result!.period2.label,
              isEarning: true,
            ),
            const SizedBox(height: 12),
            _buildDiffSection(
              'Deductions',
              Icons.arrow_downward,
              Colors.red[700]!,
              _result!.deductionsDiff,
              _result!.period1.label,
              _result!.period2.label,
              isEarning: false,
            ),
          ],
        ],
      );

  // ── Period selector ────────────────────────────────────────────────────────
  Widget _buildPeriodSelector() => Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Row(children: [
              Icon(Icons.compare_arrows, color: AppTheme.primaryColor, size: 20),
              SizedBox(width: 8),
              Text('Select Two Months to Compare',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            ]),
            const SizedBox(height: 4),
            Text('Pick a "From" month and a "To" month',
                style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: _periodDropdown(
                label: 'From',
                color: Colors.blue[700]!,
                value: _selected1,
                onChanged: (p) => setState(() { _selected1 = p; _result = null; }),
                exclude: _selected2,
              )),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Icon(Icons.arrow_forward,
                    color: AppTheme.primaryColor, size: 20),
              ),
              Expanded(child: _periodDropdown(
                label: 'To',
                color: Colors.green[700]!,
                value: _selected2,
                onChanged: (p) => setState(() { _selected2 = p; _result = null; }),
                exclude: _selected1,
              )),
            ]),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: (_selected1 != null && _selected2 != null && !_comparing)
                    ? _compare
                    : null,
                icon: const Icon(Icons.compare, size: 18),
                label: const Text('Compare'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ]),
        ),
      );

  Widget _periodDropdown({
    required String label,
    required Color color,
    required AvailablePeriod? value,
    required ValueChanged<AvailablePeriod?> onChanged,
    AvailablePeriod? exclude,
  }) {
    final items = _periods
        .where((p) => p.periodId != exclude?.periodId)
        .map((p) => DropdownMenuItem(value: p, child: Text(p.label, style: const TextStyle(fontSize: 12))))
        .toList();

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label,
          style: TextStyle(
              color: color, fontWeight: FontWeight.bold, fontSize: 12)),
      const SizedBox(height: 4),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          border: Border.all(color: color.withOpacity(0.4)),
          borderRadius: BorderRadius.circular(8),
          color: color.withOpacity(0.05),
        ),
        child: DropdownButton<AvailablePeriod>(
          value: value != null && _periods.any((p) => p.periodId == value.periodId) ? value : null,
          isExpanded: true,
          underline: const SizedBox.shrink(),
          items: items,
          onChanged: onChanged,
          hint: const Text('Select', style: TextStyle(fontSize: 12)),
        ),
      ),
    ]);
  }

  Widget _buildInlineError() => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red[50],
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Row(children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 18),
          const SizedBox(width: 8),
          Expanded(
              child: Text(_error!,
                  style: const TextStyle(color: Colors.red, fontSize: 13))),
        ]),
      );

  // ── Summary cards ──────────────────────────────────────────────────────────
  Widget _buildSummaryCards(PayslipComparison r) {
    final d = r.summaryDiff;
    return Column(children: [
      // Period labels header
      _buildPeriodLabelsHeader(r.period1.label, r.period2.label),
      const SizedBox(height: 12),
      // Three summary cards
      Row(children: [
        Expanded(child: _summaryDiffCard(
          'Gross',
          r.period1.gross,
          r.period2.gross,
          d.grossDiff,
          d.grossPct,
          isPositiveGood: true,
        )),
        const SizedBox(width: 8),
        Expanded(child: _summaryDiffCard(
          'Deductions',
          r.period1.deductions,
          r.period2.deductions,
          d.deductionsDiff,
          null,
          isPositiveGood: false,
        )),
        const SizedBox(width: 8),
        Expanded(child: _summaryDiffCard(
          'Net Pay',
          r.period1.net,
          r.period2.net,
          d.netDiff,
          d.netPct,
          isPositiveGood: true,
        )),
      ]),
    ]);
  }

  Widget _buildPeriodLabelsHeader(String label1, String label2) => Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
              decoration: BoxDecoration(
                color: Colors.blue[700],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(label1,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Icon(Icons.arrow_forward, size: 16, color: Colors.grey[600]),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
              decoration: BoxDecoration(
                color: Colors.green[700],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(label2,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12)),
            ),
          ),
        ],
      );

  Widget _summaryDiffCard(
    String label,
    double val1,
    double val2,
    double diff,
    double? pct, {
    required bool isPositiveGood,
  }) {
    final changed = diff != 0;
    final isGood  = isPositiveGood ? diff > 0 : diff < 0;
    final color   = !changed ? Colors.grey[600]! : (isGood ? Colors.green[700]! : Colors.red[700]!);
    final arrow   = diff > 0 ? '▲' : (diff < 0 ? '▼' : '→');

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              style: TextStyle(color: Colors.grey[600], fontSize: 10),
              maxLines: 1),
          const SizedBox(height: 4),
          Text(NumberFormatter.formatCurrency(val2),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 3),
          Row(children: [
            Text(arrow, style: TextStyle(color: color, fontSize: 11)),
            const SizedBox(width: 2),
            Expanded(
              child: Text(
                NumberFormatter.formatCurrency(diff.abs()) +
                    (pct != null ? ' (${pct.abs()}%)' : ''),
                style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w600,
                    fontSize: 10),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ]),
        ]),
      ),
    );
  }

  // ── Diff section ───────────────────────────────────────────────────────────
  Widget _buildDiffSection(
    String title,
    IconData icon,
    Color color,
    List<DiffLine> lines,
    String label1,
    String label2, {
    required bool isEarning,
  }) {
    if (lines.isEmpty) return const SizedBox.shrink();

    // Count changes
    final changes = lines.where((l) => l.status != 'same').length;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Text(title,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 15)),
            const Spacer(),
            if (changes > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('$changes change${changes == 1 ? '' : 's'}',
                    style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: 11)),
              ),
          ]),
          const SizedBox(height: 12),
          // Column headers
          Row(children: [
            const Expanded(
                flex: 3,
                child: Text('Item',
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                        color: Colors.grey))),
            Expanded(
                flex: 2,
                child: Text(label1,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 10,
                        color: Colors.blue[700]))),
            Expanded(
                flex: 2,
                child: Text(label2,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 10,
                        color: Colors.green[700]))),
            Expanded(
                flex: 2,
                child: Text('Change',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 10,
                        color: Colors.grey[600]))),
          ]),
          const Divider(height: 12),
          ...lines.map((l) => _buildDiffRow(l, isEarning)),
        ]),
      ),
    );
  }

  Widget _buildDiffRow(DiffLine l, bool isEarning) {
    Color diffColor;
    String badge = '';

    switch (l.status) {
      case 'new':
        diffColor = Colors.green[700]!;
        badge = 'NEW';
        break;
      case 'removed':
        diffColor = Colors.red[700]!;
        badge = 'GONE';
        break;
      case 'increased':
        diffColor = isEarning ? Colors.green[700]! : Colors.red[700]!;
        break;
      case 'decreased':
        diffColor = isEarning ? Colors.red[700]! : Colors.green[700]!;
        break;
      default:
        diffColor = Colors.grey[500]!;
    }

    final isSame    = l.status == 'same';
    final isNew     = l.status == 'new';
    final isRemoved = l.status == 'removed';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(children: [
        // Description
        Expanded(
          flex: 3,
          child: Row(children: [
            if (badge.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: diffColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(badge,
                    style: TextStyle(
                        color: diffColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 8)),
              ),
              const SizedBox(width: 4),
            ],
            Expanded(
              child: Text(
                l.description,
                style: TextStyle(
                    fontSize: 11,
                    color: isSame ? Colors.grey[600] : Colors.black87,
                    fontStyle:
                        isRemoved ? FontStyle.italic : FontStyle.normal),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ]),
        ),
        // Amount 1
        Expanded(
          flex: 2,
          child: Text(
            isNew ? '—' : NumberFormatter.formatCurrency(l.amount1),
            textAlign: TextAlign.right,
            style: TextStyle(
                fontSize: 11,
                color: isNew ? Colors.grey[400] : Colors.grey[700]),
          ),
        ),
        // Amount 2
        Expanded(
          flex: 2,
          child: Text(
            isRemoved ? '—' : NumberFormatter.formatCurrency(l.amount2),
            textAlign: TextAlign.right,
            style: TextStyle(
                fontSize: 11,
                color: isRemoved ? Colors.grey[400] : Colors.black87,
                fontWeight: isRemoved ? FontWeight.normal : FontWeight.w600),
          ),
        ),
        // Diff
        Expanded(
          flex: 2,
          child: Text(
            isSame
                ? '—'
                : (l.diff > 0 ? '+' : '') + NumberFormatter.formatCurrency(l.diff),
            textAlign: TextAlign.right,
            style: TextStyle(
                fontSize: 11,
                color: diffColor,
                fontWeight: isSame ? FontWeight.normal : FontWeight.bold),
          ),
        ),
      ]),
    );
  }
}
