import 'dart:ui' show SemanticsAction, Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guiautomotriz_mobile/core/domain/enums/user_role.dart';
import 'package:guiautomotriz_mobile/core/providers/current_user_provider.dart';
import 'package:guiautomotriz_mobile/features/home/presentation/providers/home_providers.dart';
import 'package:guiautomotriz_mobile/features/home/presentation/widgets/navigation/bottom_nav_bar.dart';
import 'package:guiautomotriz_mobile/shared/layout/bottom_navigation_insets.dart';

void main() {
  const logoSemantics = 'Volver al inicio, logo GuIA Automotriz HN';
  const logoAsset = AssetImage('assets/images/logo_icon_zoom.png');

  ProviderContainer containerFor({
    required UserRole role,
    MainNavigationTab initialTab = MainNavigationTab.home,
  }) {
    return ProviderContainer(
      overrides: [
        currentRoleProvider.overrideWithValue(role),
        homeTabProvider.overrideWith((ref) => initialTab),
      ],
    );
  }

  Widget subject(
    ProviderContainer container, {
    double width = 375,
    double height = 812,
    double textScale = 1,
    double bottomSafeArea = 0,
    bool disableAnimations = false,
    bool extendBody = false,
    WidgetBuilder? bodyBuilder,
  }) {
    return UncontrolledProviderScope(
      container: container,
      child: MediaQuery(
        data: MediaQueryData(
          size: Size(width, height),
          padding: EdgeInsets.only(bottom: bottomSafeArea),
          textScaler: TextScaler.linear(textScale),
          disableAnimations: disableAnimations,
        ),
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              extendBody: extendBody,
              body: bodyBuilder?.call(context),
              bottomNavigationBar: const BottomNavBar(),
            ),
          ),
        ),
      ),
    );
  }

  Finder logoFinder() => find.byWidgetPredicate(
        (widget) => widget is Image && widget.image == logoAsset,
        description: 'official guIAutomotriz logo image',
      );

  Rect visualRect(WidgetTester tester, Finder finder) => Rect.fromPoints(
        tester.getTopLeft(finder),
        tester.getBottomRight(finder),
      );

  testWidgets('consumer nav exposes approved labels and five positions',
      (tester) async {
    final container = containerFor(role: UserRole.consumer);
    addTearDown(container.dispose);

    await tester.pumpWidget(subject(container));

    for (final label in const ['Inicio', 'Compras', 'Solicitudes', 'Perfil']) {
      expect(find.text(label), findsOneWidget);
    }
    expect(logoFinder(), findsOneWidget);
    final navRect = tester.getRect(find.byType(BottomNavBar));
    final logoRect = tester.getRect(find.bySemanticsLabel(logoSemantics));
    expect(logoRect.size, const Size.square(56));
    expect(logoRect.top, navRect.top);
    expect(logoRect.left, greaterThanOrEqualTo(navRect.left));
    expect(logoRect.top, greaterThanOrEqualTo(navRect.top));
    expect(logoRect.right, lessThanOrEqualTo(navRect.right));
    expect(logoRect.bottom, lessThanOrEqualTo(navRect.bottom));
    expect(logoRect.center.dx, closeTo(navRect.center.dx, 0.01));

    final slotRects = <Rect>[
      tester.getRect(find.bySemanticsLabel('Inicio')),
      tester.getRect(find.bySemanticsLabel('Compras')),
      tester.getRect(find.bySemanticsLabel('Solicitudes')),
      tester.getRect(find.bySemanticsLabel('Perfil')),
    ];
    for (final slot in slotRects.skip(1)) {
      expect(slot.width, closeTo(slotRects.first.width, 0.01));
    }
    expect(
      (slotRects[0].center.dx + slotRects[3].center.dx) / 2,
      closeTo(logoRect.center.dx, 0.01),
    );
    expect(
      (slotRects[1].center.dx + slotRects[2].center.dx) / 2,
      closeTo(logoRect.center.dx, 0.01),
    );
    final leftGap = logoRect.left - slotRects[1].right;
    final rightGap = slotRects[2].left - logoRect.right;
    expect(leftGap, greaterThanOrEqualTo(0));
    expect(rightGap, closeTo(leftGap, 0.01));

    final surface = find.byKey(const Key('bottom-nav-surface'));
    expect(surface, findsOneWidget);
    final surfaceRect = tester.getRect(surface);
    expect(surfaceRect.left, closeTo(navRect.left + 14, 0.01));
    expect(surfaceRect.right, closeTo(navRect.right - 14, 0.01));
    expect(tester.widget<CustomPaint>(surface).painter, isNotNull);
    expect(surfaceRect.height, kBottomNavBarHeight);
    expect(
      surfaceRect.top - logoRect.top,
      kBottomNavOverhang,
    );
  });

  for (final edge in const ['top', 'bottom', 'left', 'right']) {
    testWidgets('center logo responds at its $edge edge', (tester) async {
      final container = containerFor(
        role: UserRole.consumer,
        initialTab: MainNavigationTab.purchases,
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(subject(container));

      final rect = tester.getRect(find.bySemanticsLabel(logoSemantics));
      final point = switch (edge) {
        'top' => Offset(rect.center.dx, rect.top + 1),
        'bottom' => Offset(rect.center.dx, rect.bottom - 1),
        'left' => Offset(rect.left + 1, rect.center.dy),
        'right' => Offset(rect.right - 1, rect.center.dy),
        _ => throw StateError('Unknown edge: $edge'),
      };

      await tester.tapAt(point);
      await tester.pump();
      expect(container.read(homeTabProvider), MainNavigationTab.home);
    });
  }

  for (final initialTab in const [
    MainNavigationTab.home,
    MainNavigationTab.purchases,
  ]) {
    testWidgets('logo bounds remain exactly 56 dp on tab $initialTab at rest',
        (tester) async {
      final container = containerFor(
        role: UserRole.consumer,
        initialTab: initialTab,
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(subject(container));
      await tester.pumpAndSettle();

      expect(
        tester.getSize(find.bySemanticsLabel(logoSemantics)),
        const Size.square(56),
      );
    });
  }

  testWidgets('flat selected pill moves inside the bar without elevation',
      (tester) async {
    final container = containerFor(
      role: UserRole.consumer,
      initialTab: MainNavigationTab.purchases,
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(subject(container));
    await tester.pumpAndSettle();

    final stage = find.byKey(const Key('bottom-nav-active-indicator'));
    final surface = find.byKey(const Key('bottom-nav-surface'));
    final chatsRect = tester.getRect(stage);
    final surfaceRect = tester.getRect(surface);
    expect(chatsRect.size, const Size.square(48));
    expect(chatsRect.top, lessThan(surfaceRect.top));
    expect(chatsRect.bottom, greaterThan(surfaceRect.top));

    await tester.tap(find.text('Inicio'));
    await tester.pumpAndSettle();

    final homeRect = tester.getRect(stage);
    expect(homeRect.size, const Size.square(48));
    expect(homeRect.center.dx, lessThan(chatsRect.center.dx));
    expect(homeRect.center.dy, closeTo(chatsRect.center.dy, 0.01));
  });

  testWidgets('consumer actions keep their tab mapping and logo returns home',
      (tester) async {
    final container = containerFor(
      role: UserRole.consumer,
      initialTab: MainNavigationTab.purchases,
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(subject(container));

    await tester.tap(find.text('Compras'));
    await tester.pump();
    expect(container.read(homeTabProvider), MainNavigationTab.purchases);

    await tester.tap(find.text('Solicitudes'));
    await tester.pump();
    expect(container.read(homeTabProvider), MainNavigationTab.requests);

    await tester.tap(find.text('Perfil'));
    await tester.pump();
    expect(container.read(homeTabProvider), MainNavigationTab.profile);

    await tester.tap(find.bySemanticsLabel(logoSemantics));
    await tester.pump();
    expect(container.read(homeTabProvider), MainNavigationTab.home);
  });

  testWidgets('store exposes Home, Mis ventas, Solicitudes and Perfil',
      (tester) async {
    final container = containerFor(
      role: UserRole.store,
      initialTab: MainNavigationTab.purchases,
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(subject(container));

    expect(find.text('Compras'), findsNothing);
    expect(find.text('Mis Compras'), findsNothing);
    expect(find.text('Mis ventas'), findsOneWidget);
    expect(find.text('Solicitudes'), findsOneWidget);
    expect(find.bySemanticsLabel(logoSemantics), findsOneWidget);
    expect(logoFinder(), findsOneWidget);

    final surfaceRect = tester.getRect(
      find.byKey(const Key('bottom-nav-surface')),
    );
    final actionRects = [
      for (final label in const [
        'Inicio',
        'Mis ventas',
        'Solicitudes',
        'Perfil'
      ])
        tester.getRect(find.bySemanticsLabel(label)),
    ];
    for (final rect in actionRects) {
      expect(rect.width, closeTo(surfaceRect.width / 5, 0.01));
      expect(rect.height, greaterThanOrEqualTo(48));
    }

    await tester.tap(find.text('Solicitudes'));
    await tester.pump();
    expect(container.read(homeTabProvider), MainNavigationTab.requests);

    await tester.tap(find.text('Perfil'));
    await tester.pump();
    expect(container.read(homeTabProvider), MainNavigationTab.profile);

    await tester.tap(find.text('Mis ventas'));
    await tester.pump();
    expect(container.read(homeTabProvider), MainNavigationTab.purchases);

    await tester.tap(find.text('Inicio'));
    await tester.pump();
    expect(container.read(homeTabProvider), MainNavigationTab.home);
  });

  testWidgets('store labels fit with safe area and enlarged text',
      (tester) async {
    final container = containerFor(
      role: UserRole.store,
      initialTab: MainNavigationTab.requests,
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      subject(
        container,
        width: 375,
        height: 812,
        textScale: 2,
        bottomSafeArea: 34,
        disableAnimations: true,
      ),
    );

    final surfaceRect = tester.getRect(
      find.byKey(const Key('bottom-nav-surface')),
    );
    for (final label in const [
      'Inicio',
      'Mis ventas',
      'Solicitudes',
      'Perfil'
    ]) {
      final actionRect = tester.getRect(find.bySemanticsLabel(label));
      final labelRect = visualRect(tester, find.text(label));
      expect(actionRect.width, closeTo(surfaceRect.width / 5, 0.01));
      expect(actionRect.bottom, lessThanOrEqualTo(812 - 34));
      expect(labelRect.left, greaterThanOrEqualTo(actionRect.left));
      expect(labelRect.right, lessThanOrEqualTo(actionRect.right));
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('nav actions expose button, tap, and selected semantics',
      (tester) async {
    final container = containerFor(
      role: UserRole.consumer,
      initialTab: MainNavigationTab.purchases,
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(subject(container));

    final semantics = tester.ensureSemantics();
    try {
      for (final label in const [
        'Inicio',
        'Compras',
        'Solicitudes',
        'Perfil'
      ]) {
        final action = find.bySemanticsLabel(label);
        expect(action, findsOneWidget);
        final data = tester.getSemantics(action).getSemanticsData();
        expect(data.flagsCollection.isButton, isTrue);
        expect(data.hasAction(SemanticsAction.tap), isTrue);
        expect(tester.getSize(action).width, greaterThanOrEqualTo(48));
        expect(tester.getSize(action).height, greaterThanOrEqualTo(48));
        expect(
          data.flagsCollection.isSelected,
          label == 'Compras' ? Tristate.isTrue : Tristate.isFalse,
        );
      }

      final logo = find.bySemanticsLabel(logoSemantics);
      final logoData = tester.getSemantics(logo).getSemanticsData();
      expect(logoData.flagsCollection.isButton, isTrue);
      expect(logoData.flagsCollection.isSelected, Tristate.isFalse);
      expect(logoData.hasAction(SemanticsAction.tap), isTrue);
      expect(tester.getSize(logo), const Size.square(56));
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('press feedback does not paint a rectangular Material overlay',
      (tester) async {
    final container = containerFor(role: UserRole.store);
    addTearDown(container.dispose);

    await tester.pumpWidget(subject(container));

    for (final label in const [
      'Inicio',
      'Mis ventas',
      'Solicitudes',
      'Perfil'
    ]) {
      final inkWell = tester.widget<InkWell>(
        find.descendant(
          of: find.bySemanticsLabel(label),
          matching: find.byType(InkWell),
        ),
      );
      expect(inkWell.splashFactory, NoSplash.splashFactory);
      expect(
        inkWell.overlayColor?.resolve({WidgetState.pressed}),
        Colors.transparent,
      );
    }
  });

  testWidgets('reduced motion keeps logo geometry stable across selection',
      (tester) async {
    final container = containerFor(
      role: UserRole.consumer,
      initialTab: MainNavigationTab.home,
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      subject(container, disableAnimations: true),
    );

    final selectedRect = tester.getRect(find.bySemanticsLabel(logoSemantics));
    container.read(homeTabProvider.notifier).state =
        MainNavigationTab.purchases;
    await tester.pump();
    final unselectedRect = tester.getRect(find.bySemanticsLabel(logoSemantics));
    final positionTween = tester.widget<TweenAnimationBuilder<double>>(
      find.byWidgetPredicate(
        (widget) => widget is TweenAnimationBuilder<double>,
      ),
    );

    expect(selectedRect.size, const Size.square(56));
    expect(unselectedRect, selectedRect);
    expect(positionTween.duration, Duration.zero);
  });

  testWidgets('nav stays overflow-free at 2x on representative phone widths',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    final originalOnError = FlutterError.onError;
    final errors = <FlutterErrorDetails>[];
    final outOfSlotLabels = <String>[];
    final containers = <ProviderContainer>[];
    FlutterError.onError = errors.add;
    try {
      for (final configuration in const [
        (width: 320.0, height: 700.0),
        (width: 375.0, height: 812.0),
        (width: 430.0, height: 932.0),
        (width: 700.0, height: 320.0),
      ]) {
        tester.view.physicalSize = Size(
          configuration.width,
          configuration.height,
        );
        final container = containerFor(role: UserRole.consumer);
        containers.add(container);
        await tester.pumpWidget(
          subject(
            container,
            width: configuration.width,
            height: configuration.height,
            textScale: 2,
            bottomSafeArea: 34,
          ),
        );
        await tester.pump();

        for (final label in const [
          'Inicio',
          'Compras',
          'Solicitudes',
          'Perfil'
        ]) {
          final labelRect = visualRect(tester, find.text(label));
          final slotRect = tester.getRect(find.bySemanticsLabel(label));
          if (labelRect.left < slotRect.left - 0.01 ||
              labelRect.top < slotRect.top - 0.01 ||
              labelRect.right > slotRect.right + 0.01 ||
              labelRect.bottom > slotRect.bottom + 0.01) {
            outOfSlotLabels.add('${configuration.width}:$label');
          }
        }
      }
      await tester.pumpWidget(const SizedBox.shrink());
    } finally {
      FlutterError.onError = originalOnError;
      for (final container in containers) {
        container.dispose();
      }
    }

    expect(errors, isEmpty);
    expect(outOfSlotLabels, isEmpty);
  });

  testWidgets('safe area moves every bar action above the system inset',
      (tester) async {
    const height = 812.0;
    const safeArea = 34.0;
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(375, height);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    final noInsetContainer = containerFor(role: UserRole.consumer);
    final insetContainer = containerFor(role: UserRole.consumer);
    addTearDown(noInsetContainer.dispose);
    addTearDown(insetContainer.dispose);

    await tester.pumpWidget(subject(noInsetContainer, height: height));
    final baselineBottoms = <String, double>{
      for (final label in const [
        'Inicio',
        'Compras',
        'Solicitudes',
        'Perfil',
        logoSemantics,
      ])
        label: tester.getRect(find.bySemanticsLabel(label)).bottom,
    };

    await tester.pumpWidget(
      subject(
        insetContainer,
        height: height,
        bottomSafeArea: safeArea,
      ),
    );
    await tester.pump();

    expect(tester.getRect(find.byType(BottomNavBar)).bottom, height);
    for (final label in const [
      'Inicio',
      'Compras',
      'Solicitudes',
      'Perfil',
      logoSemantics,
    ]) {
      final insetBottom = tester.getRect(find.bySemanticsLabel(label)).bottom;
      expect(insetBottom, lessThanOrEqualTo(height - safeArea));
      expect(baselineBottoms[label]! - insetBottom, closeTo(safeArea, 0.01));
    }
  });

  for (final configuration in const [
    (textScale: 1.0, bottomSafeArea: 0.0),
    (textScale: 2.0, bottomSafeArea: 34.0),
  ]) {
    testWidgets(
        'reserved inset clears the rendered navigation surface at '
        '${configuration.textScale}x text', (tester) async {
      const height = 812.0;
      const markerKey = Key('last-home-content');
      final container = containerFor(role: UserRole.consumer);
      addTearDown(container.dispose);

      await tester.pumpWidget(
        subject(
          container,
          height: height,
          textScale: configuration.textScale,
          bottomSafeArea: configuration.bottomSafeArea,
          extendBody: true,
          bodyBuilder: (context) => Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: EdgeInsets.only(
                bottom: bottomNavigationContentInset(context),
              ),
              child: const SizedBox(
                key: markerKey,
                width: 48,
                height: 48,
              ),
            ),
          ),
        ),
      );

      final surface = find.byKey(const Key('bottom-nav-surface'));
      final surfaceRect = tester.getRect(surface);
      final markerRect = tester.getRect(find.byKey(markerKey));

      expect(
        markerRect.bottom,
        lessThanOrEqualTo(surfaceRect.top),
        reason: 'The public Home inset must clear the real opaque bar; '
            'surface=$surfaceRect marker=$markerRect',
      );

      for (final label in const [
        'Inicio',
        'Compras',
        'Solicitudes',
        'Perfil'
      ]) {
        final actionRect = tester.getRect(find.bySemanticsLabel(label));
        expect(actionRect.top, greaterThanOrEqualTo(surfaceRect.top));
        expect(
          actionRect.bottom,
          lessThanOrEqualTo(height - configuration.bottomSafeArea),
        );
      }
    });
  }
}
