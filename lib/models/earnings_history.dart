class EarningsYear {
  final int year;
  final int monthsPaid;
  final double gross;
  final double deductions;
  final double net;
  final double avgMonthlyGross;
  final double? growthPct;

  EarningsYear({
    required this.year,
    required this.monthsPaid,
    required this.gross,
    required this.deductions,
    required this.net,
    required this.avgMonthlyGross,
    this.growthPct,
  });

  factory EarningsYear.fromJson(Map<String, dynamic> j) => EarningsYear(
        year: (j['year'] as num).toInt(),
        monthsPaid: (j['months_paid'] as num).toInt(),
        gross: (j['gross'] as num).toDouble(),
        deductions: (j['deductions'] as num).toDouble(),
        net: (j['net'] as num).toDouble(),
        avgMonthlyGross: (j['avg_monthly_gross'] as num).toDouble(),
        growthPct: j['growth_pct'] != null
            ? (j['growth_pct'] as num).toDouble()
            : null,
      );
}

class CareerStats {
  final int totalYearsOnRecord;
  final double totalGrossCareer;
  final double totalNetCareer;
  final double totalDeductionsCareer;
  final int bestYear;
  final double bestYearGross;
  final double? careerGrowthPct;
  final int firstYearOnRecord;
  final int latestYear;
  final double latestAnnualGross;

  CareerStats({
    required this.totalYearsOnRecord,
    required this.totalGrossCareer,
    required this.totalNetCareer,
    required this.totalDeductionsCareer,
    required this.bestYear,
    required this.bestYearGross,
    this.careerGrowthPct,
    required this.firstYearOnRecord,
    required this.latestYear,
    required this.latestAnnualGross,
  });

  factory CareerStats.fromJson(Map<String, dynamic> j) => CareerStats(
        totalYearsOnRecord: (j['total_years_on_record'] as num).toInt(),
        totalGrossCareer: (j['total_gross_career'] as num).toDouble(),
        totalNetCareer: (j['total_net_career'] as num).toDouble(),
        totalDeductionsCareer: (j['total_deductions_career'] as num).toDouble(),
        bestYear: (j['best_year'] as num).toInt(),
        bestYearGross: (j['best_year_gross'] as num).toDouble(),
        careerGrowthPct: j['career_growth_pct'] != null
            ? (j['career_growth_pct'] as num).toDouble()
            : null,
        firstYearOnRecord: (j['first_year_on_record'] as num).toInt(),
        latestYear: (j['latest_year'] as num).toInt(),
        latestAnnualGross: (j['latest_annual_gross'] as num).toDouble(),
      );
}

class EarningsHistoryEmployee {
  final String name;
  final String staffId;
  final String department;
  final String salaryType;
  final String? employmentDate;

  EarningsHistoryEmployee({
    required this.name,
    required this.staffId,
    required this.department,
    required this.salaryType,
    this.employmentDate,
  });

  factory EarningsHistoryEmployee.fromJson(Map<String, dynamic> j) =>
      EarningsHistoryEmployee(
        name: j['name']?.toString() ?? '',
        staffId: j['staff_id']?.toString() ?? '',
        department: j['department']?.toString() ?? '',
        salaryType: j['salary_type']?.toString() ?? '',
        employmentDate: j['employment_date']?.toString(),
      );
}

class EarningsHistory {
  final EarningsHistoryEmployee employee;
  final CareerStats careerStats;
  final List<EarningsYear> annualBreakdown;

  EarningsHistory({
    required this.employee,
    required this.careerStats,
    required this.annualBreakdown,
  });

  factory EarningsHistory.fromJson(Map<String, dynamic> json) {
    final d = json['data'] as Map<String, dynamic>;
    return EarningsHistory(
      employee: EarningsHistoryEmployee.fromJson(d['employee']),
      careerStats: CareerStats.fromJson(d['career_stats']),
      annualBreakdown: (d['annual_breakdown'] as List<dynamic>)
          .map((e) => EarningsYear.fromJson(e))
          .toList(),
    );
  }
}
