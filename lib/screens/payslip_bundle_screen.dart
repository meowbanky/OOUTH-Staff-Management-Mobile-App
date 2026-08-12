import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/payslip_bundle.dart';
import '../providers/auth_provider.dart';
import '../services/payslip_bundle_service.dart';
import '../utils/app_theme.dart';
import '../utils/number_formatter.dart';

class PayslipBundleScreen extends StatefulWidget {
  const PayslipBundleScreen({super.key});

  @override
  State<PayslipBundleScreen> createState() => _PayslipBundleScreenState();
}

class _PayslipBundleScreenState extends State<PayslipBundleScreen> {
  late final PayslipBundleService _service;
  late final String _staffId;

  List<BundlePeriod> _periods = [];
  final Set<int> _selected = {};    // selected period IDs

  bool _loadingPeriods = true;
  bool _fetchingBundle = false;
  bool _generatingPdf  = false;
  String? _error;

  PayslipBundle? _bundle;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    _staffId = auth.user?.id ?? '';
    _service = PayslipBundleService(auth.token ?? '');
    _loadPeriods();
  }

  Future<void> _loadPeriods() async {
    setState(() { _loadingPeriods = true; _error = null; });
    try {
      final periods = await _service.getPeriods(_staffId);
      setState(() {
        _periods = periods;
        // Default: last 3 months selected
        _applyPreset(3, notify: false);
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loadingPeriods = false);
    }
  }

  void _applyPreset(int n, {bool notify = true}) {
    final take = _periods.take(n).map((p) => p.periodId).toSet();
    _selected
      ..clear()
      ..addAll(take);
    if (notify) setState(() {});
  }

  Future<void> _fetchBundle() async {
    if (_selected.isEmpty) return;
    setState(() { _fetchingBundle = true; _error = null; _bundle = null; });
    try {
      final bundle = await _service.fetchBundle(
          staffId: _staffId, periodIds: _selected.toList());
      setState(() => _bundle = bundle);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _fetchingBundle = false);
    }
  }

  Future<void> _generatePdf() async {
    if (_bundle == null) return;
    setState(() => _generatingPdf = true);
    try {
      final bytes   = await _buildPdf(_bundle!);
      final emp     = _bundle!.employee;
      final range   = (_bundle!.bundleSummary?.dateRange ?? '')
          .replaceAll(' ', '_')
          .replaceAll('–', '-');
      final tempDir = await getTemporaryDirectory();
      final file    = File('${tempDir.path}/OOUTH_Payslips_${emp.staffId}_$range.pdf');
      await file.writeAsBytes(bytes);
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'OOUTH Payslip Bundle — ${emp.name}',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PDF error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _generatingPdf = false);
    }
  }

  // ── PDF builder ────────────────────────────────────────────────────────────
  Future<Uint8List> _buildPdf(PayslipBundle bundle) async {
    final pdf  = pw.Document();
    final emp  = bundle.employee;

    // Load logo
    pw.ImageProvider? logo;
    try {
      final bytes = await rootBundle.load('assets/images/oouth_logo.png');
      logo = pw.MemoryImage(bytes.buffer.asUint8List());
    } catch (_) {}

    final headerBlue = PdfColor.fromHex('#1a3a6b');
    final lightGrey  = PdfColor.fromHex('#f5f5f5');

    for (final slip in bundle.payslips) {
      pdf.addPage(pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (ctx) => pw.Stack(children: [
          // Watermark
          pw.Center(
            child: pw.Opacity(
              opacity: 0.04,
              child: pw.Transform.rotate(
                angle: -0.5,
                child: pw.Text('OOUTH PAYSLIP',
                    style: pw.TextStyle(
                        fontSize: 60,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blue)),
              ),
            ),
          ),

          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // ── Header ──────────────────────────────────────────────────
              pw.Container(
                padding: const pw.EdgeInsets.all(14),
                decoration: pw.BoxDecoration(
                  color: headerBlue,
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                  pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                    if (logo != null)
                      pw.Image(logo, width: 40, height: 40),
                    pw.SizedBox(height: 4),
                    pw.Text('OLABISI ONABANJO UNIVERSITY',
                        style: pw.TextStyle(
                            color: PdfColors.white,
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 10)),
                    pw.Text('TEACHING HOSPITAL, SAGAMU',
                        style: const pw.TextStyle(
                            color: PdfColors.white, fontSize: 8)),
                  ]),
                  pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                    pw.Text('PAYSLIP',
                        style: pw.TextStyle(
                            color: PdfColors.white,
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 18)),
                    pw.Text(slip.periodLabel,
                        style: pw.TextStyle(
                            color: PdfColors.amber,
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 12)),
                  ]),
                ]),
              ),

              pw.SizedBox(height: 12),

              // ── Employee details ─────────────────────────────────────────
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  color: lightGrey,
                  borderRadius: pw.BorderRadius.circular(4),
                  border: pw.Border.all(color: PdfColors.grey300),
                ),
                child: pw.Row(children: [
                  pw.Expanded(child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                    _pdfEmpRow('Name',       emp.name),
                    _pdfEmpRow('Staff ID',   emp.staffId),
                    _pdfEmpRow('IPPIS/PP No',emp.ppno),
                    _pdfEmpRow('Grade Level',emp.gradeLevel),
                  ])),
                  pw.SizedBox(width: 20),
                  pw.Expanded(child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                    _pdfEmpRow('Department',  emp.department),
                    _pdfEmpRow('Salary Scale',emp.salaryType),
                    if (emp.employmentDate != null)
                      _pdfEmpRow('Date Employed', emp.employmentDate!),
                    _pdfEmpRow('Gender', emp.gender),
                  ])),
                ]),
              ),

              pw.SizedBox(height: 14),

              // ── Earnings table ────────────────────────────────────────────
              _pdfSectionHeader('EARNINGS', headerBlue),
              pw.SizedBox(height: 4),
              _pdfTable(slip.earnings, isEarning: true),

              pw.SizedBox(height: 10),

              // ── Deductions table ──────────────────────────────────────────
              _pdfSectionHeader('DEDUCTIONS', PdfColor.fromHex('#b71c1c')),
              pw.SizedBox(height: 4),
              _pdfTable(slip.deductions, isEarning: false),

              pw.SizedBox(height: 14),

              // ── Net pay box ───────────────────────────────────────────────
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromHex('#e8f5e9'),
                  borderRadius: pw.BorderRadius.circular(6),
                  border: pw.Border.all(color: PdfColor.fromHex('#4caf50')),
                ),
                child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                  pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                    pw.Text('GROSS PAY',
                        style: const pw.TextStyle(
                            color: PdfColors.grey700, fontSize: 9)),
                    pw.Text(NumberFormatter.formatCurrencyPDF(slip.gross),
                        style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColor.fromHex('#1565c0'),
                            fontSize: 12)),
                  ]),
                  pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                    pw.Text('TOTAL DEDUCTIONS',
                        style: const pw.TextStyle(
                            color: PdfColors.grey700, fontSize: 9)),
                    pw.Text(NumberFormatter.formatCurrencyPDF(slip.totalDeductions),
                        style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColor.fromHex('#b71c1c'),
                            fontSize: 12)),
                  ]),
                  pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                    pw.Text('NET PAY',
                        style: const pw.TextStyle(
                            color: PdfColors.grey700, fontSize: 9)),
                    pw.Text(NumberFormatter.formatCurrencyPDF(slip.net),
                        style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColor.fromHex('#2e7d32'),
                            fontSize: 16)),
                  ]),
                ]),
              ),

              pw.Spacer(),

              // ── Footer ────────────────────────────────────────────────────
              pw.Divider(color: PdfColors.grey300),
              pw.SizedBox(height: 4),
              pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                pw.Text('This payslip is computer-generated and requires no signature.',
                    style: const pw.TextStyle(
                        color: PdfColors.grey600, fontSize: 7)),
                pw.Text('Page ${bundle.payslips.indexOf(slip) + 1} of ${bundle.payslips.length}',
                    style: const pw.TextStyle(
                        color: PdfColors.grey600, fontSize: 7)),
              ]),
            ],
          ),
        ]),
      ));
    }

    return pdf.save();
  }

  pw.Widget _pdfEmpRow(String label, String value) => pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 2),
        child: pw.Row(children: [
          pw.SizedBox(
            width: 85,
            child: pw.Text(label,
                style: const pw.TextStyle(
                    color: PdfColors.grey700, fontSize: 8)),
          ),
          pw.Text(': ',
              style: const pw.TextStyle(color: PdfColors.grey700, fontSize: 8)),
          pw.Expanded(
            child: pw.Text(value,
                style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold, fontSize: 8)),
          ),
        ]),
      );

  pw.Widget _pdfSectionHeader(String title, PdfColor color) => pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration:
            pw.BoxDecoration(color: color, borderRadius: pw.BorderRadius.circular(3)),
        child: pw.Text(title,
            style: pw.TextStyle(
                color: PdfColors.white,
                fontWeight: pw.FontWeight.bold,
                fontSize: 9)),
      );

  pw.Widget _pdfTable(List<BundleLineItem> items, {required bool isEarning}) {
    final accentColor = isEarning
        ? PdfColor.fromHex('#1565c0')
        : PdfColor.fromHex('#b71c1c');

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      columnWidths: {
        0: const pw.FlexColumnWidth(3),
        1: const pw.FlexColumnWidth(1.5),
      },
      children: [
        // Header row
        pw.TableRow(
          decoration: pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            _pdfCell('Description', header: true),
            _pdfCell('Amount (NGN)', header: true, align: pw.TextAlign.right),
          ],
        ),
        // Data rows
        ...items.asMap().entries.map((entry) => pw.TableRow(
              decoration: entry.key.isEven
                  ? const pw.BoxDecoration(color: PdfColors.white)
                  : pw.BoxDecoration(color: PdfColors.grey50),
              children: [
                _pdfCell(entry.value.description),
                _pdfCell(
                  NumberFormatter.formatCurrencyPDF(entry.value.amount),
                  align: pw.TextAlign.right,
                  color: accentColor,
                ),
              ],
            )),
        // Total row
        pw.TableRow(
          decoration: pw.BoxDecoration(color: PdfColors.grey100),
          children: [
            _pdfCell(isEarning ? 'TOTAL EARNINGS' : 'TOTAL DEDUCTIONS',
                bold: true),
            _pdfCell(
              NumberFormatter.formatCurrencyPDF(
                  items.fold(0.0, (s, e) => s + e.amount)),
              bold: true,
              align: pw.TextAlign.right,
              color: accentColor,
            ),
          ],
        ),
      ],
    );
  }

  pw.Widget _pdfCell(
    String text, {
    bool header = false,
    bool bold = false,
    pw.TextAlign align = pw.TextAlign.left,
    PdfColor? color,
  }) =>
      pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        child: pw.Text(text,
            textAlign: align,
            style: pw.TextStyle(
              fontSize: header ? 8 : 9,
              fontWeight: (header || bold)
                  ? pw.FontWeight.bold
                  : pw.FontWeight.normal,
              color: color ?? (header ? PdfColors.grey800 : PdfColors.black),
            )),
      );

  // ── UI ─────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Payslip Bundle',
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

  Widget _buildBody() => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildInfoBanner(),
          const SizedBox(height: 16),
          _buildPresets(),
          const SizedBox(height: 16),
          _buildPeriodList(),
          if (_error != null) ...[
            const SizedBox(height: 12),
            _buildInlineError(),
          ],
          if (_bundle != null) ...[
            const SizedBox(height: 16),
            _buildBundlePreview(),
          ],
          const SizedBox(height: 16),
          _buildActionButtons(),
          const SizedBox(height: 32),
        ],
      );

  Widget _buildInfoBanner() => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.blue[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blue.shade200),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Multi-Month Payslip Bundle',
                  style: TextStyle(
                      color: Colors.blue[800],
                      fontWeight: FontWeight.bold,
                      fontSize: 13)),
              const SizedBox(height: 4),
              Text(
                'Select the months you need and download as a single PDF. '
                'Banks and mortgage lenders typically require the last 3–6 months payslips.',
                style:
                    TextStyle(color: Colors.blue[700], fontSize: 12),
              ),
            ]),
          ),
        ]),
      );

  Widget _buildPresets() => Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Quick Select',
                style:
                    TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 10),
            Row(children: [
              _presetBtn('Last 3', 3),
              const SizedBox(width: 8),
              _presetBtn('Last 6', 6),
              const SizedBox(width: 8),
              _presetBtn('Last 12', 12),
              const Spacer(),
              TextButton(
                onPressed: () => setState(() => _selected.clear()),
                child: Text('Clear',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12)),
              ),
            ]),
          ]),
        ),
      );

  Widget _presetBtn(String label, int n) {
    final canTake  = _periods.length >= n;
    final isActive = canTake &&
        _selected.length == n &&
        _periods.take(n).every((p) => _selected.contains(p.periodId));

    return OutlinedButton(
      onPressed: canTake ? () => _applyPreset(n) : null,
      style: OutlinedButton.styleFrom(
        foregroundColor:
            isActive ? Colors.white : AppTheme.primaryColor,
        backgroundColor: isActive ? AppTheme.primaryColor : null,
        side: BorderSide(
            color: isActive ? AppTheme.primaryColor : Colors.grey.shade300),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(label, style: const TextStyle(fontSize: 12)),
    );
  }

  Widget _buildPeriodList() => Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Text('Select Months',
                  style:
                      TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const Spacer(),
              Text('${_selected.length} selected',
                  style: TextStyle(
                      color: _selected.isEmpty
                          ? Colors.grey[400]
                          : AppTheme.primaryColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 12)),
            ]),
            const SizedBox(height: 8),
            ...(_periods.take(24).map((p) {
              final isChecked = _selected.contains(p.periodId);
              return CheckboxListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: Text(p.label,
                    style: const TextStyle(fontSize: 13)),
                value: isChecked,
                activeColor: AppTheme.primaryColor,
                onChanged: (_) {
                  setState(() {
                    if (isChecked) {
                      _selected.remove(p.periodId);
                    } else {
                      if (_selected.length >= 12) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Maximum 12 months per bundle'),
                              behavior: SnackBarBehavior.floating),
                        );
                        return;
                      }
                      _selected.add(p.periodId);
                    }
                    _bundle = null;
                  });
                },
              );
            })),
          ]),
        ),
      );

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

  Widget _buildBundlePreview() {
    final s = _bundle!.bundleSummary!;
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.green[50],
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(Icons.check_circle_outline, color: Colors.green[700], size: 18),
            const SizedBox(width: 8),
            Text('Bundle Ready — ${s.payslipCount} payslip${s.payslipCount == 1 ? '' : 's'}',
                style: TextStyle(
                    color: Colors.green[800],
                    fontWeight: FontWeight.bold,
                    fontSize: 14)),
          ]),
          const SizedBox(height: 10),
          Text(s.dateRange,
              style: TextStyle(color: Colors.green[700], fontSize: 12)),
          const SizedBox(height: 8),
          Row(children: [
            _previewStat('Total Gross', s.totalGross, Colors.blue[700]!),
            _previewStat('Total Deducted', s.totalDeductions, Colors.red[700]!),
            _previewStat('Total Net', s.totalNet, Colors.green[700]!),
          ]),
        ]),
      ),
    );
  }

  Widget _previewStat(String label, double amount, Color color) => Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 10)),
          Text(NumberFormatter.formatCurrency(amount),
              style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ]),
      );

  Widget _buildActionButtons() => Column(children: [
        // Preview bundle
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _selected.isNotEmpty && !_fetchingBundle && !_generatingPdf
                ? _fetchBundle
                : null,
            icon: _fetchingBundle
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.visibility_outlined, size: 18),
            label: Text(_fetchingBundle ? 'Loading...' : 'Preview Bundle'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),
        const SizedBox(height: 10),
        // Generate PDF
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _bundle != null && !_generatingPdf && !_fetchingBundle
                ? _generatePdf
                : null,
            icon: _generatingPdf
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.picture_as_pdf, size: 18),
            label: Text(_generatingPdf ? 'Generating PDF...' : 'Download PDF Bundle'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[700],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),
      ]);
}
