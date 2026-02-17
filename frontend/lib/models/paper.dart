class Paper {
  final String paperId;
  final String title;
  final List<String> authors;
  final String abstract_;
  final String? publishedDate;
  final String source;
  final String url;
  final String pdfUrl;
  final String? collectionId;

  const Paper({
    required this.paperId,
    required this.title,
    this.authors = const [],
    this.abstract_ = '',
    this.publishedDate,
    this.source = '',
    this.url = '',
    this.pdfUrl = '',
    this.collectionId,
  });

  factory Paper.fromJson(Map<String, dynamic> json) {
    return Paper(
      paperId: json['paper_id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      authors: (json['authors'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      abstract_: json['abstract'] as String? ?? '',
      publishedDate: json['published_date'] as String?,
      source: json['source'] as String? ?? '',
      url: json['url'] as String? ?? '',
      pdfUrl: json['pdf_url'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'paper_id': paperId,
        'title': title,
        'authors': authors,
        'abstract': abstract_,
        'published_date': publishedDate,
        'source': source,
        'url': url,
        'pdf_url': pdfUrl,
      };

  /// Convert to a row suitable for the Supabase `favorites` table.
  Map<String, dynamic> toFavoriteRow(String userId, {String? collectionId}) => {
        'user_id': userId,
        'paper_id': paperId,
        'title': title,
        'authors': authors,
        'abstract': abstract_,
        'published_date': publishedDate,
        'source': source,
        'url': url,
        'pdf_url': pdfUrl,
        if (collectionId != null) 'collection_id': collectionId,
      };

  factory Paper.fromFavoriteRow(Map<String, dynamic> row) {
    return Paper(
      paperId: row['paper_id'] as String? ?? '',
      title: row['title'] as String? ?? '',
      authors: (row['authors'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      abstract_: row['abstract'] as String? ?? '',
      publishedDate: row['published_date'] as String?,
      source: row['source'] as String? ?? '',
      url: row['url'] as String? ?? '',
      pdfUrl: row['pdf_url'] as String? ?? '',
      collectionId: row['collection_id'] as String?,
    );
  }

  String get year {
    if (publishedDate == null || publishedDate!.length < 4) return '';
    return publishedDate!.substring(0, 4);
  }

  String get authorsShort {
    if (authors.isEmpty) return '';
    if (authors.length == 1) return authors.first;
    return '${authors.first} et al.';
  }
}

class SourceStatus {
  final String name;
  final bool ok;
  final String? error;

  const SourceStatus({required this.name, required this.ok, this.error});

  factory SourceStatus.fromJson(Map<String, dynamic> json) {
    return SourceStatus(
      name: json['name'] as String? ?? '',
      ok: json['ok'] as bool? ?? true,
      error: json['error'] as String?,
    );
  }
}

class PaperSearchResult {
  final int total;
  final int page;
  final int perPage;
  final bool hasMore;
  final List<Paper> papers;
  final List<SourceStatus> sources;

  const PaperSearchResult({
    required this.total,
    required this.page,
    required this.perPage,
    this.hasMore = true,
    required this.papers,
    this.sources = const [],
  });

  factory PaperSearchResult.fromJson(Map<String, dynamic> json) {
    return PaperSearchResult(
      total: json['total'] as int? ?? 0,
      page: json['page'] as int? ?? 1,
      perPage: json['per_page'] as int? ?? 10,
      hasMore: json['has_more'] as bool? ?? true,
      papers: (json['papers'] as List<dynamic>?)
              ?.map((e) => Paper.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      sources: (json['sources'] as List<dynamic>?)
              ?.map((e) => SourceStatus.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class PaperCollection {
  final String id;
  final String name;
  final String color;

  const PaperCollection({
    required this.id,
    required this.name,
    this.color = '#0061A4',
  });

  factory PaperCollection.fromJson(Map<String, dynamic> json) {
    return PaperCollection(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      color: json['color'] as String? ?? '#0061A4',
    );
  }
}
