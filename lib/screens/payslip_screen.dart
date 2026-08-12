// lib/screens/payslip_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import '../providers/auth_provider.dart';
import '../services/payslip_service.dart';
import '../models/period.dart';
import '../utils/app_theme.dart';
import '../utils/number_formatter.dart';
import '../utils/salary_scheme.dart';
import 'package:fl_chart/fl_chart.dart';

class PayslipScreen extends StatefulWidget {
  const PayslipScreen({super.key});

  @override
  State<PayslipScreen> createState() => _PayslipScreenState();
}

class _PayslipScreenState extends State<PayslipScreen> {
  late final PayslipService _payslipService;
  Period? _selectedPeriod;
  List<Period> _periods = [];
  Map<String, dynamic>? _payslipData;
  bool _isLoading = false;
  bool _showAnalytics = false;
  Map<String, dynamic>? _previousPayslip;
  bool _isLoadingComparison = false;

  @override
  void initState() {
    super.initState();
    _payslipService = PayslipService(context.read<AuthProvider>());
    _loadPeriods();
  }

  Future<void> _loadPeriods() async {
    try {
      setState(() => _isLoading = true);

      final authProvider = context.read<AuthProvider>();
      if (authProvider.user == null) {
        throw 'User not authenticated';
      }

      final periods = await _payslipService.getPeriods();

      if (mounted) {
        setState(() {
          _periods = periods;
          _selectedPeriod = periods.isNotEmpty ? periods.first : null;
        });

        if (_selectedPeriod != null) {
          await _loadPayslip();
        }
      }
    } catch (e) {
      if (mounted) {
        if (e.toString().contains('User not authenticated')) {
          Navigator.of(context).pushReplacementNamed('/login');
        }
        _showError(e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadPayslip() async {
    if (_selectedPeriod == null) return;

    try {
      setState(() => _isLoading = true);
      final data = await _payslipService.getPayslip(_selectedPeriod!.periodId);
      setState(() => _payslipData = data);
    } catch (e) {
      _showError('Error loading payslip: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<Uint8List> _loadImage(String assetPath) async {
    try {
      final ByteData data = await rootBundle.load(assetPath);
      return data.buffer.asUint8List();
    } catch (e) {
      throw 'Error loading image: $e';
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _downloadPayslip() async {
    if (_payslipData == null) return;

    try {
      setState(() => _isLoading = true);

      // Load images
      final logoBytesL = await _loadImage('assets/images/ogun_logo.png');
      final logoBytesR = await _loadImage('assets/images/oouth_logo.png');
      final watermarkBytes =
          await _loadImage('assets/images/oouth_logo_watermark.png');

      final pdf = pw.Document();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(24),
          build: (context) {
            return pw.Stack(
              children: [
                // Watermark
                pw.Positioned.fill(
                  child: pw.Opacity(
                    opacity: 0.1,
                    child: pw.Center(
                      child: pw.Image(pw.MemoryImage(watermarkBytes)),
                    ),
                  ),
                ),
                // Content
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                  children: [
                    // Header with logos
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Image(pw.MemoryImage(logoBytesL),
                            width: 60, height: 60),
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.center,
                          children: [
                            pw.Text(
                              'OLABISI ONABANJO UNIVERSITY',
                              style: pw.TextStyle(
                                fontSize: 16,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                            pw.Text(
                              'TEACHING HOSPITAL',
                              style: pw.TextStyle(
                                fontSize: 16,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                            pw.Text(
                              'SAGAMU, OGUN STATE',
                              style: pw.TextStyle(
                                fontSize: 16,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        pw.Image(pw.MemoryImage(logoBytesR),
                            width: 60, height: 60),
                      ],
                    ),
                    pw.SizedBox(height: 20),
                    // Period
                    pw.Center(
                      child: pw.Text(
                        'PAYSLIP FOR THE MONTH OF ${_selectedPeriod?.description}',
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),
                    pw.SizedBox(height: 20),
                    // Employee Details
                    pw.Container(
                      padding: const pw.EdgeInsets.all(10),
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(width: 1),
                      ),
                      child: _buildPdfEmployeeInfo(),
                    ),
                    pw.SizedBox(height: 20),
                    // Allowances and Deductions
                    pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Expanded(
                          child: pw.Container(
                            padding: const pw.EdgeInsets.all(10),
                            decoration: pw.BoxDecoration(
                              border: pw.Border.all(width: 1),
                            ),
                            child: _buildPdfAllowances(),
                          ),
                        ),
                        pw.SizedBox(width: 20),
                        pw.Expanded(
                          child: pw.Container(
                            padding: const pw.EdgeInsets.all(10),
                            decoration: pw.BoxDecoration(
                              border: pw.Border.all(width: 1),
                            ),
                            child: _buildPdfDeductions(),
                          ),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 20),
                    // Net Pay
                    pw.Container(
                      padding: const pw.EdgeInsets.all(10),
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(width: 1),
                      ),
                      child: _buildPdfNetPay(),
                    ),
                    // Footer
                    pw.Spacer(),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          'Generated: ${DateTime.now().toString().split(' ')[0]}',
                          style: const pw.TextStyle(
                            fontSize: 8,
                            color: PdfColors.grey,
                          ),
                        ),
                        pw.Text(
                          'Page 1 of 1',
                          style: const pw.TextStyle(
                            fontSize: 8,
                            color: PdfColors.grey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      );

      // Save PDF to temporary file and share
      final bytes = await pdf.save();
      final tempDir = await getTemporaryDirectory();
      final file = File(
          '${tempDir.path}/OOUTH_Payslip_${_selectedPeriod!.description}.pdf');
      await file.writeAsBytes(bytes);

      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'OOUTH Payslip for ${_selectedPeriod!.description}',
      );
    } catch (e) {
      _showError('Error generating PDF: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  pw.Widget _buildPdfEmployeeInfo() {
    final employeeInfo = _payslipData!['employeeInfo'];
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Employee Details',
          style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 10),
        _buildPdfInfoRow('Name', employeeInfo['name'].toString()),
        _buildPdfInfoRow('Staff No.', employeeInfo['staffId'].toString()),
        _buildPdfInfoRow('Dept', employeeInfo['department'].toString()),
        _buildPdfInfoRow('Bank', employeeInfo['bank'].toString()),
        _buildPdfInfoRow('Acct No.', employeeInfo['accountno'].toString()),
        _buildPdfInfoRow(
            gradeStepLabel(employeeInfo['grade_scheme']?.toString()),
            employeeInfo['grade_step'].toString()),
        _buildPdfInfoRow(
            'Salary Structure', employeeInfo['salarytype'].toString()),
      ],
    );
  }

  pw.Widget _buildPdfAllowances() {
    final payrollInfo = _payslipData!['payrollInfo'];
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Allowances',
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 10),
        ...payrollInfo['earnings'].map<pw.Widget>((e) {
          return pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 2),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(e['description'].toString()),
                pw.Text(NumberFormatter.formatCurrencyPDF(e['amount'])),
              ],
            ),
          );
        }).toList(),
        pw.Divider(),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('Gross Salary:',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.Text(NumberFormatter.formatCurrencyPDF(
                payrollInfo['totalEarnings'])),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildPdfDeductions() {
    final payrollInfo = _payslipData!['payrollInfo'];
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Deductions',
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 10),
        ...payrollInfo['deductions'].map<pw.Widget>((e) {
          return pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 2),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(e['description'].toString()),
                pw.Text(NumberFormatter.formatCurrencyPDF(e['amount'])),
              ],
            ),
          );
        }).toList(),
        pw.Divider(),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('Total Deductions:',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.Text(NumberFormatter.formatCurrencyPDF(
                payrollInfo['totalDeductions'])),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildPdfNetPay() {
    final payrollInfo = _payslipData!['payrollInfo'];
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          'NET PAY:',
          style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.Text(
          NumberFormatter.formatCurrencyPDF(payrollInfo['netPay']),
          style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
      ],
    );
  }

  pw.Widget _buildPdfInfoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 120,
            child: pw.Text(
              '$label:',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Expanded(child: pw.Text(value)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthProvider>().user;
    if (user == null) {
      return const Center(
        child: Text('Please login to view payslip'),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payslip', style: TextStyle(color: Colors.white)),
        backgroundColor: AppTheme.primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (_payslipData != null)
            IconButton(
              icon: const Icon(Icons.download, color: Colors.white),
              onPressed: _downloadPayslip,
              tooltip: 'Download Payslip',
            ),
          IconButton(
            icon: const Icon(Icons.analytics, color: Colors.white),
            onPressed: () {
              setState(() {
                _showAnalytics = !_showAnalytics;
              });
              if (_showAnalytics && _previousPayslip == null) {
                _loadPreviousPayslip();
              }
            },
            tooltip: 'Analytics',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : RefreshIndicator(
              onRefresh: _loadPayslip,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildPeriodSelector(),
                    if (_payslipData != null) ...[
                      const SizedBox(height: 20),
                      _buildPayslipCard(),
                    ],
                    if (_showAnalytics) ...[
                      const SizedBox(height: 20),
                      _buildAnalyticsSection(),
                    ],
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildAnalyticsSection() {
    if (!_showAnalytics || _payslipData == null) return const SizedBox.shrink();

    final payrollInfo = _payslipData!['payrollInfo'];
    final totalEarnings = (payrollInfo['totalEarnings'] as num).toDouble();
    final totalDeductions = (payrollInfo['totalDeductions'] as num).toDouble();

    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Payslip Analytics',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    setState(() {
                      _showAnalytics = false;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildEarningsDeductionsPieChart(totalEarnings, totalDeductions),
            const Divider(height: 32),
            _buildEarningsBreakdown(),
            const Divider(height: 32),
            _buildDeductionsBreakdown(),
            if (_previousPayslip != null) ...[
              const Divider(height: 32),
              _buildMonthlyComparison(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEarningsDeductionsPieChart(double earnings, double deductions) {
    final total = earnings + deductions;
    return SizedBox(
      height: 200,
      child: Row(
        children: [
          Expanded(
            child: PieChart(
              PieChartData(
                sections: [
                  PieChartSectionData(
                    value: earnings,
                    title: '${((earnings / total) * 100).toStringAsFixed(1)}%',
                    color: Colors.green,
                    titleStyle: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  PieChartSectionData(
                    value: deductions,
                    title:
                        '${((deductions / total) * 100).toStringAsFixed(1)}%',
                    color: Colors.red,
                    titleStyle: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
                sectionsSpace: 2,
                centerSpaceRadius: 40,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLegendItem('Earnings', Colors.green),
              const SizedBox(height: 8),
              _buildLegendItem('Deductions', Colors.red),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _loadPreviousPayslip() async {
    if (_selectedPeriod == null) return;

    try {
      setState(() => _isLoadingComparison = true);

      // Find the index of current period
      final currentIndex = _periods
          .indexWhere((period) => period.periodId == _selectedPeriod!.periodId);

      // Check if there's a previous period
      if (currentIndex < _periods.length - 1) {
        final previousPeriod = _periods[currentIndex + 1];
        final previousData =
            await _payslipService.getPayslip(previousPeriod.periodId);

        setState(() {
          _previousPayslip = previousData;
          _showAnalytics = true;
        });

        // Build monthly comparison section
        _buildMonthlyComparison();
      } else {
        _showError('No previous payslip available for comparison');
      }
    } catch (e) {
      _showError('Error loading comparison data: $e');
    } finally {
      setState(() => _isLoadingComparison = false);
    }
  }

  Widget _buildMonthlyComparison() {
    if (_previousPayslip == null) return const SizedBox.shrink();

    final currentPayroll = _payslipData!['payrollInfo'];
    final previousPayroll = _previousPayslip!['payrollInfo'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Monthly Comparison',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildComparisonRow(
                  'Gross Earnings',
                  previousPayroll['totalEarnings'],
                  currentPayroll['totalEarnings'],
                ),
                const Divider(),
                _buildComparisonRow(
                  'Total Deductions',
                  previousPayroll['totalDeductions'],
                  currentPayroll['totalDeductions'],
                ),
                const Divider(),
                _buildComparisonRow(
                  'Net Pay',
                  previousPayroll['netPay'],
                  currentPayroll['netPay'],
                  isNetPay: true,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildComparisonRow(
    String label,
    dynamic previous,
    dynamic current, {
    bool isNetPay = false,
  }) {
    final prevValue = (previous as num).toDouble();
    final currValue = (current as num).toDouble();
    final difference = currValue - prevValue;
    final percentageChange = (difference / prevValue * 100);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isNetPay ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Previous Month
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Previous',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    NumberFormatter.formatCurrency(prevValue),
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
              // Current Month
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'Current',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    NumberFormatter.formatCurrency(currValue),
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Change Percentage
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Icon(
                difference >= 0 ? Icons.arrow_upward : Icons.arrow_downward,
                color: difference >= 0 ? Colors.green : Colors.red,
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                '${percentageChange.abs().toStringAsFixed(1)}%',
                style: TextStyle(
                  color: difference >= 0 ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                difference >= 0 ? 'Increase' : 'Decrease',
                style: TextStyle(
                  color: difference >= 0 ? Colors.green : Colors.red,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          color: color,
        ),
        const SizedBox(width: 8),
        Text(label),
      ],
    );
  }

  Widget _buildEarningsBreakdown() {
    final payrollInfo = _payslipData!['payrollInfo'];
    final earnings = payrollInfo['earnings'] as List;
    final totalEarnings = payrollInfo['totalEarnings'] as num;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Earnings Breakdown',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 200,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: totalEarnings.toDouble(),
              barGroups: earnings.asMap().entries.map((entry) {
                return BarChartGroupData(
                  x: entry.key,
                  barRods: [
                    BarChartRodData(
                      toY: (entry.value['amount'] as num).toDouble(),
                      color: Colors.green,
                      width: 20,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(4),
                      ),
                    ),
                  ],
                );
              }).toList(),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: RotatedBox(
                          quarterTurns: 1,
                          child: Text(
                            earnings[value.toInt()]['description'].toString(),
                            style: const TextStyle(fontSize: 10),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        NumberFormatter.formatCurrency(value),
                        style: const TextStyle(fontSize: 10),
                      );
                    },
                  ),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDeductionsBreakdown() {
    final payrollInfo = _payslipData!['payrollInfo'];
    final deductions = payrollInfo['deductions'] as List;
    final totalDeductions = payrollInfo['totalDeductions'] as num;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Deductions Breakdown',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 200,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: totalDeductions.toDouble(),
              barGroups: deductions.asMap().entries.map((entry) {
                return BarChartGroupData(
                  x: entry.key,
                  barRods: [
                    BarChartRodData(
                      toY: (entry.value['amount'] as num).toDouble(),
                      color: Colors.red,
                      width: 20,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(4),
                      ),
                    ),
                  ],
                );
              }).toList(),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: RotatedBox(
                          quarterTurns: 1,
                          child: Text(
                            deductions[value.toInt()]['description'].toString(),
                            style: const TextStyle(fontSize: 10),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        NumberFormatter.formatCurrency(value),
                        style: const TextStyle(fontSize: 10),
                      );
                    },
                  ),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPeriodSelector() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Payment Period',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<Period>(
              value: _selectedPeriod,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: _periods
                  .map((period) => DropdownMenuItem(
                        value: period,
                        child: Text(period.description),
                      ))
                  .toList(),
              onChanged: (Period? newValue) {
                setState(() => _selectedPeriod = newValue);
                _loadPayslip();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPayslipCard() {
    final employeeInfo = _payslipData!['employeeInfo'];
    final payrollInfo = _payslipData!['payrollInfo'];

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Employee Information',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const Divider(),
            _buildInfoRow('Name', employeeInfo['name'].toString()),
            _buildInfoRow('Staff ID', employeeInfo['staffId'].toString()),
            _buildInfoRow('Department', employeeInfo['department'].toString()),
            _buildInfoRow('Bank', employeeInfo['bank'].toString()),
            _buildInfoRow('Account No.', employeeInfo['accountno'].toString()),
            _buildInfoRow(
                gradeStepLabel(employeeInfo['grade_scheme']?.toString()),
                employeeInfo['grade_step'].toString()),
            const SizedBox(height: 20),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Container(
                constraints: const BoxConstraints(minWidth: 600),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 300,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Earnings',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const Divider(),
                          ...(payrollInfo['earnings'] as List)
                              .map((e) => _buildAmountRow(
                                    e['description'].toString(),
                                    e['amount'],
                                  )),
                          const Divider(),
                          _buildTotalRow(
                              'Gross Pay', payrollInfo['totalEarnings']),
                        ],
                      ),
                    ),
                    const SizedBox(width: 20),
                    SizedBox(
                      width: 300,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Deductions',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const Divider(),
                          ...(payrollInfo['deductions'] as List)
                              .map((e) => _buildAmountRow(
                                    e['description'].toString(),
                                    e['amount'],
                                  )),
                          const Divider(),
                          _buildTotalRow(
                              'Tot Deduc.', payrollInfo['totalDeductions']),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Divider(thickness: 2),
            _buildTotalRow('Net Pay', payrollInfo['netPay'], isNetPay: true),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildAmountRow(String label, dynamic amount) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(label)),
          Text(NumberFormatter.formatCurrency(amount)),
        ],
      ),
    );
  }

  Widget _buildTotalRow(String label, dynamic amount, {bool isNetPay = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isNetPay ? FontWeight.bold : FontWeight.normal,
              fontSize: isNetPay ? 18 : 16,
            ),
          ),
          Text(
            NumberFormatter.formatCurrency(amount),
            style: TextStyle(
              fontWeight: isNetPay ? FontWeight.bold : FontWeight.normal,
              fontSize: isNetPay ? 18 : 16,
              color: isNetPay ? AppTheme.primaryColor : null,
            ),
          ),
        ],
      ),
    );
  }
}
