import 'package:dio/dio.dart';

import '../core/constants/api_constants.dart';
import '../models/paper.dart';

class PaperService {
  final Dio _dio;

  PaperService()
      : _dio = Dio(BaseOptions(
          baseUrl: ApiConstants.backendBaseUrl,
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
        ));

  Future<PaperSearchResult> searchPapers({
    required String query,
    int page = 1,
    int perPage = 10,
    String? source,
    int? yearFrom,
    int? yearTo,
  }) async {
    final params = <String, dynamic>{
      'query': query,
      'page': page,
      'per_page': perPage,
    };
    if (source != null) params['source'] = source;
    if (yearFrom != null) params['year_from'] = yearFrom;
    if (yearTo != null) params['year_to'] = yearTo;

    final response = await _dio.get('/papers/search', queryParameters: params);
    return PaperSearchResult.fromJson(response.data as Map<String, dynamic>);
  }
}
