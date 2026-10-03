import 'dart:collection';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:paseo_api/problem.dart';

class _Bucket {
  final List<DateTime> timestamps = <DateTime>[];
}

/// Sliding-window rate limiter for auth endpoints (T032; AGENTS.md §8).
/// Returns 429 `RATE_LIMITED` when the limit is exceeded within the window.
/// In-memory for MVP; move to Redis/DB via `system_settings` later.
Middleware rateLimiter({
  Map<String, int> limits = const {
    'login': 5,
    'otp': 5,
    'forgot': 3,
    'reset': 3,
  },
  Duration window = const Duration(minutes: 1),
}) {
  final buckets = HashMap<String, _Bucket>();

  return (handler) {
    return (context) async {
      final routeKey = _routeKey(context.request.uri.path);
      if (routeKey == null) return handler(context);

      final limit = limits[routeKey];
      if (limit == null) return handler(context);

      final ip = _clientIp(context.request);
      final key = '$routeKey:$ip';
      final now = DateTime.now();

      final bucket = buckets.putIfAbsent(key, _Bucket.new);
      bucket.timestamps.retainWhere((t) => now.difference(t) < window);

      if (bucket.timestamps.length >= limit) {
        return problemJson(
          status: HttpStatus.tooManyRequests,
          title: 'Too Many Requests',
          code: 'RATE_LIMITED',
          detail: 'Rate limit exceeded. Retry later.',
        );
      }

      bucket.timestamps.add(now);
      return handler(context);
    };
  };
}

String? _routeKey(String path) {
  final normalized = path.toLowerCase();
  if (normalized.startsWith('/auth/login')) return 'login';
  if (normalized.startsWith('/auth/phone/send-otp')) return 'otp';
  if (normalized.startsWith('/auth/password/forgot')) return 'forgot';
  if (normalized.startsWith('/auth/password/reset')) return 'reset';
  return null;
}

String _clientIp(Request request) {
  final xff = request.headers['x-forwarded-for'];
  if (xff != null && xff.isNotEmpty) return xff.split(',').first.trim();
  final xrip = request.headers['x-real-ip'];
  if (xrip != null && xrip.isNotEmpty) return xrip;
  try {
    return request.connectionInfo.remoteAddress.address;
  } on Object {
    return 'unknown';
  }
}
