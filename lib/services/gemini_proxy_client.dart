import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

/// HTTP transport that redirects Google Gemini traffic through our Supabase
/// `gemini-proxy` Edge Function so the Gemini API key never ships in the client.
///
/// The `google_generative_ai` SDK builds and sends requests to
/// `https://generativelanguage.googleapis.com/...`; passing this client as the
/// SDK's `httpClient:` lets us rewrite only the origin to the Edge Function,
/// preserving the path + query + body verbatim. We strip Google's
/// `x-goog-api-key` header (the SDK sends a dummy value) and attach Supabase
/// auth instead — the proxy supplies the real key server-side.
///
/// Non-Gemini requests pass through untouched.
class GeminiProxyClient extends http.BaseClient {
  GeminiProxyClient([http.Client? inner]) : _inner = inner ?? http.Client();

  final http.Client _inner;

  static const String _supabaseUrl =
      String.fromEnvironment('SUPABASE_URL', defaultValue: '');
  static const String _anonKey =
      String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');

  static const String _googleHost = 'generativelanguage.googleapis.com';

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    if (request.url.host != _googleHost) {
      return _inner.send(request);
    }

    // Rewrite origin -> Supabase function, preserving path + query.
    // e.g. /v1beta/models/gemini-2.5-flash:generateContent
    //   -> /functions/v1/gemini-proxy/v1beta/models/gemini-2.5-flash:generateContent
    final proxied = request.url.replace(
      scheme: 'https',
      host: Uri.parse(_supabaseUrl).host,
      port: null,
      path: '/functions/v1/gemini-proxy${request.url.path}',
    );

    // Live access token (handles refresh). Fall back to the anon key for an
    // unauthenticated session — the function still enforces a valid user JWT.
    final token =
        Supabase.instance.client.auth.currentSession?.accessToken ?? _anonKey;

    final newRequest = http.Request(request.method, proxied)
      ..followRedirects = request.followRedirects
      ..maxRedirects = request.maxRedirects
      ..persistentConnection = request.persistentConnection
      ..headers.addAll(request.headers);

    if (request is http.Request) {
      newRequest.bodyBytes = request.bodyBytes;
    }

    // Swap Google's key header for Supabase auth.
    newRequest.headers.remove('x-goog-api-key');
    newRequest.headers.remove('X-Goog-Api-Key');
    newRequest.headers['Authorization'] = 'Bearer $token';
    newRequest.headers['apikey'] = _anonKey;

    return _inner.send(newRequest);
  }

  @override
  void close() {
    _inner.close();
    super.close();
  }
}
