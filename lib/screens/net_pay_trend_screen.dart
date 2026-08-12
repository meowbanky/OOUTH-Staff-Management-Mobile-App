import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/net_pay_trend.dart';
import '../providers/auth_provider.dart';
import '../services/net_pay_trend_service.dart';
import '../utils/app_theme.dart';
import '../utils/number_formatter.dart';

class NetPayTrendScreen extends StatefulWidget {
  const NetPayTrendScreen({super.key});

  @override
  State<NetPayTrendScreen> createState() => _NetPayTrendScreenState();
}

class _NetPayTrendScreenState extends State<NetPayTrendScreen>
    with SingleTickerProviderStateMixin {
  late final NetPayTrendService _service;
  NetPayTrend? _data;
  bool _isLoading = true;
  String? _error;
  int? _touchedIndex;
  bool _showGross = true;
  bool _showNet   = true;
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    final auth = context.read<AuthProvider>();
    _service = NetPayTrendService(auth.token ?? '');
    _load(auth.user?.id ?? '');
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load(String staffId) async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final data = await _service.getTrend(staffId);
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
        title: const Text('Net Pay Trend', style: TextStyle(color: Colors.white)),
        backgroundColor: AppTheme.primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(text: 'Chart'),
            Tab(text: 'Month List'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError()
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildChartTab(),
                    _buildListTab(),
                  ],
                ),
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

  // ── Chart tab ──────────────────────────────────────────────────────────────
  Widget _buildChartTab() {
    final d = _data!;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildStatsRow(d.careerStats),
        const SizedBox(height: 16),
        _buildChartCard(d),
        const SizedBox(height: 16),
        _buildSignificantEvents(d),
      ],
    );
  }

  // ── Career stat cards ──────────────────────────────────────────────────────
  Widget _buildStatsRow(TrendCareerStats s) => Column(children: [
        Row(children: [
          Expanded(child: _statCard('Avg Monthly Gross',
              NumberFormatter.formatCurrency(s.avgMonthlyGross),
              Colors.blue[700]!, Icons.trending_up, null)),
          const SizedBox(width: 10),
          Expanded(child: _statCard('Avg Monthly Net',
              NumberFormatter.formatCurrency(s.avgMonthlyNet),
              Colors.green[700]!, Icons.account_balance_wallet_outlined, null)),
          const SizedBox(width: 10),
          Expanded(child: _statCard('Months on Record',
              '${s.totalMonths}',
              Colors.purple[700]!, Icons.calendar_today_outlined,
              '${s.firstMonth} – ${s.latestMonth}')),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: _statCard('Best Gross Month',
              s.maxGrossMonth,
              Colors.blue[800]!, Icons.emoji_events_outlined,
              NumberFormatter.formatCurrency(s.maxGross))),
          const SizedBox(width: 10),
          Expanded(child: _statCard('Best Net Month',
              s.maxNetMonth,
              Colors.green[800]!, Icons.star_outline,
              NumberFormatter.formatCurrency(s.maxNet))),
          const SizedBox(width: 10),
          Expanded(child: _statCard('Lowest Net Month',
              s.minNetMonth,
              Colors.red[600]!, Icons.arrow_downward,
              NumberFormatter.formatCurrency(s.minNet))),
        ]),
      ]);

  Widget _statCard(String label, String value, Color color, IconData icon,
      String? sub) =>
      Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(icon, size: 13, color: color),
              const SizedBox(width: 4),
              Expanded(child: Text(label,
                  style: TextStyle(color: Colors.grey[600], fontSize: 9),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis)),
            ]),
            const SizedBox(height: 4),
            Text(value,
                style: TextStyle(
                    color: color, fontWeight: FontWeight.bold, fontSize: 12),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
            if (sub != null)
              Text(sub,
                  style: TextStyle(color: Colors.grey[500], fontSize: 9),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
          ]),
        ),
      );

  // ── Chart card ─────────────────────────────────────────────────────────────
  Widget _buildChartCard(NetPayTrend d) {
    final months = d.months;
    if (months.isEmpty) return const SizedBox.shrink();

    final maxY = months.map((m) => m.gross).reduce((a, b) => a > b ? a : b) * 1.12;

    // Touched month detail
    TrendMonth? touched;
    if (_touchedIndex != null && _touchedIndex! < months.length) {
      touched = months[_touchedIndex!];
    }

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Title + toggles
          Row(children: [
            const Icon(Icons.show_chart, color: AppTheme.primaryColor, size: 18),
            const SizedBox(width: 8),
            const Expanded(
              child: Text('All-Time Pay Trend',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            ),
          ]),
          const SizedBox(height: 4),
          Text('${months.length} months  ·  ${d.careerStats.firstMonth} to ${d.careerStats.latestMonth}',
              style: TextStyle(color: Colors.grey[500], fontSize: 11)),
          const SizedBox(height: 10),
          // Toggle buttons
          Row(children: [
            _toggleChip('Gross', Colors.blue[700]!, _showGross,
                () => setState(() => _showGross = !_showGross)),
            const SizedBox(width: 8),
            _toggleChip('Net', Colors.green[700]!, _showNet,
                () => setState(() => _showNet = !_showNet)),
            const Spacer(),
            Text('Tap a point for detail',
                style: TextStyle(color: Colors.grey[400], fontSize: 10)),
          ]),
          const SizedBox(height: 16),

          // Scrollable chart
          SizedBox(
            height: 220,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                // ~28px per data point, min 300
                width: (months.length * 28.0).clamp(300.0, double.infinity),
                child: LineChart(LineChartData(
                  minY: 0,
                  maxY: maxY,
                  clipData: const FlClipData.all(),
                  lineTouchData: LineTouchData(
                    touchCallback: (event, response) {
                      setState(() {
                        if (response?.lineBarSpots?.isNotEmpty == true) {
                          _touchedIndex =
                              response!.lineBarSpots!.first.spotIndex;
                        } else if (event is FlTapUpEvent) {
                          _touchedIndex = null;
                        }
                      });
                    },
                    getTouchedSpotIndicator: (barData, spotIndexes) =>
                        spotIndexes.map((i) => TouchedSpotIndicatorData(
                              FlLine(
                                  color: Colors.grey.withOpacity(0.4),
                                  strokeWidth: 1,
                                  dashArray: [4, 4]),
                              FlDotData(
                                getDotPainter: (spot, pct, bar, idx) =>
                                    FlDotCirclePainter(
                                  radius: 5,
                                  color: bar.color ?? Colors.blue,
                                  strokeWidth: 2,
                                  strokeColor: Colors.white,
                                ),
                              ),
                            )).toList(),
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (spots) => spots.map((s) {
                        final mo = months[s.spotIndex];
                        final isGross = s.barIndex == 0;
                        return LineTooltipItem(
                          '${mo.label}\n${isGross ? 'Gross' : 'Net'}: ${NumberFormatter.formatCurrency(s.y)}',
                          TextStyle(
                              color: isGross ? Colors.blue[200] : Colors.green[200],
                              fontSize: 10,
                              fontWeight: FontWeight.bold),
                        );
                      }).toList(),
                    ),
                  ),
                  lineBarsData: [
                    if (_showGross)
                      LineChartBarData(
                        spots: months.asMap().entries
                            .map((e) => FlSpot(e.key.toDouble(), e.value.gross))
                            .toList(),
                        isCurved: true,
                        curveSmoothness: 0.25,
                        color: Colors.blue[700],
                        barWidth: 2,
                        dotData: FlDotData(
                          getDotPainter: (spot, pct, bar, idx) {
                            final sig = months[idx].isSignificant;
                            return FlDotCirclePainter(
                              radius: sig ? 4 : 2,
                              color: sig ? Colors.amber : Colors.blue[700]!,
                              strokeWidth: sig ? 1.5 : 0,
                              strokeColor: Colors.white,
                            );
                          },
                        ),
                        belowBarData: BarAreaData(
                          show: true,
                          color: Colors.blue[700]!.withOpacity(0.06),
                        ),
                      ),
                    if (_showNet)
                      LineChartBarData(
                        spots: months.asMap().entries
                            .map((e) => FlSpot(e.key.toDouble(), e.value.net))
                            .toList(),
                        isCurved: true,
                        curveSmoothness: 0.25,
                        color: Colors.green[700],
                        barWidth: 2.5,
                        dotData: FlDotData(
                          getDotPainter: (spot, pct, bar, idx) {
                            final sig = months[idx].isSignificant;
                            return FlDotCirclePainter(
                              radius: sig ? 4 : 2,
                              color: sig ? Colors.amber : Colors.green[700]!,
                              strokeWidth: sig ? 1.5 : 0,
                              strokeColor: Colors.white,
                            );
                          },
                        ),
                        belowBarData: BarAreaData(
                          show: true,
                          color: Colors.green[700]!.withOpacity(0.08),
                        ),
                      ),
                  ],
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: (months.length / 8).ceilToDouble(),
                        getTitlesWidget: (v, _) {
                          final idx = v.toInt();
                          if (idx < 0 || idx >= months.length) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(months[idx].label,
                                style: const TextStyle(fontSize: 8)),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 50,
                        getTitlesWidget: (v, _) => Text(_shortAmt(v),
                            style: const TextStyle(fontSize: 8)),
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
                    getDrawingHorizontalLine: (_) => const FlLine(
                        color: Color(0xFFEEEEEE), strokeWidth: 1),
                  ),
                  borderData: FlBorderData(show: false),
                )),
              ),
            ),
          ),

          // Touched month detail
          if (touched != null) ...[
            const SizedBox(height: 14),
            _buildTouchedDetail(touched),
          ],
        ]),
      ),
    );
  }

  Widget _toggleChip(String label, Color color, bool active, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: active ? color.withOpacity(0.12) : Colors.grey[100],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: active ? color : Colors.grey[300]!, width: 1.5),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                    color: active ? color : Colors.grey[400],
                    shape: BoxShape.circle)),
            const SizedBox(width: 5),
            Text(label,
                style: TextStyle(
                    color: active ? color : Colors.grey[500],
                    fontWeight: FontWeight.bold,
                    fontSize: 11)),
          ]),
        ),
      );

  Widget _buildTouchedDetail(TrendMonth m) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withOpacity(0.06),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.primaryColor.withOpacity(0.2)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text('${m.monthName} ${m.year}',
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor)),
            const Spacer(),
            if (m.isSignificant)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                    color: Colors.amber[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber.shade300)),
                child: Text('Significant change',
                    style: TextStyle(
                        color: Colors.amber[800],
                        fontSize: 9,
                        fontWeight: FontWeight.bold)),
              ),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            _miniStat('Gross', NumberFormatter.formatCurrency(m.gross),
                Colors.blue[700]!),
            _miniStat('Deductions',
                NumberFormatter.formatCurrency(m.deductions), Colors.red[600]!),
            _miniStat('Net', NumberFormatter.formatCurrency(m.net),
                Colors.green[700]!),
            _miniStat('Net %', '${m.pctNetOfGross}%', Colors.purple[700]!),
          ]),
          if (m.netChangePct != null) ...[
            const SizedBox(height: 6),
            Row(children: [
              Icon(
                m.netChangePct! >= 0
                    ? Icons.trending_up
                    : Icons.trending_down,
                size: 14,
                color: m.netChangePct! >= 0
                    ? Colors.green[700]
                    : Colors.red[600],
              ),
              const SizedBox(width: 4),
              Text(
                'Net ${m.netChangePct! >= 0 ? '+' : ''}${m.netChangePct!.toStringAsFixed(1)}% vs previous month',
                style: TextStyle(
                    fontSize: 11,
                    color: m.netChangePct! >= 0
                        ? Colors.green[700]
                        : Colors.red[600]),
              ),
            ]),
          ],
        ]),
      );

  Widget _miniStat(String label, String value, Color color) => Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 9)),
          Text(value,
              style: TextStyle(
                  color: color, fontWeight: FontWeight.bold, fontSize: 11),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ]),
      );

  // ── Significant events ─────────────────────────────────────────────────────
  Widget _buildSignificantEvents(NetPayTrend d) {
    final events = d.months.where((m) => m.isSignificant).toList();
    if (events.isEmpty) return const SizedBox.shrink();

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(Icons.bolt, color: Colors.amber[700], size: 18),
            const SizedBox(width: 6),
            Text('Significant Changes (${events.length})',
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          ]),
          const SizedBox(height: 10),
          ...events.map((m) {
            final pct = m.grossChangePct ?? m.netChangePct ?? 0;
            final up  = pct >= 0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: (up ? Colors.green : Colors.red).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    up ? Icons.trending_up : Icons.trending_down,
                    size: 14,
                    color: up ? Colors.green[700] : Colors.red[600],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text('${m.monthName} ${m.year}',
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 12)),
                    Text(
                      'Gross: ${NumberFormatter.formatCurrency(m.gross)}  ·  '
                      'Net: ${NumberFormatter.formatCurrency(m.net)}',
                      style:
                          TextStyle(color: Colors.grey[600], fontSize: 11),
                    ),
                  ]),
                ),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  if (m.grossChangePct != null)
                    Text(
                      'Gross ${m.grossChangePct! >= 0 ? '+' : ''}${m.grossChangePct!.toStringAsFixed(1)}%',
                      style: TextStyle(
                          fontSize: 10,
                          color:
                              m.grossChangePct! >= 0 ? Colors.blue[700] : Colors.red[600],
                          fontWeight: FontWeight.bold),
                    ),
                  if (m.netChangePct != null)
                    Text(
                      'Net ${m.netChangePct! >= 0 ? '+' : ''}${m.netChangePct!.toStringAsFixed(1)}%',
                      style: TextStyle(
                          fontSize: 10,
                          color: m.netChangePct! >= 0
                              ? Colors.green[700]
                              : Colors.red[600],
                          fontWeight: FontWeight.bold),
                    ),
                ]),
              ]),
            );
          }),
        ]),
      ),
    );
  }

  // ── Month list tab ─────────────────────────────────────────────────────────
  Widget _buildListTab() {
    final months = _data!.months.reversed.toList(); // newest first
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: months.length,
      separatorBuilder: (_, __) => const SizedBox(height: 6),
      itemBuilder: (_, i) => _buildMonthRow(months[i]),
    );
  }

  Widget _buildMonthRow(TrendMonth m) {
    final netPct = m.netChangePct;
    final isUp   = netPct != null && netPct >= 0;

    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(children: [
          // Month label
          SizedBox(
            width: 56,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(m.label,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 12)),
              if (m.isSignificant)
                Icon(Icons.bolt, size: 12, color: Colors.amber[700]),
            ]),
          ),
          const SizedBox(width: 10),
          // Gross
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Gross', style: TextStyle(color: Colors.grey[500], fontSize: 9)),
              Text(NumberFormatter.formatCurrency(m.gross),
                  style: TextStyle(
                      color: Colors.blue[700],
                      fontWeight: FontWeight.w600,
                      fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ]),
          ),
          // Net
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Net', style: TextStyle(color: Colors.grey[500], fontSize: 9)),
              Text(NumberFormatter.formatCurrency(m.net),
                  style: TextStyle(
                      color: Colors.green[700],
                      fontWeight: FontWeight.bold,
                      fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ]),
          ),
          // Net %
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('${m.pctNetOfGross}% net',
                style: TextStyle(color: Colors.grey[500], fontSize: 9)),
            if (netPct != null)
              Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(
                  isUp ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                  size: 14,
                  color: isUp ? Colors.green[700] : Colors.red[600],
                ),
                Text(
                  '${netPct.toStringAsFixed(1)}%',
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isUp ? Colors.green[700] : Colors.red[600]),
                ),
              ])
            else
              Text('—', style: TextStyle(color: Colors.grey[400], fontSize: 10)),
          ]),
        ]),
      ),
    );
  }

  String _shortAmt(double v) {
    if (v >= 1000000) return '₦${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000)    return '₦${(v / 1000).toStringAsFixed(0)}K';
    return '₦${v.toStringAsFixed(0)}';
  }
}
