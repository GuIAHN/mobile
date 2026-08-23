import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/domain/enums/service_type.dart';
import '../providers/home_providers.dart';
import '../widgets/provider_detail_widgets.dart';
import '../widgets/service_provider_detail_view.dart';

class MechanicDetailPage extends ConsumerWidget {
  final String mechanicId;

  const MechanicDetailPage({super.key, required this.mechanicId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final args = (id: mechanicId, type: ServiceType.mechanic);
    final detailAsync = ref.watch(providerDetailProvider(args));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: detailAsync.when(
        loading: () => const ServiceProviderDetailSkeleton(),
        error: (e, _) => DetailErrorView(
          title: 'No se pudo cargar el perfil',
          message:
              'No pudimos cargar los datos. Revisa tu conexión e inténtalo nuevamente.',
          onRetry: () => ref.invalidate(providerDetailProvider(args)),
        ),
        data: (detail) => ServiceProviderDetailView(
          detail: detail,
          heroTag: 'provider-avatar-$mechanicId',
        ),
      ),
    );
  }
}
