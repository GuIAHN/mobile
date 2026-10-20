import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/provider_feedback/provider_feedback_scope.dart';
import '../providers/reviews_providers.dart';
import 'provider_review_action_card.dart';
import 'provider_reviews_button.dart';

/// Adaptador instalado por la composición de rutas para el contrato compartido.
class ProviderFeedbackIntegration extends ConsumerWidget {
  final Widget child;

  const ProviderFeedbackIntegration({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) => ProviderFeedbackScope(
        buildReviewsButton: (target) =>
            ProviderReviewsButton(targetId: target.userId),
        buildReviewAction: (target) => ProviderReviewActionCard(
          targetId: target.userId,
          providerProfileId: target.profileId,
          providerName: target.name,
          offerId: target.offerId,
        ),
        registerContact: (profileId, channel) => registerProviderContact(
          ref,
          providerProfileId: profileId,
          channel: channel,
        ),
        child: child,
      );
}
