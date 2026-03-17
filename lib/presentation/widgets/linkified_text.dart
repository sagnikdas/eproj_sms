import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:elder_shield/presentation/messages/url_preview_sheet.dart';

/// Renders [text] as a [Text.rich], with any HTTP/HTTPS URLs highlighted and
/// tappable. Tapping a URL opens [showUrlPreviewSheet] so the user can inspect
/// the expanded destination before deciding whether to open it.
class LinkifiedText extends StatelessWidget {
  const LinkifiedText(
    this.text, {
    super.key,
    this.style,
  });

  final String text;
  final TextStyle? style;

  static final _urlPattern = RegExp(r'https?://[^\s]+', caseSensitive: false);

  @override
  Widget build(BuildContext context) {
    final matches = _urlPattern.allMatches(text).toList();
    if (matches.isEmpty) return Text(text, style: style);

    final linkColor = Theme.of(context).colorScheme.primary;
    final spans = <InlineSpan>[];
    var cursor = 0;

    for (final match in matches) {
      if (match.start > cursor) {
        spans.add(TextSpan(
          text: text.substring(cursor, match.start),
          style: style,
        ));
      }

      final url = match.group(0)!;
      spans.add(TextSpan(
        text: url,
        style: (style ?? const TextStyle()).copyWith(
          color: linkColor,
          decoration: TextDecoration.underline,
          decorationColor: linkColor,
        ),
        recognizer: TapGestureRecognizer()
          ..onTap = () => showUrlPreviewSheet(context, url),
      ));

      cursor = match.end;
    }

    if (cursor < text.length) {
      spans.add(TextSpan(text: text.substring(cursor), style: style));
    }

    return Text.rich(TextSpan(children: spans));
  }
}
