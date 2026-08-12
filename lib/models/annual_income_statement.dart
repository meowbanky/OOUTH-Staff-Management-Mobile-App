class StatementEmployee {
  final String name;
  final String staffId;
  final String ppno;
  final String department;
  final String salaryType;
  final String gradeLevel;
  final String gender;

  StatementEmployee({
    required this.name,
    required this.staffId,
    required this.ppno,
    required this.department,
    required this.salaryType,
    required this.gradeLevel,
    required this.gender,
  });

  factory StatementEmployee.fromJson(Map<String, dynamic> j) =>
      StatementEmployee(
        name:        j['name']?.toString() ?? '',
        staffId:     j['staff_id']?.toString() ?? '',
        ppno:        j['ppno']?.toString() ?? '',
        department:  j['department']?.toString() ?? '',
        salaryType:  j['salary_type']?.toString() ?? '',
        gradeLevel:  j['grade_level']?.toString() ?? '',
        gender:      j['gender']?.toString() ?? '',
      );
}

class StatementSummary {
  final int monthsPaid;
  final double totalGross;
  final double totalDeductions;
  final double totalNet;
  final double avgMonthlyGross;
  final double avgMonthlyNet;

  StatementSummary({
    required this.monthsPaid,
    required this.totalGross,
    required this.totalDeductions,
    required this.totalNet,
    required this.avgMonthlyGross,
    required this.avgMonthlyNet,
  });

  factory StatementSummary.fromJson(Map<String, dynamic> j) => StatementSummary(
        monthsPaid:       (j['months_paid'] as num).toInt(),
        totalGross:       (j['total_gross'] as num).toDouble(),
        totalDeductions:  (j['total_deductions'] as num).toDouble(),
        totalNet:         (j['total_net'] as num).toDouble(),
        avgMonthlyGross:  (j['avg_monthly_gross'] as num).toDouble(),
        avgMonthlyNet:    (j['avg_monthly_net'] as num).toDouble(),
      );
}

// One earning or deduction type across all 12 months
class StatementLineType {
  final int edId;
  final String description;
  final Map<int, double> months; // 1..12 → amount
  final double annualTotal;

  StatementLineType({
    required this.edId,
    required this.description,
    required this.months,
    required this.annualTotal,
  });

  factory StatementLineType.fromJson(Map<String, dynamic> j) {
    final rawMonths = j['months'] as Map<String, dynamic>;
    final months = <int, double>{};
    for (var mn = 1; mn <= 12; mn++) {
      months[mn] = (rawMonths[mn.toString()] as num?)?.toDouble() ?? 0.0;
    }
    return StatementLineType(
      edId:        (j['ed_id'] as num).toInt(),
      description: j['description']?.toString() ?? '',
      months:      months,
      annualTotal: (j['annual_total'] as num).toDouble(),
    );
  }
}

class StatementMonth {
  final int monthNum;
  final String monthName;
  final bool paid;
  final double gross;
  final double deductions;
  final double net;

  StatementMonth({
    required this.monthNum,
    required this.monthName,
    required this.paid,
    required this.gross,
    required this.deductions,
    required this.net,
  });

  factory StatementMonth.fromJson(Map<String, dynamic> j) => StatementMonth(
        monthNum:    (j['month_num'] as num).toInt(),
        monthName:   j['month_name']?.toString() ?? '',
        paid:        j['paid'] == true || j['paid'] == 1,
        gross:       (j['gross'] as num).toDouble(),
        deductions:  (j['deductions'] as num).toDouble(),
        net:         (j['net'] as num).toDouble(),
      );
}

class AnnualIncomeStatement {
  final StatementEmployee employee;
  final int year;
  final List<String> availableYears;
  final StatementSummary summary;
  final List<StatementLineType> earnings;
  final List<StatementLineType> deductions;
  final List<StatementMonth> monthlyTotals;

  AnnualIncomeStatement({
    required this.employee,
    required this.year,
    required this.availableYears,
    required this.summary,
    required this.earnings,
    required this.deductions,
    required this.monthlyTotals,
  });

  factory AnnualIncomeStatement.fromJson(Map<String, dynamic> json) {
    final d = json['data'] as Map<String, dynamic>;
    return AnnualIncomeStatement(
      employee:      StatementEmployee.fromJson(d['employee']),
      year:          (d['year'] as num).toInt(),
      availableYears: (d['available_years'] as List).map((e) => e.toString()).toList(),
      summary:       StatementSummary.fromJson(d['summary']),
      earnings:      (d['earnings'] as List)
          .map((e) => StatementLineType.fromJson(e))
          .toList(),
      deductions:    (d['deductions'] as List)
          .map((e) => StatementLineType.fromJson(e))
          .toList(),
      monthlyTotals: (d['monthly_totals'] as List)
          .map((e) => StatementMonth.fromJson(e))
          .toList(),
    );
  }
}
