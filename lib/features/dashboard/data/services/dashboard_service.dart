import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_constants.dart';
import '../models/dashboard_stats_model.dart';

class DashboardService {
  Future<DashboardStats> getDashboard(String token) async {
    final json = await ApiClient.get(ApiConstants.dashboard, token: token);
    return DashboardStats.fromJson(json);
  }
}
