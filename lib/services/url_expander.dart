import 'dart:io';

/// Follows HTTP redirects and returns the final destination URL.
/// Used to reveal where a short link actually leads before the user opens it.
class UrlExpander {
  const UrlExpander._();

  /// Resolves [url] by following up to 5 redirect hops with a 5 s timeout.
  /// Returns the final URL string, or [url] unchanged on any error.
  static Future<String> expand(String url) async {
    Uri current;
    try {
      current = Uri.parse(url);
    } catch (_) {
      return url;
    }
    if (!current.hasScheme) return url;

    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 5)
      ..idleTimeout = const Duration(seconds: 3);

    try {
      for (var hop = 0; hop < 5; hop++) {
        final request = await client.openUrl('HEAD', current);
        request.followRedirects = false;
        request.headers
          ..set(HttpHeaders.userAgentHeader, 'ElderShield/1.0')
          ..set(HttpHeaders.acceptHeader, '*/*');

        final response = await request.close();
        await response.drain<void>();

        final status = response.statusCode;
        final isRedirect =
            status == 301 || status == 302 || status == 303 ||
            status == 307 || status == 308;
        if (!isRedirect) break;

        final location = response.headers.value(HttpHeaders.locationHeader);
        if (location == null) break;
        current = current.resolve(location);
      }
      return current.toString();
    } catch (_) {
      return url;
    } finally {
      client.close();
    }
  }
}
