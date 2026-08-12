class ComparisonPeriod {
  final int periodId;
  final String label;
  final double gross;
  final double deductions;
  final double net;

  ComparisonPeriod({
    required this.periodId,
    required this.label,
    required this.gross,
    required this.deductions,
    required this.net,
  });

  factory ComparisonPeriod.fromJson(Map<String, dynamic> j) => ComparisonPeriod(
        periodId: (j['period_id'] as num).toInt(),
        label: j['label']?.toString() ?? '',
        gross: (j['gross'] as num).toDouble(),
        deductions: (j['deductions'] as num).toDouble(),
        net: (j['net'] as num).toDouble(),
      );
}

class ComparisonSummaryDiff {
  final double grossDiff;
  final double deductionsDiff;
  final double netDiff;
  final double? grossPct;
  final double? netPct;

  ComparisonSummaryDiff({
    required this.grossDiff,
    required this.deductionsDiff,
    required this.netDiff,
    this.grossPct,
    this.netPct,
  });

  factory ComparisonSummaryDiff.fromJson(Map<String, dynamic> j) =>
      ComparisonSummaryDiff(
        grossDiff: (j['gross_diff'] as num).toDouble(),
        deductionsDiff: (j['deductions_diff'] as num).toDouble(),
        netDiff: (j['net_diff'] as num).toDouble(),
        grossPct: j['gross_pct'] != null ? (j['gross_pct'] as num).toDouble() : null,
        netPct: j['net_pct'] != null ? (j['net_pct'] as num).toDouble() : null,
      );
}

class DiffLine {
  final String description;
  final double amount1;
  final double amount2;
  final double diff;
  final String status; // 'new' | 'removed' | 'increased' | 'decreased' | 'same'

  DiffLine({
    required this.description,
    required this.amount1,
    required this.amount2,
    required this.diff,
    required this.status,
  });

  factory DiffLine.fromJson(Map<String, dynamic> j) => DiffLine(
        description: j['description']?.toString() ?? '',
        amount1: (j['amount_1'] as num).toDouble(),
        amount2: (j['amount_2'] as num).toDouble(),
        diff: (j['diff'] as num).toDouble(),
        status: j['status']?.toString() ?? 'same',
      );
}

class AvailablePeriod {
  final int periodId;
  final String description;
  final String periodYear;

  AvailablePeriod({
    required this.periodId,
    required this.description,
    required this.periodYear,
  });

  String get label => '$description $periodYear';

  factory AvailablePeriod.fromJson(Map<String, dynamic> j) => AvailablePeriod(
        periodId: (j['periodId'] as num).toInt(),
        description: j['description']?.toString() ?? '',
        periodYear: j['periodYear']?.toString() ?? '',
      );
}

class PayslipComparison {
  final String employeeName;
  final String staffId;
  final String department;
  final List<AvailablePeriod> availablePeriods;
  final ComparisonPeriod period1;
  final ComparisonPeriod period2;
  final ComparisonSummaryDiff summaryDiff;
  final List<DiffLine> earningsDiff;
  final List<DiffLine> deductionsDiff;

  PayslipComparison({
    required this.employeeName,
    required this.staffId,
    required this.department,
    required this.availablePeriods,
    required this.period1,
    required this.period2,
    required this.summaryDiff,
    required this.earningsDiff,
    required this.deductionsDiff,
  });

  factory PayslipComparison.fromJson(Map<String, dynamic> json) {
    final d = json['data'] as Map<String, dynamic>;
    final emp = d['employee'] as Map<String, dynamic>;
    return PayslipComparison(
      employeeName: emp['name']?.toString() ?? '',
      staffId: emp['staff_id']?.toString() ?? '',
      department: emp['department']?.toString() ?? '',
      availablePeriods: (d['available_periods'] as List<dynamic>)
          .map((e) => AvailablePeriod.fromJson(e))
          .toList(),
      period1: ComparisonPeriod.fromJson(d['period_1']),
      period2: ComparisonPeriod.fromJson(d['period_2']),
      summaryDiff: ComparisonSummaryDiff.fromJson(d['summary_diff']),
      earningsDiff: (d['earnings_diff'] as List<dynamic>)
          .map((e) => DiffLine.fromJson(e))
          .toList(),
      deductionsDiff: (d['deductions_diff'] as List<dynamic>)
          .map((e) => DiffLine.fromJson(e))
          .toList(),
    );
  }
}
