import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:elder_shield/services/url_expander.dart';

/// Shows a bottom sheet that expands [shortUrl] and lets the user decide
/// whether to open the final destination.
void showUrlPreviewSheet(BuildContext context, String shortUrl) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _UrlPreviewSheet(shortUrl: shortUrl),
  );
}

class _UrlPreviewSheet extends StatefulWidget {
  const _UrlPreviewSheet({required this.shortUrl});
  final String shortUrl;

  @override
  State<_UrlPreviewSheet> createState() => _UrlPreviewSheetState();
}

class _UrlPreviewSheetState extends State<_UrlPreviewSheet> {
  String? _finalUrl;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _expand();
  }

  Future<void> _expand() async {
    final result = await UrlExpander.expand(widget.shortUrl);
    if (mounted) setState(() { _finalUrl = result; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isSame = _finalUrl == widget.shortUrl;

    return Padding(
      padding: EdgeInsets.only(
        left: 24, right: 24, top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.link, color: colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'Link destination',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _UrlRow(label: 'Original', url: widget.shortUrl),
          if (_loading) ...[
            const SizedBox(height: 12),
            const Row(
              children: [
                SizedBox(
                  width: 16, height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 10),
                Text('Checking where this leads…'),
              ],
            ),
          ] else if (!isSame) ...[
            const SizedBox(height: 4),
            const Divider(),
            const SizedBox(height: 4),
            _UrlRow(
              label: 'Leads to',
              url: _finalUrl!,
              highlight: true,
            ),
          ],
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _loading
                      ? null
                      : () async {
                          final url = Uri.tryParse(_finalUrl ?? widget.shortUrl);
                          if (url != null && await canLaunchUrl(url)) {
                            await launchUrl(url,
                                mode: LaunchMode.externalApplication);
                          }
                          if (context.mounted) Navigator.of(context).pop();
                        },
                  icon: const Icon(Icons.open_in_new, size: 18),
                  label: const Text('Open link'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _UrlRow extends StatelessWidget {
  const _UrlRow({
    required this.label,
    required this.url,
    this.highlight = false,
  });

  final String label;
  final String url;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 72,
          child: Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(
          child: Text(
            url,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: highlight ? theme.colorScheme.primary : null,
              fontWeight: highlight ? FontWeight.w500 : null,
            ),
          ),
        ),
      ],
    );
  }
}
