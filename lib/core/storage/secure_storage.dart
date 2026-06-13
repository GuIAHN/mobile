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

  // ── Access Token ─────────────────────────────────────────────────────────

  Future<void> saveToken(String token) async {
    await _storage.write(key: _keyAccessToken, value: token);
  }

  Future<String?> getToken() async {
    return _storage.read(key: _keyAccessToken);
  }

  Future<void> deleteToken() async {
    await _storage.delete(key: _keyAccessToken);
  }

  // ── Refresh Token ─────────────────────────────────────────────────────────

  Future<void> saveRefreshToken(String token) async {
    await _storage.write(key: _keyRefreshToken, value: token);
  }

  Future<String?> getRefreshToken() async {
    return _storage.read(key: _keyRefreshToken);
  }

  Future<void> deleteRefreshToken() async {
    await _storage.delete(key: _keyRefreshToken);
  }

  // ── User ID ──────────────────────────────────────────────────────────────

  Future<void> saveUserId(String userId) async {
    await _storage.write(key: _keyUserId, value: userId);
  }

  Future<String?> getUserId() async {
    return _storage.read(key: _keyUserId);
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
    ]);
  }

  /// Borra todo el almacenamiento seguro.
  Future<void> clearAll() async {
    await _storage.deleteAll();
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
