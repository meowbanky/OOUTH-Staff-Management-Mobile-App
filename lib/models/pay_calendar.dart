class CalendarLineItem {
  final int id;
  final String description;
  final double amount;

  CalendarLineItem({required this.id, required this.description, required this.amount});

  factory CalendarLineItem.fromJson(Map<String, dynamic> j) => CalendarLineItem(
        id: (j['id'] as num).toInt(),
        description: j['description']?.toString() ?? '',
        amount: (j['amount'] as num).toDouble(),
      );
}

class CalendarMonth {
  final int monthNum;
  final String monthName;
  final bool paid;
  final int? periodId;
  final double gross;
  final double deductions;
  final double net;
  final List<CalendarLineItem> earnings;
  final List<CalendarLineItem> deductionsList;

  CalendarMonth({
    required this.monthNum,
    required this.monthName,
    required this.paid,
    this.periodId,
    required this.gross,
    required this.deductions,
    required this.net,
    required this.earnings,
    required this.deductionsList,
  });

  factory CalendarMonth.fromJson(Map<String, dynamic> j) => CalendarMonth(
        monthNum: (j['month_num'] as num).toInt(),
        monthName: j['month_name']?.toString() ?? '',
        paid: j['paid'] == true,
        periodId: j['period_id'] != null ? (j['period_id'] as num).toInt() : null,
        gross: (j['gross'] as num).toDouble(),
        deductions: (j['deductions'] as num).toDouble(),
        net: (j['net'] as num).toDouble(),
        earnings: (j['earnings'] as List<dynamic>)
            .map((e) => CalendarLineItem.fromJson(e))
            .toList(),
        deductionsList: (j['deductions_list'] as List<dynamic>)
            .map((e) => CalendarLineItem.fromJson(e))
            .toList(),
      );
}

class YearSummary {
  final int monthsPaid;
  final double ytdGross;
  final double ytdNet;
  final double ytdDeductions;
  final double avgMonthlyNet;
  final String? bestNetMonth;
  final double bestNet;

  YearSummary({
    required this.monthsPaid,
    required this.ytdGross,
    required this.ytdNet,
    required this.ytdDeductions,
    required this.avgMonthlyNet,
    this.bestNetMonth,
    required this.bestNet,
  });

  factory YearSummary.fromJson(Map<String, dynamic> j) => YearSummary(
        monthsPaid: (j['months_paid'] as num).toInt(),
        ytdGross: (j['ytd_gross'] as num).toDouble(),
        ytdNet: (j['ytd_net'] as num).toDouble(),
        ytdDeductions: (j['ytd_deductions'] as num).toDouble(),
        avgMonthlyNet: (j['avg_monthly_net'] as num).toDouble(),
        bestNetMonth: j['best_net_month']?.toString(),
        bestNet: (j['best_net'] as num).toDouble(),
      );
}

class PayCalendar {
  final String employeeName;
  final String staffId;
  final String department;
  final int year;
  final List<int> availableYears;
  final YearSummary yearSummary;
  final List<CalendarMonth> calendar;

  PayCalendar({
    required this.employeeName,
    required this.staffId,
    required this.department,
    required this.year,
    required this.availableYears,
    required this.yearSummary,
    required this.calendar,
  });

  factory PayCalendar.fromJson(Map<String, dynamic> json) {
    final d   = json['data'] as Map<String, dynamic>;
    final emp = d['employee'] as Map<String, dynamic>;
    return PayCalendar(
      employeeName: emp['name']?.toString() ?? '',
      staffId: emp['staff_id']?.toString() ?? '',
      department: emp['department']?.toString() ?? '',
      year: (d['year'] as num).toInt(),
      availableYears: (d['available_years'] as List<dynamic>)
          .map((y) => int.tryParse(y.toString()) ?? 0)
          .toList(),
      yearSummary: YearSummary.fromJson(d['year_summary']),
      calendar: (d['calendar'] as List<dynamic>)
          .map((e) => CalendarMonth.fromJson(e))
          .toList(),
    );
  }
}
