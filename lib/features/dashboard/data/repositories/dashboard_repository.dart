import '../../../../core/network/api_client.dart';
import '../../../vaults/data/models/vault_list_model.dart';
import '../models/dashboard_stats_model.dart';
import '../models/recent_item_model.dart';
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

  Future<List<VaultListModel>> getRecentVaults(String token) async {
    try {
      return await _service.getRecentVaults(token);
    } on ApiException {
      rethrow;
    } catch (_) {
      return [];
    }
  }

  Future<List<RecentItemModel>> getRecentItems(String token) async {
    try {
      return await _service.getRecentItems(token);
    } on ApiException {
      rethrow;
    } catch (_) {
      return [];
    }
  }

  Future<List<dynamic>> getRecentFiles(String token) async {
    try {
      return await _service.getRecentFiles(token);
    } on ApiException {
      rethrow;
    } catch (_) {
      return [];
    }
  }
}
