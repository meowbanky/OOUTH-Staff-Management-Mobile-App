import 'package:dio/dio.dart';
import '../models/payslip_bundle.dart';

class PayslipBundleService {
  static const String _baseUrl = 'https://oouthsalary.com.ng/auth_api';
  final Dio _dio;

  PayslipBundleService(String token)
      : _dio = Dio(BaseOptions(
          baseUrl: _baseUrl,
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 20),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
          validateStatus: (s) => s! < 500,
        ));

  Future<List<BundlePeriod>> getPeriods(String staffId) async {
    try {
      final response = await _dio.get(
        '/api/payroll/payslip_bundle.php',
        queryParameters: {'userId': staffId, 'listOnly': '1'},
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        final list =
            response.data['data']['available_periods'] as List<dynamic>;
        return list.map((e) => BundlePeriod.fromJson(e)).toList();
      }
      throw response.data['message'] ?? 'Failed to load periods';
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Connection error';
    }
  }

  Future<PayslipBundle> fetchBundle({
    required String staffId,
    required List<int> periodIds,
  }) async {
    try {
      final response = await _dio.get(
        '/api/payroll/payslip_bundle.php',
        queryParameters: {
          'userId': staffId,
          'periodIds': periodIds.join(','),
        },
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        return PayslipBundle.fromJson(response.data);
      }
      throw response.data['message'] ?? 'Failed to load bundle';
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Connection error';
    }
  }
}
