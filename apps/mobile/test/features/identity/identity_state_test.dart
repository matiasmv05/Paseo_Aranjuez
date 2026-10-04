import 'package:flutter_test/flutter_test.dart';
import 'package:paseo_mobile/features/identity/identity_state.dart';

void main() {
  test('initial state is idle', () {
    final state = IdentityState();
    expect(state.status, IdentityStatus.initial);
  });

  test('register transitions to loading then success', () async {
    final state = IdentityState();
    await state.register(
      phone: '+59112345678',
      email: 'test@example.com',
      password: 'Password123',
    );
    expect(state.status, IdentityStatus.success);
  });

  test('register with error sets error status and message', () async {
    final state = IdentityState();
    await state.register(
      phone: '+59112345678',
      email: 'test@example.com',
      password: 'Password123',
      fail: true,
    );
    expect(state.status, IdentityStatus.error);
    expect(state.error, contains('Registration failed'));
  });
}
