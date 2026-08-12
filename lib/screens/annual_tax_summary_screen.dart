import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/annual_tax_summary.dart';
import '../utils/salary_scheme.dart';
import '../providers/auth_provider.dart';
import '../services/annual_tax_service.dart';
import '../utils/app_theme.dart';
import '../utils/number_formatter.dart';

class AnnualTaxSummaryScreen extends StatefulWidget {
  const AnnualTaxSummaryScreen({super.key});

  @override
  State<AnnualTaxSummaryScreen> createState() => _AnnualTaxSummaryScreenState();
}

class _AnnualTaxSummaryScreenState extends State<AnnualTaxSummaryScreen> {
  late final AnnualTaxService _service;
  late final String _staffId;
  AnnualTaxSummary? _data;
  int? _selectedYear;
  bool _isLoading = true;
  bool _isExporting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    _staffId = auth.user?.id ?? '';
    _service = AnnualTaxService(auth.token ?? '');
    _load();
  }

  Future<void> _load({int? year}) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final data = await _service.getSummary(staffId: _staffId, year: year);
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

  // ── PDF export ─────────────────────────────────────────────────────────────
  Future<void> _exportPdf() async {
    if (_data == null) return;
    setState(() => _isExporting = true);
    try {
      final logoL = await _loadAsset('assets/images/ogun_logo.png');
      final logoR = await _loadAsset('assets/images/oouth_logo.png');
      final wm = await _loadAsset('assets/images/oouth_logo_watermark.png');

      final d = _data!;
      final pdf = pw.Document();

      pdf.addPage(pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        build: (ctx) => [
          // Header
          pw.Stack(children: [
            pw.Positioned.fill(
              child: pw.Opacity(
                opacity: 0.07,
                child: pw.Center(child: pw.Image(pw.MemoryImage(wm))),
              ),
            ),
            pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                children: [
                  pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Image(pw.MemoryImage(logoL), width: 55, height: 55),
                        pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.center,
                            children: [
                              pw.Text(
                                  'OLABISI ONABANJO UNIVERSITY TEACHING HOSPITAL',
                                  style: pw.TextStyle(
                                      fontSize: 12,
                                      fontWeight: pw.FontWeight.bold)),
                              pw.Text('SAGAMU, OGUN STATE',
                                  style: pw.TextStyle(
                                      fontSize: 10,
                                      fontWeight: pw.FontWeight.bold)),
                            ]),
                        pw.Image(pw.MemoryImage(logoR), width: 55, height: 55),
                      ]),
                  pw.SizedBox(height: 12),
                  pw.Center(
                      child: pw.Text(
                    'ANNUAL INCOME & TAX SUMMARY — ${d.year}',
                    style: pw.TextStyle(
                        fontSize: 14, fontWeight: pw.FontWeight.bold),
                  )),
                  pw.SizedBox(height: 12),

                  // Employee info box
                  pw.Container(
                    padding: const pw.EdgeInsets.all(10),
                    decoration: pw.BoxDecoration(border: pw.Border.all()),
                    child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('Employee Details',
                              style:
                                  pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                          pw.SizedBox(height: 6),
                          _pdfRow('Name', d.employee.name),
                          _pdfRow('Staff ID', d.employee.staffId),
                          _pdfRow('Department', d.employee.department),
                          _pdfRow(gradeStepLabel(d.employee.gradeScheme),
                              d.employee.gradeStep),
                          _pdfRow('Tax Year', d.year.toString()),
                          _pdfRow(
                              'Months Covered', '${d.monthsCount} month(s)'),
                        ]),
                  ),
                  pw.SizedBox(height: 12),

                  // Summary box
                  pw.Container(
                    padding: const pw.EdgeInsets.all(10),
                    decoration: pw.BoxDecoration(border: pw.Border.all()),
                    child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('Annual Summary',
                              style:
                                  pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                          pw.SizedBox(height: 6),
                          _pdfAmountRow(
                              'Total Gross Earnings', d.summary.totalGross,
                              bold: false),
                          _pdfAmountRow(
                              'Total Deductions', d.summary.totalDeductions,
                              bold: false),
                          _pdfAmountRow(
                              'Total PAYE (Income Tax)', d.summary.totalPaye,
                              bold: false),
                          _pdfAmountRow('Total Pension', d.summary.totalPension,
                              bold: false),
                          pw.Divider(),
                          _pdfAmountRow('Total Net Pay', d.summary.totalNet,
                              bold: true),
                          pw.SizedBox(height: 4),
                          pw.Text(
                            'Effective Tax Rate: ${d.summary.effectiveTaxRate.toStringAsFixed(1)}%',
                            style: pw.TextStyle(
                                fontSize: 9, color: PdfColors.grey700),
                          ),
                        ]),
                  ),
                  pw.SizedBox(height: 12),

                  // Deductions breakdown
                  if (d.deductionsBreakdown.isNotEmpty) ...[
                    pw.Text('Deductions Breakdown',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 6),
                    pw.Table(
                      border: pw.TableBorder.all(color: PdfColors.grey400),
                      columnWidths: {
                        0: const pw.FlexColumnWidth(4),
                        1: const pw.FlexColumnWidth(2),
                        2: const pw.FlexColumnWidth(1.5),
                      },
                      children: [
                        pw.TableRow(
                          decoration:
                              const pw.BoxDecoration(color: PdfColors.grey200),
                          children: [
                            _pdfCell('Deduction', bold: true),
                            _pdfCell('Annual Total (₦)', bold: true),
                            _pdfCell('% of Gross', bold: true),
                          ],
                        ),
                        ...d.deductionsBreakdown
                            .map((item) => pw.TableRow(children: [
                                  _pdfCell(item.description),
                                  _pdfCell(NumberFormatter.formatCurrencyPDF(
                                      item.total)),
                                  _pdfCell(
                                      '${item.pctOfGross.toStringAsFixed(1)}%'),
                                ])),
                      ],
                    ),
                    pw.SizedBox(height: 12),
                  ],

                  // Monthly breakdown
                  pw.Text('Monthly Breakdown',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 6),
                  pw.Table(
                    border: pw.TableBorder.all(color: PdfColors.grey400),
                    columnWidths: {
                      0: const pw.FlexColumnWidth(2.5),
                      1: const pw.FlexColumnWidth(2),
                      2: const pw.FlexColumnWidth(2),
                      3: const pw.FlexColumnWidth(2),
                    },
                    children: [
                      pw.TableRow(
                        decoration:
                            const pw.BoxDecoration(color: PdfColors.grey200),
                        children: [
                          _pdfCell('Month', bold: true),
                          _pdfCell('Gross (₦)', bold: true),
                          _pdfCell('Deductions (₦)', bold: true),
                          _pdfCell('Net Pay (₦)', bold: true),
                        ],
                      ),
                      ...d.monthlyBreakdown.map((row) => pw.TableRow(children: [
                            _pdfCell(row.month),
                            _pdfCell(
                                NumberFormatter.formatCurrencyPDF(row.gross)),
                            _pdfCell(NumberFormatter.formatCurrencyPDF(
                                row.deductions)),
                            _pdfCell(
                                NumberFormatter.formatCurrencyPDF(row.net)),
                          ])),
                      // Totals row
                      pw.TableRow(
                        decoration:
                            const pw.BoxDecoration(color: PdfColors.grey100),
                        children: [
                          _pdfCell('TOTAL', bold: true),
                          _pdfCell(
                              NumberFormatter.formatCurrencyPDF(
                                  d.summary.totalGross),
                              bold: true),
                          _pdfCell(
                              NumberFormatter.formatCurrencyPDF(
                                  d.summary.totalDeductions),
                              bold: true),
                          _pdfCell(
                              NumberFormatter.formatCurrencyPDF(
                                  d.summary.totalNet),
                              bold: true),
                        ],
                      ),
                    ],
                  ),

                  pw.Spacer(),
                  pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                            'Generated: ${DateTime.now().toString().split(' ')[0]}',
                            style: const pw.TextStyle(
                                fontSize: 8, color: PdfColors.grey)),
                        pw.Text('OOUTH Salary Management System',
                            style: const pw.TextStyle(
                                fontSize: 8, color: PdfColors.grey)),
                      ]),
                ]),
          ]),
        ],
      ));

      final bytes = await pdf.save();
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/OOUTH_Tax_Summary_${d.year}.pdf');
      await file.writeAsBytes(bytes);
      await Share.shareXFiles([XFile(file.path)],
          text: 'OOUTH Annual Tax Summary ${d.year}');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Export failed: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  // ── PDF helpers ────────────────────────────────────────────────────────────
  Future<Uint8List> _loadAsset(String path) async {
    final data = await rootBundle.load(path);
    return data.buffer.asUint8List();
  }

  pw.Widget _pdfRow(String label, String value) => pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 2),
        child: pw.Row(children: [
          pw.SizedBox(
              width: 110,
              child: pw.Text('$label:',
                  style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold, fontSize: 9))),
          pw.Expanded(
              child: pw.Text(value, style: const pw.TextStyle(fontSize: 9))),
        ]),
      );

  pw.Widget _pdfAmountRow(String label, double amount, {bool bold = false}) =>
      pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 2),
        child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(label,
                  style: pw.TextStyle(
                      fontWeight:
                          bold ? pw.FontWeight.bold : pw.FontWeight.normal,
                      fontSize: 9)),
              pw.Text(NumberFormatter.formatCurrencyPDF(amount),
                  style: pw.TextStyle(
                      fontWeight:
                          bold ? pw.FontWeight.bold : pw.FontWeight.normal,
                      fontSize: 9)),
            ]),
      );

  pw.Widget _pdfCell(String text, {bool bold = false}) => pw.Padding(
        padding: const pw.EdgeInsets.all(4),
        child: pw.Text(text,
            style: pw.TextStyle(
                fontSize: 8,
                fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal)),
      );

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Tax Summary', style: TextStyle(color: Colors.white)),
        backgroundColor: AppTheme.primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (_data != null && !_isExporting)
            IconButton(
              icon: const Icon(Icons.download, color: Colors.white),
              tooltip: 'Export PDF',
              onPressed: _exportPdf,
            ),
          if (_isExporting)
            const Padding(
              padding: EdgeInsets.all(14),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2),
              ),
            ),
        ],
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
          _buildEmployeeCard(d),
          const SizedBox(height: 16),
          _buildSummaryCards(d.summary),
          const SizedBox(height: 16),
          _buildKeyHighlights(d.summary),
          const SizedBox(height: 16),
          _buildDeductionsBreakdown(d),
          const SizedBox(height: 16),
          _buildMonthlyChart(d),
          const SizedBox(height: 16),
          _buildMonthlyTable(d),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // ── Year selector ──────────────────────────────────────────────────────────
  Widget _buildYearSelector(AnnualTaxSummary d) => Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(children: [
            const Icon(Icons.calendar_today_outlined,
                color: AppTheme.primaryColor, size: 20),
            const SizedBox(width: 10),
            const Text('Tax Year:',
                style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButton<int>(
                value: _selectedYear,
                isExpanded: true,
                underline: const SizedBox.shrink(),
                items: d.availableYears
                    .map((y) =>
                        DropdownMenuItem(value: y, child: Text(y.toString())))
                    .toList(),
                onChanged: (y) {
                  if (y != null && y != _selectedYear) _load(year: y);
                },
              ),
            ),
            Text(
              '${d.monthsCount} month${d.monthsCount == 1 ? '' : 's'}',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ]),
        ),
      );

  // ── Employee card ──────────────────────────────────────────────────────────
  Widget _buildEmployeeCard(AnnualTaxSummary d) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: Colors.white.withOpacity(0.2),
            child: Text(
              d.employee.name.isNotEmpty
                  ? d.employee.name[0].toUpperCase()
                  : 'S',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(d.employee.name,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15)),
                Text(d.employee.department,
                    style:
                        const TextStyle(color: Colors.white70, fontSize: 12)),
                Text(
                    '${gradeStepLabel(d.employee.gradeScheme)}: ${d.employee.gradeStep}  ·  Staff: ${d.employee.staffId}',
                    style:
                        const TextStyle(color: Colors.white60, fontSize: 11)),
              ])),
        ]),
      );

  // ── Top 3 summary cards ────────────────────────────────────────────────────
  Widget _buildSummaryCards(TaxSummary s) => Row(children: [
        Expanded(
            child: _summaryCard('Total Gross', s.totalGross, Colors.blue[700]!,
                Icons.arrow_upward)),
        const SizedBox(width: 8),
        Expanded(
            child: _summaryCard('Total Deductions', s.totalDeductions,
                Colors.red[600]!, Icons.arrow_downward)),
        const SizedBox(width: 8),
        Expanded(
            child: _summaryCard('Net Pay', s.totalNet, Colors.green[700]!,
                Icons.account_balance_wallet)),
      ]);

  Widget _summaryCard(
          String label, double amount, Color color, IconData icon) =>
      Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 4),
              Expanded(
                  child: Text(label,
                      style: TextStyle(color: Colors.grey[600], fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis)),
            ]),
            const SizedBox(height: 6),
            Text(NumberFormatter.formatCurrency(amount),
                style: TextStyle(
                    color: color, fontWeight: FontWeight.bold, fontSize: 13),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ]),
        ),
      );

  // ── Key highlights: PAYE, Pension, effective rate ───────────────────────────
  Widget _buildKeyHighlights(TaxSummary s) => Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Icon(Icons.insights,
                  color: AppTheme.primaryColor, size: 18),
              const SizedBox(width: 8),
              Text('Key Tax Figures — ${_selectedYear ?? ''}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 15)),
            ]),
            const Divider(height: 20),
            _highlightRow(
                'PAYE (Income Tax)', s.totalPaye, Colors.orange[700]!),
            _highlightRow(
                'Pension Contributions', s.totalPension, Colors.purple[600]!),
            const Divider(height: 20),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('Effective Tax Rate',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Text(
                  '${s.effectiveTaxRate.toStringAsFixed(1)}%',
                  style: TextStyle(
                      color: Colors.orange[700],
                      fontWeight: FontWeight.bold,
                      fontSize: 13),
                ),
              ),
            ]),
          ]),
        ),
      );

  Widget _highlightRow(String label, double amount, Color color) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child:
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Row(children: [
            Container(
                width: 10,
                height: 10,
                decoration:
                    BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontSize: 13)),
          ]),
          Text(NumberFormatter.formatCurrency(amount),
              style: TextStyle(
                  color: color, fontWeight: FontWeight.bold, fontSize: 13)),
        ]),
      );

  // ── Deductions breakdown table ─────────────────────────────────────────────
  Widget _buildDeductionsBreakdown(AnnualTaxSummary d) {
    if (d.deductionsBreakdown.isEmpty) return const SizedBox.shrink();
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(Icons.list_alt, color: AppTheme.primaryColor, size: 18),
            const SizedBox(width: 8),
            const Text('All Deductions',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          ]),
          const SizedBox(height: 12),
          // Header
          Row(children: [
            const Expanded(
                flex: 4,
                child: Text('Description',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                        color: Colors.grey))),
            const Expanded(
                flex: 3,
                child: Text('Annual Total',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                        color: Colors.grey))),
            Expanded(
                flex: 2,
                child: Text('% Gross',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                        color: Colors.grey[600]))),
          ]),
          const Divider(height: 12),
          ...d.deductionsBreakdown.map((item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(children: [
                  Expanded(
                      flex: 4,
                      child: Text(item.description,
                          style: const TextStyle(fontSize: 13))),
                  Expanded(
                    flex: 3,
                    child: Text(NumberFormatter.formatCurrency(item.total),
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text('${item.pctOfGross.toStringAsFixed(1)}%',
                        textAlign: TextAlign.right,
                        style:
                            TextStyle(fontSize: 12, color: Colors.grey[600])),
                  ),
                ]),
              )),
          const Divider(height: 16),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('TOTAL', style: TextStyle(fontWeight: FontWeight.bold)),
            Text(NumberFormatter.formatCurrency(d.summary.totalDeductions),
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          ]),
        ]),
      ),
    );
  }

  // ── Monthly net pay bar chart ──────────────────────────────────────────────
  Widget _buildMonthlyChart(AnnualTaxSummary d) {
    if (d.monthlyBreakdown.isEmpty) return const SizedBox.shrink();
    final maxY =
        d.monthlyBreakdown.map((r) => r.gross).reduce((a, b) => a > b ? a : b) *
            1.1;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Row(children: [
            Icon(Icons.bar_chart, color: AppTheme.primaryColor, size: 18),
            SizedBox(width: 8),
            Text('Monthly Earnings vs Net Pay',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          ]),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: BarChart(BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxY,
              barGroups: d.monthlyBreakdown.asMap().entries.map((entry) {
                final i = entry.key;
                final row = entry.value;
                return BarChartGroupData(x: i, barsSpace: 4, barRods: [
                  BarChartRodData(
                    toY: row.gross,
                    color: AppTheme.primaryColor.withOpacity(0.5),
                    width: 10,
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(3)),
                  ),
                  BarChartRodData(
                    toY: row.net,
                    color: Colors.green[600]!,
                    width: 10,
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(3)),
                  ),
                ]);
              }).toList(),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (v, _) {
                    final idx = v.toInt();
                    if (idx >= d.monthlyBreakdown.length) return const Text('');
                    final month =
                        d.monthlyBreakdown[idx].month.split(' ').first;
                    return Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(month.substring(0, 3),
                          style: const TextStyle(fontSize: 9)),
                    );
                  },
                )),
                leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 52,
                  getTitlesWidget: (v, _) => Text(
                    NumberFormatter.formatCurrency(v).replaceAll(',', ''),
                    style: const TextStyle(fontSize: 8),
                  ),
                )),
                rightTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
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
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            _legend(AppTheme.primaryColor.withOpacity(0.5), 'Gross'),
            const SizedBox(width: 16),
            _legend(Colors.green[600]!, 'Net Pay'),
          ]),
        ]),
      ),
    );
  }

  Widget _legend(Color color, String label) => Row(children: [
        Container(width: 12, height: 12, color: color),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11)),
      ]);

  // ── Monthly breakdown table ────────────────────────────────────────────────
  Widget _buildMonthlyTable(AnnualTaxSummary d) => Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Row(children: [
              Icon(Icons.table_rows_outlined,
                  color: AppTheme.primaryColor, size: 18),
              SizedBox(width: 8),
              Text('Monthly Breakdown',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            ]),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowHeight: 36,
                dataRowMinHeight: 40,
                dataRowMaxHeight: 40,
                columnSpacing: 16,
                headingTextStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: AppTheme.primaryColor),
                columns: const [
                  DataColumn(label: Text('Month')),
                  DataColumn(label: Text('Gross'), numeric: true),
                  DataColumn(label: Text('Deductions'), numeric: true),
                  DataColumn(label: Text('Net Pay'), numeric: true),
                ],
                rows: [
                  ...d.monthlyBreakdown.map((row) => DataRow(cells: [
                        DataCell(Text(row.month,
                            style: const TextStyle(fontSize: 12))),
                        DataCell(Text(NumberFormatter.formatCurrency(row.gross),
                            style: const TextStyle(fontSize: 12))),
                        DataCell(Text(
                            NumberFormatter.formatCurrency(row.deductions),
                            style: const TextStyle(
                                fontSize: 12, color: Colors.red))),
                        DataCell(Text(NumberFormatter.formatCurrency(row.net),
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.green[700]))),
                      ])),
                  // Totals footer row
                  DataRow(
                    color: WidgetStateProperty.all(Colors.grey[100]),
                    cells: [
                      const DataCell(Text('TOTAL',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 12))),
                      DataCell(Text(
                          NumberFormatter.formatCurrency(d.summary.totalGross),
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 12))),
                      DataCell(Text(
                          NumberFormatter.formatCurrency(
                              d.summary.totalDeductions),
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: Colors.red))),
                      DataCell(Text(
                          NumberFormatter.formatCurrency(d.summary.totalNet),
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: Colors.green[700]))),
                    ],
                  ),
                ],
              ),
            ),
          ]),
        ),
      );
}
