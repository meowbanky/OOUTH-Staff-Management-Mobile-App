import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/salary_certificate.dart';
import '../utils/salary_scheme.dart';
import '../providers/auth_provider.dart';
import '../services/salary_certificate_service.dart';
import '../utils/app_theme.dart';
import '../utils/number_formatter.dart';

class SalaryCertificateScreen extends StatefulWidget {
  const SalaryCertificateScreen({super.key});

  @override
  State<SalaryCertificateScreen> createState() =>
      _SalaryCertificateScreenState();
}

class _SalaryCertificateScreenState extends State<SalaryCertificateScreen> {
  late final SalaryCertificateService _service;
  late final String _staffId;

  final _purposeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  SalaryCertificate? _data;
  bool _isLoading = false;
  bool _isExporting = false;
  String? _error;

  static const _purposeOptions = [
    'Bank Loan Application',
    'Mortgage / Housing Loan',
    'Salary Advance',
    'Visa Application',
    'School Fees Payment',
    'Personal / Other',
  ];

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    _staffId = auth.user?.id ?? '';
    _service = SalaryCertificateService(auth.token ?? '');
  }

  @override
  void dispose() {
    _purposeController.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _error = null;
      _data = null;
    });
    try {
      final cert = await _service.getCertificate(
        staffId: _staffId,
        purpose: _purposeController.text.trim(),
      );
      setState(() => _data = cert);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ── PDF ─────────────────────────────────────────────────────────────────────
  Future<void> _exportPdf() async {
    if (_data == null) return;
    setState(() => _isExporting = true);
    try {
      final logoL = await _loadAsset('assets/images/ogun_logo.png');
      final logoR = await _loadAsset('assets/images/oouth_logo.png');
      final wm = await _loadAsset('assets/images/oouth_logo_watermark.png');

      final cert = _data!;
      final emp = cert.employee;
      final sal = cert.salary;
      final pdf = pw.Document();

      pdf.addPage(pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 50, vertical: 40),
        build: (ctx) => pw.Stack(children: [
          // Watermark
          pw.Positioned.fill(
            child: pw.Center(
              child: pw.Opacity(
                opacity: 0.07,
                child: pw.Image(pw.MemoryImage(wm), width: 350),
              ),
            ),
          ),
          pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                // Header
                pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Image(pw.MemoryImage(logoL), width: 60, height: 60),
                      pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.center,
                          children: [
                            pw.Text(
                                'OLABISI ONABANJO UNIVERSITY TEACHING HOSPITAL',
                                style: pw.TextStyle(
                                    fontSize: 11,
                                    fontWeight: pw.FontWeight.bold)),
                            pw.Text('SAGAMU, OGUN STATE, NIGERIA',
                                style: pw.TextStyle(
                                    fontSize: 9,
                                    fontWeight: pw.FontWeight.bold)),
                            pw.Text('Tel: 037-640491  |  oouthsalary.com.ng',
                                style: const pw.TextStyle(
                                    fontSize: 8, color: PdfColors.grey700)),
                          ]),
                      pw.Image(pw.MemoryImage(logoR), width: 60, height: 60),
                    ]),
                pw.Divider(thickness: 2, color: PdfColors.blue900),
                pw.SizedBox(height: 6),

                // Title
                pw.Center(
                    child: pw.Text('SALARY CERTIFICATE',
                        style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.bold,
                            decoration: pw.TextDecoration.underline))),
                pw.SizedBox(height: 16),

                // Reference & date
                pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                          'Ref: OOUTH/SAL/CERT/${emp.staffId}/${DateTime.now().year}',
                          style: const pw.TextStyle(
                              fontSize: 9, color: PdfColors.grey700)),
                      pw.Text('Date: ${cert.generatedDate}',
                          style: const pw.TextStyle(
                              fontSize: 9, color: PdfColors.grey700)),
                    ]),
                pw.SizedBox(height: 18),

                // Purpose line
                if (cert.purpose.isNotEmpty) ...[
                  pw.RichText(
                      text: pw.TextSpan(children: [
                    pw.TextSpan(
                        text: 'TO WHOM IT MAY CONCERN / ',
                        style: pw.TextStyle(
                            fontSize: 10, fontWeight: pw.FontWeight.bold)),
                    pw.TextSpan(
                        text: cert.purpose.toUpperCase(),
                        style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.blue900)),
                  ])),
                  pw.SizedBox(height: 14),
                ],

                // Body letter
                pw.Text(
                  'This is to certify that the under-mentioned staff is a bona-fide employee of '
                  'Olabisi Onabanjo University Teaching Hospital (OOUTH), Sagamu, Ogun State, '
                  'and that the following details are correct as at the date of this certificate:',
                  style: const pw.TextStyle(fontSize: 10),
                ),
                pw.SizedBox(height: 16),

                // Details table
                _pdfTable([
                  ['Full Name', emp.name],
                  ['Staff ID', emp.staffId],
                  if (emp.ppno.isNotEmpty) ['Pension Pin (PPNO)', emp.ppno],
                  ['Department', emp.department],
                  ['Salary Scale', emp.salaryType],
                  if (emp.gradeStep.isNotEmpty)
                    [gradeStepLabel(emp.salaryType), emp.gradeStep],
                  if (emp.levelOfAppointment != null)
                    ['Designation', emp.levelOfAppointment!],
                  if (emp.employmentDate != null)
                    ['Date of First Appointment', emp.employmentDate!],
                  if (emp.confirmationDate != null)
                    ['Date of Confirmation', emp.confirmationDate!],
                ]),
                pw.SizedBox(height: 16),

                // Salary section
                pw.Text('SALARY DETAILS',
                    style: pw.TextStyle(
                        fontSize: 10, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 6),
                if (sal.period != null)
                  pw.Text('As at ${sal.period}',
                      style: const pw.TextStyle(
                          fontSize: 9, color: PdfColors.grey700)),
                pw.SizedBox(height: 6),
                _pdfTable([
                  [
                    'Gross Monthly Salary',
                    '₦${NumberFormatter.formatCurrencyPDF(sal.gross)}'
                  ],
                  [
                    'Total Monthly Deductions',
                    '₦${NumberFormatter.formatCurrencyPDF(sal.deductions)}'
                  ],
                  [
                    'Net Monthly Salary',
                    '₦${NumberFormatter.formatCurrencyPDF(sal.net)}'
                  ],
                ], highlightLast: true),
                pw.SizedBox(height: 20),

                // Closing statement
                pw.Text(
                  'The above information has been provided in good faith based on records available '
                  'at the time of issue. This certificate is issued without any obligation or '
                  'liability on the part of the Hospital.',
                  style:
                      const pw.TextStyle(fontSize: 9, color: PdfColors.grey800),
                ),
                pw.SizedBox(height: 30),

                // Signature block
                pw.Row(children: [
                  pw.Expanded(
                      child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                        pw.Container(
                            height: 1, color: PdfColors.black, width: 200),
                        pw.SizedBox(height: 4),
                        pw.Text('Authorised Signatory',
                            style: const pw.TextStyle(fontSize: 9)),
                        pw.Text('Director of Finance & Accounts',
                            style: pw.TextStyle(
                                fontSize: 9, fontWeight: pw.FontWeight.bold)),
                        pw.Text('OOUTH, Sagamu',
                            style: const pw.TextStyle(fontSize: 9)),
                      ])),
                  pw.Expanded(
                      child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                        pw.Container(
                            height: 1, color: PdfColors.black, width: 200),
                        pw.SizedBox(height: 4),
                        pw.Text('Official Stamp & Date',
                            style: const pw.TextStyle(fontSize: 9)),
                      ])),
                ]),

                pw.Spacer(),
                pw.Divider(thickness: 0.5),
                pw.Center(
                    child: pw.Text(
                  'This certificate was generated electronically via the OOUTH Salary Management System on ${cert.generatedDate}.',
                  style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey),
                  textAlign: pw.TextAlign.center,
                )),
              ]),
        ]),
      ));

      final bytes = await pdf.save();
      final tempDir = await getTemporaryDirectory();
      final file =
          File('${tempDir.path}/OOUTH_Salary_Certificate_${emp.staffId}.pdf');
      await file.writeAsBytes(bytes);
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'OOUTH Salary Certificate — ${emp.name}',
      );
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

  // ── PDF helpers ─────────────────────────────────────────────────────────────
  Future<Uint8List> _loadAsset(String path) async {
    final data = await rootBundle.load(path);
    return data.buffer.asUint8List();
  }

  pw.Widget _pdfTable(List<List<String>> rows, {bool highlightLast = false}) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
      columnWidths: {
        0: const pw.FlexColumnWidth(2),
        1: const pw.FlexColumnWidth(3),
      },
      children: rows.asMap().entries.map((entry) {
        final isLast = highlightLast && entry.key == rows.length - 1;
        return pw.TableRow(
          decoration: isLast
              ? const pw.BoxDecoration(color: PdfColors.lightBlue50)
              : (entry.key.isEven
                  ? const pw.BoxDecoration(color: PdfColors.grey100)
                  : null),
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(5),
              child: pw.Text(entry.value[0],
                  style: pw.TextStyle(
                      fontSize: 9,
                      fontWeight:
                          isLast ? pw.FontWeight.bold : pw.FontWeight.normal)),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(5),
              child: pw.Text(entry.value[1],
                  style: pw.TextStyle(
                      fontSize: 9,
                      fontWeight:
                          isLast ? pw.FontWeight.bold : pw.FontWeight.normal)),
            ),
          ],
        );
      }).toList(),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Salary Certificate',
            style: TextStyle(color: Colors.white)),
        backgroundColor: AppTheme.primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (_data != null && !_isExporting)
            IconButton(
              icon: const Icon(Icons.download, color: Colors.white),
              tooltip: 'Download PDF',
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          _buildInfoBanner(),
          const SizedBox(height: 16),
          _buildPurposeForm(),
          if (_isLoading) ...[
            const SizedBox(height: 32),
            const CircularProgressIndicator(),
          ],
          if (_error != null) ...[
            const SizedBox(height: 16),
            _buildError(),
          ],
          if (_data != null) ...[
            const SizedBox(height: 20),
            _buildCertificatePreview(_data!),
          ],
        ]),
      ),
    );
  }

  // ── Info banner ────────────────────────────────────────────────────────────
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
              child: Text(
            'A salary certificate is an official document confirming your employment and '
            'current salary at OOUTH. It is commonly required for bank loans, visa '
            'applications, and other financial purposes.',
            style: TextStyle(color: Colors.blue[800], fontSize: 13),
          )),
        ]),
      );

  // ── Purpose form ───────────────────────────────────────────────────────────
  Widget _buildPurposeForm() => Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Select Purpose',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'Purpose of Certificate',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                  prefixIcon: const Icon(Icons.assignment_outlined),
                ),
                items: _purposeOptions
                    .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                    .toList(),
                onChanged: (val) {
                  if (val != null) _purposeController.text = val;
                },
                validator: (_) => _purposeController.text.isEmpty
                    ? 'Please select a purpose'
                    : null,
              ),
              const SizedBox(height: 8),
              Text('Or type a custom purpose:',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _purposeController,
                decoration: InputDecoration(
                  hintText: 'e.g. Bank Loan Application',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                  prefixIcon: const Icon(Icons.edit_outlined),
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Purpose is required'
                    : null,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: _isLoading ? null : _generate,
                  icon: const Icon(Icons.workspace_premium_outlined,
                      color: Colors.white),
                  label: const Text('Generate Certificate',
                      style: TextStyle(color: Colors.white, fontSize: 15)),
                ),
              ),
            ]),
          ),
        ),
      );

  // ── Error ──────────────────────────────────────────────────────────────────
  Widget _buildError() => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.red[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Row(children: [
          const Icon(Icons.error_outline, color: Colors.red),
          const SizedBox(width: 10),
          Expanded(
              child: Text(_error!, style: const TextStyle(color: Colors.red))),
        ]),
      );

  // ── Certificate preview card ───────────────────────────────────────────────
  Widget _buildCertificatePreview(SalaryCertificate cert) {
    final emp = cert.employee;
    final sal = cert.salary;

    return Column(children: [
      // Action bar
      Row(children: [
        const Icon(Icons.check_circle, color: Colors.green, size: 20),
        const SizedBox(width: 6),
        const Expanded(
          child: Text('Certificate ready — tap download to export PDF',
              style:
                  TextStyle(color: Colors.green, fontWeight: FontWeight.w600)),
        ),
        TextButton.icon(
          onPressed: _isExporting ? null : _exportPdf,
          icon: const Icon(Icons.picture_as_pdf),
          label: const Text('Export PDF'),
        ),
      ]),
      const SizedBox(height: 12),

      // Preview card styled like a certificate
      Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade300),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.15),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(children: [
          // Certificate header strip
          Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: Row(children: [
              const Icon(Icons.workspace_premium,
                  color: Colors.amber, size: 28),
              const SizedBox(width: 12),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    const Text('SALARY CERTIFICATE',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            letterSpacing: 1)),
                    Text('Generated: ${cert.generatedDate}',
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 11)),
                  ])),
            ]),
          ),

          // Purpose chip
          if (cert.purpose.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.amber[50],
              child: Row(children: [
                Icon(Icons.label_outline, size: 14, color: Colors.amber[800]),
                const SizedBox(width: 6),
                Text('Purpose: ${cert.purpose}',
                    style: TextStyle(
                        color: Colors.amber[800],
                        fontWeight: FontWeight.w600,
                        fontSize: 12)),
              ]),
            ),

          // Employee details
          Padding(
            padding: const EdgeInsets.all(16),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _sectionLabel('Employee Details'),
              const SizedBox(height: 8),
              _detailRow('Full Name', emp.name, bold: true),
              _detailRow('Staff ID', emp.staffId),
              _detailRow('Department', emp.department),
              _detailRow('Salary Scale', emp.salaryType),
              if (emp.gradeStep.isNotEmpty)
                _detailRow(gradeStepLabel(emp.salaryType), emp.gradeStep),
              if (emp.levelOfAppointment != null)
                _detailRow('Designation', emp.levelOfAppointment!),
              if (emp.employmentDate != null)
                _detailRow('First Appointment', emp.employmentDate!),
              if (emp.confirmationDate != null)
                _detailRow('Date of Confirmation', emp.confirmationDate!),

              const SizedBox(height: 16),
              _sectionLabel('Salary Details'),
              if (sal.period != null) ...[
                const SizedBox(height: 4),
                Text('As at ${sal.period}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 11)),
              ],
              const SizedBox(height: 8),
              _salaryRow('Gross Monthly Salary', sal.gross, Colors.blue[700]!),
              _salaryRow('Total Deductions', sal.deductions, Colors.red[600]!),
              const Divider(height: 16),
              _salaryRow('Net Monthly Salary', sal.net, Colors.green[700]!,
                  large: true),

              const SizedBox(height: 20),
              // Official note
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.security, size: 14, color: Colors.grey[500]),
                      const SizedBox(width: 6),
                      Expanded(
                          child: Text(
                        'This certificate is valid only with the official signature and stamp '
                        'of the Director of Finance & Accounts, OOUTH.',
                        style: TextStyle(color: Colors.grey[600], fontSize: 11),
                      )),
                    ]),
              ),
            ]),
          ),
        ]),
      ),
    ]);
  }

  Widget _sectionLabel(String label) => Text(
        label,
        style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: AppTheme.primaryColor),
      );

  Widget _detailRow(String label, String value, {bool bold = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(
            width: 150,
            child: Text(label,
                style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          ),
          Expanded(
            child: Text(value,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
          ),
        ]),
      );

  Widget _salaryRow(String label, double amount, Color color,
          {bool large = false}) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child:
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(label,
              style: TextStyle(
                  fontSize: large ? 14 : 13,
                  fontWeight: large ? FontWeight.bold : FontWeight.normal)),
          Text(NumberFormatter.formatCurrency(amount),
              style: TextStyle(
                  color: color,
                  fontSize: large ? 15 : 13,
                  fontWeight: large ? FontWeight.bold : FontWeight.w600)),
        ]),
      );
}
