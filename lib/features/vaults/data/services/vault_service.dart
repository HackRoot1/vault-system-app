import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_constants.dart';
import '../models/create_vault_request_model.dart';
import '../models/create_vault_response_model.dart';
import '../models/vault_list_model.dart';

class VaultService {
  Future<CreateVaultResponseModel> createVault(
    CreateVaultRequestModel request,
    String token,
  ) async {
    final json = await ApiClient.post(
      ApiConstants.vaults,
      request.toJson(),
      token: token,
    );
    return CreateVaultResponseModel.fromJson(json);
  }

  Future<List<VaultListModel>> getVaults(String token) async {
    final json = await ApiClient.get(ApiConstants.vaults, token: token);
    final data = json['data'] as List<dynamic>;
    return data
        .map((e) => VaultListModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
