import 'dart:ui' show SemanticsAction, Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guiautomotriz_mobile/core/domain/enums/user_role.dart';
import 'package:guiautomotriz_mobile/core/providers/current_user_provider.dart';
import 'package:guiautomotriz_mobile/core/theme/app_colors.dart';
import 'package:guiautomotriz_mobile/features/home/presentation/providers/home_providers.dart';
import 'package:guiautomotriz_mobile/features/home/presentation/widgets/navigation/bottom_nav_bar.dart';

void main() {
  const logoSemantics = 'Volver al inicio, logo guIAutomotriz';
  const logoAsset = AssetImage('assets/images/logo_icon_zoom.png');

  ProviderContainer containerFor({
    required UserRole role,
    int initialTab = 0,
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

    for (final label in const ['Inicio', 'Chats', 'Compras', 'Perfil']) {
      expect(find.text(label), findsOneWidget);
    }
    expect(logoFinder(), findsOneWidget);
    final navRect = tester.getRect(find.byType(BottomNavBar));
    final logoRect = tester.getRect(find.bySemanticsLabel(logoSemantics));
    expect(logoRect.size, const Size.square(58));
    expect(logoRect.top, navRect.top);
    expect(logoRect.left, greaterThanOrEqualTo(navRect.left));
    expect(logoRect.top, greaterThanOrEqualTo(navRect.top));
    expect(logoRect.right, lessThanOrEqualTo(navRect.right));
    expect(logoRect.bottom, lessThanOrEqualTo(navRect.bottom));
    expect(logoRect.center.dx, closeTo(navRect.center.dx, 0.01));

    final slotRects = <Rect>[
      tester.getRect(find.bySemanticsLabel('Inicio')),
      tester.getRect(find.bySemanticsLabel('Chats')),
      tester.getRect(find.bySemanticsLabel('Compras')),
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
    final decoration =
        tester.widget<DecoratedBox>(surface).decoration as BoxDecoration;
    expect(decoration.color, AppColors.surface);
    expect(decoration.borderRadius, BorderRadius.circular(28));
    expect(
      surfaceRect.top - logoRect.top,
      kBottomNavOverhang,
    );
  });

  for (final edge in const ['top', 'bottom', 'left', 'right']) {
    testWidgets('center logo responds at its $edge edge', (tester) async {
      final container = containerFor(
        role: UserRole.consumer,
        initialTab: 1,
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
      expect(container.read(homeTabProvider), 0);
    });
  }

  for (final initialTab in const [0, 1]) {
    testWidgets('logo bounds remain exactly 58 dp on tab $initialTab at rest',
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
        const Size.square(58),
      );
    });
  }

  testWidgets('selected destination rises above inactive destinations',
      (tester) async {
    final container = containerFor(
      role: UserRole.consumer,
      initialTab: 1,
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(subject(container));
    await tester.pumpAndSettle();

    final homeStage = find.byKey(const Key('bottom-nav-icon-stage-Inicio'));
    final chatsStage = find.byKey(const Key('bottom-nav-icon-stage-Chats'));
    expect(tester.getSize(homeStage), const Size.square(48));
    expect(tester.getSize(chatsStage), const Size.square(48));
    expect(
      tester.getTopLeft(homeStage).dy - tester.getTopLeft(chatsStage).dy,
      closeTo(6, 0.01),
    );

    await tester.tap(find.text('Inicio'));
    await tester.pumpAndSettle();

    expect(
      tester.getTopLeft(chatsStage).dy - tester.getTopLeft(homeStage).dy,
      closeTo(6, 0.01),
    );
  });

  testWidgets('consumer actions keep their tab mapping and logo returns home',
      (tester) async {
    final container = containerFor(
      role: UserRole.consumer,
      initialTab: 1,
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(subject(container));

    await tester.tap(find.text('Compras'));
    await tester.pump();
    expect(container.read(homeTabProvider), 2);

    await tester.tap(find.text('Perfil'));
    await tester.pump();
    expect(container.read(homeTabProvider), 3);

    await tester.tap(find.bySemanticsLabel(logoSemantics));
    await tester.pump();
    expect(container.read(homeTabProvider), 0);
  });

  testWidgets('store omits purchases and preserves its index mapping',
      (tester) async {
    final container = containerFor(role: UserRole.store, initialTab: 1);
    addTearDown(container.dispose);

    await tester.pumpWidget(subject(container));

    expect(find.text('Compras'), findsNothing);
    expect(find.text('Mis Compras'), findsNothing);

    await tester.tap(find.text('Perfil'));
    await tester.pump();
    expect(container.read(homeTabProvider), 2);

    await tester.tap(find.text('Chats'));
    await tester.pump();
    expect(container.read(homeTabProvider), 1);

    await tester.tap(find.bySemanticsLabel(logoSemantics));
    await tester.pump();
    expect(container.read(homeTabProvider), 0);
  });

  testWidgets('nav actions expose button, tap, and selected semantics',
      (tester) async {
    final container = containerFor(
      role: UserRole.consumer,
      initialTab: 1,
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(subject(container));

    final semantics = tester.ensureSemantics();
    try {
      for (final label in const ['Inicio', 'Chats', 'Compras', 'Perfil']) {
        final action = find.bySemanticsLabel(label);
        expect(action, findsOneWidget);
        final data = tester.getSemantics(action).getSemanticsData();
        expect(data.flagsCollection.isButton, isTrue);
        expect(data.hasAction(SemanticsAction.tap), isTrue);
        expect(tester.getSize(action).width, greaterThanOrEqualTo(48));
        expect(tester.getSize(action).height, greaterThanOrEqualTo(48));
        expect(
          data.flagsCollection.isSelected,
          label == 'Chats' ? Tristate.isTrue : Tristate.isFalse,
        );
      }

      final logo = find.bySemanticsLabel(logoSemantics);
      final logoData = tester.getSemantics(logo).getSemanticsData();
      expect(logoData.flagsCollection.isButton, isTrue);
      expect(logoData.flagsCollection.isSelected, Tristate.isFalse);
      expect(logoData.hasAction(SemanticsAction.tap), isTrue);
      expect(tester.getSize(logo), const Size.square(58));
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('reduced motion keeps logo geometry stable across selection',
      (tester) async {
    final container = containerFor(
      role: UserRole.consumer,
      initialTab: 0,
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      subject(container, disableAnimations: true),
    );

    final selectedRect = tester.getRect(find.bySemanticsLabel(logoSemantics));
    container.read(homeTabProvider.notifier).state = 1;
    await tester.pump();
    final unselectedRect = tester.getRect(find.bySemanticsLabel(logoSemantics));
    final slides = tester.widgetList<AnimatedSlide>(find.byType(AnimatedSlide));
    final scales = tester.widgetList<AnimatedScale>(find.byType(AnimatedScale));

    expect(selectedRect.size, const Size.square(58));
    expect(unselectedRect, selectedRect);
    expect(slides, isNotEmpty);
    expect(slides.every((slide) => slide.duration == Duration.zero), isTrue);
    expect(scales, isNotEmpty);
    expect(scales.every((scale) => scale.duration == Duration.zero), isTrue);
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

        for (final label in const ['Inicio', 'Chats', 'Compras', 'Perfil']) {
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
        'Chats',
        'Compras',
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
      'Chats',
      'Compras',
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
                bottom: bottomNavContentInset(context),
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

      for (final label in const ['Inicio', 'Chats', 'Compras', 'Perfil']) {
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
