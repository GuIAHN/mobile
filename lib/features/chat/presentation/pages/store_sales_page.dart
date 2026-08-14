import 'package:flutter/material.dart';

import 'chat_inbox_page.dart';

/// Gestión de solicitudes recibidas, cotizaciones y ventas de la tienda.
class StoreSalesPage extends StatelessWidget {
  const StoreSalesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const RequestManagementPage(isStore: true);
  }
}
