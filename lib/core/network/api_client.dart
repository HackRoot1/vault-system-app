import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_constants.dart';

class ApiClient {
  const ApiClient._();

  static Future<Map<String, dynamic>> post(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}$endpoint');
    final response = await http
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 30));

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode == 200 || response.statusCode == 201) {
      return decoded;
    } else {
      final message = decoded['message'] ?? 'Something went wrong';
      throw ApiException(
        message: message.toString(),
        statusCode: response.statusCode,
      );
    }
  }
}

class ApiException implements Exception {
  const ApiException({required this.message, required this.statusCode});

  final String message;
  final int statusCode;
}
