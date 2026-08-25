import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Proveedor global de [SecureStorage].
final secureStorageProvider = Provider<SecureStorage>((ref) {
  return SecureStorage();
});

/// Wrapper sobre [FlutterSecureStorage] para gestionar tokens JWT de forma segura.
/// Es el ÚNICO lugar de la app donde se persisten datos sensibles.
class SecureStorage {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  // ── Claves ───────────────────────────────────────────────────────────────
  static const _keyAccessToken = 'access_token';
  static const _keyRefreshToken = 'refresh_token';
  static const _keyUserId = 'user_id';
  static const _keySyncedDeviceToken = 'synced_device_token';
  static const _keySyncedDeviceUserId = 'synced_device_user_id';
  static const _contactedProviderPrefix = 'review_contacted_provider';
  static const _handledStoreReviewPrefix = 'handled_store_review';

  // ── Access Token ─────────────────────────────────────────────────────────

  Future<void> saveToken(String token) async {
    await _storage.write(key: _keyAccessToken, value: token);
  }

  Future<String?> getToken() async {
    return _storage.read(key: _keyAccessToken);
  }

  // ── Refresh Token ─────────────────────────────────────────────────────────

  Future<void> saveRefreshToken(String token) async {
    await _storage.write(key: _keyRefreshToken, value: token);
  }

  Future<String?> getRefreshToken() async {
    return _storage.read(key: _keyRefreshToken);
  }

  // ── User ID ──────────────────────────────────────────────────────────────

  Future<void> saveUserId(String userId) async {
    await _storage.write(key: _keyUserId, value: userId);
  }

  Future<String?> getUserId() async {
    return _storage.read(key: _keyUserId);
  }

  // ── Push token synchronization ────────────────────────────────────────────

  Future<bool> isDeviceTokenSynced({
    required String userId,
    required String token,
  }) async {
    final values = await Future.wait([
      _storage.read(key: _keySyncedDeviceUserId),
      _storage.read(key: _keySyncedDeviceToken),
    ]);
    return values[0] == userId && values[1] == token;
  }

  Future<void> markDeviceTokenSynced({
    required String userId,
    required String token,
  }) async {
    await Future.wait([
      _storage.write(key: _keySyncedDeviceUserId, value: userId),
      _storage.write(key: _keySyncedDeviceToken, value: token),
    ]);
  }

  Future<String?> _contactedProviderKey(String providerProfileId) async {
    final userId = await getUserId();
    if (userId == null || userId.isEmpty) return null;
    return '${_contactedProviderPrefix}_${userId}_$providerProfileId';
  }

  Future<void> markProviderContacted(String providerProfileId) async {
    final key = await _contactedProviderKey(providerProfileId);
    if (key != null) await _storage.write(key: key, value: 'true');
  }

  Future<bool> hasContactedProvider(String providerProfileId) async {
    final key = await _contactedProviderKey(providerProfileId);
    if (key == null) return false;
    return await _storage.read(key: key) == 'true';
  }

  Future<String?> _handledStoreReviewKey(String conversationId) async {
    final userId = await getUserId();
    if (userId == null || userId.isEmpty) return null;
    return '${_handledStoreReviewPrefix}_${userId}_$conversationId';
  }

  Future<void> markStoreReviewHandled(String conversationId) async {
    final key = await _handledStoreReviewKey(conversationId);
    if (key != null) await _storage.write(key: key, value: 'true');
  }

  Future<bool> hasHandledStoreReview(String conversationId) async {
    final key = await _handledStoreReviewKey(conversationId);
    if (key == null) return false;
    return await _storage.read(key: key) == 'true';
  }

  // ── Utilidades ───────────────────────────────────────────────────────────

  /// Verifica si hay un token de acceso guardado.
  Future<bool> hasToken() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  /// Elimina todos los tokens (logout).
  Future<void> clearTokens() async {
    await Future.wait([
      _storage.delete(key: _keyAccessToken),
      _storage.delete(key: _keyRefreshToken),
      _storage.delete(key: _keyUserId),
      _storage.delete(key: _keySyncedDeviceToken),
      _storage.delete(key: _keySyncedDeviceUserId),
    ]);
  }

  // ── Onboarding ──────────────────────────────────────────────────────────
  static const _keyOnboardingSeen = 'onboarding_seen';

  /// Marca el onboarding como visto.
  Future<void> markOnboardingSeen() async {
    await _storage.write(key: _keyOnboardingSeen, value: 'true');
  }

  /// Verifica si el usuario ya vio el onboarding.
  Future<bool> hasSeenOnboarding() async {
    final value = await _storage.read(key: _keyOnboardingSeen);
    return value == 'true';
  }
}
