class BundlePeriod {
  final int periodId;
  final String description;
  final String periodYear;

  BundlePeriod({
    required this.periodId,
    required this.description,
    required this.periodYear,
  });

  String get label => '$description $periodYear';

  factory BundlePeriod.fromJson(Map<String, dynamic> j) => BundlePeriod(
        periodId: (j['periodId'] as num).toInt(),
        description: j['description']?.toString() ?? '',
        periodYear: j['periodYear']?.toString() ?? '',
      );
}

class BundleLineItem {
  final String description;
  final double amount;

  BundleLineItem({required this.description, required this.amount});

  factory BundleLineItem.fromJson(Map<String, dynamic> j) => BundleLineItem(
        description: j['description']?.toString() ?? '',
        amount: (j['amount'] as num).toDouble(),
      );
}

class BundlePayslip {
  final int periodId;
  final String periodLabel;
  final String month;
  final int year;
  final List<BundleLineItem> earnings;
  final List<BundleLineItem> deductions;
  final double gross;
  final double totalDeductions;
  final double net;

  BundlePayslip({
    required this.periodId,
    required this.periodLabel,
    required this.month,
    required this.year,
    required this.earnings,
    required this.deductions,
    required this.gross,
    required this.totalDeductions,
    required this.net,
  });

  factory BundlePayslip.fromJson(Map<String, dynamic> j) => BundlePayslip(
        periodId: (j['period_id'] as num).toInt(),
        periodLabel: j['period_label']?.toString() ?? '',
        month: j['month']?.toString() ?? '',
        year: (j['year'] as num).toInt(),
        earnings: (j['earnings'] as List<dynamic>)
            .map((e) => BundleLineItem.fromJson(e))
            .toList(),
        deductions: (j['deductions'] as List<dynamic>)
            .map((e) => BundleLineItem.fromJson(e))
            .toList(),
        gross: (j['gross'] as num).toDouble(),
        totalDeductions: (j['total_deductions'] as num).toDouble(),
        net: (j['net'] as num).toDouble(),
      );
}

class BundleSummary {
  final int payslipCount;
  final String dateRange;
  final double totalGross;
  final double totalNet;
  final double totalDeductions;

  BundleSummary({
    required this.payslipCount,
    required this.dateRange,
    required this.totalGross,
    required this.totalNet,
    required this.totalDeductions,
  });

  factory BundleSummary.fromJson(Map<String, dynamic> j) => BundleSummary(
        payslipCount: (j['payslip_count'] as num).toInt(),
        dateRange: j['date_range']?.toString() ?? '',
        totalGross: (j['total_gross'] as num).toDouble(),
        totalNet: (j['total_net'] as num).toDouble(),
        totalDeductions: (j['total_deductions'] as num).toDouble(),
      );
}

class BundleEmployee {
  final String name;
  final String staffId;
  final String ppno;
  final String department;
  final String salaryType;
  final String? employmentDate;
  final String? confirmationDate;
  final String gradeLevel;
  final String gender;

  BundleEmployee({
    required this.name,
    required this.staffId,
    required this.ppno,
    required this.department,
    required this.salaryType,
    this.employmentDate,
    this.confirmationDate,
    required this.gradeLevel,
    required this.gender,
  });

  factory BundleEmployee.fromJson(Map<String, dynamic> j) => BundleEmployee(
        name: j['name']?.toString() ?? '',
        staffId: j['staff_id']?.toString() ?? '',
        ppno: j['ppno']?.toString() ?? '',
        department: j['department']?.toString() ?? '',
        salaryType: j['salary_type']?.toString() ?? '',
        employmentDate: j['employment_date']?.toString(),
        confirmationDate: j['confirmation_date']?.toString(),
        gradeLevel: j['grade_level']?.toString() ?? '',
        gender: j['gender']?.toString() ?? '',
      );
}

class PayslipBundle {
  final BundleEmployee employee;
  final List<BundlePeriod> availablePeriods;
  final BundleSummary? bundleSummary;
  final List<BundlePayslip> payslips;

  PayslipBundle({
    required this.employee,
    required this.availablePeriods,
    this.bundleSummary,
    this.payslips = const [],
  });

  factory PayslipBundle.fromJson(Map<String, dynamic> json) {
    final d = json['data'] as Map<String, dynamic>;
    return PayslipBundle(
      employee: BundleEmployee.fromJson(d['employee']),
      availablePeriods: (d['available_periods'] as List<dynamic>)
          .map((e) => BundlePeriod.fromJson(e))
          .toList(),
      bundleSummary: d['bundle_summary'] != null
          ? BundleSummary.fromJson(d['bundle_summary'])
          : null,
      payslips: d['payslips'] != null
          ? (d['payslips'] as List<dynamic>)
              .map((e) => BundlePayslip.fromJson(e))
              .toList()
          : [],
    );
  }
}
