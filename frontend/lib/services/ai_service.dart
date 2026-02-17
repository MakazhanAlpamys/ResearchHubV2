import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/constants/api_constants.dart';

class AiService {
  final Dio _dio;

  AiService()
      : _dio = Dio(BaseOptions(
          baseUrl: ApiConstants.backendBaseUrl,
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 120),
        ));

  Options? get _authOptions {
    final token =
        Supabase.instance.client.auth.currentSession?.accessToken;
    return token != null
        ? Options(headers: {'Authorization': 'Bearer $token'})
        : null;
  }

  /// Generate an AI summary for a paper.
  Future<String> summarize({
    required String title,
    required String abstract_,
    required String language,
  }) async {
    final response = await _dio.post(
      '/ai/summarize',
      data: {
        'title': title,
        'abstract': abstract_,
        'language': language,
      },
      options: _authOptions,
    );
    final data = response.data as Map<String, dynamic>;
    return data['summary'] as String? ?? '';
  }

  /// Analyze a full PDF document via Gemini.
  Future<String> analyzePdf({
    required String pdfUrl,
    required String language,
  }) async {
    final response = await _dio.post(
      '/ai/analyze-pdf',
      data: {
        'pdf_url': pdfUrl,
        'language': language,
      },
      options: _authOptions,
    );
    final data = response.data as Map<String, dynamic>;
    return data['analysis'] as String? ?? '';
  }
}
