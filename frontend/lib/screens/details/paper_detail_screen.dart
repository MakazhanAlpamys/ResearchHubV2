import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/ai_service.dart';
import '../../utils/citation_formatter.dart';

import '../../core/l10n/app_localizations.dart';
import '../../models/paper.dart';
import '../../providers/favorites_provider.dart';
import '../../providers/locale_provider.dart';

final _aiServiceProvider = Provider<AiService>((ref) => AiService());

class PaperDetailScreen extends ConsumerStatefulWidget {
  final Paper paper;
  const PaperDetailScreen({super.key, required this.paper});

  @override
  ConsumerState<PaperDetailScreen> createState() => _PaperDetailScreenState();
}

class _PaperDetailScreenState extends ConsumerState<PaperDetailScreen> {
  String? _summary;
  bool _loadingSummary = false;
  String? _summaryError;

  String? _pdfAnalysis;
  bool _loadingPdf = false;
  String? _pdfError;

  bool _favBusy = false;

  Future<void> _generateSummary() async {
    setState(() {
      _loadingSummary = true;
      _summaryError = null;
    });

    try {
      final locale = ref.read(localeProvider);
      final ai = ref.read(_aiServiceProvider);
      final summary = await ai.summarize(
        title: widget.paper.title,
        abstract_: widget.paper.abstract_,
        language: locale.languageCode,
      );
      if (mounted) setState(() => _summary = summary);
    } catch (e) {
      if (mounted) setState(() => _summaryError = '$e');
    } finally {
      if (mounted) setState(() => _loadingSummary = false);
    }
  }

  Future<void> _analyzePdf() async {
    setState(() {
      _loadingPdf = true;
      _pdfError = null;
    });
    try {
      final locale = ref.read(localeProvider);
      final ai = ref.read(_aiServiceProvider);
      final analysis = await ai.analyzePdf(
        pdfUrl: widget.paper.pdfUrl,
        language: locale.languageCode,
      );
      if (mounted) setState(() => _pdfAnalysis = analysis);
    } catch (e) {
      if (mounted) setState(() => _pdfError = '$e');
    } finally {
      if (mounted) setState(() => _loadingPdf = false);
    }
  }

  Future<void> _toggleFavorite(bool isFav) async {
    if (_favBusy) return;
    setState(() => _favBusy = true);
    final l10n = AppLocalizations.of(context);
    try {
      final notifier = ref.read(favoritesProvider.notifier);
      if (isFav) {
        await notifier.remove(widget.paper.paperId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.removedFromFavorites)),
          );
        }
      } else {
        // Show collection picker when adding
        final collectionId = await _pickCollection();
        await notifier.add(widget.paper, collectionId: collectionId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.addedToFavorites)),
          );
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.error)),
        );
      }
    } finally {
      if (mounted) setState(() => _favBusy = false);
    }
  }

  Future<String?> _pickCollection() async {
    final collections =
        ref.read(collectionsProvider).valueOrNull ?? [];
    if (collections.isEmpty) return null;

    final l10n = AppLocalizations.of(context);
    return showModalBottomSheet<String?>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
              child: Text(l10n.moveToCollection,
                  style: Theme.of(ctx).textTheme.titleMedium),
            ),
            ListTile(
              leading: const Icon(Icons.inbox_outlined),
              title: Text(l10n.allFavorites),
              onTap: () => Navigator.pop(ctx, null),
            ),
            for (final col in collections)
              ListTile(
                leading: const Icon(Icons.folder_outlined),
                title: Text(col.name),
                onTap: () => Navigator.pop(ctx, col.id),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _showMoveToCollection() async {
    final collectionId = await _pickCollection();
    // null returned from sheet = "All Favorites" or dismissed
    if (!mounted) return;
    final l10n = AppLocalizations.of(context);
    try {
      await ref
          .read(favoritesProvider.notifier)
          .moveToCollection(widget.paper.paperId, collectionId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.addedToFavorites)),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.error)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final paper = widget.paper;

    final isFav = ref.watch(favoritesProvider).whenOrNull(
              data: (list) => list.any((p) => p.paperId == paper.paperId),
            ) ??
        false;

    return Scaffold(
      appBar: AppBar(
        title: Text(paper.source.toUpperCase()),
        actions: [
          // Favorite button with loading
          if (_favBusy)
            const Padding(
              padding: EdgeInsets.all(12),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            IconButton(
              tooltip:
                  isFav ? l10n.removeFromFavorites : l10n.addToFavorites,
              icon: Icon(
                isFav ? Icons.bookmark : Icons.bookmark_border,
                color: isFav ? theme.colorScheme.primary : null,
              ),
              onPressed: () => _toggleFavorite(isFav),
            ),
          // Citation export
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'move_collection') {
                _showMoveToCollection();
              } else {
                _copyCitation(value);
              }
            },
            itemBuilder: (_) => [
              if (isFav)
                PopupMenuItem(
                  value: 'move_collection',
                  child: Row(
                    children: [
                      const Icon(Icons.folder_outlined, size: 20),
                      const SizedBox(width: 8),
                      Text(l10n.moveToCollection),
                    ],
                  ),
                ),
              if (isFav) const PopupMenuDivider(),
              PopupMenuItem(
                value: 'bibtex',
                child: Row(
                  children: [
                    const Icon(Icons.format_quote, size: 20),
                    const SizedBox(width: 8),
                    const Text('BibTeX'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'apa',
                child: Row(
                  children: [
                    const Icon(Icons.format_quote, size: 20),
                    const SizedBox(width: 8),
                    const Text('APA'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'mla',
                child: Row(
                  children: [
                    const Icon(Icons.format_quote, size: 20),
                    const SizedBox(width: 8),
                    const Text('MLA'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Text(
              paper.title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            // Meta badge row
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                if (paper.year.isNotEmpty)
                  Chip(
                    avatar: const Icon(Icons.calendar_today, size: 16),
                    label: Text(paper.year),
                    visualDensity: VisualDensity.compact,
                  ),
                Chip(
                  avatar: const Icon(Icons.source, size: 16),
                  label: Text(paper.source),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Authors
            if (paper.authors.isNotEmpty) ...[
              Text(l10n.authors,
                  style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.primary)),
              const SizedBox(height: 4),
              Text(paper.authors.join(', '),
                  style: theme.textTheme.bodyMedium),
              const SizedBox(height: 20),
            ],
            // Abstract
            Text(l10n.abstract_,
                style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.primary)),
            const SizedBox(height: 4),
            Text(paper.abstract_,
                style:
                    theme.textTheme.bodyMedium?.copyWith(height: 1.5)),
            const SizedBox(height: 24),
            // PDF link + Analyze PDF
            if (paper.pdfUrl.isNotEmpty)
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _openUrl(paper.pdfUrl),
                    icon: const Icon(Icons.picture_as_pdf),
                    label: Text(l10n.openPdf),
                  ),
                  FilledButton.tonal(
                    onPressed: _loadingPdf ? null : _analyzePdf,
                    child: _loadingPdf
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2),
                          )
                        : Text(l10n.analyzePdf),
                  ),
                ],
              ),
            // PDF analysis result
            if (_pdfAnalysis != null) ...[
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
              Text(l10n.pdfAnalysis,
                  style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Card(
                color: theme.colorScheme.surfaceContainerLow,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: MarkdownBody(data: _pdfAnalysis!),
                ),
              ),
            ] else if (_pdfError != null) ...[
              const SizedBox(height: 12),
              Text(_pdfError!,
                  style: TextStyle(color: theme.colorScheme.error)),
            ],
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            // AI Summary section
            Text(l10n.aiSummary,
                style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            if (_summary != null)
              Card(
                color: theme.colorScheme.surfaceContainerLow,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: MarkdownBody(data: _summary!),
                ),
              )
            else if (_loadingSummary)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_summaryError != null)
              Column(
                children: [
                  Text(_summaryError!,
                      style:
                          TextStyle(color: theme.colorScheme.error)),
                  const SizedBox(height: 8),
                  FilledButton.tonal(
                    onPressed: _generateSummary,
                    child: Text(l10n.retry),
                  ),
                ],
              )
            else
              FilledButton.icon(
                onPressed: _generateSummary,
                icon: const Icon(Icons.auto_awesome),
                label: Text(l10n.generateSummary),
              ),
          ],
        ),
      ),
    );
  }

  void _copyCitation(String format) {
    final paper = widget.paper;
    final l10n = AppLocalizations.of(context);
    String text;
    switch (format) {
      case 'bibtex':
        text = CitationFormatter.toBibtex(paper);
        break;
      case 'apa':
        text = CitationFormatter.toApa(paper);
        break;
      case 'mla':
        text = CitationFormatter.toMla(paper);
        break;
      default:
        return;
    }
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.citationCopied)),
    );
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
