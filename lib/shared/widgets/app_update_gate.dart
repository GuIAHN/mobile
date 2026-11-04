import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:upgrader/upgrader.dart';

import '../../core/services/app_update_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_icons.dart';

/// Lives above authentication and maintenance so the update remains visible
/// even when the user's saved session cannot be restored.
class AppUpdateGate extends ConsumerStatefulWidget {
  const AppUpdateGate({
    super.key,
    required this.child,
    required this.backButtonDispatcher,
  });

  final Widget child;
  final BackButtonDispatcher backButtonDispatcher;

  @override
  ConsumerState<AppUpdateGate> createState() => _AppUpdateGateState();
}

class _AppUpdateGateState extends ConsumerState<AppUpdateGate> {
  late final AppUpdateService _service;
  late final StreamSubscription<UpgraderState> _subscription;
  late final ChildBackButtonDispatcher _backDispatcher;
  UpgraderVersionInfo? _update;

  @override
  void initState() {
    super.initState();
    _service = ref.read(appUpdateServiceProvider);
    _backDispatcher = widget.backButtonDispatcher
        .createChildBackButtonDispatcher()
      ..addCallback(_handleBack);
    _subscription = _service.stateStream.listen((_) => _evaluate());
    unawaited(_initialize());
  }

  Future<void> _initialize() async {
    await _service.initialize();
    _evaluate();
  }

  void _evaluate() {
    if (!mounted) return;
    final update = _service.versionInfo;
    if (update?.appStoreListingURL?.isNotEmpty != true) return;
    if (_update != null) {
      // Refresh the displayed version after a resumed store check.
      setState(() => _update = update);
      return;
    }
    if (!_service.shouldDisplayUpgrade()) return;
    _backDispatcher.takePriority();
    setState(() => _update = update);
    unawaited(_saveAlert());
  }

  Future<void> _saveAlert() async {
    try {
      await _service.saveLastAlerted();
    } catch (error) {
      debugPrint('[Updates] No se pudo guardar el aviso: $error');
    }
  }

  Future<bool> _handleBack() async {
    if (_update == null) return false;
    _dismiss();
    return true;
  }

  void _dismiss() {
    widget.backButtonDispatcher.forget(_backDispatcher);
    setState(() => _update = null);
  }

  @override
  void dispose() {
    _subscription.cancel();
    _backDispatcher.removeCallback(_handleBack);
    widget.backButtonDispatcher.forget(_backDispatcher);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ExcludeFocus(
          excluding: _update != null,
          child: ExcludeSemantics(
            excluding: _update != null,
            child: widget.child,
          ),
        ),
        if (_update != null) ...[
          const ModalBarrier(dismissible: false, color: Colors.black54),
          SafeArea(
            child: AppUpdateDialog(
              version: _update!.appStoreVersion?.toString(),
              onUpdate: _service.openStore,
              onLater: _dismiss,
            ),
          ),
        ],
      ],
    );
  }
}

class AppUpdateDialog extends StatefulWidget {
  const AppUpdateDialog({
    super.key,
    required this.onUpdate,
    required this.onLater,
    this.version,
  });

  final String? version;
  final Future<bool> Function() onUpdate;
  final VoidCallback onLater;

  @override
  State<AppUpdateDialog> createState() => _AppUpdateDialogState();
}

class _AppUpdateDialogState extends State<AppUpdateDialog> {
  bool _opening = false;
  bool _failed = false;

  Future<void> _openStore() async {
    if (_opening) return;
    setState(() {
      _opening = true;
      _failed = false;
    });
    var opened = false;
    try {
      opened = await widget.onUpdate();
    } catch (_) {
      // Keep a recoverable error in the notice if the platform fails.
    }
    if (!mounted) return;
    setState(() {
      _opening = false;
      _failed = !opened;
    });
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return FocusScope(
      autofocus: true,
      child: Dialog(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const AppLineIcon(
                  AppIcons.retry,
                  size: AppIconSize.hero,
                  color: AppColors.primary,
                ),
                const SizedBox(height: 24),
                Semantics(
                  namesRoute: true,
                  header: true,
                  child: Text(
                    'Nueva actualización',
                    textAlign: TextAlign.center,
                    style: textTheme.headlineMedium?.copyWith(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Ya está disponible una nueva versión de GuIA. Puedes actualizar ahora o seguir usando la app y hacerlo más tarde.',
                  textAlign: TextAlign.center,
                  style: textTheme.bodyMedium?.copyWith(
                    fontSize: 15,
                    height: 1.45,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (widget.version?.isNotEmpty == true) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Versión ${widget.version}',
                    style: textTheme.bodyMedium
                        ?.copyWith(color: AppColors.textPrimary),
                  ),
                ],
                if (_failed) ...[
                  const SizedBox(height: 16),
                  Semantics(
                    liveRegion: true,
                    child: Text(
                      'No se pudo abrir la página de actualización. Puedes intentarlo de nuevo o seguir usando la app.',
                      textAlign: TextAlign.center,
                      style: textTheme.bodyMedium
                          ?.copyWith(color: AppColors.errorInk),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _opening ? null : _openStore,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(48, 56),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 16),
                      shape: const StadiumBorder(),
                      // Large bold type meets 3:1 contrast on the brand orange.
                      textStyle: textTheme.titleMedium?.copyWith(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2,
                      ),
                    ),
                    child: Text(
                      _opening ? 'ABRIENDO…' : 'ACTUALIZAR',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: widget.onLater,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    minimumSize: const Size(48, 48),
                  ),
                  child: const Text('Más tarde'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
