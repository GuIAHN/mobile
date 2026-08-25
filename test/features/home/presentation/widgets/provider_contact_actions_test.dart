import 'package:flutter_test/flutter_test.dart';
import 'package:guiautomotriz_mobile/features/home/presentation/widgets/provider_detail_widgets.dart';
import 'package:guiautomotriz_mobile/features/vehicles/domain/entities/user_car.dart';

void main() {
  test('builds a WhatsApp inquiry with the selected vehicle', () {
    final message = ContactActions.providerInquiryMessage(
      vehicle: const UserCar(
        id: 'car-1',
        brand: 'Toyota',
        model: 'Corolla',
        year: 2020,
        version: 'XLE 1.8L',
      ),
    );
    final uri = ContactActions.whatsappUri(
      '9999-9999',
      message: message,
    );

    expect(uri.host, 'wa.me');
    expect(uri.path, '/50499999999');
    expect(uri.queryParameters['text'], contains('Marca: Toyota'));
    expect(uri.queryParameters['text'], contains('Modelo: Corolla'));
    expect(uri.queryParameters['text'], contains('Año: 2020'));
    expect(uri.queryParameters['text'], contains('Versión: XLE 1.8L'));
    expect(uri.queryParameters['text'], contains('GuIA-HN'));
  });

  test('states when an older vehicle has no version data', () {
    final message = ContactActions.providerInquiryMessage(
      vehicle: const UserCar(
        id: 'legacy-car',
        brand: 'Honda',
        model: 'Civic',
        year: 2018,
      ),
    );

    expect(message, contains('Versión: No especificada'));
  });
}
