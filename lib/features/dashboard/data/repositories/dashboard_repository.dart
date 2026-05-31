import '../../../../core/network/api_client.dart';
import '../models/dashboard_stats_model.dart';
import '../services/dashboard_service.dart';

class DashboardRepository {
  final _service = DashboardService();

  Future<DashboardStats> getDashboard(String token) async {
    try {
      return await _service.getDashboard(token);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw const ApiException(
        message: 'Failed to load dashboard. Please try again.',
        statusCode: 0,
      );
    }
  }
}
