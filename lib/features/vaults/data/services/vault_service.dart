import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_constants.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
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

  Future<void> deleteVault(int vaultId, String token) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}/vaults/$vaultId');
    final response = await http
        .delete(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode == 200 || response.statusCode == 204) {
      return;
    }

    Map<String, dynamic> decoded = const {};
    if (response.body.isNotEmpty) {
      decoded = jsonDecode(response.body) as Map<String, dynamic>;
    }
    final message = decoded['message'] ?? 'Something went wrong';
    throw ApiException(
      message: message.toString(),
      statusCode: response.statusCode,
    );
  }

  Future<VaultListModel> updateVault(
    int vaultId,
    String name,
    String token,
  ) async {
    final json = await ApiClient.put(ApiConstants.vaultDetail(vaultId), {
      'name': name,
    }, token: token);
    return VaultListModel.fromJson(json['data'] as Map<String, dynamic>);
  }
}
