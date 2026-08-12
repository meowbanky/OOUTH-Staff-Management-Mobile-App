import 'package:dio/dio.dart';
import '../models/promotion_estimate.dart';

class PromotionService {
  static const String _baseUrl = 'https://oouthsalary.com.ng';
  final Dio _dio;

  PromotionService(String token)
      : _dio = Dio(BaseOptions(
          baseUrl: _baseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
          validateStatus: (status) => status! < 500,
        ));

  Future<PromotionEstimate> estimate({
    required String staffId,
    required int gradePlus,
    required int stepPlus,
  }) async {
    try {
      final response = await _dio.get(
        '/api/estimate_promotion.php',
        queryParameters: {
          'staff_id': staffId,
          'grade_plus': gradePlus,
          'step_plus': stepPlus,
        },
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return PromotionEstimate.fromJson(response.data);
      }

      throw response.data['message'] ?? 'Failed to estimate promotion';
    } on DioException catch (e) {
      if (e.response != null) {
        throw e.response?.data['message'] ?? 'Request failed';
      }
      throw 'Connection error. Please check your internet connection.';
    }
  }
}
