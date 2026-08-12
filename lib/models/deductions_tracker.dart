class DeductionMonth {
  final int periodId;
  final String month;
  final double amount;

  DeductionMonth({required this.periodId, required this.month, required this.amount});

  factory DeductionMonth.fromJson(Map<String, dynamic> j) => DeductionMonth(
        periodId: (j['period_id'] as num).toInt(),
        month: j['month']?.toString() ?? '',
        amount: (j['amount'] as num).toDouble(),
      );
}

class DeductionItem {
  final int id;
  final String description;
  final String category;
  final double annualTotal;
  final int monthsActive;
  final double avgMonthly;
  final double pctOfGross;
  final List<DeductionMonth> monthly;

  DeductionItem({
    required this.id,
    required this.description,
    required this.category,
    required this.annualTotal,
    required this.monthsActive,
    required this.avgMonthly,
    required this.pctOfGross,
    required this.monthly,
  });

  factory DeductionItem.fromJson(Map<String, dynamic> j) => DeductionItem(
        id: (j['id'] as num).toInt(),
        description: j['description']?.toString() ?? '',
        category: j['category']?.toString() ?? 'other',
        annualTotal: (j['annual_total'] as num).toDouble(),
        monthsActive: (j['months_active'] as num).toInt(),
        avgMonthly: (j['avg_monthly'] as num).toDouble(),
        pctOfGross: (j['pct_of_gross'] as num).toDouble(),
        monthly: (j['monthly'] as List<dynamic>)
            .map((e) => DeductionMonth.fromJson(e))
            .toList(),
      );
}

class DeductionCategoryTotals {
  final double statutory;
  final double loans;
  final double union;
  final double health;
  final double other;

  DeductionCategoryTotals({
    required this.statutory,
    required this.loans,
    required this.union,
    required this.health,
    required this.other,
  });

  factory DeductionCategoryTotals.fromJson(Map<String, dynamic> j) =>
      DeductionCategoryTotals(
        statutory: (j['statutory'] as num).toDouble(),
        loans: (j['loans'] as num).toDouble(),
        union: (j['union'] as num).toDouble(),
        health: (j['health'] as num).toDouble(),
        other: (j['other'] as num).toDouble(),
      );
}

class DeductionSummary {
  final double annualGross;
  final double totalDeductions;
  final int deductionCount;
  final DeductionCategoryTotals categoryTotals;

  DeductionSummary({
    required this.annualGross,
    required this.totalDeductions,
    required this.deductionCount,
    required this.categoryTotals,
  });

  factory DeductionSummary.fromJson(Map<String, dynamic> j) => DeductionSummary(
        annualGross: (j['annual_gross'] as num).toDouble(),
        totalDeductions: (j['total_deductions'] as num).toDouble(),
        deductionCount: (j['deduction_count'] as num).toInt(),
        categoryTotals:
            DeductionCategoryTotals.fromJson(j['category_totals']),
      );
}

class DeductionsTracker {
  final String employeeName;
  final String staffId;
  final String department;
  final int year;
  final List<int> availableYears;
  final DeductionSummary summary;
  final List<DeductionItem> deductions;

  DeductionsTracker({
    required this.employeeName,
    required this.staffId,
    required this.department,
    required this.year,
    required this.availableYears,
    required this.summary,
    required this.deductions,
  });

  factory DeductionsTracker.fromJson(Map<String, dynamic> json) {
    final d = json['data'] as Map<String, dynamic>;
    final emp = d['employee'] as Map<String, dynamic>;
    return DeductionsTracker(
      employeeName: emp['name']?.toString() ?? '',
      staffId: emp['staff_id']?.toString() ?? '',
      department: emp['department']?.toString() ?? '',
      year: (d['year'] as num).toInt(),
      availableYears: (d['available_years'] as List<dynamic>)
          .map((y) => int.tryParse(y.toString()) ?? 0)
          .toList(),
      summary: DeductionSummary.fromJson(d['summary']),
      deductions: (d['deductions'] as List<dynamic>)
          .map((e) => DeductionItem.fromJson(e))
          .toList(),
    );
  }
}
