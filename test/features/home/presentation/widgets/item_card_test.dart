import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:guiautomotriz_mobile/core/domain/enums/service_type.dart';
import 'package:guiautomotriz_mobile/features/home/domain/entities/home_item.dart';
import 'package:guiautomotriz_mobile/features/home/presentation/widgets/item_card.dart';

void main() {
  HomeItem workshop({String? photo}) => HomeItem(
        id: 'workshop-1',
        name: 'Taller Norte',
        detail: 'Diagnóstico y frenos',
        rating: 4.8,
        reviews: 24,
        distanceKm: 2.4,
        isOpen: true,
        iconName: 'warehouse_outlined',
        type: ServiceType.workshops,
        photo: photo,
      );

  Widget subject(HomeItem item) {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, __) => Material(
            child: SizedBox(width: 390, child: ItemCard(item: item)),
          ),
        ),
      ],
    );
    return MaterialApp.router(routerConfig: router);
  }

  testWidgets('shows the workshop preview in the results list', (tester) async {
    await tester.pumpWidget(subject(workshop()));

    final preview = find.byKey(
      const Key('provider-list-preview-photo-workshop-1'),
    );
    expect(preview, findsOneWidget);
    expect(tester.widget<Image>(preview).image, isA<AssetImage>());
  });

  testWidgets('uses an uploaded photo before the workshop preview',
      (tester) async {
    await tester.pumpWidget(
      subject(workshop(photo: 'https://example.com/workshop.jpg')),
    );

    final photo = find.byKey(const Key('provider-list-photo-workshop-1'));
    expect(photo, findsOneWidget);
    expect(
      tester.widget<Image>(photo).image,
      isA<NetworkImage>().having(
        (image) => image.url,
        'url',
        'https://example.com/workshop.jpg',
      ),
    );
    expect(
      find.byKey(const Key('provider-list-preview-photo-workshop-1')),
      findsNothing,
    );
  });
}
