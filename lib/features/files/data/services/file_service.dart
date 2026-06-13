import 'dart:convert';
import 'dart:typed_data';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_constants.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../models/vault_file_model.dart';

class FileService {
  Future<List<VaultFileModel>> getFiles(int vaultId, String token) async {
    final json = await ApiClient.get(
      ApiConstants.vaultFiles(vaultId),
      token: token,
    );
    final data = json['data'] as List<dynamic>;
    return data
        .map((e) => VaultFileModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<VaultFileModel> getFile(int vaultId, int fileId, String token) async {
    final json = await ApiClient.get(
      ApiConstants.vaultFile(vaultId, fileId),
      token: token,
    );
    return VaultFileModel.fromJson(json['data'] as Map<String, dynamic>);
  }

  Future<String> getDownloadUrl(int vaultId, int fileId, String token) async {
    final json = await ApiClient.get(
      ApiConstants.vaultFileDownloadUrl(vaultId, fileId),
      token: token,
    );
    return json['data']['download_url'] as String;
  }

  Future<Uint8List> downloadFile(
    String downloadUrlOrToken, {
    String? token,
  }) async {
    final uri = downloadUrlOrToken.startsWith('http')
        ? Uri.parse(downloadUrlOrToken)
        : downloadUrlOrToken.startsWith('/')
            ? Uri.parse('${ApiConstants.baseUrl}$downloadUrlOrToken')
            : downloadUrlOrToken.startsWith('files/download/')
                ? Uri.parse('${ApiConstants.baseUrl}/$downloadUrlOrToken')
                : Uri.parse(
                    '${ApiConstants.baseUrl}/files/download/${Uri.encodeComponent(downloadUrlOrToken)}',
                  );

    final headers = <String, String>{
      'Accept': 'application/octet-stream',
      if (token != null) 'Authorization': 'Bearer $token',
    };

    final response = await http
        .get(uri, headers: headers)
        .timeout(const Duration(seconds: 120));
    debugPrint(
      'FileService download request: ${uri.toString()} status=${response.statusCode} bytes=${response.bodyBytes.length}',
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return response.bodyBytes;
    }

    if (response.body.isNotEmpty) {
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          debugPrint(
            'FileService download error response: ${response.statusCode} ${decoded['message']}',
          );
          throw ApiException(
            message: decoded['message']?.toString() ?? 'Download failed',
            statusCode: response.statusCode,
          );
        }
      } catch (_) {
        debugPrint(
          'FileService download non-JSON error response: ${response.statusCode} ${response.body}',
        );
        throw ApiException(
          message: response.body,
          statusCode: response.statusCode,
        );
      }
    }

    debugPrint(
      'FileService download empty/unknown failure: ${response.statusCode}',
    );
    throw ApiException(
      message: 'Download failed',
      statusCode: response.statusCode,
    );
  }

  Future<void> deleteFile(int vaultId, int fileId, String token) async {
    await ApiClient.delete(
      ApiConstants.vaultFile(vaultId, fileId),
      token: token,
    );
  }

  Future<VaultFileModel> uploadFile({
    required int vaultId,
    required String token,
    required String fileName,
    required Uint8List encryptedBytes,
    required String ivBase64,
    required String tagBase64,
  }) async {
    final uri = Uri.parse(
      '${ApiConstants.baseUrl}${ApiConstants.vaultFiles(vaultId)}',
    );

    final request = http.MultipartRequest('POST', uri);
    request.headers['Authorization'] = 'Bearer $token';

    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        encryptedBytes,
        filename: '$fileName.enc',
        contentType: MediaType('application', 'octet-stream'),
      ),
    );

    request.fields['file_name'] = fileName;
    request.fields['iv'] = ivBase64;
    request.fields['tag'] = tagBase64;

    final streamedResponse = await request
        .send()
        .timeout(const Duration(seconds: 120));
    final response = await http.Response.fromStream(streamedResponse);
    final decoded = response.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode == 200 || response.statusCode == 201) {
      return VaultFileModel.fromJson(decoded['data'] as Map<String, dynamic>);
    }

    throw ApiException(
      message: decoded['message']?.toString() ?? 'Upload failed',
      statusCode: response.statusCode,
    );
  }
}
