import 'package:flutter/material.dart';
import '../../core/theme/app_spacing.dart';

/// Scaffold base de la app. Agrega padding estándar de pantalla
/// y gestión uniforme de safe area para todas las páginas.
class AppScaffold extends StatelessWidget {
  final String? title;
  final Widget body;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final Widget? bottomSheet;
  final bool applyHorizontalPadding;
  final bool applyTopPadding;
  final Color? backgroundColor;
  final PreferredSizeWidget? appBar;
  final Widget? drawer;
  final bool extendBodyBehindAppBar;

  const AppScaffold({
    super.key,
    this.title,
    required this.body,
    this.actions,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.bottomSheet,
    this.applyHorizontalPadding = true,
    this.applyTopPadding = false,
    this.backgroundColor,
    this.appBar,
    this.drawer,
    this.extendBodyBehindAppBar = false,
  });

  @override
  Widget build(BuildContext context) {
    // Construye el AppBar solo si se pasa título o acciones y no hay appBar custom.
    final effectiveAppBar = appBar ??
        (title != null || actions != null
            ? AppBar(
                title: title != null ? Text(title!) : null,
                actions: actions,
              )
            : null);

    Widget content = body;

    if (applyHorizontalPadding) {
      content = Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenHorizontal,
        ),
        child: content,
      );
    }

    if (applyTopPadding) {
      content = Padding(
        padding: const EdgeInsets.only(top: AppSpacing.screenVertical),
        child: content,
      );
    }

    return Scaffold(
      appBar: effectiveAppBar,
      backgroundColor: backgroundColor,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
      bottomSheet: bottomSheet,
      drawer: drawer,
      extendBodyBehindAppBar: extendBodyBehindAppBar,
      body: SafeArea(child: content),
    );
  }
}
