import 'package:flutter/material.dart';

import 'chat_inbox_page.dart';

/// Gestión completa de solicitudes de compra del consumidor.
class ConsumerPurchasesPage extends StatelessWidget {
  const ConsumerPurchasesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const RequestManagementPage(isStore: false);
  }
}

/// Alias temporal para no romper referencias externas mientras se migra el
/// nombre histórico de la pantalla.
@Deprecated('Use ConsumerPurchasesPage instead')
class MisComprasPage extends ConsumerPurchasesPage {
  const MisComprasPage({super.key});
}
