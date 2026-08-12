import 'package:dio/dio.dart';
import '../models/payslip_comparison.dart';

class PayslipComparisonService {
  static const String _baseUrl = 'https://oouthsalary.com.ng/auth_api';
  final Dio _dio;

  PayslipComparisonService(String token)
      : _dio = Dio(BaseOptions(
          baseUrl: _baseUrl,
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
          validateStatus: (s) => s! < 500,
        ));

  Future<List<AvailablePeriod>> getPeriods(String staffId) async {
    try {
      final response = await _dio.get(
        '/api/payroll/payslip_comparison.php',
        queryParameters: {'userId': staffId, 'listOnly': '1'},
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        final list = response.data['data']['available_periods'] as List<dynamic>;
        return list.map((e) => AvailablePeriod.fromJson(e)).toList();
      }
      throw response.data['message'] ?? 'Failed to load periods';
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Connection error';
    }
  }

  Future<PayslipComparison> compare({
    required String staffId,
    required int periodId1,
    required int periodId2,
  }) async {
    try {
      final response = await _dio.get(
        '/api/payroll/payslip_comparison.php',
        queryParameters: {
          'userId': staffId,
          'periodId1': periodId1,
          'periodId2': periodId2,
        },
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        return PayslipComparison.fromJson(response.data);
      }
      throw response.data['message'] ?? 'Failed to load comparison';
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Connection error';
    }
  }
}
