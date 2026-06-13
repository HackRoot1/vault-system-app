import 'dart:typed_data';

import '../../../../core/network/api_client.dart';
import '../models/vault_file_model.dart';
import '../services/file_service.dart';

class FileRepository {
  FileRepository({FileService? service}) : _service = service ?? FileService();

  final FileService _service;

  Future<List<VaultFileModel>> getFiles(int vaultId, String token) async {
    try {
      return await _service.getFiles(vaultId, token);
    } on ApiException {
      rethrow;
    } catch (_) {
      throw const ApiException(
        message: 'Failed to load files. Please try again.',
        statusCode: 0,
      );
    }
  }

  Future<VaultFileModel> getFile(int vaultId, int fileId, String token) async {
    try {
      return await _service.getFile(vaultId, fileId, token);
    } on ApiException {
      rethrow;
    } catch (_) {
      throw const ApiException(
        message: 'Failed to load file details.',
        statusCode: 0,
      );
    }
  }

  Future<String> getDownloadUrl(int vaultId, int fileId, String token) async {
    try {
      return await _service.getDownloadUrl(vaultId, fileId, token);
    } on ApiException {
      rethrow;
    } catch (_) {
      throw const ApiException(
        message: 'Failed to get download URL.',
        statusCode: 0,
      );
    }
  }

  Future<void> deleteFile(int vaultId, int fileId, String token) async {
    try {
      await _service.deleteFile(vaultId, fileId, token);
    } on ApiException {
      rethrow;
    } catch (_) {
      throw const ApiException(
        message: 'Failed to delete file.',
        statusCode: 0,
      );
    }
  }

  Future<VaultFileModel> uploadFile({
    required int vaultId,
    required String token,
    required String fileName,
    required Uint8List encryptedBytes,
    required String ivBase64,
    required String tagBase64,
  }) async {
    try {
      return await _service.uploadFile(
        vaultId: vaultId,
        token: token,
        fileName: fileName,
        encryptedBytes: encryptedBytes,
        ivBase64: ivBase64,
        tagBase64: tagBase64,
      );
    } on ApiException {
      rethrow;
    } catch (_) {
      throw const ApiException(
        message: 'Upload failed. Please try again.',
        statusCode: 0,
      );
    }
  }
}
