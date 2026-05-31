import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_constants.dart';
import '../../../vaults/data/models/vault_list_model.dart';
import '../models/dashboard_stats_model.dart';
import '../models/recent_item_model.dart';

class DashboardService {
  Future<DashboardStats> getDashboard(String token) async {
    final json = await ApiClient.get(ApiConstants.dashboard, token: token);
    return DashboardStats.fromJson(json);
  }

  Future<List<VaultListModel>> getRecentVaults(String token) async {
    final json = await ApiClient.get(ApiConstants.recentVaults, token: token);
    final data = json['data'] as List<dynamic>;
    return data
        .map((e) => VaultListModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<RecentItemModel>> getRecentItems(String token) async {
    final json = await ApiClient.get(ApiConstants.recentItems, token: token);
    final data = json['data'] as List<dynamic>;
    return data
        .map((e) => RecentItemModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<dynamic>> getRecentFiles(String token) async {
    final json = await ApiClient.get(ApiConstants.recentFiles, token: token);
    return json['data'] as List<dynamic>;
  }
}
