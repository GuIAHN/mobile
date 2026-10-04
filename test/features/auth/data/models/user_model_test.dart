import 'package:flutter_test/flutter_test.dart';
import 'package:guiautomotriz_mobile/core/domain/enums/account_status.dart';
import 'package:guiautomotriz_mobile/features/auth/data/models/user_model.dart';

void main() {
  test('maps the last profile coordinates returned by users/me', () {
    final user = UserModel.fromJson(const {
      'id': 'user-1',
      'email': 'driver@example.com',
      'name': 'Driver',
      'location': {
        'lat': 14.0723,
        'lon': -87.1921,
      },
    });

    expect(user.latitude, 14.0723);
    expect(user.longitude, -87.1921);
  });

  test('maps the mechanic description returned inside the provider profile',
      () {
    final user = UserModel.fromJson(const {
      'id': 'mechanic-user-1',
      'email': 'mechanic@example.com',
      'name': 'Taller Central',
      'userType': 'WORKSHOP',
      'mechanicProfile': {
        'description': 'Especialistas en diagnóstico y frenos.',
      },
    });

    expect(user.description, 'Especialistas en diagnóstico y frenos.');
  });

  test('maps account deletion lifecycle fields returned by users/me', () {
    final user = UserModel.fromJson(const {
      'id': 'user-1',
      'email': 'driver@example.com',
      'name': 'Driver',
      'accountStatus': 'PENDING_DELETION',
      'deletionRequestedAt': '2026-09-09T12:00:00.000Z',
      'deletionPurgeAt': '2026-10-09T12:00:00.000Z',
      'provider': 'google',
    });

    expect(user.accountStatus, AccountStatus.pendingDeletion);
    expect(
        user.deletionRequestedAt, DateTime.parse('2026-09-09T12:00:00.000Z'));
    expect(
        user.deletionScheduledAt, DateTime.parse('2026-10-09T12:00:00.000Z'));
    expect(user.requiresDeletionPassword, isFalse);
  });

  test('defaults active password accounts when lifecycle fields are absent',
      () {
    final user = UserModel.fromJson(const {
      'id': 'user-1',
      'email': 'driver@example.com',
      'name': 'Driver',
    });

    expect(user.accountStatus, AccountStatus.active);
    expect(user.deletionRequestedAt, isNull);
    expect(user.deletionScheduledAt, isNull);
    expect(user.requiresDeletionPassword, isTrue);
  });
}
