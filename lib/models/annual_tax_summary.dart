class TaxDeductionItem {
  final String description;
  final double total;
  final double pctOfGross;

  TaxDeductionItem({
    required this.description,
    required this.total,
    required this.pctOfGross,
  });

  factory TaxDeductionItem.fromJson(Map<String, dynamic> j) => TaxDeductionItem(
        description: j['description']?.toString() ?? '',
        total: (j['total'] as num?)?.toDouble() ?? 0,
        pctOfGross: (j['pct_of_gross'] as num?)?.toDouble() ?? 0,
      );
}

class EarningItem {
  final String description;
  final double total;

  EarningItem({required this.description, required this.total});

  factory EarningItem.fromJson(Map<String, dynamic> j) => EarningItem(
        description: j['description']?.toString() ?? '',
        total: (j['total'] as num?)?.toDouble() ?? 0,
      );
}

class MonthlyRow {
  final int periodId;
  final String month;
  final double gross;
  final double deductions;
  final double net;

  MonthlyRow({
    required this.periodId,
    required this.month,
    required this.gross,
    required this.deductions,
    required this.net,
  });

  factory MonthlyRow.fromJson(Map<String, dynamic> j) => MonthlyRow(
        periodId: (j['period_id'] as num?)?.toInt() ?? 0,
        month: j['month']?.toString() ?? '',
        gross: (j['gross'] as num?)?.toDouble() ?? 0,
        deductions: (j['deductions'] as num?)?.toDouble() ?? 0,
        net: (j['net'] as num?)?.toDouble() ?? 0,
      );
}

class TaxSummary {
  final double totalGross;
  final double totalDeductions;
  final double totalNet;
  final double totalPaye;
  final double totalNhf;
  final double totalPension;
  final double effectiveTaxRate;

  TaxSummary({
    required this.totalGross,
    required this.totalDeductions,
    required this.totalNet,
    required this.totalPaye,
    required this.totalNhf,
    required this.totalPension,
    required this.effectiveTaxRate,
  });

  factory TaxSummary.fromJson(Map<String, dynamic> j) => TaxSummary(
        totalGross: (j['total_gross'] as num?)?.toDouble() ?? 0,
        totalDeductions: (j['total_deductions'] as num?)?.toDouble() ?? 0,
        totalNet: (j['total_net'] as num?)?.toDouble() ?? 0,
        totalPaye: (j['total_paye'] as num?)?.toDouble() ?? 0,
        totalNhf: (j['total_nhf'] as num?)?.toDouble() ?? 0,
        totalPension: (j['total_pension'] as num?)?.toDouble() ?? 0,
        effectiveTaxRate: (j['effective_tax_rate'] as num?)?.toDouble() ?? 0,
      );
}

class EmployeeTaxInfo {
  final String name;
  final String staffId;
  final String gradeStep;

  /// Pay scale the grade belongs to, e.g. 'CONHESS'. Empty when the API
  /// could not determine it; see utils/salary_scheme.dart.
  final String gradeScheme;
  final String department;

  EmployeeTaxInfo({
    required this.name,
    required this.staffId,
    required this.gradeStep,
    required this.gradeScheme,
    required this.department,
  });

  factory EmployeeTaxInfo.fromJson(Map<String, dynamic> j) => EmployeeTaxInfo(
        name: j['name']?.toString() ?? '',
        staffId: j['staff_id']?.toString() ?? '',
        gradeStep: j['grade_step']?.toString() ?? '',
        gradeScheme: j['grade_scheme']?.toString() ?? '',
        department: j['department']?.toString() ?? '',
      );
}

class AnnualTaxSummary {
  final EmployeeTaxInfo employee;
  final int year;
  final List<int> availableYears;
  final int monthsCount;
  final TaxSummary summary;
  final List<EarningItem> earningsBreakdown;
  final List<TaxDeductionItem> deductionsBreakdown;
  final List<MonthlyRow> monthlyBreakdown;

  AnnualTaxSummary({
    required this.employee,
    required this.year,
    required this.availableYears,
    required this.monthsCount,
    required this.summary,
    required this.earningsBreakdown,
    required this.deductionsBreakdown,
    required this.monthlyBreakdown,
  });

  factory AnnualTaxSummary.fromJson(Map<String, dynamic> json) {
    final d = json['data'] as Map<String, dynamic>;
    return AnnualTaxSummary(
      employee: EmployeeTaxInfo.fromJson(d['employee']),
      year: (d['year'] as num?)?.toInt() ?? DateTime.now().year,
      availableYears: (d['available_years'] as List<dynamic>?)
              ?.map((y) => int.tryParse(y.toString()) ?? 0)
              .toList() ??
          [],
      monthsCount: (d['months_count'] as num?)?.toInt() ?? 0,
      summary: TaxSummary.fromJson(d['summary']),
      earningsBreakdown: (d['earnings_breakdown'] as List<dynamic>?)
              ?.map((e) => EarningItem.fromJson(e))
              .toList() ??
          [],
      deductionsBreakdown: (d['deductions_breakdown'] as List<dynamic>?)
              ?.map((e) => TaxDeductionItem.fromJson(e))
              .toList() ??
          [],
      monthlyBreakdown: (d['monthly_breakdown'] as List<dynamic>?)
              ?.map((e) => MonthlyRow.fromJson(e))
              .toList() ??
          [],
    );
  }
}
