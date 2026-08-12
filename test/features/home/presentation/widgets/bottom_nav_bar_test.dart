import 'dart:ui' show SemanticsAction, Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guiautomotriz_mobile/core/domain/enums/user_role.dart';
import 'package:guiautomotriz_mobile/core/providers/current_user_provider.dart';
import 'package:guiautomotriz_mobile/features/home/presentation/providers/home_providers.dart';
import 'package:guiautomotriz_mobile/features/home/presentation/widgets/navigation/bottom_nav_bar.dart';

void main() {
  const logoSemantics = 'Volver al inicio, logo guIAutomotriz';
  const logoAsset = AssetImage('assets/images/logo_icon.png');

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
        child: const MaterialApp(
          home: Scaffold(bottomNavigationBar: BottomNavBar()),
        ),
      ),
    );
  }

  Finder logoFinder() => find.byWidgetPredicate(
        (widget) => widget is Image && widget.image == logoAsset,
        description: 'official guIAutomotriz logo image',
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
    expect(tester.getSize(logoFinder()), const Size.square(64));

    final centers = <double>[
      tester.getCenter(find.text('Inicio')).dx,
      tester.getCenter(find.text('Chats')).dx,
      tester.getCenter(logoFinder()).dx,
      tester.getCenter(find.text('Compras')).dx,
      tester.getCenter(find.text('Perfil')).dx,
    ];
    expect(centers, orderedEquals([...centers]..sort()));

    final navStack = find.byWidgetPredicate(
      (widget) =>
          widget is Stack &&
          widget.alignment == Alignment.topCenter &&
          widget.clipBehavior == Clip.none,
      description: 'bottom navigation Stack',
    );
    final stackTop = tester.getTopLeft(navStack).dy;
    expect(tester.getTopLeft(logoFinder()).dy, stackTop - 12);
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
      expect(tester.getSize(logo).width, greaterThanOrEqualTo(64));
      expect(tester.getSize(logo).height, greaterThanOrEqualTo(64));
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('reduced motion disables logo scaling', (tester) async {
    final container = containerFor(
      role: UserRole.consumer,
      initialTab: 1,
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      subject(container, disableAnimations: true),
    );

    final animatedScale =
        tester.widget<AnimatedScale>(find.byType(AnimatedScale));
    expect(animatedScale.scale, 1);
    expect(animatedScale.duration, Duration.zero);
  });

  testWidgets('nav fits small and large phones with scaled text and safe area',
      (tester) async {
    final originalOnError = FlutterError.onError;
    final errors = <FlutterErrorDetails>[];
    FlutterError.onError = errors.add;
    try {
      for (final configuration in const [
        (width: 320.0, height: 700.0, scale: 2.0, safeArea: 24.0),
        (width: 430.0, height: 932.0, scale: 1.3, safeArea: 34.0),
      ]) {
        final container = containerFor(role: UserRole.consumer);
        await tester.pumpWidget(
          subject(
            container,
            width: configuration.width,
            height: configuration.height,
            textScale: configuration.scale,
            bottomSafeArea: configuration.safeArea,
          ),
        );
        await tester.pump();

        expect(find.text('Compras'), findsOneWidget);
        expect(
          bottomNavContentInset(
            tester.element(find.byType(BottomNavBar)),
          ),
          kBottomNavBarHeight + configuration.safeArea,
        );
        container.dispose();
      }
    } finally {
      FlutterError.onError = originalOnError;
    }

    expect(errors, isEmpty);
  });
}
