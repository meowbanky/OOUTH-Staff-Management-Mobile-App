import 'package:dio/dio.dart';
import '../models/pay_calendar.dart';

class PayCalendarService {
  static const String _baseUrl = 'https://oouthsalary.com.ng/auth_api';
  final Dio _dio;

  PayCalendarService(String token)
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

  Future<PayCalendar> getCalendar({required String staffId, int? year}) async {
    try {
      final params = <String, dynamic>{'userId': staffId};
      if (year != null) params['year'] = year;

      final response = await _dio.get(
        '/api/payroll/pay_calendar.php',
        queryParameters: params,
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        return PayCalendar.fromJson(response.data);
      }
      throw response.data['message'] ?? 'Failed to load calendar';
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Connection error';
    }
  }
}
