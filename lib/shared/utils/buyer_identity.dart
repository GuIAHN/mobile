import '../../core/domain/enums/offer_status.dart';

/// Presentation only: use the persisted offer status, never the request's
/// closed state or a local tap on Comprar, to reveal the buyer to a store.
abstract final class BuyerIdentity {
  static const hiddenMessagePreview = 'Tienes un nuevo mensaje.';

  /// Same initials + six-character code format as store aliases. A stable
  /// name-derived code keeps requests, chats and notification previews aligned
  /// without changing the API or storing aliases locally.
  static String alias(String? name) {
    final normalized =
        (name ?? '').trim().replaceAll(RegExp(r'\s+'), ' ').toUpperCase();
    final words = normalized.split(' ').where((word) => word.isNotEmpty);
    final initials = words.take(2).map((word) => word[0]).join();
    // FNV-1a is deterministic across Dart runtimes; String.hashCode is not.
    var hash = 0x811c9dc5;
    for (final unit in normalized.codeUnits) {
      hash ^= unit;
      // Split the FNV multiplier to keep arithmetic exact on Flutter web too.
      hash = ((hash * 0x0193) + ((hash & 0xff) << 24)) & 0xffffffff;
    }
    final suffix =
        hash.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase();
    return '${initials.isEmpty ? 'CL' : initials}-$suffix';
  }

  static String aliasFromMessage(String body) {
    final separator = body.indexOf(':');
    return alias(separator > 0 ? body.substring(0, separator) : null);
  }

  static bool isRevealed(String? offerStatus) =>
      OfferStatusX.fromApi(offerStatus).revealsIdentity;

  static String displayName(String? name, String? offerStatus) =>
      isRevealed(offerStatus) && name?.trim().isNotEmpty == true
          ? name!
          : alias(name);

  static String? avatarUrl(String? url, String? offerStatus) =>
      isRevealed(offerStatus) ? url : null;
}
