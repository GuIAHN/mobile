import 'package:flutter_test/flutter_test.dart';
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
}
