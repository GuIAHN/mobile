import 'package:flutter/material.dart';

import 'chat_inbox_page.dart';

/// Solicitudes activas que la tienda debe responder, cotizar o entregar.
class StoreRequestsPage extends StatelessWidget {
  const StoreRequestsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const RequestsInboxPage(
      mode: RequestInboxMode.storeRequests,
    );
  }
}
