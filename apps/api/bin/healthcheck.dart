import 'dart:io';

/// Healthcheck para la imagen `scratch` (sin shell, sin wget/curl).
///
/// Docker Compose lo ejecuta en forma exec (`test: ["CMD", "/app/healthcheck"]`),
/// por lo que no necesita `/bin/sh`. Devuelve 0 si `/health` responde 200.
Future<void> main() async {
  final client = HttpClient();
  try {
    final request = await client
        .getUrl(Uri.parse('http://127.0.0.1:8080/health'))
        .timeout(const Duration(seconds: 3));
    final response = await request.close().timeout(const Duration(seconds: 3));
    await response.drain<void>();
    exitCode = response.statusCode == HttpStatus.ok ? 0 : 1;
  } catch (_) {
    exitCode = 1;
  } finally {
    client.close(force: true);
  }
}
