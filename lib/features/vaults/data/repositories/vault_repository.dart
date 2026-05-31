import '../../../../core/network/api_client.dart';
import '../models/create_vault_item_request_model.dart';
import '../models/create_vault_request_model.dart';
import '../models/create_vault_response_model.dart';
import '../models/vault_item_model.dart';
import '../models/vault_list_model.dart';
import '../services/vault_item_service.dart';
import '../services/vault_service.dart';

class VaultRepository {
  final _service = VaultService();
  final _itemService = VaultItemService();

  Future<CreateVaultResponseModel> createVault(
    CreateVaultRequestModel request,
    String token,
  ) async {
    try {
      return await _service.createVault(request, token);
    } on ApiException {
      rethrow;
    } catch (_) {
      throw const ApiException(
        message: 'Failed to create vault. Please try again.',
        statusCode: 0,
      );
    }
  }

  Future<List<VaultListModel>> getVaults(String token) async {
    try {
      return await _service.getVaults(token);
    } on ApiException {
      rethrow;
    } catch (_) {
      throw const ApiException(
        message: 'Failed to load vaults. Please try again.',
        statusCode: 0,
      );
    }
  }

  Future<VaultItemModel> createItem(
    int vaultId,
    CreateVaultItemRequestModel request,
    String token,
  ) async {
    try {
      return await _itemService.createItem(vaultId, request, token);
    } on ApiException {
      rethrow;
    } catch (_) {
      throw const ApiException(
        message: 'Failed to create item. Please try again.',
        statusCode: 0,
      );
    }
  }

  Future<void> deleteItem(int vaultId, int itemId, String token) async {
    try {
      await _itemService.deleteItem(vaultId, itemId, token);
    } on ApiException {
      rethrow;
    } catch (_) {
      throw const ApiException(
        message: 'Failed to delete item. Please try again.',
        statusCode: 0,
      );
    }
  }

  Future<VaultItemModel> updateItem(
    int vaultId,
    int itemId,
    CreateVaultItemRequestModel request,
    String token,
  ) async {
    try {
      return await _itemService.updateItem(vaultId, itemId, request, token);
    } on ApiException {
      rethrow;
    } catch (_) {
      throw const ApiException(
        message: 'Failed to update item. Please try again.',
        statusCode: 0,
      );
    }
  }

  Future<List<VaultItemModel>> getItems(int vaultId, String token) async {
    try {
      return await _itemService.getItems(vaultId, token);
    } on ApiException {
      rethrow;
    } catch (_) {
      throw const ApiException(
        message: 'Failed to load items. Please try again.',
        statusCode: 0,
      );
    }
  }

  Future<VaultItemModel> getItem(int vaultId, int itemId, String token) async {
    try {
      return await _itemService.getItem(vaultId, itemId, token);
    } on ApiException {
      rethrow;
    } catch (_) {
      throw const ApiException(
        message: 'Failed to load item. Please try again.',
        statusCode: 0,
      );
    }
  }

  Future<VaultListModel> getVaultDetail(int vaultId, String token) async {
    try {
      return await _itemService.getVaultDetail(vaultId, token);
    } on ApiException {
      rethrow;
    } catch (_) {
      throw const ApiException(
        message: 'Failed to load vault. Please try again.',
        statusCode: 0,
      );
    }
  }

  Future<void> deleteVault(int vaultId, String token) async {
    try {
      await _service.deleteVault(vaultId, token);
    } on ApiException {
      rethrow;
    } catch (_) {
      throw const ApiException(
        message: 'Failed to delete vault. Please try again.',
        statusCode: 0,
      );
    }
  }

  Future<VaultListModel> updateVault(
    int vaultId,
    String name,
    String token,
  ) async {
    try {
      return await _service.updateVault(vaultId, name, token);
    } on ApiException {
      rethrow;
    } catch (_) {
      throw const ApiException(
        message: 'Failed to update vault. Please try again.',
        statusCode: 0,
      );
    }
  }
}
