import 'package:dio/dio.dart';
import '../models/annual_tax_summary.dart';

class AnnualTaxService {
  static const String _baseUrl = 'https://oouthsalary.com.ng/auth_api';
  final Dio _dio;

  AnnualTaxService(String token)
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

  Future<AnnualTaxSummary> getSummary({
    required String staffId,
    int? year,
  }) async {
    try {
      final params = <String, dynamic>{'userId': staffId};
      if (year != null) params['year'] = year;

      final response = await _dio.get(
        '/api/payroll/annual_tax_summary.php',
        queryParameters: params,
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return AnnualTaxSummary.fromJson(response.data);
      }
      throw response.data['message'] ?? 'Failed to load tax summary';
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Connection error';
    }
  }
}
