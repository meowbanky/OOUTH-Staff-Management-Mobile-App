import 'package:dio/dio.dart';
import '../models/salary_certificate.dart';

class SalaryCertificateService {
  static const String _baseUrl = 'https://oouthsalary.com.ng/auth_api';
  final Dio _dio;

  SalaryCertificateService(String token)
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

  Future<SalaryCertificate> getCertificate({
    required String staffId,
    String purpose = '',
  }) async {
    try {
      final params = <String, dynamic>{'userId': staffId};
      if (purpose.isNotEmpty) params['purpose'] = purpose;

      final response = await _dio.get(
        '/api/payroll/salary_certificate.php',
        queryParameters: params,
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return SalaryCertificate.fromJson(response.data);
      }
      throw response.data['message'] ?? 'Failed to load certificate data';
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Connection error';
    }
  }
}
