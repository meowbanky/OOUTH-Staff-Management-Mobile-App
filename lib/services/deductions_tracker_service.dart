import 'package:dio/dio.dart';
import '../models/deductions_tracker.dart';

class DeductionsTrackerService {
  static const String _baseUrl = 'https://oouthsalary.com.ng/auth_api';
  final Dio _dio;

  DeductionsTrackerService(String token)
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

  Future<DeductionsTracker> getTracker({
    required String staffId,
    int? year,
  }) async {
    try {
      final params = <String, dynamic>{'userId': staffId};
      if (year != null) params['year'] = year;

      final response = await _dio.get(
        '/api/payroll/deductions_tracker.php',
        queryParameters: params,
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        return DeductionsTracker.fromJson(response.data);
      }
      throw response.data['message'] ?? 'Failed to load deductions';
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Connection error';
    }
  }
}
