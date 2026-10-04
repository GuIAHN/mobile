import 'package:flutter/material.dart';

import 'chat_inbox_page.dart';

class ConsumerRequestsPage extends StatelessWidget {
  const ConsumerRequestsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const RequestsInboxPage(
      mode: RequestInboxMode.consumerRequests,
    );
  }
}
