import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:guiautomotriz_mobile/core/domain/enums/service_type.dart';
import 'package:guiautomotriz_mobile/core/router/route_names.dart';
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

  HomeItem store() => const HomeItem(
        id: 'store-1',
        name: 'Repuestos Centro',
        detail: 'Tienda de repuestos',
        rating: 4.6,
        reviews: 18,
        distanceKm: 1.8,
        isOpen: true,
        iconName: 'storefront_outlined',
        type: ServiceType.spareParts,
      );

  HomeItem mechanic() => const HomeItem(
        id: 'mechanic-1',
        name: 'Carlos Mecánico',
        detail: 'Mecánica general',
        rating: 4.7,
        reviews: 12,
        distanceKm: 1.2,
        isOpen: true,
        iconName: 'person_outlined',
        type: ServiceType.mechanic,
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
        GoRoute(
          path: RouteNames.workshopDetail,
          builder: (_, state) => Scaffold(
            body: Text('Taller ${state.pathParameters['id']}'),
          ),
        ),
        GoRoute(
          path: RouteNames.storeDetail,
          builder: (_, state) => Scaffold(
            body: Text('Tienda ${state.pathParameters['id']}'),
          ),
        ),
      ],
    );
    return MaterialApp.router(routerConfig: router);
  }

  testWidgets('uses an honest fallback when a workshop has no photo',
      (tester) async {
    await tester.pumpWidget(subject(workshop()));

    expect(
      find.byKey(const Key('provider-list-fallback-workshop-1')),
      findsOneWidget,
    );
    expect(find.byType(Image), findsNothing);
  });

  testWidgets('does not offer favorites for workshops or mechanics',
      (tester) async {
    await tester.pumpWidget(subject(workshop()));
    expect(find.bySemanticsLabel(RegExp('favoritos')), findsNothing);

    await tester.pumpWidget(subject(mechanic()));
    expect(find.bySemanticsLabel(RegExp('favoritos')), findsNothing);
  });

  testWidgets('uses an uploaded workshop photo when available', (tester) async {
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
    expect(find.byKey(const Key('provider-list-fallback-workshop-1')),
        findsNothing);
  });

  testWidgets('uses distinct typed routes for workshops and stores',
      (tester) async {
    await tester.pumpWidget(subject(workshop()));
    await tester.tap(find.text('Taller Norte'));
    await tester.pumpAndSettle();
    expect(find.text('Taller workshop-1'), findsOneWidget);

    await tester.pumpWidget(subject(store()));
    await tester.tap(find.text('Repuestos Centro'));
    await tester.pumpAndSettle();
    expect(find.text('Tienda store-1'), findsOneWidget);
  });
}
