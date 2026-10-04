import 'customer_repository.dart';

/// Implementación simulada del perfil del cliente (desarrollo/tests).
class MockCustomerRepository implements CustomerRepository {
  @override
  Future<String> fetchQrTicket(String accessToken) async {
    await Future<void>.delayed(const Duration(milliseconds: 10));
    return 'qr-mock:$accessToken';
  }
}
