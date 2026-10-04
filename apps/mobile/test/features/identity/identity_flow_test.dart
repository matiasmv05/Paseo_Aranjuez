import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:paseo_mobile/core/di/injection.dart';
import 'package:paseo_mobile/features/identity/registration_screen.dart';
import 'package:paseo_mobile/features/identity/otp_verify_screen.dart';

void main() {
  setUp(() {
    InjectionContainer.setupDependencies(useMock: true);
  });
  testWidgets('Registration flow', (WidgetTester tester) async {
    await tester.pumpWidget(RegistrationScreen());
    expect(find.text('Register'), findsOneWidget);
  });

  testWidgets('Registration form interaction', (WidgetTester tester) async {
    await tester.pumpWidget(RegistrationScreen());
    final phoneField = find.byKey(const Key('phoneField'));
    final emailField = find.byKey(const Key('emailField'));
    final passwordField = find.byKey(const Key('passwordField'));
    final submitButton = find.byKey(const Key('registerButton'));

    expect(phoneField, findsOneWidget);
    expect(emailField, findsOneWidget);
    expect(passwordField, findsOneWidget);
    expect(submitButton, findsOneWidget);

    await tester.enterText(phoneField, '+59112345678');
    await tester.enterText(emailField, 'test@example.com');
    await tester.enterText(passwordField, 'Password123');
    await tester.tap(submitButton);
    await tester.pumpAndSettle();
  });

  testWidgets('Navigate to OtpVerifyScreen after register', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(RegistrationScreen());
    final submitButton = find.byKey(const Key('registerButton'));
    await tester.tap(submitButton);
    await tester.pumpAndSettle();
    expect(find.text('Verify OTP'), findsOneWidget);
  });

  testWidgets('OTP verification flow', (WidgetTester tester) async {
    await tester.pumpWidget(OtpVerifyScreen());
    final otpField = find.byKey(const Key('otpField'));
    final verifyBtn = find.byKey(const Key('verifyOtpButton'));

    expect(otpField, findsOneWidget);
    expect(verifyBtn, findsOneWidget);

    await tester.enterText(otpField, '123456');
    await tester.tap(verifyBtn);
    await tester.pumpAndSettle();

    expect(find.text('Login Screen'), findsOneWidget);
  });
}
