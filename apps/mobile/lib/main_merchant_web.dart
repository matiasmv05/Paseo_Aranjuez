import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paseo_mobile/features/merchant/presentation/merchant_app.dart';

/// Punto de entrada de la app web del comercio (T107).
void main() {
  runApp(const ProviderScope(child: MerchantApp()));
}
