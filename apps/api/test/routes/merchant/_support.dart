/// Helpers compartidos por las pruebas de rutas del panel del comercio.
library;

import 'dart:convert';

import 'package:dart_frog/dart_frog.dart';
import 'package:mocktail/mocktail.dart';
import 'package:paseo_api/adapters/in/merchant_use_cases.dart';
import 'package:paseo_api/application/identity/ports.dart';
import 'package:paseo_api/application/merchant/ports.dart';
import 'package:paseo_api/application/merchant/use_cases/identify_customer.dart';
import 'package:paseo_api/domain/identity/identity.dart';
import 'package:paseo_shared/paseo_shared.dart' as contract;

class MockContext extends Mock implements RequestContext {}

class FixedClock implements Clock {
  FixedClock([DateTime? now]) : _now = now ?? DateTime.utc(2026);

  final DateTime _now;

  @override
  DateTime nowUtc() => _now;
}

class FakeRateLimiter implements RateLimiter {
  FakeRateLimiter({this.allowed = true});

  bool allowed;
  int calls = 0;

  @override
  Future<bool> tryAcquire({
    required String establishmentId,
    required MerchantAction action,
  }) async {
    calls++;
    return allowed;
  }
}

class StubVerifier implements TokenVerifier {
  StubVerifier([this.claims]);

  AuthClaims? claims;

  @override
  AuthClaims? verify(String token, {required DateTime now}) => claims;
}

class StubUsers implements UserRepository {
  StubUsers({this.user});

  User? user;

  @override
  Future<User?> findById(String id) async => user;

  @override
  Future<User?> findByEmail(Email email) async => null;

  @override
  Future<User?> insertIfAbsent({
    required String id,
    required Email email,
    required String passwordHash,
    required UserRole role,
  }) async => null;

  @override
  Future<void> incrementTokenVersion(String userId) async {}

  @override
  Future<void> setPassword({
    required String userId,
    required String passwordHash,
  }) async {}

  @override
  Future<void> markEmailVerified(String userId) async {}
}

class StubEstablishments implements EstablishmentRepository {
  StubEstablishments({this.context});

  MerchantContext? context;

  @override
  Future<MerchantContext?> findContext(String userId) async => context;

  @override
  Future<CustomerRecord?> findCustomerByPhone(String phone) async => null;

  @override
  Future<CustomerRecord?> findCustomerByUserId(String userId) async => null;
}

MerchantContext sampleMerchant({
  MerchantRole role = MerchantRole.owner,
  String establishmentId = 'est-1',
  String? branchId,
}) => MerchantContext(
  establishmentId: establishmentId,
  establishmentName: 'Comercio Uno',
  userId: 'user-1',
  role: role,
  branchId: branchId,
);

User sampleUser({
  UserStatus status = UserStatus.active,
  bool phoneVerified = true,
  int tokenVersion = 0,
}) => User(
  id: 'user-1',
  email: 'owner@paseo.dev',
  passwordHash: 'phc',
  role: UserRole.merchantOwner,
  status: status,
  tokenVersion: tokenVersion,
  emailVerified: true,
  phoneVerified: phoneVerified,
);

AuthClaims sampleClaims({
  String audience = 'paseo-web-merchant',
  UserRole role = UserRole.merchantOwner,
  String subject = 'user-1',
  String? establishmentId = 'est-1',
  String? branchId,
  bool phoneVerified = true,
  int tokenVersion = 0,
}) => AuthClaims(
  issuer: 'paseo-api',
  audience: audience,
  subject: subject,
  issuedAt: DateTime.utc(2026),
  expiresAt: DateTime.utc(2026).add(const Duration(minutes: 15)),
  jwtId: 'jti-1',
  role: role,
  customerId: null,
  establishmentId: establishmentId,
  branchId: branchId,
  phoneVerified: phoneVerified,
  emailVerified: true,
  tokenVersion: tokenVersion,
);

MerchantDependencies merchantDeps({
  IdentifyFn? identify,
  PreviewFn? preview,
  RegisterPurchaseFn? register,
  ListMovementsFn? list,
  TokenVerifier? verifier,
  UserRepository? users,
  EstablishmentRepository? establishments,
  RateLimiter? rateLimiter,
  Clock? clock,
}) => MerchantDependencies(
  identifyCustomer:
      identify ??
      ({
        required MerchantContext context,
        required IdentifyInput input,
      }) async => throw StateError('identify no configurado'),
  previewPurchase:
      preview ??
      ({
        required MerchantContext context,
        required contract.PreviewPurchaseRequest request,
      }) async => throw StateError('preview no configurado'),
  registerPurchase:
      register ??
      ({
        required MerchantContext context,
        required contract.RegisterPurchaseRequest request,
        required String idempotencyKey,
      }) async => throw StateError('register no configurado'),
  listMovements:
      list ??
      ({required MerchantContext context, int? limit, String? cursor}) async =>
          throw StateError('movements no configurado'),
  verifier: verifier ?? StubVerifier(),
  users: users ?? StubUsers(),
  establishments: establishments ?? StubEstablishments(),
  rateLimiter: rateLimiter ?? FakeRateLimiter(),
  clock: clock ?? FixedClock(),
);

RequestContext routeContext({
  required String method,
  required String path,
  required MerchantDependencies deps,
  MerchantContext? merchant,
  Object? body,
  Map<String, String> headers = const {},
}) {
  final ctx = MockContext();
  when(() => ctx.request).thenReturn(
    Request(
      method,
      Uri.parse('http://localhost$path'),
      headers: {'content-type': 'application/json', ...headers},
      body: body is String ? body : (body == null ? null : jsonEncode(body)),
    ),
  );
  when(() => ctx.read<MerchantContext>())
      .thenReturn(merchant ?? sampleMerchant());
  when(() => ctx.read<Future<MerchantDependencies>>())
      .thenAnswer((_) async => deps);
  return ctx;
}

RequestContext middlewareContext({
  required MerchantDependencies deps,
  String? authorization,
}) {
  final ctx = MockContext();
  when(() => ctx.request).thenReturn(
    Request(
      'POST',
      Uri.parse('http://localhost/merchant/customers/identify'),
      headers: {if (authorization != null) 'authorization': authorization},
    ),
  );
  when(() => ctx.read<Future<MerchantDependencies>>())
      .thenAnswer((_) async => deps);
  when(() => ctx.provide<MerchantContext>(any())).thenReturn(ctx);
  return ctx;
}
