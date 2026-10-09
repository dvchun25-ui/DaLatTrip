import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../constants/api_constants.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  const ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class ApiClient {
  final String baseUrl;
  final http.Client _httpClient;

  ApiClient({String? baseUrl, http.Client? httpClient})
    : baseUrl = baseUrl ?? ApiConstants.baseUrl,
      _httpClient = httpClient ?? http.Client();

  Future<Map<String, dynamic>> get(String path) async {
    return _send(() => _httpClient.get(_uri(path)));
  }

  Future<Map<String, dynamic>> post(
    String path, {
    required Map<String, dynamic> body,
  }) async {
    return _send(
      () => _httpClient.post(
        _uri(path),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      ),
    );
  }

  Uri _uri(String path) => Uri.parse('$baseUrl$path');

  Future<Map<String, dynamic>> _send(
    Future<http.Response> Function() request,
  ) async {
    try {
      final response = await request().timeout(const Duration(seconds: 20));
      final decoded = response.body.isEmpty
          ? <String, dynamic>{}
          : jsonDecode(response.body);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        final detail = decoded is Map ? decoded['detail'] : null;
        throw ApiException(
          detail?.toString() ?? 'Máy chủ trả lỗi ${response.statusCode}.',
          statusCode: response.statusCode,
        );
      }
      if (decoded is! Map) {
        throw const ApiException('Response API không phải JSON object.');
      }
      return Map<String, dynamic>.from(decoded);
    } on ApiException {
      rethrow;
    } on FormatException {
      throw const ApiException('Không thể đọc dữ liệu JSON từ máy chủ.');
    } on http.ClientException catch (error) {
      throw ApiException('Không thể kết nối backend: ${error.message}');
    } on TimeoutException {
      throw const ApiException(
        'Backend phản hồi quá lâu. Hãy kiểm tra server localhost:8000.',
      );
    }
  }
}
