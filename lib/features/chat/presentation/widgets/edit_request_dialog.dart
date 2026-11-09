import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/photos/request_photos_controller.dart';
import '../../../../shared/photos/request_photos_editor.dart';
import '../../../home/presentation/providers/home_providers.dart';
import '../../domain/entities/chat_thread.dart';

class EditRequestDialog extends ConsumerStatefulWidget {
  const EditRequestDialog({super.key, required this.thread});
  final ChatThread thread;

  static Future<bool?> show(BuildContext context, ChatThread thread) =>
      showDialog<bool>(
          context: context,
          barrierDismissible: false,
          animationStyle: MediaQuery.disableAnimationsOf(context)
              ? AnimationStyle.noAnimation
              : null,
          builder: (_) => EditRequestDialog(thread: thread));

  @override
  ConsumerState<EditRequestDialog> createState() => _EditRequestDialogState();
}

class _EditRequestDialogState extends ConsumerState<EditRequestDialog> {
  late final _details =
      TextEditingController(text: widget.thread.details ?? '');
  late final RequestPhotosController _photos;
  bool _saving = false;
  bool _locked = false;
  bool _changed = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _photos = RequestPhotosController(
        ref.read(dioClientProvider).uploadRequestImage,
        initialUrls: widget.thread.photoUrls.isNotEmpty
            ? widget.thread.photoUrls
            : [if (widget.thread.fotoUrl != null) widget.thread.fotoUrl!]);
    _photos.addListener(_onChanged);
    _details.addListener(_onChanged);
  }

  void _onChanged() {
    if (mounted) {
      setState(() {
        _changed = true;
      });
    }
  }

  @override
  void dispose() {
    _photos.removeListener(_onChanged);
    _details.removeListener(_onChanged);
    _photos.dispose();
    _details.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || _locked || !_photos.ready) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final result = await ref.read(updateSearchRequestUseCaseProvider)(
        requestId: widget.thread.id,
        details: _details.text.trim(),
        photoUrls: _photos.urls);
    if (!mounted) return;
    result.fold((failure) {
      if (failure is RequestPhotosUnavailableFailure) _photos.requireReupload();
      setState(() {
        _saving = false;
        _locked = failure is RequestNotEditableFailure;
        _error = failure.message;
      });
    }, (_) => Navigator.pop(context, true));
  }

  @override
  Widget build(BuildContext context) => PopScope(
        canPop: !_saving,
        child: Dialog.fullscreen(
            backgroundColor: AppColors.background,
            child: SafeArea(
                child: Column(children: [
              Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: Row(children: [
                    Expanded(
                        child:
                            Text('Editar solicitud', style: AppTypography.h1)),
                    IconButton(
                        tooltip: 'Cerrar edición',
                        constraints:
                            const BoxConstraints(minWidth: 48, minHeight: 48),
                        onPressed: _saving
                            ? null
                            : () => Navigator.pop(context, false),
                        icon: const AppLineIcon(AppIcons.close)),
                  ])),
              Expanded(
                  child: AbsorbPointer(
                      absorbing: _saving || _locked,
                      child: ListView(
                          padding: const EdgeInsets.all(24),
                          children: [
                            Text(
                                '${widget.thread.quantity} ${widget.thread.quantity == 1 ? 'unidad' : 'unidades'} · La cantidad, el vehículo y el repuesto no se pueden cambiar.',
                                style: AppTypography.bodySm),
                            const SizedBox(height: 24),
                            Text('DESCRIPCIÓN', style: AppTypography.overline),
                            const SizedBox(height: 10),
                            TextField(
                                key: const Key('edit-request-details'),
                                controller: _details,
                                minLines: 3,
                                maxLines: 8,
                                style: AppTypography.body,
                                decoration: InputDecoration(
                                    filled: true,
                                    fillColor: AppColors.surface,
                                    contentPadding: const EdgeInsets.all(16),
                                    border: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(14)))),
                            const SizedBox(height: 24),
                            RequestPhotosEditor(controller: _photos),
                          ]))),
              if (_error != null)
                Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Semantics(
                        liveRegion: true,
                        child: Text(_error!,
                            style: AppTypography.bodySm
                                .copyWith(color: AppColors.errorInk)))),
              Padding(
                  padding: const EdgeInsets.all(24),
                  child: SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        key: const Key('save-request'),
                        style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.textOnPrimary,
                            textStyle: AppTypography.label,
                            minimumSize: const Size(48, 52),
                            shape: const StadiumBorder()),
                        onPressed:
                            _saving || _locked || !_photos.ready || !_changed
                                ? null
                                : _save,
                        child: _saving
                            ? const SizedBox.square(
                                dimension: 24,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.textOnPrimary,
                                    semanticsLabel: 'Guardando solicitud'))
                            : const Text('GUARDAR CAMBIOS'),
                      ))),
            ]))),
      );
}
