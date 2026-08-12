import 'package:dio/dio.dart';
import '../models/earnings_history.dart';

class EarningsHistoryService {
  static const String _baseUrl = 'https://oouthsalary.com.ng/auth_api';
  final Dio _dio;

  EarningsHistoryService(String token)
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

  Future<EarningsHistory> getHistory(String staffId) async {
    try {
      final response = await _dio.get(
        '/api/payroll/earnings_history.php',
        queryParameters: {'userId': staffId},
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        return EarningsHistory.fromJson(response.data);
      }
      throw response.data['message'] ?? 'Failed to load earnings history';
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Connection error';
    }
  }
}
