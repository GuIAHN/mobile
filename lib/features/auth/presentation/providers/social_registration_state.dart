import 'package:flutter_riverpod/flutter_riverpod.dart';

class SocialRegistrationData {
  final String idToken;
  final String provider; // 'GOOGLE' | 'APPLE'
  final String email;
  final String name;

  const SocialRegistrationData({
    required this.idToken,
    required this.provider,
    required this.email,
    required this.name,
  });
}

class SocialRegistrationNotifier extends StateNotifier<SocialRegistrationData?> {
  SocialRegistrationNotifier() : super(null);

  void setData({
    required String idToken,
    required String provider,
    required String email,
    required String name,
  }) {
    state = SocialRegistrationData(
      idToken: idToken,
      provider: provider,
      email: email,
      name: name,
    );
  }

  void clear() {
    state = null;
  }
}

final socialRegistrationProvider =
    StateNotifierProvider<SocialRegistrationNotifier, SocialRegistrationData?>((ref) {
  return SocialRegistrationNotifier();
});
