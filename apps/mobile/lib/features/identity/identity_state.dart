import 'package:flutter/foundation.dart';

enum IdentityStatus { initial, loading, success, error }

class IdentityState extends ChangeNotifier {
  IdentityStatus _status = IdentityStatus.initial;
  String? _error;

  IdentityStatus get status => _status;
  String? get error => _error;

  Future<void> register({required String phone, required String email, required String password, bool fail = false}) async {
    _status = IdentityStatus.loading;
    notifyListeners();
    try {
      // Simulated network call
      await Future.delayed(const Duration(milliseconds: 100));
      if (fail) {
        throw Exception('Registration failed');
      }
      _status = IdentityStatus.success;
      notifyListeners();
    } catch (e) {
      _status = IdentityStatus.error;
      _error = e.toString();
      notifyListeners();
    }
  }

  void reset() {
    _status = IdentityStatus.initial;
    _error = null;
    notifyListeners();
  }
}
