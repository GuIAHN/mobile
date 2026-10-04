import 'package:flutter/material.dart';

import 'chat_inbox_page.dart';

/// Historial de ventas entregadas y canceladas de la tienda.
class StoreSalesPage extends StatelessWidget {
  const StoreSalesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const RequestsInboxPage(
      mode: RequestInboxMode.storeSales,
    );
  }
}
