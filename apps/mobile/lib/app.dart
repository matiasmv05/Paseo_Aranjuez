import 'package:flutter/material.dart';
import 'package:paseo_mobile/design_system/tokens/paseo_theme.dart';
import 'package:paseo_mobile/pages/customer_main_page.dart';

/// Widget raíz de la aplicación móvil del cliente (Paseo Points).
class CustomerApp extends StatelessWidget {
  /// Crea la aplicación para el cliente final con el tema VIP Obsidian.
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Paseo Points — VIP Obsidian',
      debugShowCheckedModeBanner: false,
      theme: PaseoTheme.darkTheme,
      home: const CustomerMainPage(),
    );
  }
}

/// Widget raíz del comercio (flujo comercio).
class MerchantWebApp extends StatelessWidget {
  /// Crea la aplicación web de comercio.
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Paseo Points — Comercio',
      debugShowCheckedModeBanner: false,
      theme: PaseoTheme.darkTheme,
      home: Scaffold(
        appBar: AppBar(title: const Text('Paseo Points — Comercio')),
        body: const Center(child: Text('Commerce dashboard (placeholder)')),
      ),
    );
  }
}

/// Widget raíz de la administración (flujo admin).
class AdminWebApp extends StatelessWidget {
  /// Crea la aplicación web de administración.
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Paseo Points — Administración',
      debugShowCheckedModeBanner: false,
      theme: PaseoTheme.darkTheme,
      home: Scaffold(
        appBar: AppBar(title: const Text('Paseo Points — Administración')),
        body: const Center(child: Text('Admin panel (placeholder)')),
      ),
    );
  }
}
