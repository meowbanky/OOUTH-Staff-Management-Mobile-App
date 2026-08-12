class TrendMonth {
  final int periodId;
  final String label;
  final String monthName;
  final int year;
  final double gross;
  final double deductions;
  final double net;
  final double pctNetOfGross;
  final double? netChangePct;
  final double? grossChangePct;
  final bool isSignificant;

  TrendMonth({
    required this.periodId,
    required this.label,
    required this.monthName,
    required this.year,
    required this.gross,
    required this.deductions,
    required this.net,
    required this.pctNetOfGross,
    this.netChangePct,
    this.grossChangePct,
    required this.isSignificant,
  });

  factory TrendMonth.fromJson(Map<String, dynamic> j) => TrendMonth(
        periodId: (j['period_id'] as num).toInt(),
        label: j['label']?.toString() ?? '',
        monthName: j['month_name']?.toString() ?? '',
        year: (j['year'] as num).toInt(),
        gross: (j['gross'] as num).toDouble(),
        deductions: (j['deductions'] as num).toDouble(),
        net: (j['net'] as num).toDouble(),
        pctNetOfGross: (j['pct_net_of_gross'] as num).toDouble(),
        netChangePct: j['net_change_pct'] != null
            ? (j['net_change_pct'] as num).toDouble()
            : null,
        grossChangePct: j['gross_change_pct'] != null
            ? (j['gross_change_pct'] as num).toDouble()
            : null,
        isSignificant: j['is_significant'] == true,
      );
}

class TrendCareerStats {
  final int totalMonths;
  final double avgMonthlyGross;
  final double avgMonthlyNet;
  final double maxGross;
  final String maxGrossMonth;
  final double maxNet;
  final String maxNetMonth;
  final double minNet;
  final String minNetMonth;
  final double maxDeductions;
  final String maxDeductionsMonth;
  final String firstMonth;
  final String latestMonth;

  TrendCareerStats({
    required this.totalMonths,
    required this.avgMonthlyGross,
    required this.avgMonthlyNet,
    required this.maxGross,
    required this.maxGrossMonth,
    required this.maxNet,
    required this.maxNetMonth,
    required this.minNet,
    required this.minNetMonth,
    required this.maxDeductions,
    required this.maxDeductionsMonth,
    required this.firstMonth,
    required this.latestMonth,
  });

  factory TrendCareerStats.fromJson(Map<String, dynamic> j) => TrendCareerStats(
        totalMonths: (j['total_months'] as num).toInt(),
        avgMonthlyGross: (j['avg_monthly_gross'] as num).toDouble(),
        avgMonthlyNet: (j['avg_monthly_net'] as num).toDouble(),
        maxGross: (j['max_gross'] as num).toDouble(),
        maxGrossMonth: j['max_gross_month']?.toString() ?? '',
        maxNet: (j['max_net'] as num).toDouble(),
        maxNetMonth: j['max_net_month']?.toString() ?? '',
        minNet: (j['min_net'] as num).toDouble(),
        minNetMonth: j['min_net_month']?.toString() ?? '',
        maxDeductions: (j['max_deductions'] as num).toDouble(),
        maxDeductionsMonth: j['max_deductions_month']?.toString() ?? '',
        firstMonth: j['first_month']?.toString() ?? '',
        latestMonth: j['latest_month']?.toString() ?? '',
      );
}

class NetPayTrend {
  final String employeeName;
  final String staffId;
  final String department;
  final TrendCareerStats careerStats;
  final List<TrendMonth> months;

  NetPayTrend({
    required this.employeeName,
    required this.staffId,
    required this.department,
    required this.careerStats,
    required this.months,
  });

  factory NetPayTrend.fromJson(Map<String, dynamic> json) {
    final d   = json['data'] as Map<String, dynamic>;
    final emp = d['employee'] as Map<String, dynamic>;
    return NetPayTrend(
      employeeName: emp['name']?.toString() ?? '',
      staffId: emp['staff_id']?.toString() ?? '',
      department: emp['department']?.toString() ?? '',
      careerStats: TrendCareerStats.fromJson(d['career_stats']),
      months: (d['months'] as List<dynamic>)
          .map((e) => TrendMonth.fromJson(e))
          .toList(),
    );
  }
}
