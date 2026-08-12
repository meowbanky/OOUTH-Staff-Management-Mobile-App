import 'package:dio/dio.dart';

class PayStatus {
  final bool salaryPaid;
  final String? paidPeriod;
  final String? latestPaid;
  final int payDay;
  final String nextPayDate;
  final String nextPeriodLabel;
  final int daysUntilPay;
  final String currentMonth;

  PayStatus({
    required this.salaryPaid,
    this.paidPeriod,
    this.latestPaid,
    required this.payDay,
    required this.nextPayDate,
    required this.nextPeriodLabel,
    required this.daysUntilPay,
    required this.currentMonth,
  });

  factory PayStatus.fromJson(Map<String, dynamic> json) {
    final d = json['data'] as Map<String, dynamic>;
    return PayStatus(
      salaryPaid:      d['salary_paid'] as bool? ?? false,
      paidPeriod:      d['paid_period'] as String?,
      latestPaid:      d['latest_paid'] as String?,
      payDay:          (d['pay_day'] as num?)?.toInt() ?? 27,
      nextPayDate:     d['next_pay_date'] as String? ?? '',
      nextPeriodLabel: d['next_period_label'] as String? ?? '',
      daysUntilPay:    (d['days_until_pay'] as num?)?.toInt() ?? 0,
      currentMonth:    d['current_month'] as String? ?? '',
    );
  }
}

class PayStatusService {
  static const String _baseUrl = 'https://oouthsalary.com.ng/auth_api';
  final Dio _dio;

  PayStatusService(String token)
      : _dio = Dio(BaseOptions(
          baseUrl: _baseUrl,
          connectTimeout: const Duration(seconds: 8),
          receiveTimeout: const Duration(seconds: 8),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
          validateStatus: (s) => s! < 500,
        ));

  Future<PayStatus> getPayStatus() async {
    try {
      final response = await _dio.get('/api/payroll/pay_status.php');
      if (response.statusCode == 200 && response.data['success'] == true) {
        return PayStatus.fromJson(response.data);
      }
      throw response.data['message'] ?? 'Failed to load pay status';
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Connection error';
    }
  }
}
