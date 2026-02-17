import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/models/paper.dart';

void main() {
  group('Paper', () {
    final sampleJson = {
      'paper_id': 'arxiv:123',
      'title': 'Quantum Computing',
      'authors': ['Alice Smith', 'Bob Jones'],
      'abstract': 'A paper about quantum computing.',
      'published_date': '2025-01-15',
      'source': 'arxiv',
      'url': 'https://arxiv.org/abs/123',
      'pdf_url': 'https://arxiv.org/pdf/123',
    };

    test('fromJson parses all fields correctly', () {
      final paper = Paper.fromJson(sampleJson);

      expect(paper.paperId, 'arxiv:123');
      expect(paper.title, 'Quantum Computing');
      expect(paper.authors, ['Alice Smith', 'Bob Jones']);
      expect(paper.abstract_, 'A paper about quantum computing.');
      expect(paper.publishedDate, '2025-01-15');
      expect(paper.source, 'arxiv');
      expect(paper.url, 'https://arxiv.org/abs/123');
      expect(paper.pdfUrl, 'https://arxiv.org/pdf/123');
    });

    test('fromJson handles missing fields with defaults', () {
      final paper = Paper.fromJson({'paper_id': 'x'});

      expect(paper.paperId, 'x');
      expect(paper.title, '');
      expect(paper.authors, isEmpty);
      expect(paper.abstract_, '');
      expect(paper.publishedDate, isNull);
      expect(paper.source, '');
      expect(paper.url, '');
      expect(paper.pdfUrl, '');
    });

    test('fromJson handles completely empty map', () {
      final paper = Paper.fromJson({});
      expect(paper.paperId, '');
      expect(paper.authors, isEmpty);
    });

    test('toJson produces correct map', () {
      final paper = Paper.fromJson(sampleJson);
      final json = paper.toJson();

      expect(json['paper_id'], 'arxiv:123');
      expect(json['title'], 'Quantum Computing');
      expect(json['authors'], ['Alice Smith', 'Bob Jones']);
      expect(json['abstract'], 'A paper about quantum computing.');
      expect(json['published_date'], '2025-01-15');
      expect(json['source'], 'arxiv');
      expect(json['url'], 'https://arxiv.org/abs/123');
      expect(json['pdf_url'], 'https://arxiv.org/pdf/123');
    });

    test('fromJson -> toJson roundtrip preserves data', () {
      final paper = Paper.fromJson(sampleJson);
      final json = paper.toJson();
      final paper2 = Paper.fromJson(json);

      expect(paper2.paperId, paper.paperId);
      expect(paper2.title, paper.title);
      expect(paper2.authors, paper.authors);
      expect(paper2.abstract_, paper.abstract_);
      expect(paper2.publishedDate, paper.publishedDate);
      expect(paper2.source, paper.source);
      expect(paper2.url, paper.url);
      expect(paper2.pdfUrl, paper.pdfUrl);
    });

    test('toFavoriteRow includes user_id', () {
      final paper = Paper.fromJson(sampleJson);
      final row = paper.toFavoriteRow('user-1');

      expect(row['user_id'], 'user-1');
      expect(row['paper_id'], 'arxiv:123');
      expect(row['title'], 'Quantum Computing');
      expect(row.containsKey('collection_id'), isFalse);
    });

    test('toFavoriteRow includes collection_id when provided', () {
      final paper = Paper.fromJson(sampleJson);
      final row = paper.toFavoriteRow('user-1', collectionId: 'col-1');

      expect(row['collection_id'], 'col-1');
    });

    test('fromFavoriteRow parses collection_id', () {
      final row = {
        ...sampleJson,
        'collection_id': 'col-abc',
      };
      final paper = Paper.fromFavoriteRow(row);

      expect(paper.paperId, 'arxiv:123');
      expect(paper.collectionId, 'col-abc');
    });

    test('fromFavoriteRow handles null collection_id', () {
      final paper = Paper.fromFavoriteRow(sampleJson);
      expect(paper.collectionId, isNull);
    });

    group('year', () {
      test('extracts year from date string', () {
        const paper = Paper(paperId: 'x', title: 't', publishedDate: '2025-01-15');
        expect(paper.year, '2025');
      });

      test('returns empty string when publishedDate is null', () {
        const paper = Paper(paperId: 'x', title: 't');
        expect(paper.year, '');
      });

      test('returns empty string when publishedDate is too short', () {
        const paper = Paper(paperId: 'x', title: 't', publishedDate: '20');
        expect(paper.year, '');
      });

      test('extracts year from 4-char string', () {
        const paper = Paper(paperId: 'x', title: 't', publishedDate: '2024');
        expect(paper.year, '2024');
      });
    });

    group('authorsShort', () {
      test('returns empty string when no authors', () {
        const paper = Paper(paperId: 'x', title: 't');
        expect(paper.authorsShort, '');
      });

      test('returns single author name', () {
        const paper = Paper(paperId: 'x', title: 't', authors: ['Alice Smith']);
        expect(paper.authorsShort, 'Alice Smith');
      });

      test('returns "first et al." for multiple authors', () {
        const paper = Paper(paperId: 'x', title: 't', authors: ['Alice Smith', 'Bob Jones']);
        expect(paper.authorsShort, 'Alice Smith et al.');
      });

      test('returns "first et al." for three authors', () {
        const paper = Paper(paperId: 'x', title: 't', authors: ['A', 'B', 'C']);
        expect(paper.authorsShort, 'A et al.');
      });
    });
  });

  group('SourceStatus', () {
    test('fromJson parses correctly', () {
      final status = SourceStatus.fromJson({
        'name': 'arxiv',
        'ok': true,
      });
      expect(status.name, 'arxiv');
      expect(status.ok, isTrue);
      expect(status.error, isNull);
    });

    test('fromJson parses error', () {
      final status = SourceStatus.fromJson({
        'name': 'openalex',
        'ok': false,
        'error': 'timeout',
      });
      expect(status.name, 'openalex');
      expect(status.ok, isFalse);
      expect(status.error, 'timeout');
    });

    test('fromJson handles missing fields', () {
      final status = SourceStatus.fromJson({});
      expect(status.name, '');
      expect(status.ok, isTrue);
      expect(status.error, isNull);
    });
  });

  group('PaperSearchResult', () {
    test('fromJson parses full response', () {
      final result = PaperSearchResult.fromJson({
        'total': 42,
        'page': 2,
        'per_page': 10,
        'has_more': true,
        'papers': [
          {
            'paper_id': 'p1',
            'title': 'Paper One',
            'authors': ['Author A'],
          },
        ],
        'sources': [
          {'name': 'arxiv', 'ok': true},
        ],
      });

      expect(result.total, 42);
      expect(result.page, 2);
      expect(result.perPage, 10);
      expect(result.hasMore, isTrue);
      expect(result.papers, hasLength(1));
      expect(result.papers.first.paperId, 'p1');
      expect(result.sources, hasLength(1));
      expect(result.sources.first.name, 'arxiv');
    });

    test('fromJson handles empty data', () {
      final result = PaperSearchResult.fromJson({});

      expect(result.total, 0);
      expect(result.page, 1);
      expect(result.perPage, 10);
      expect(result.hasMore, isTrue);
      expect(result.papers, isEmpty);
      expect(result.sources, isEmpty);
    });

    test('fromJson handles has_more=false', () {
      final result = PaperSearchResult.fromJson({
        'total': 5,
        'page': 1,
        'per_page': 10,
        'has_more': false,
        'papers': [],
      });
      expect(result.hasMore, isFalse);
    });
  });

  group('PaperCollection', () {
    test('fromJson parses correctly', () {
      final col = PaperCollection.fromJson({
        'id': 'col-1',
        'name': 'My Collection',
        'color': '#FF0000',
      });
      expect(col.id, 'col-1');
      expect(col.name, 'My Collection');
      expect(col.color, '#FF0000');
    });

    test('fromJson uses default color', () {
      final col = PaperCollection.fromJson({
        'id': 'col-2',
        'name': 'Test',
      });
      expect(col.color, '#0061A4');
    });

    test('fromJson handles empty map', () {
      final col = PaperCollection.fromJson({});
      expect(col.id, '');
      expect(col.name, '');
      expect(col.color, '#0061A4');
    });
  });
}
