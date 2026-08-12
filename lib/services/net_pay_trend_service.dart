import 'package:dio/dio.dart';
import '../models/net_pay_trend.dart';

class NetPayTrendService {
  static const String _baseUrl = 'https://oouthsalary.com.ng/auth_api';
  final Dio _dio;

  NetPayTrendService(String token)
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

  Future<NetPayTrend> getTrend(String staffId) async {
    try {
      final response = await _dio.get(
        '/api/payroll/net_pay_trend.php',
        queryParameters: {'userId': staffId},
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        return NetPayTrend.fromJson(response.data);
      }
      throw response.data['message'] ?? 'Failed to load trend';
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Connection error';
    }
  }
}
