import 'dart:async';
import 'dart:io';

import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:paseo_api/application/identity/ports.dart';
import 'package:paseo_api/domain/identity/identity.dart';

/// Email message content for identity notifications.
final class EmailMessage {
  const EmailMessage({
    required this.to,
    required this.subject,
    required this.body,
  });

  final String to;
  final String subject;
  final String body;
}

/// SMTP configuration read from environment.
final class SmtpConfig {
  const SmtpConfig({
    required this.host,
    required this.port,
    required this.username,
    required this.password,
    required this.from,
  });

  final String host;
  final int port;
  final String username;
  final String password;
  final String from;

  factory SmtpConfig.fromEnv() {
    final host = Platform.environment['SMTP_HOST'] ?? 'smtp.gmail.com';
    final port = int.tryParse(Platform.environment['SMTP_PORT'] ?? '') ?? 587;
    final username = Platform.environment['SMTP_USER'] ?? '';
    final password = Platform.environment['SMTP_PASSWORD'] ?? '';
    final from = Platform.environment['SMTP_FROM'] ?? '';
    return SmtpConfig(
      host: host,
      port: port,
      username: username,
      password: password,
      from: from,
    );
  }

  bool get isConfigured =>
      host.isNotEmpty && username.isNotEmpty && password.isNotEmpty;
}

/// SMTP email sender using `mailer` 7.2.0.
/// Uses STARTTLS (port 587) with Gmail/Google Workspace.
/// Reads configuration from environment; no hardcoded credentials.
final class SmtpEmailSender implements EmailSender {
  const SmtpEmailSender({required SmtpConfig config}) : _config = config;

  final SmtpConfig _config;

  @override
  Future<void> sendEmailVerification({
    required Email email,
    required String token,
  }) async {
    await _send(
      to: email.value,
      subject: 'Verifica tu correo — Paseo Points',
      body:
          'Tu token de verificación es: $token\n\nEste enlace expira en 24 horas.',
    );
  }

  @override
  Future<void> sendPasswordReset({
    required Email email,
    required String token,
  }) async {
    await _send(
      to: email.value,
      subject: 'Recupera tu contraseña — Paseo Points',
      body:
          'Tu token de recuperación es: $token\n\nEste enlace expira en 30 minutos y solo se puede usar una vez.',
    );
  }

  /// Send email via SMTP.
  Future<void> _send({
    required String to,
    required String subject,
    required String body,
  }) async {
    if (!_config.isConfigured) {
      throw EmailNotConfiguredException(
        'SMTP not configured: set SMTP_HOST, SMTP_USER, SMTP_PASSWORD, SMTP_FROM',
      );
    }
    final smtpServer = SmtpServer(
      _config.host,
      port: _config.port,
      username: _config.username,
      password: _config.password,
      // STARTTLS on port 587
      ssl: false,
    );
    final message = Message()
      ..from = Address(_config.from)
      ..recipients.add(Address(to))
      ..subject = subject
      ..text = body;
    try {
      await send(message, smtpServer);
    } on MailerException catch (e) {
      throw EmailSendException('SMTP send failed: ${e.message}', e);
    }
  }
}

/// Exception when SMTP is not configured.
class EmailNotConfiguredException implements Exception {
  EmailNotConfiguredException(this.message);
  final String message;
}

/// Exception when SMTP send fails.
class EmailSendException implements Exception {
  EmailSendException(this.message, this.cause);
  final String message;
  final MailerException cause;
}
