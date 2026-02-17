import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/models/paper.dart';
import 'package:frontend/utils/citation_formatter.dart';

void main() {
  final paper = Paper(
    paperId: 'arxiv:2025.12345',
    title: 'Deep Learning for Scientific Discovery',
    authors: ['Alice Smith', 'Bob Jones', 'Carol Lee'],
    abstract_: 'We present a novel approach...',
    publishedDate: '2025-06-15',
    source: 'arxiv',
    url: 'https://arxiv.org/abs/2025.12345',
    pdfUrl: 'https://arxiv.org/pdf/2025.12345',
  );

  group('CitationFormatter.toBibtex', () {
    test('generates valid BibTeX entry', () {
      final bib = CitationFormatter.toBibtex(paper);

      expect(bib, contains('@article{'));
      expect(bib, contains('smith2025'));
      expect(bib, contains('title     = {Deep Learning for Scientific Discovery}'));
      expect(bib, contains('author    = {Alice Smith and Bob Jones and Carol Lee}'));
      expect(bib, contains('year      = {2025}'));
      expect(bib, contains('url       = {https://arxiv.org/abs/2025.12345}'));
      expect(bib, endsWith('}\n'));
    });

    test('handles single author', () {
      const p = Paper(
        paperId: 'x',
        title: 'A Paper',
        authors: ['John Doe'],
        publishedDate: '2024-01-01',
      );
      final bib = CitationFormatter.toBibtex(p);
      expect(bib, contains('author    = {John Doe}'));
      expect(bib, contains('doe2024'));
    });

    test('handles no authors', () {
      const p = Paper(paperId: 'x', title: 'A Paper');
      final bib = CitationFormatter.toBibtex(p);
      expect(bib, isNot(contains('author')));
      expect(bib, contains('unknown'));
    });

    test('handles no year', () {
      const p = Paper(paperId: 'x', title: 'A Paper', authors: ['A B']);
      final bib = CitationFormatter.toBibtex(p);
      expect(bib, isNot(contains('year')));
      expect(bib, contains('bnd'));
    });

    test('handles no URL', () {
      const p = Paper(
        paperId: 'x',
        title: 'A Paper',
        publishedDate: '2025-01-01',
      );
      final bib = CitationFormatter.toBibtex(p);
      expect(bib, isNot(contains('url')));
    });
  });

  group('CitationFormatter.toApa', () {
    test('formats multiple authors correctly', () {
      final apa = CitationFormatter.toApa(paper);
      // 3+ authors → first et al.
      expect(apa, contains('Smith, A.'));
      expect(apa, contains('et al.'));
      expect(apa, contains('(2025)'));
      expect(apa, contains('Deep Learning for Scientific Discovery'));
      expect(apa, contains('https://arxiv.org/abs/2025.12345'));
    });

    test('formats two authors with ampersand', () {
      const p = Paper(
        paperId: 'x',
        title: 'Test',
        authors: ['Alice Smith', 'Bob Jones'],
        publishedDate: '2024-01-01',
      );
      final apa = CitationFormatter.toApa(p);
      expect(apa, contains('Smith, A.'));
      expect(apa, contains('& Jones, B.'));
    });

    test('formats single author', () {
      const p = Paper(
        paperId: 'x',
        title: 'Test',
        authors: ['Alice Smith'],
        publishedDate: '2024-01-01',
      );
      final apa = CitationFormatter.toApa(p);
      expect(apa, startsWith('Smith, A.'));
    });

    test('handles no authors', () {
      const p = Paper(paperId: 'x', title: 'Test');
      final apa = CitationFormatter.toApa(p);
      expect(apa, startsWith('Unknown'));
    });

    test('handles no year', () {
      const p = Paper(paperId: 'x', title: 'Test', authors: ['A B']);
      final apa = CitationFormatter.toApa(p);
      expect(apa, contains('(n.d.)'));
    });
  });

  group('CitationFormatter.toMla', () {
    test('formats multiple authors correctly', () {
      final mla = CitationFormatter.toMla(paper);
      expect(mla, contains('Alice Smith, et al.'));
      expect(mla, contains('"Deep Learning for Scientific Discovery."'));
      expect(mla, contains('2025'));
      expect(mla, contains('https://arxiv.org/abs/2025.12345'));
    });

    test('formats two authors', () {
      const p = Paper(
        paperId: 'x',
        title: 'Test',
        authors: ['Alice Smith', 'Bob Jones'],
        publishedDate: '2024-01-01',
      );
      final mla = CitationFormatter.toMla(p);
      expect(mla, contains('Alice Smith, and Bob Jones.'));
    });

    test('formats single author', () {
      const p = Paper(
        paperId: 'x',
        title: 'Test',
        authors: ['Alice Smith'],
        publishedDate: '2024-01-01',
      );
      final mla = CitationFormatter.toMla(p);
      expect(mla, startsWith('Alice Smith.'));
    });

    test('handles no authors', () {
      const p = Paper(paperId: 'x', title: 'Test');
      final mla = CitationFormatter.toMla(p);
      expect(mla, startsWith('Unknown.'));
    });
  });
}
