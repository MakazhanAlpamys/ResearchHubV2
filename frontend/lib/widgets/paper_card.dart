import 'package:flutter/material.dart';

import '../models/paper.dart';
import '../screens/details/paper_detail_screen.dart';

class PaperCard extends StatelessWidget {
  final Paper paper;
  const PaperCard({super.key, required this.paper});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PaperDetailScreen(paper: paper),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  paper.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                // Authors
                if (paper.authors.isNotEmpty)
                  Text(
                    paper.authorsShort,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                const SizedBox(height: 6),
                // Abstract snippet
                if (paper.abstract_.isNotEmpty)
                  Text(
                    paper.abstract_,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                const SizedBox(height: 10),
                // Bottom badges
                Row(
                  children: [
                    if (paper.year.isNotEmpty)
                      _Badge(
                        icon: Icons.calendar_today,
                        label: paper.year,
                        theme: theme,
                      ),
                    if (paper.source.isNotEmpty) ...[  
                      const SizedBox(width: 8),
                      _Badge(
                        icon: Icons.source,
                        label: paper.source,
                        theme: theme,
                      ),
                    ],
                    const Spacer(),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 14,
                      color: theme.colorScheme.outlineVariant,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final IconData icon;
  final String label;
  final ThemeData theme;

  const _Badge({
    required this.icon,
    required this.label,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
