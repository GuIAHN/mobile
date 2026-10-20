import 'package:flutter/widgets.dart';

/// Datos de presentación que permiten componer reseñas sin importar features.
class ProviderFeedbackTarget {
  final String userId;
  final String profileId;
  final String name;
  final String? offerId;

  const ProviderFeedbackTarget({
    required this.userId,
    required this.profileId,
    required this.name,
    this.offerId,
  });
}

typedef ProviderFeedbackBuilder = Widget Function(
    ProviderFeedbackTarget target);
typedef RegisterProviderContact = Future<bool> Function(
    String profileId, String channel);

/// Contrato entre la ficha de un proveedor y el módulo de reseñas.
/// La composición concreta se instala desde el router, no desde otra feature.
class ProviderFeedbackScope extends InheritedWidget {
  final ProviderFeedbackBuilder buildReviewsButton;
  final ProviderFeedbackBuilder buildReviewAction;
  final RegisterProviderContact registerContact;

  const ProviderFeedbackScope({
    super.key,
    required this.buildReviewsButton,
    required this.buildReviewAction,
    required this.registerContact,
    required super.child,
  });

  static ProviderFeedbackScope of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<ProviderFeedbackScope>();
    if (scope == null) {
      throw FlutterError(
          'ProviderFeedbackScope debe instalarse al componer la ruta del proveedor.');
    }
    return scope;
  }

  @override
  bool updateShouldNotify(ProviderFeedbackScope oldWidget) =>
      buildReviewsButton != oldWidget.buildReviewsButton ||
      buildReviewAction != oldWidget.buildReviewAction ||
      registerContact != oldWidget.registerContact;
}
