// lib/services/pension_service.dart

import 'package:dio/dio.dart';
import '../services/api_service.dart';
import '../models/period.dart';
import '../providers/auth_provider.dart';

class PensionService {
  final ApiService _apiService = ApiService();
  final AuthProvider _authProvider;

  PensionService(this._authProvider);

  Future<List<Period>> getPeriods() async {
    try {
      final response = await _apiService.dio.get('/api/payroll/periods.php');

      if (response.data['success']) {
        return (response.data['data'] as List)
            .map((period) => Period.fromJson(period))
            .toList();
      }
      throw 'Failed to load periods';
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw 'Session expired. Please login again.';
      }
      throw 'Error loading periods: ${e.message}';
    } catch (e) {
      throw 'Error loading periods: $e';
    }
  }

  Future<Map<String, dynamic>> getPensionReport({
    int? periodFrom,
    int? periodTo,
  }) async {
    try {
      // Get user ID from AuthProvider
      final userId = _authProvider.user?.id;
      if (userId == null) {
        throw 'User not authenticated';
      }

      final queryParams = <String, dynamic>{
        'userId': userId,
      };

      if (periodFrom != null) {
        queryParams['periodFrom'] = periodFrom;
      }
      if (periodTo != null) {
        queryParams['periodTo'] = periodTo;
      }

      final response = await _apiService.dio.get(
        '/api/payroll/pension_report.php',
        queryParameters: queryParams,
      );

      if (response.data['success']) {
        return response.data['data'];
      }
      throw response.data['message'] ?? 'Failed to load pension report';
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw 'Session expired. Please login again.';
      }
      throw 'Error loading pension report: ${e.message}';
    } catch (e) {
      throw 'Error loading pension report: $e';
    }
  }
}

