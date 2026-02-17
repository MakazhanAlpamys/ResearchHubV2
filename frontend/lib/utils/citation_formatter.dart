import '../models/paper.dart';

class CitationFormatter {
  CitationFormatter._();

  static String toBibtex(Paper paper) {
    final key = _bibtexKey(paper);
    final authorStr = paper.authors.join(' and ');
    final buf = StringBuffer('@article{$key,\n');
    buf.writeln('  title     = {${paper.title}},');
    if (paper.authors.isNotEmpty) {
      buf.writeln('  author    = {$authorStr},');
    }
    if (paper.year.isNotEmpty) {
      buf.writeln('  year      = {${paper.year}},');
    }
    if (paper.url.isNotEmpty) {
      buf.writeln('  url       = {${paper.url}},');
    }
    buf.writeln('}');
    return buf.toString();
  }

  static String toApa(Paper paper) {
    final authors = _apaAuthors(paper.authors);
    final year = paper.year.isNotEmpty ? '(${paper.year})' : '(n.d.)';
    final title = paper.title;
    final url = paper.url.isNotEmpty ? ' ${paper.url}' : '';
    return '$authors $year. $title.$url';
  }

  static String toMla(Paper paper) {
    final authors = _mlaAuthors(paper.authors);
    final year = paper.year.isNotEmpty ? ' ${paper.year}' : '';
    final url = paper.url.isNotEmpty ? ' ${paper.url}' : '';
    return '$authors "${paper.title}."$year.$url';
  }

  static String _bibtexKey(Paper paper) {
    final first = paper.authors.isNotEmpty
        ? paper.authors.first.split(' ').last.toLowerCase()
        : 'unknown';
    final year = paper.year.isNotEmpty ? paper.year : 'nd';
    return '$first$year';
  }

  static String _apaAuthors(List<String> authors) {
    if (authors.isEmpty) return 'Unknown';
    if (authors.length == 1) return _apaName(authors.first);
    if (authors.length == 2) {
      return '${_apaName(authors[0])}, & ${_apaName(authors[1])}';
    }
    return '${_apaName(authors.first)}, et al.';
  }

  static String _apaName(String fullName) {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.length < 2) return fullName;
    final last = parts.last;
    final initials =
        parts.sublist(0, parts.length - 1).map((p) => '${p[0]}.').join(' ');
    return '$last, $initials';
  }

  static String _mlaAuthors(List<String> authors) {
    if (authors.isEmpty) return 'Unknown.';
    if (authors.length == 1) return '${authors.first}.';
    if (authors.length == 2) {
      return '${authors.first}, and ${authors[1]}.';
    }
    return '${authors.first}, et al.';
  }
}
