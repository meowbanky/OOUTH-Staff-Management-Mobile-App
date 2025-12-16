// lib/screens/pension_report_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import '../providers/auth_provider.dart';
import '../services/pension_service.dart';
import '../models/period.dart';
import '../utils/app_theme.dart';
import '../utils/number_formatter.dart';
import 'package:fl_chart/fl_chart.dart';

class PensionReportScreen extends StatefulWidget {
  const PensionReportScreen({super.key});

  @override
  State<PensionReportScreen> createState() => _PensionReportScreenState();
}

class _PensionReportScreenState extends State<PensionReportScreen> {
  late final PensionService _pensionService;
  Period? _selectedPeriodFrom;
  Period? _selectedPeriodTo;
  List<Period> _periods = [];
  Map<String, dynamic>? _pensionData;
  bool _isLoading = false;
  bool _showAllPeriods = false;

  @override
  void initState() {
    super.initState();
    _pensionService = PensionService(context.read<AuthProvider>());
    _loadPeriods();
  }

  Future<void> _loadPeriods() async {
    try {
      setState(() => _isLoading = true);

      final authProvider = context.read<AuthProvider>();
      if (authProvider.user == null) {
        throw 'User not authenticated';
      }

      final periods = await _pensionService.getPeriods();

      if (mounted) {
        setState(() {
          _periods = periods;
          if (periods.isNotEmpty) {
            _selectedPeriodFrom = periods.last;
            _selectedPeriodTo = periods.first;
          }
        });

        await _loadPensionReport();
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

  Future<void> _loadPensionReport() async {
    try {
      setState(() => _isLoading = true);

      final periodFrom = _showAllPeriods
          ? null
          : (_selectedPeriodFrom != null
              ? int.tryParse(_selectedPeriodFrom!.periodId)
              : null);
      final periodTo = _showAllPeriods
          ? null
          : (_selectedPeriodTo != null
              ? int.tryParse(_selectedPeriodTo!.periodId)
              : null);

      final data = await _pensionService.getPensionReport(
        periodFrom: periodFrom,
        periodTo: periodTo,
      );
      setState(() => _pensionData = data);
    } catch (e) {
      _showError('Error loading pension report: $e');
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

  Future<void> _downloadReport() async {
    if (_pensionData == null) {
      _showError('No pension data available. Please load the report first.');
      return;
    }

    try {
      setState(() => _isLoading = true);

      // Verify data structure before generating PDF
      if (!_pensionData!.containsKey('employeeInfo')) {
        throw Exception('Employee info missing from pension data');
      }
      if (!_pensionData!.containsKey('pensionData')) {
        throw Exception('Pension data array missing');
      }

      // Load images
      final logoBytesL = await _loadImage('assets/images/ogun_logo.png');
      final logoBytesR = await _loadImage('assets/images/oouth_logo.png');
      final watermarkBytes =
          await _loadImage('assets/images/oouth_logo_watermark.png');

      final pdf = pw.Document();

      // Safely extract data with detailed logging
      final employeeInfo =
          _pensionData!['employeeInfo'] as Map<String, dynamic>?;
      final pensionDataRaw = _pensionData!['pensionData'];
      final summary = _pensionData!['summary'] as Map<String, dynamic>? ?? {};

      // Convert pensionData to List with proper type checking
      List<dynamic> pensionList = [];
      if (pensionDataRaw != null) {
        if (pensionDataRaw is List) {
          pensionList = List.from(
              pensionDataRaw); // Create a new list to ensure it's mutable
        } else if (pensionDataRaw is Map) {
          // If it's a map, convert values to list
          print('WARNING: pensionData is a Map, converting to List');
          pensionList = pensionDataRaw.values.toList();
        } else {
          print(
              'ERROR: pensionData is not a List or Map, it is: ${pensionDataRaw.runtimeType}');
          print('pensionDataRaw value: $pensionDataRaw');
        }
      } else {
        print('WARNING: pensionDataRaw is null');
      }

      // Debug: Print pension data
      print('=== PDF Generation Debug ===');
      print('Employee Info: $employeeInfo');
      print('Pension List Length: ${pensionList.length}');
      print('Pension List Type: ${pensionList.runtimeType}');
      print('Pension Data: $pensionList');
      print('Summary: $summary');
      print('===========================');

      if (employeeInfo == null) {
        throw Exception('Employee info is null');
      }

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
                    // Title
                    pw.Center(
                      child: pw.Text(
                        'STAFF PENSION FUND REPORT',
                        style: pw.TextStyle(
                          fontSize: 16,
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
                      child: _buildPdfEmployeeInfo(employeeInfo),
                    ),
                    pw.SizedBox(height: 20),
                    // Pension Data Table
                    pw.Container(
                      padding: const pw.EdgeInsets.all(10),
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(width: 1),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'Pension Contributions',
                            style: pw.TextStyle(
                              fontSize: 14,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.SizedBox(height: 10),
                          pw.Table(
                            border: pw.TableBorder.all(),
                            columnWidths: {
                              0: const pw.FlexColumnWidth(1),
                              1: const pw.FlexColumnWidth(3),
                              2: const pw.FlexColumnWidth(2),
                            },
                            children: [
                              // Header row
                              pw.TableRow(
                                decoration: const pw.BoxDecoration(
                                  color: PdfColors.grey300,
                                ),
                                children: [
                                  _buildPdfTableCell('S/No.', isHeader: true),
                                  _buildPdfTableCell('Period', isHeader: true),
                                  _buildPdfTableCell('Amount (₦)',
                                      isHeader: true),
                                ],
                              ),
                              // Data rows or empty message
                              if (pensionList.isEmpty)
                                pw.TableRow(
                                  children: [
                                    _buildPdfTableCell(''),
                                    _buildPdfTableCell(
                                      'No pension contributions found',
                                      isHeader: false,
                                    ),
                                    _buildPdfTableCell(''),
                                  ],
                                )
                              else
                                ...pensionList.asMap().entries.map((entry) {
                                  final index = entry.key + 1;
                                  final itemRaw = entry.value;

                                  // Ensure item is a Map
                                  Map<String, dynamic> item;
                                  if (itemRaw is Map) {
                                    item = Map<String, dynamic>.from(itemRaw);
                                  } else {
                                    print(
                                        'ERROR: Item at index $index is not a Map: ${itemRaw.runtimeType}');
                                    item = {};
                                  }

                                  // Handle different possible field names
                                  String periodText;
                                  if (item.containsKey('periodText') &&
                                      item['periodText'] != null) {
                                    periodText = item['periodText'].toString();
                                  } else if (item
                                          .containsKey('periodDescription') ||
                                      item.containsKey('periodYear')) {
                                    final desc =
                                        item['periodDescription']?.toString() ??
                                            '';
                                    final year =
                                        item['periodYear']?.toString() ?? '';
                                    periodText = '$desc $year'.trim();
                                    if (periodText.isEmpty) periodText = 'N/A';
                                  } else {
                                    periodText =
                                        'Period ${item['period'] ?? index}';
                                  }

                                  // Get pension amount
                                  num pensionAmount = 0.0;
                                  if (item.containsKey('pensionAmount')) {
                                    pensionAmount =
                                        (item['pensionAmount'] as num?) ?? 0.0;
                                  } else if (item
                                      .containsKey('pension_amount')) {
                                    pensionAmount =
                                        (item['pension_amount'] as num?) ?? 0.0;
                                  }

                                  print(
                                      'PDF Row $index: periodText=$periodText, amount=$pensionAmount');

                                  return pw.TableRow(
                                    children: [
                                      _buildPdfTableCell(index.toString()),
                                      _buildPdfTableCell(periodText),
                                      _buildPdfTableCell(
                                        NumberFormatter.formatCurrencyPDF(
                                            pensionAmount),
                                      ),
                                    ],
                                  );
                                }).toList(),
                            ],
                          ),
                          if (pensionList.isNotEmpty) ...[
                            pw.SizedBox(height: 10),
                            pw.Row(
                              mainAxisAlignment:
                                  pw.MainAxisAlignment.spaceBetween,
                              children: [
                                pw.Text(
                                  'Total Contributions:',
                                  style: pw.TextStyle(
                                    fontWeight: pw.FontWeight.bold,
                                  ),
                                ),
                                pw.Text(
                                  '${summary['totalContributions'] ?? pensionList.length}',
                                  style: pw.TextStyle(
                                    fontWeight: pw.FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            pw.SizedBox(height: 5),
                            pw.Row(
                              mainAxisAlignment:
                                  pw.MainAxisAlignment.spaceBetween,
                              children: [
                                pw.Text(
                                  'Total Amount:',
                                  style: pw.TextStyle(
                                    fontWeight: pw.FontWeight.bold,
                                  ),
                                ),
                                pw.Text(
                                  NumberFormatter.formatCurrencyPDF(
                                    summary['totalAmount'] ?? 0.0,
                                  ),
                                  style: pw.TextStyle(
                                    fontWeight: pw.FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
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
      final periodText = _showAllPeriods
          ? 'All_Periods'
          : '${_selectedPeriodFrom?.description}_to_${_selectedPeriodTo?.description}';
      final file = File('${tempDir.path}/OOUTH_Pension_Report_$periodText.pdf');
      await file.writeAsBytes(bytes);

      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'OOUTH Pension Report',
      );
    } catch (e) {
      _showError('Error generating PDF: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  pw.Widget _buildPdfEmployeeInfo(Map<String, dynamic> employeeInfo) {
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
        if (employeeInfo['pfaName']?.toString().isNotEmpty ?? false)
          _buildPdfInfoRow('PFA Name', employeeInfo['pfaName'].toString()),
        if (employeeInfo['pfaAccountNo']?.toString().isNotEmpty ?? false)
          _buildPdfInfoRow(
              'PFA Account No.', employeeInfo['pfaAccountNo'].toString()),
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

  pw.Widget _buildPdfTableCell(String text, {bool isHeader = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(4),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthProvider>().user;
    if (user == null) {
      return const Center(
        child: Text('Please login to view pension report'),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title:
            const Text('Pension Report', style: TextStyle(color: Colors.white)),
        backgroundColor: AppTheme.primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (_pensionData != null)
            IconButton(
              icon: const Icon(Icons.download, color: Colors.white),
              onPressed: _downloadReport,
              tooltip: 'Download Report',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : RefreshIndicator(
              onRefresh: _loadPensionReport,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildPeriodSelector(),
                    if (_pensionData != null) ...[
                      const SizedBox(height: 20),
                      _buildEmployeeInfoCard(),
                      const SizedBox(height: 20),
                      _buildSummaryCard(),
                      const SizedBox(height: 20),
                      _buildPensionListCard(),
                      const SizedBox(height: 20),
                      _buildChartCard(),
                    ],
                  ],
                ),
              ),
            ),
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
            Row(
              children: [
                Expanded(
                  child: CheckboxListTile(
                    title: const Text('Show All Periods'),
                    value: _showAllPeriods,
                    onChanged: (value) {
                      setState(() {
                        _showAllPeriods = value ?? false;
                      });
                      _loadPensionReport();
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                ),
              ],
            ),
            if (!_showAllPeriods) ...[
              const SizedBox(height: 10),
              const Text(
                'Select Period Range',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('From Period'),
                        const SizedBox(height: 5),
                        DropdownButtonFormField<Period>(
                          value: _selectedPeriodFrom,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                          ),
                          items: _periods
                              .map((period) => DropdownMenuItem(
                                    value: period,
                                    child: Text(
                                      period.description,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ))
                              .toList(),
                          selectedItemBuilder: (BuildContext context) {
                            return _periods.map<Widget>((Period period) {
                              return Text(
                                period.description,
                                overflow: TextOverflow.ellipsis,
                              );
                            }).toList();
                          },
                          onChanged: (Period? newValue) {
                            setState(() => _selectedPeriodFrom = newValue);
                            _loadPensionReport();
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('To Period'),
                        const SizedBox(height: 5),
                        DropdownButtonFormField<Period>(
                          value: _selectedPeriodTo,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                          ),
                          items: _periods
                              .map((period) => DropdownMenuItem(
                                    value: period,
                                    child: Text(
                                      period.description,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ))
                              .toList(),
                          selectedItemBuilder: (BuildContext context) {
                            return _periods.map<Widget>((Period period) {
                              return Text(
                                period.description,
                                overflow: TextOverflow.ellipsis,
                              );
                            }).toList();
                          },
                          onChanged: (Period? newValue) {
                            setState(() => _selectedPeriodTo = newValue);
                            _loadPensionReport();
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmployeeInfoCard() {
    final employeeInfo = _pensionData!['employeeInfo'];
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
            if (employeeInfo['pfaName']?.toString().isNotEmpty ?? false)
              _buildInfoRow('PFA Name', employeeInfo['pfaName'].toString()),
            if (employeeInfo['pfaAccountNo']?.toString().isNotEmpty ?? false)
              _buildInfoRow(
                  'PFA Account No.', employeeInfo['pfaAccountNo'].toString()),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    final summary = _pensionData!['summary'];
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Summary',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const Divider(),
            _buildSummaryRow(
              'Total Contributions',
              summary['totalContributions'].toString(),
            ),
            _buildSummaryRow(
              'Total Amount',
              NumberFormatter.formatCurrency(summary['totalAmount']),
              isTotal: true,
            ),
            _buildSummaryRow(
              'Average Amount',
              NumberFormatter.formatCurrency(summary['averageAmount']),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPensionListCard() {
    final pensionListRaw = _pensionData!['pensionData'];
    final pensionList = pensionListRaw is List ? pensionListRaw : [];
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pension Contributions',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const Divider(),
            if (pensionList.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(
                  child: Text('No pension data found for the selected period.'),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: pensionList.length,
                itemBuilder: (context, index) {
                  final item = pensionList[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(item['periodText'].toString()),
                    trailing: Text(
                      NumberFormatter.formatCurrency(item['pensionAmount']),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartCard() {
    final pensionListRaw = _pensionData!['pensionData'];
    final pensionList = pensionListRaw is List ? pensionListRaw : [];
    if (pensionList.isEmpty) return const SizedBox.shrink();

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Contribution Trend',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 250,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: (pensionList
                          .map((e) => e['pensionAmount'] as num)
                          .reduce((a, b) => a > b ? a : b) *
                      1.1),
                  barGroups: pensionList.asMap().entries.map((entry) {
                    return BarChartGroupData(
                      x: entry.key,
                      barRods: [
                        BarChartRodData(
                          toY: (entry.value['pensionAmount'] as num).toDouble(),
                          color: AppTheme.primaryColor,
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
                          if (value.toInt() >= pensionList.length)
                            return const Text('');
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: RotatedBox(
                              quarterTurns: 1,
                              child: Text(
                                '${value.toInt() + 1}',
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

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 18 : 16,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 18 : 16,
              color: isTotal ? AppTheme.primaryColor : null,
            ),
          ),
        ],
      ),
    );
  }
}
