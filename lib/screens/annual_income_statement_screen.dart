import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/annual_income_statement.dart';
import '../providers/auth_provider.dart';
import '../services/annual_income_statement_service.dart';
import '../utils/app_theme.dart';
import '../utils/number_formatter.dart';

class AnnualIncomeStatementScreen extends StatefulWidget {
  const AnnualIncomeStatementScreen({super.key});

  @override
  State<AnnualIncomeStatementScreen> createState() =>
      _AnnualIncomeStatementScreenState();
}

class _AnnualIncomeStatementScreenState
    extends State<AnnualIncomeStatementScreen>
    with SingleTickerProviderStateMixin {
  late final AnnualIncomeStatementService _service;
  late final String _staffId;
  late final TabController _tabs;

  AnnualIncomeStatement? _data;
  bool _loading = true;
  bool _exporting = false;
  String? _error;
  int? _selectedYear;

  static const _monthAbbr = [
    '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    final auth = context.read<AuthProvider>();
    _staffId = auth.user?.id ?? '';
    _service = AnnualIncomeStatementService(auth.token ?? '');
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _load({int? year}) async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await _service.getStatement(staffId: _staffId, year: year);
      setState(() {
        _data = data;
        _selectedYear = data.year;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  // ── PDF ────────────────────────────────────────────────────────────────────
  Future<void> _export() async {
    if (_data == null) return;
    setState(() => _exporting = true);
    try {
      final bytes = await _buildPdf(_data!);
      final emp   = _data!.employee;
      final dir   = await getTemporaryDirectory();
      final file  = File(
          '${dir.path}/OOUTH_Income_Statement_${emp.staffId}_${_data!.year}.pdf');
      await file.writeAsBytes(bytes);
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'OOUTH Annual Income Statement ${_data!.year} — ${emp.name}',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<Uint8List> _buildPdf(AnnualIncomeStatement d) async {
    final pdf  = pw.Document();
    final emp  = d.employee;
    final s    = d.summary;

    pw.ImageProvider? logo;
    try {
      final bytes = await rootBundle.load('assets/images/oouth_logo.png');
      logo = pw.MemoryImage(bytes.buffer.asUint8List());
    } catch (_) {}

    final headerBlue = PdfColor.fromHex('#1a3a6b');
    final paidMonths = d.monthlyTotals.where((m) => m.paid).map((m) => m.monthNum).toSet();

    pdf.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4.landscape,
      margin: const pw.EdgeInsets.all(28),
      header: (ctx) => pw.Container(
        margin: const pw.EdgeInsets.only(bottom: 10),
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(
          color: headerBlue,
          borderRadius: pw.BorderRadius.circular(5),
        ),
        child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
          pw.Row(children: [
            if (logo != null) ...[
              pw.Image(logo, width: 34, height: 34),
              pw.SizedBox(width: 10),
            ],
            pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
              pw.Text('OLABISI ONABANJO UNIVERSITY TEACHING HOSPITAL',
                  style: pw.TextStyle(
                      color: PdfColors.white,
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 10)),
              pw.Text('ANNUAL INCOME STATEMENT — ${d.year}',
                  style: pw.TextStyle(
                      color: PdfColors.amber,
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 9)),
            ]),
          ]),
          pw.Text('Page ${ctx.pageNumber} of ${ctx.pagesCount}',
              style: const pw.TextStyle(color: PdfColors.white, fontSize: 8)),
        ]),
      ),
      build: (ctx) => [
        // ── Employee block ──────────────────────────────────────────────────
        pw.Container(
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(
            color: PdfColors.grey100,
            borderRadius: pw.BorderRadius.circular(4),
            border: pw.Border.all(color: PdfColors.grey300),
          ),
          child: pw.Row(children: [
            pw.Expanded(child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
              _pdfEmpRow('Name',        emp.name),
              _pdfEmpRow('Staff ID',    emp.staffId),
              _pdfEmpRow('IPPIS/PP No', emp.ppno),
            ])),
            pw.SizedBox(width: 20),
            pw.Expanded(child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
              _pdfEmpRow('Department',   emp.department),
              _pdfEmpRow('Salary Scale', emp.salaryType),
              _pdfEmpRow('Grade Level',  emp.gradeLevel),
            ])),
            pw.SizedBox(width: 20),
            pw.Expanded(child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
              _pdfEmpRow('Months Paid', '${s.monthsPaid} of 12'),
              _pdfEmpRow('Total Gross', NumberFormatter.formatCurrencyPDF(s.totalGross)),
              _pdfEmpRow('Total Net',   NumberFormatter.formatCurrencyPDF(s.totalNet)),
            ])),
          ]),
        ),
        pw.SizedBox(height: 14),

        // ── Earnings matrix ─────────────────────────────────────────────────
        _pdfSectionHeader('EARNINGS', headerBlue),
        pw.SizedBox(height: 4),
        _pdfMatrix(d.earnings, paidMonths, PdfColor.fromHex('#1565c0')),
        pw.SizedBox(height: 14),

        // ── Deductions matrix ───────────────────────────────────────────────
        _pdfSectionHeader('DEDUCTIONS', PdfColor.fromHex('#b71c1c')),
        pw.SizedBox(height: 4),
        _pdfMatrix(d.deductions, paidMonths, PdfColor.fromHex('#b71c1c')),
        pw.SizedBox(height: 14),

        // ── Monthly totals ──────────────────────────────────────────────────
        _pdfSectionHeader('MONTHLY SUMMARY', PdfColor.fromHex('#2e7d32')),
        pw.SizedBox(height: 4),
        _pdfMonthlySummary(d.monthlyTotals),

        pw.SizedBox(height: 8),
        pw.Text(
          'This statement is computer-generated. '
          'For queries contact the Accounts/Payroll Department.',
          style: const pw.TextStyle(color: PdfColors.grey600, fontSize: 7),
        ),
      ],
    ));

    return pdf.save();
  }

  pw.Widget _pdfEmpRow(String label, String value) => pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 2),
        child: pw.Row(children: [
          pw.SizedBox(
            width: 70,
            child: pw.Text(label,
                style: const pw.TextStyle(
                    color: PdfColors.grey700, fontSize: 8)),
          ),
          pw.Text(': ', style: const pw.TextStyle(fontSize: 8)),
          pw.Expanded(
            child: pw.Text(value,
                style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold, fontSize: 8)),
          ),
        ]),
      );

  pw.Widget _pdfSectionHeader(String title, PdfColor color) => pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: pw.BoxDecoration(
            color: color,
            borderRadius: pw.BorderRadius.circular(3)),
        child: pw.Text(title,
            style: pw.TextStyle(
                color: PdfColors.white,
                fontWeight: pw.FontWeight.bold,
                fontSize: 9)),
      );

  pw.Widget _pdfMatrix(
    List<StatementLineType> items,
    Set<int> paidMonths,
    PdfColor accentColor,
  ) {
    if (items.isEmpty) {
      return pw.Text('No data', style: const pw.TextStyle(fontSize: 9));
    }

    // Column widths: description + 12 months + total
    final colWidths = <int, pw.TableColumnWidth>{
      0: const pw.FlexColumnWidth(2.2),
    };
    for (var i = 1; i <= 12; i++) {
      colWidths[i] = const pw.FlexColumnWidth(0.8);
    }
    colWidths[13] = const pw.FlexColumnWidth(1.0);

    pw.TableRow headerRow() => pw.TableRow(
          decoration: pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            _mc('Description', bold: true, align: pw.TextAlign.left),
            ..._monthAbbr.skip(1).map((m) => _mc(m, bold: true)),
            _mc('Total', bold: true),
          ],
        );

    pw.TableRow dataRow(StatementLineType item, int idx) => pw.TableRow(
          decoration: idx.isEven
              ? const pw.BoxDecoration(color: PdfColors.white)
              : pw.BoxDecoration(color: PdfColors.grey50),
          children: [
            _mc(item.description, align: pw.TextAlign.left, fontSize: 7.5),
            ...List.generate(12, (i) {
              final mn  = i + 1;
              final amt = item.months[mn] ?? 0;
              final isPaid = paidMonths.contains(mn);
              return _mc(
                amt > 0 ? _fmtK(amt) : (isPaid ? '-' : ''),
                color: amt > 0 ? accentColor : PdfColors.grey500,
                fontSize: 7.5,
              );
            }),
            _mc(
              NumberFormatter.formatCurrencyPDF(item.annualTotal),
              bold: true,
              color: accentColor,
              fontSize: 7.5,
            ),
          ],
        );

    // Total row
    pw.TableRow totalRow() {
      final monthlyTotals = List.generate(12, (i) {
        final mn = i + 1;
        return items.fold(0.0, (s, e) => s + (e.months[mn] ?? 0));
      });
      final grandTotal = items.fold(0.0, (s, e) => s + e.annualTotal);
      return pw.TableRow(
        decoration: pw.BoxDecoration(color: PdfColors.grey200),
        children: [
          _mc('TOTAL', bold: true, align: pw.TextAlign.left),
          ...monthlyTotals.map((a) =>
              _mc(a > 0 ? _fmtK(a) : '', bold: true, color: accentColor)),
          _mc(NumberFormatter.formatCurrencyPDF(grandTotal),
              bold: true, color: accentColor),
        ],
      );
    }

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.3),
      columnWidths: colWidths,
      children: [
        headerRow(),
        ...items.asMap().entries.map((e) => dataRow(e.value, e.key)),
        totalRow(),
      ],
    );
  }

  pw.Widget _pdfMonthlySummary(List<StatementMonth> months) {
    final paidMonths = months.where((m) => m.paid).toList();
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.3),
      columnWidths: {
        0: const pw.FlexColumnWidth(1.2),
        1: const pw.FlexColumnWidth(1),
        2: const pw.FlexColumnWidth(1),
        3: const pw.FlexColumnWidth(1),
      },
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            _mc('Month', bold: true, align: pw.TextAlign.left),
            _mc('Gross', bold: true),
            _mc('Deductions', bold: true),
            _mc('Net Pay', bold: true),
          ],
        ),
        ...paidMonths.asMap().entries.map((e) => pw.TableRow(
              decoration: e.key.isEven
                  ? const pw.BoxDecoration(color: PdfColors.white)
                  : pw.BoxDecoration(color: PdfColors.grey50),
              children: [
                _mc(e.value.monthName, align: pw.TextAlign.left),
                _mc(NumberFormatter.formatCurrencyPDF(e.value.gross),
                    color: PdfColor.fromHex('#1565c0')),
                _mc(NumberFormatter.formatCurrencyPDF(e.value.deductions),
                    color: PdfColor.fromHex('#b71c1c')),
                _mc(NumberFormatter.formatCurrencyPDF(e.value.net),
                    bold: true, color: PdfColor.fromHex('#2e7d32')),
              ],
            )),
      ],
    );
  }

  pw.Widget _mc(
    String text, {
    bool bold = false,
    pw.TextAlign align = pw.TextAlign.right,
    PdfColor? color,
    double fontSize = 8,
  }) =>
      pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
        child: pw.Text(text,
            textAlign: align,
            style: pw.TextStyle(
              fontSize: fontSize,
              fontWeight:
                  bold ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: color,
            )),
      );

  // Format large numbers compactly for the matrix cells (e.g. 462,500 → 462.5K)
  String _fmtK(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000)    return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
  }

  // ── UI ─────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Annual Income Statement',
            style: TextStyle(color: Colors.white)),
        backgroundColor: AppTheme.primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (_data != null)
            _exporting
                ? const Padding(
                    padding: EdgeInsets.all(14),
                    child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white)),
                  )
                : IconButton(
                    icon: const Icon(Icons.picture_as_pdf_outlined,
                        color: Colors.white),
                    tooltip: 'Export PDF',
                    onPressed: _export,
                  ),
        ],
        bottom: _data == null
            ? null
            : TabBar(
                controller: _tabs,
                indicatorColor: Colors.white,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white60,
                tabs: const [
                  Tab(text: 'Summary'),
                  Tab(text: 'Earnings'),
                  Tab(text: 'Deductions'),
                ],
              ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError()
              : _buildBody(),
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

  Widget _buildBody() {
    final d = _data!;
    return Column(children: [
      _buildYearBar(d),
      Expanded(
        child: TabBarView(
          controller: _tabs,
          children: [
            _buildSummaryTab(d),
            _buildMatrixTab(d.earnings, isEarning: true),
            _buildMatrixTab(d.deductions, isEarning: false),
          ],
        ),
      ),
    ]);
  }

  Widget _buildYearBar(AnnualIncomeStatement d) => Container(
        color: Colors.white,
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(children: [
          const Icon(Icons.calendar_today,
              size: 16, color: AppTheme.primaryColor),
          const SizedBox(width: 8),
          const Text('Year:',
              style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(width: 10),
          DropdownButton<int>(
            value: _selectedYear,
            underline: const SizedBox(),
            isDense: true,
            items: d.availableYears
                .map((y) => DropdownMenuItem(
                      value: int.parse(y),
                      child: Text(y,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor)),
                    ))
                .toList(),
            onChanged: (y) {
              if (y != null && y != _selectedYear) _load(year: y);
            },
          ),
          const Spacer(),
          Text(
            '${d.summary.monthsPaid}/12 months paid',
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
        ]),
      );

  // ── Summary tab ────────────────────────────────────────────────────────────
  Widget _buildSummaryTab(AnnualIncomeStatement d) {
    final s = d.summary;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 4 stat cards
        Row(children: [
          _statCard('Total Gross',
              NumberFormatter.formatCurrency(s.totalGross),
              Colors.blue[700]!, Icons.trending_up),
          const SizedBox(width: 12),
          _statCard('Total Deducted',
              NumberFormatter.formatCurrency(s.totalDeductions),
              Colors.red[700]!, Icons.trending_down),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          _statCard('Total Net Pay',
              NumberFormatter.formatCurrency(s.totalNet),
              Colors.green[700]!, Icons.account_balance_wallet_outlined),
          const SizedBox(width: 12),
          _statCard('Avg Monthly Net',
              NumberFormatter.formatCurrency(s.avgMonthlyNet),
              Colors.purple[700]!, Icons.bar_chart),
        ]),

        const SizedBox(height: 20),
        // Monthly totals table
        Card(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              const Text('Month-by-Month',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 10),
              // Header
              _monthRow('Month', 'Gross', 'Deductions', 'Net',
                  isHeader: true),
              const Divider(height: 1),
              ...d.monthlyTotals.map((m) {
                if (!m.paid) return const SizedBox.shrink();
                return Column(children: [
                  _monthRow(
                    _monthAbbr[m.monthNum],
                    NumberFormatter.formatCurrency(m.gross),
                    NumberFormatter.formatCurrency(m.deductions),
                    NumberFormatter.formatCurrency(m.net),
                  ),
                  const Divider(height: 1),
                ]);
              }),
              // Totals row
              _monthRow(
                'TOTAL',
                NumberFormatter.formatCurrency(s.totalGross),
                NumberFormatter.formatCurrency(s.totalDeductions),
                NumberFormatter.formatCurrency(s.totalNet),
                isBold: true,
              ),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _statCard(
      String label, String value, Color color, IconData icon) =>
      Expanded(
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                  color: color.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 3))
            ],
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(label,
                    style: TextStyle(
                        color: Colors.grey[600], fontSize: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ),
            ]),
            const SizedBox(height: 6),
            Text(value,
                style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 13),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ]),
        ),
      );

  Widget _monthRow(
    String month,
    String gross,
    String ded,
    String net, {
    bool isHeader = false,
    bool isBold = false,
  }) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(children: [
          SizedBox(
            width: 36,
            child: Text(month,
                style: TextStyle(
                    fontWeight:
                        (isHeader || isBold) ? FontWeight.bold : FontWeight.normal,
                    fontSize: 12,
                    color: isHeader ? Colors.grey[600] : null)),
          ),
          Expanded(
            child: Text(gross,
                textAlign: TextAlign.right,
                style: TextStyle(
                    fontWeight:
                        (isHeader || isBold) ? FontWeight.bold : FontWeight.normal,
                    fontSize: 12,
                    color: isHeader
                        ? Colors.grey[600]
                        : (isBold ? Colors.blue[700] : Colors.blue[800]))),
          ),
          Expanded(
            child: Text(ded,
                textAlign: TextAlign.right,
                style: TextStyle(
                    fontWeight:
                        (isHeader || isBold) ? FontWeight.bold : FontWeight.normal,
                    fontSize: 12,
                    color: isHeader
                        ? Colors.grey[600]
                        : (isBold ? Colors.red[700] : Colors.red[800]))),
          ),
          Expanded(
            child: Text(net,
                textAlign: TextAlign.right,
                style: TextStyle(
                    fontWeight:
                        (isHeader || isBold) ? FontWeight.bold : FontWeight.normal,
                    fontSize: 12,
                    color: isHeader
                        ? Colors.grey[600]
                        : (isBold ? Colors.green[700] : Colors.green[800]))),
          ),
        ]),
      );

  // ── Matrix tab ─────────────────────────────────────────────────────────────
  Widget _buildMatrixTab(List<StatementLineType> items,
      {required bool isEarning}) {
    if (items.isEmpty) {
      return Center(
        child: Text(
          'No ${isEarning ? 'earnings' : 'deductions'} data',
          style: TextStyle(color: Colors.grey[500]),
        ),
      );
    }

    final color = isEarning ? Colors.blue[700]! : Colors.red[700]!;
    final paidMonths = _data!.monthlyTotals
        .where((m) => m.paid)
        .map((m) => m.monthNum)
        .toSet();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(children: [
        // Horizontally scrollable matrix
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Card(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                // Month header row
                _matrixRow(
                  label: 'Description',
                  cells: [
                    ...List.generate(12, (i) {
                      final mn = i + 1;
                      return _monthAbbr[mn];
                    }),
                    'Annual Total',
                  ],
                  isHeader: true,
                  paidMonths: paidMonths,
                  color: color,
                ),
                const Divider(height: 1),
                // Data rows
                ...items.asMap().entries.map((entry) {
                  final item = entry.value;
                  return Column(children: [
                    _matrixRow(
                      label: item.description,
                      cells: [
                        ...List.generate(12, (i) {
                          final mn  = i + 1;
                          final amt = item.months[mn] ?? 0;
                          if (!paidMonths.contains(mn)) return '';
                          return amt > 0
                              ? NumberFormatter.formatCurrency(amt)
                              : '—';
                        }),
                        NumberFormatter.formatCurrency(item.annualTotal),
                      ],
                      isEven: entry.key.isEven,
                      isTotalCol: true,
                      paidMonths: paidMonths,
                      color: color,
                    ),
                    const Divider(height: 1),
                  ]);
                }),
                // Grand total row
                _matrixRow(
                  label: isEarning ? 'TOTAL EARNINGS' : 'TOTAL DEDUCTIONS',
                  cells: [
                    ...List.generate(12, (i) {
                      final mn = i + 1;
                      if (!paidMonths.contains(mn)) return '';
                      final total = items.fold(
                          0.0, (s, e) => s + (e.months[mn] ?? 0));
                      return total > 0
                          ? NumberFormatter.formatCurrency(total)
                          : '—';
                    }),
                    NumberFormatter.formatCurrency(
                        items.fold(0.0, (s, e) => s + e.annualTotal)),
                  ],
                  isBold: true,
                  isTotalCol: true,
                  paidMonths: paidMonths,
                  color: color,
                ),
              ]),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _matrixRow({
    required String label,
    required List<String> cells,
    bool isHeader = false,
    bool isBold = false,
    bool isEven = true,
    bool isTotalCol = false,
    required Set<int> paidMonths,
    required Color color,
  }) {
    final bg = isHeader || isBold
        ? Colors.grey[100]
        : (isEven ? Colors.white : Colors.grey[50]);

    return Container(
      color: bg,
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
        SizedBox(
          width: 150,
          child: Text(label,
              style: TextStyle(
                  fontWeight:
                      (isHeader || isBold) ? FontWeight.bold : FontWeight.normal,
                  fontSize: 11,
                  color: isHeader ? Colors.grey[600] : null)),
        ),
        ...cells.asMap().entries.map((e) {
          final isLast = e.key == cells.length - 1;
          final isPaid = isLast ||
              isHeader ||
              (e.key < 12 && paidMonths.contains(e.key + 1));
          return SizedBox(
            width: isLast ? 120 : 80,
            child: Text(
              e.value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 11,
                fontWeight: (isHeader || isBold || isLast)
                    ? FontWeight.bold
                    : FontWeight.normal,
                color: isHeader
                    ? Colors.grey[600]
                    : (!isPaid
                        ? Colors.transparent
                        : (isLast || isBold) ? color : null),
              ),
            ),
          );
        }),
      ]),
    );
  }
}
