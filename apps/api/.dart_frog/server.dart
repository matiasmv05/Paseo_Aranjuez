// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, implicit_dynamic_list_literal

import 'dart:io';

import 'package:dart_frog/dart_frog.dart';


import '../routes/ready.dart' as ready;
import '../routes/health.dart' as health;
import '../routes/auth/verify-email.dart' as auth_verify_email;
import '../routes/auth/register.dart' as auth_register;
import '../routes/auth/refresh.dart' as auth_refresh;
import '../routes/auth/logout.dart' as auth_logout;
import '../routes/auth/login.dart' as auth_login;
import '../routes/auth/phone/verify.dart' as auth_phone_verify;
import '../routes/auth/phone/send-otp.dart' as auth_phone_send_otp;
import '../routes/auth/password/reset.dart' as auth_password_reset;
import '../routes/auth/password/forgot.dart' as auth_password_forgot;

import '../routes/_middleware.dart' as middleware;
import '../routes/auth/_middleware.dart' as auth_middleware;

void main() async {
  final address = InternetAddress.tryParse('') ?? InternetAddress.anyIPv6;
  final port = int.tryParse(Platform.environment['PORT'] ?? '8080') ?? 8080;
  hotReload(() => createServer(address, port));
}

Future<HttpServer> createServer(InternetAddress address, int port) {
  final handler = Cascade().add(buildRootHandler()).handler;
  return serve(handler, address, port);
}

Handler buildRootHandler() {
  final pipeline = const Pipeline().addMiddleware(middleware.middleware);
  final router = Router()
    ..mount('/', (context) => buildHandler()(context))
    ..mount('/auth', (context) => buildAuthHandler()(context))
    ..mount('/auth/phone', (context) => buildAuthPhoneHandler()(context))
    ..mount('/auth/password', (context) => buildAuthPasswordHandler()(context));
  return pipeline.addHandler(router);
}

Handler buildHandler() {
  final pipeline = const Pipeline();
  final router = Router()
    ..all('/health', (context) => health.onRequest(context,))..all('/ready', (context) => ready.onRequest(context,));
  return pipeline.addHandler(router);
}

Handler buildAuthHandler() {
  final pipeline = const Pipeline().addMiddleware(auth_middleware.middleware);
  final router = Router()
    ..all('/login', (context) => auth_login.onRequest(context,))..all('/logout', (context) => auth_logout.onRequest(context,))..all('/refresh', (context) => auth_refresh.onRequest(context,))..all('/register', (context) => auth_register.onRequest(context,))..all('/verify-email', (context) => auth_verify_email.onRequest(context,));
  return pipeline.addHandler(router);
}

Handler buildAuthPhoneHandler() {
  final pipeline = const Pipeline().addMiddleware(auth_middleware.middleware);
  final router = Router()
    ..all('/send-otp', (context) => auth_phone_send_otp.onRequest(context,))..all('/verify', (context) => auth_phone_verify.onRequest(context,));
  return pipeline.addHandler(router);
}

Handler buildAuthPasswordHandler() {
  final pipeline = const Pipeline().addMiddleware(auth_middleware.middleware);
  final router = Router()
    ..all('/forgot', (context) => auth_password_forgot.onRequest(context,))..all('/reset', (context) => auth_password_reset.onRequest(context,));
  return pipeline.addHandler(router);
}

