import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/pay_calendar.dart';
import '../providers/auth_provider.dart';
import '../services/pay_calendar_service.dart';
import '../utils/app_theme.dart';
import '../utils/number_formatter.dart';

class PayCalendarScreen extends StatefulWidget {
  const PayCalendarScreen({super.key});

  @override
  State<PayCalendarScreen> createState() => _PayCalendarScreenState();
}

class _PayCalendarScreenState extends State<PayCalendarScreen> {
  late final PayCalendarService _service;
  late final String _staffId;

  PayCalendar? _data;
  bool _isLoading = true;
  String? _error;
  int? _selectedYear;
  int? _expandedMonth; // month_num of the tapped card

  static const _shortMonths = [
    '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    _staffId = auth.user?.id ?? '';
    _service = PayCalendarService(auth.token ?? '');
    _load();
  }

  Future<void> _load({int? year}) async {
    setState(() { _isLoading = true; _error = null; _expandedMonth = null; });
    try {
      final data = await _service.getCalendar(staffId: _staffId, year: year);
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
        title: const Text('Pay Calendar', style: TextStyle(color: Colors.white)),
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
            ElevatedButton(onPressed: _load, child: const Text('Retry')),
          ]),
        ),
      );

  Widget _buildContent() {
    final d = _data!;
    return RefreshIndicator(
      onRefresh: () => _load(year: _selectedYear),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildYearSelector(d),
          const SizedBox(height: 16),
          _buildYearStats(d.yearSummary),
          const SizedBox(height: 16),
          _buildLegend(),
          const SizedBox(height: 12),
          _buildCalendarGrid(d),
          if (_expandedMonth != null) ...[
            const SizedBox(height: 12),
            _buildExpandedDetail(d),
          ],
        ],
      ),
    );
  }

  // ── Year selector ──────────────────────────────────────────────────────────
  Widget _buildYearSelector(PayCalendar d) => Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(children: [
            const Icon(Icons.calendar_month_outlined,
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
                    .map((y) => DropdownMenuItem(
                        value: y, child: Text(y.toString())))
                    .toList(),
                onChanged: (y) {
                  if (y != null && y != _selectedYear) _load(year: y);
                },
              ),
            ),
            Text('${d.yearSummary.monthsPaid}/12 paid',
                style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          ]),
        ),
      );

  // ── Year stats ─────────────────────────────────────────────────────────────
  Widget _buildYearStats(YearSummary s) {
    return Column(children: [
      Row(children: [
        Expanded(child: _statCard('YTD Gross', s.ytdGross, Colors.blue[700]!,
            Icons.trending_up)),
        const SizedBox(width: 10),
        Expanded(child: _statCard('YTD Net', s.ytdNet, Colors.green[700]!,
            Icons.account_balance_wallet_outlined)),
        const SizedBox(width: 10),
        Expanded(child: _statCard('YTD Deducted', s.ytdDeductions,
            Colors.red[700]!, Icons.remove_circle_outline)),
      ]),
      const SizedBox(height: 10),
      Row(children: [
        Expanded(child: _statCard('Avg Monthly Net', s.avgMonthlyNet,
            Colors.purple[700]!, Icons.calculate_outlined)),
        const SizedBox(width: 10),
        Expanded(
          child: Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Icon(Icons.emoji_events_outlined,
                      size: 14, color: Colors.amber[700]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text('Best Month',
                        style: TextStyle(color: Colors.grey[600], fontSize: 10),
                        maxLines: 1),
                  ),
                ]),
                const SizedBox(height: 5),
                Text(s.bestNetMonth ?? '—',
                    style: TextStyle(
                        color: Colors.amber[700],
                        fontWeight: FontWeight.bold,
                        fontSize: 13)),
                if (s.bestNet > 0)
                  Text(NumberFormatter.formatCurrency(s.bestNet),
                      style: TextStyle(color: Colors.grey[600], fontSize: 10)),
              ]),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Icon(Icons.calendar_today_outlined,
                      size: 14, color: Colors.teal[700]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text('Months Paid',
                        style: TextStyle(color: Colors.grey[600], fontSize: 10),
                        maxLines: 1),
                  ),
                ]),
                const SizedBox(height: 5),
                Text('${s.monthsPaid} of 12',
                    style: TextStyle(
                        color: Colors.teal[700],
                        fontWeight: FontWeight.bold,
                        fontSize: 13)),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: s.monthsPaid / 12,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.teal[700]!),
                    minHeight: 4,
                  ),
                ),
              ]),
            ),
          ),
        ),
      ]),
    ]);
  }

  Widget _statCard(String label, double amount, Color color, IconData icon) =>
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

  // ── Legend ─────────────────────────────────────────────────────────────────
  Widget _buildLegend() => Row(
        children: [
          _legendItem(AppTheme.primaryColor, 'Paid'),
          const SizedBox(width: 16),
          _legendItem(Colors.grey[300]!, 'Not paid'),
          const SizedBox(width: 16),
          _legendItem(Colors.amber[400]!, 'Best net pay'),
          const Spacer(),
          Text('Tap a month for detail',
              style: TextStyle(color: Colors.grey[500], fontSize: 11)),
        ],
      );

  Widget _legendItem(Color color, String label) => Row(children: [
        Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
                color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11)),
      ]);

  // ── Calendar grid ──────────────────────────────────────────────────────────
  Widget _buildCalendarGrid(PayCalendar d) {
    final bestMonth = d.yearSummary.bestNetMonth;

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.0,
      children: d.calendar.map((month) {
        final isBest    = month.paid && month.monthName == bestMonth;
        final isExpanded= _expandedMonth == month.monthNum;

        Color bgColor;
        Color textColor;
        Color? borderColor;

        if (!month.paid) {
          bgColor   = Colors.grey[100]!;
          textColor = Colors.grey[400]!;
        } else if (isBest) {
          bgColor     = Colors.amber[50]!;
          textColor   = Colors.amber[800]!;
          borderColor = Colors.amber[400];
        } else if (isExpanded) {
          bgColor     = AppTheme.primaryColor;
          textColor   = Colors.white;
          borderColor = AppTheme.primaryColor;
        } else {
          bgColor   = Colors.white;
          textColor = AppTheme.primaryColor;
        }

        return GestureDetector(
          onTap: month.paid
              ? () => setState(() {
                    _expandedMonth =
                        _expandedMonth == month.monthNum ? null : month.monthNum;
                  })
              : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
              border: borderColor != null
                  ? Border.all(color: borderColor, width: 2)
                  : Border.all(color: Colors.grey[200]!, width: 1),
              boxShadow: month.paid
                  ? [
                      BoxShadow(
                          color: (isBest ? Colors.amber : AppTheme.primaryColor)
                              .withOpacity(0.12),
                          blurRadius: 6,
                          offset: const Offset(0, 2))
                    ]
                  : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isBest)
                  Icon(Icons.star, size: 12, color: Colors.amber[600]),
                Text(
                  _shortMonths[month.monthNum],
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: textColor),
                ),
                if (month.paid) ...[
                  const SizedBox(height: 4),
                  Text(
                    _shortAmount(month.net),
                    style: TextStyle(
                        fontSize: 11,
                        color: isExpanded ? Colors.white70 : Colors.green[700],
                        fontWeight: FontWeight.w600),
                  ),
                  Text(
                    'net',
                    style: TextStyle(
                        fontSize: 9,
                        color: isExpanded ? Colors.white60 : Colors.grey[500]),
                  ),
                ] else
                  Text('—',
                      style: TextStyle(color: Colors.grey[400], fontSize: 11)),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── Expanded month detail ──────────────────────────────────────────────────
  Widget _buildExpandedDetail(PayCalendar d) {
    final month = d.calendar.firstWhere((m) => m.monthNum == _expandedMonth);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Header
          Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.receipt_long_outlined,
                  color: AppTheme.primaryColor, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('${month.monthName} ${d.year}',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15)),
                Text('Period ID: ${month.periodId}',
                    style: TextStyle(color: Colors.grey[500], fontSize: 11)),
              ]),
            ),
            IconButton(
              icon: const Icon(Icons.close, size: 18),
              onPressed: () => setState(() => _expandedMonth = null),
              color: Colors.grey[500],
            ),
          ]),
          const SizedBox(height: 12),

          // Summary row
          Row(children: [
            _detailChip('Gross', month.gross, Colors.blue[700]!),
            const SizedBox(width: 6),
            _detailChip('Deductions', month.deductions, Colors.red[700]!),
            const SizedBox(width: 6),
            _detailChip('Net', month.net, Colors.green[700]!),
          ]),
          const SizedBox(height: 14),

          // Earnings
          if (month.earnings.isNotEmpty) ...[
            _sectionHeader('Earnings', Colors.blue[700]!),
            const SizedBox(height: 6),
            ...month.earnings.map((e) => _lineRow(e.description, e.amount,
                Colors.blue[700]!)),
            _totalRow('Total Earnings', month.gross, Colors.blue[700]!),
            const SizedBox(height: 12),
          ],

          // Deductions
          if (month.deductionsList.isNotEmpty) ...[
            _sectionHeader('Deductions', Colors.red[700]!),
            const SizedBox(height: 6),
            ...month.deductionsList.map((d) => _lineRow(d.description, d.amount,
                Colors.red[700]!)),
            _totalRow('Total Deductions', month.deductions, Colors.red[700]!),
            const Divider(height: 16),
            Row(children: [
              const Expanded(
                child: Text('NET PAY',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 13)),
              ),
              Text(NumberFormatter.formatCurrency(month.net),
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Colors.green)),
            ]),
          ],
        ]),
      ),
    );
  }

  Widget _detailChip(String label, double amount, Color color) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Column(children: [
            Text(label,
                style: TextStyle(color: color, fontSize: 10),
                maxLines: 1),
            const SizedBox(height: 2),
            Text(NumberFormatter.formatCurrency(amount),
                style: TextStyle(
                    color: color, fontWeight: FontWeight.bold, fontSize: 11),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ]),
        ),
      );

  Widget _sectionHeader(String title, Color color) => Row(children: [
        Container(width: 3, height: 14, color: color,
            margin: const EdgeInsets.only(right: 6)),
        Text(title,
            style: TextStyle(
                fontWeight: FontWeight.bold, color: color, fontSize: 12)),
      ]);

  Widget _lineRow(String description, double amount, Color color) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(children: [
          const SizedBox(width: 9),
          Expanded(
            child: Text(description,
                style: const TextStyle(fontSize: 12),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ),
          Text(NumberFormatter.formatCurrency(amount),
              style: TextStyle(fontSize: 12, color: color)),
        ]),
      );

  Widget _totalRow(String label, double amount, Color color) => Padding(
        padding: const EdgeInsets.only(top: 6, bottom: 2),
        child: Row(children: [
          Expanded(
            child: Text(label,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 12)),
          ),
          Text(NumberFormatter.formatCurrency(amount),
              style: TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 12, color: color)),
        ]),
      );

  String _shortAmount(double v) {
    if (v >= 1000000) return '₦${(v / 1000000).toStringAsFixed(2)}M';
    if (v >= 1000)    return '₦${(v / 1000).toStringAsFixed(1)}K';
    return '₦${v.toStringAsFixed(0)}';
  }
}
