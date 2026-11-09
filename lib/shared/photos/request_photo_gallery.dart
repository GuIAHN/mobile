import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_icons.dart';
import '../../core/theme/app_typography.dart';
import 'request_photo_image.dart';

class RequestPhotoGallery extends StatelessWidget {
  const RequestPhotoGallery({super.key, required this.urls, this.onEdit});
  final List<String> urls;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
      builder: (context, constraints) =>
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(
                  child: Text('FOTOS DEL REPUESTO',
                      style: AppTypography.overline
                          .copyWith(color: AppColors.textPrimary))),
              if (onEdit != null) ...[
                const SizedBox(width: 8),
                if (constraints.maxWidth >= 360 &&
                    MediaQuery.textScalerOf(context).scale(13) <= 16)
                  TextButton.icon(
                    key: const Key('edit-request'),
                    onPressed: onEdit,
                    style: TextButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        minimumSize: const Size(48, 48),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        textStyle: AppTypography.label,
                        shape: const StadiumBorder()),
                    icon: const AppLineIcon(AppIcons.edit,
                        size: AppIconSize.action),
                    label: const Text('Editar solicitud'),
                  )
                else
                  IconButton(
                    key: const Key('edit-request'),
                    tooltip: 'Editar solicitud',
                    onPressed: onEdit,
                    constraints:
                        const BoxConstraints(minWidth: 48, minHeight: 48),
                    icon: const AppLineIcon(AppIcons.edit,
                        size: AppIconSize.action, color: AppColors.primary),
                  ),
              ],
            ]),
            const SizedBox(height: 12),
            if (urls.isEmpty)
              Text('Esta solicitud no tiene fotos adjuntas.',
                  style: AppTypography.bodySm
                      .copyWith(color: AppColors.textPrimary))
            else
              SizedBox(
                key: const Key('request-photo-strip'),
                height: 80,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  primary: false,
                  padding: EdgeInsets.zero,
                  itemCount: urls.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) => Semantics(
                      button: true,
                      label: 'Ver foto ${index + 1} de ${urls.length}',
                      hint: 'Abre la foto a pantalla completa',
                      child: SizedBox.square(
                          dimension: 80,
                          child: Material(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(14),
                              clipBehavior: Clip.antiAlias,
                              child: InkWell(
                                  onTap: () => showDialog<void>(
                                      context: context,
                                      animationStyle:
                                          MediaQuery.disableAnimationsOf(
                                                  context)
                                              ? AnimationStyle.noAnimation
                                              : null,
                                      builder: (_) => _PhotoViewer(
                                          urls: urls, initialIndex: index)),
                                  child: ExcludeSemantics(
                                      child: RequestPhotoImage(
                                          url: urls[index],
                                          fit: BoxFit.cover)))))),
                ),
              ),
          ]));
}

class _PhotoViewer extends StatefulWidget {
  const _PhotoViewer({required this.urls, required this.initialIndex});
  final List<String> urls;
  final int initialIndex;
  @override
  State<_PhotoViewer> createState() => _PhotoViewerState();
}

class _PhotoViewerState extends State<_PhotoViewer> {
  late int _index = widget.initialIndex;
  final _transform = TransformationController();
  void _move(int delta) => setState(() {
        _index += delta;
        _transform.value = Matrix4.identity();
      });
  @override
  void dispose() {
    _transform.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Dialog.fullscreen(
        backgroundColor: AppColors.background,
        child: SafeArea(
            child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(children: [
                  Row(children: [
                    Expanded(
                        child: Semantics(
                            liveRegion: true,
                            child: Text(
                                'Foto ${_index + 1} de ${widget.urls.length}',
                                style: AppTypography.title))),
                    IconButton(
                        tooltip: 'Cerrar fotos',
                        constraints:
                            const BoxConstraints(minWidth: 48, minHeight: 48),
                        onPressed: () => Navigator.pop(context),
                        icon: const AppLineIcon(AppIcons.close))
                  ]),
                  Expanded(
                      child: InteractiveViewer(
                          key: ValueKey(_index),
                          transformationController: _transform,
                          minScale: 1,
                          maxScale: 4,
                          child: Center(
                              child: RequestPhotoImage(
                                  url: widget.urls[_index])))),
                  Wrap(alignment: WrapAlignment.center, children: [
                    IconButton(
                        tooltip: 'Foto anterior',
                        constraints:
                            const BoxConstraints(minWidth: 48, minHeight: 48),
                        onPressed: _index > 0 ? () => _move(-1) : null,
                        icon: const AppLineIcon(AppIcons.back)),
                    IconButton(
                        tooltip: 'Alejar foto',
                        constraints:
                            const BoxConstraints(minWidth: 48, minHeight: 48),
                        onPressed: () {
                          final scale =
                              (_transform.value.getMaxScaleOnAxis() / 1.5)
                                  .clamp(1.0, 4.0);
                          _transform.value =
                              Matrix4.diagonal3Values(scale, scale, 1);
                        },
                        icon: const AppLineIcon(AppIcons.zoomOut)),
                    IconButton(
                        tooltip: 'Acercar foto',
                        constraints:
                            const BoxConstraints(minWidth: 48, minHeight: 48),
                        onPressed: () {
                          final scale =
                              (_transform.value.getMaxScaleOnAxis() * 1.5)
                                  .clamp(1.0, 4.0);
                          _transform.value =
                              Matrix4.diagonal3Values(scale, scale, 1);
                        },
                        icon: const AppLineIcon(AppIcons.zoomIn)),
                    IconButton(
                        tooltip: 'Foto siguiente',
                        constraints:
                            const BoxConstraints(minWidth: 48, minHeight: 48),
                        onPressed: _index < widget.urls.length - 1
                            ? () => _move(1)
                            : null,
                        icon: const AppLineIcon(AppIcons.next)),
                  ]),
                ]))),
      );
}
