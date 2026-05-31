import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_constants.dart';
import '../models/create_vault_item_request_model.dart';
import '../models/vault_item_model.dart';
import '../models/vault_list_model.dart';

class VaultItemService {
  Future<VaultItemModel> createItem(
    int vaultId,
    CreateVaultItemRequestModel request,
    String token,
  ) async {
    final json = await ApiClient.post(
      ApiConstants.vaultItems(vaultId),
      request.toJson(),
      token: token,
    );
    return VaultItemModel.fromJson(json['data'] as Map<String, dynamic>);
  }

  Future<List<VaultItemModel>> getItems(int vaultId, String token) async {
    final json = await ApiClient.get(
      ApiConstants.vaultItems(vaultId),
      token: token,
    );
    final data = json['data'] as List<dynamic>;
    return data
        .map((e) => VaultItemModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<VaultItemModel> getItem(int vaultId, int itemId, String token) async {
    final json = await ApiClient.get(
      ApiConstants.vaultItem(vaultId, itemId),
      token: token,
    );
    return VaultItemModel.fromJson(json['data'] as Map<String, dynamic>);
  }

  Future<VaultListModel> getVaultDetail(int vaultId, String token) async {
    final json = await ApiClient.get(
      ApiConstants.vaultDetail(vaultId),
      token: token,
    );
    return VaultListModel.fromJson(json['data'] as Map<String, dynamic>);
  }
}
