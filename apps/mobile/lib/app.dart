import 'package:flutter/material.dart';
import 'package:paseo_mobile/design_system/tokens/paseo_theme.dart';
import 'package:paseo_mobile/pages/admin_overview_page.dart';
import 'package:paseo_mobile/pages/customer_main_page.dart';
import 'package:paseo_mobile/pages/merchant_pos_page.dart';

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
      title: 'Paseo Points — Boutique POS Terminal',
      debugShowCheckedModeBanner: false,
      theme: PaseoTheme.darkTheme,
      home: const MerchantPosPage(),
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
      title: 'Paseo Points — Executive Overview',
      debugShowCheckedModeBanner: false,
      theme: PaseoTheme.darkTheme,
      home: const AdminOverviewPage(),
    );
  }
}
