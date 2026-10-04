import 'package:flutter/material.dart';

/// Widget raíz del comercio (flujo comercio).
class MerchantWebApp extends StatelessWidget {
  /// Crea la app placeholder del comercio.
  const MerchantWebApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Paseo Points — Comercio',
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(title: const Text('Paseo Points — Comercio')),
        body: const Center(child: Text('Commerce dashboard (placeholder)')),
      ),
    );
  }
}

/// Widget raíz de la administración (flujo admin).
class AdminWebApp extends StatelessWidget {
  /// Crea la app placeholder de la administracion.
  const AdminWebApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Paseo Points — Administración',
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(title: const Text('Paseo Points — Administración')),
        body: const Center(child: Text('Admin panel (placeholder)')),
      ),
    );
  }
}
