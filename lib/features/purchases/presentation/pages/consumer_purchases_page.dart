import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/layout/bottom_navigation_insets.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/skeleton_loader.dart';
import '../../../../shared/widgets/staggered_entrance.dart';
import '../../../../shared/widgets/status_filter_selector.dart';
import '../../domain/entities/consumer_purchase.dart';
import '../../domain/entities/purchases_result.dart';
import '../providers/purchases_providers.dart';
import '../widgets/consumer_purchase_card.dart';

class ConsumerPurchasesPage extends ConsumerStatefulWidget {
  const ConsumerPurchasesPage({super.key});

  @override
  ConsumerState<ConsumerPurchasesPage> createState() =>
      _ConsumerPurchasesPageState();
}

class _ConsumerPurchasesPageState extends ConsumerState<ConsumerPurchasesPage> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final purchases = ref.watch(consumerPurchasesProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: purchases.when(
          skipLoadingOnReload: true,
          loading: _buildLoading,
          error: (_, __) => _buildError(),
          data: _buildData,
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return Column(
      children: [
        _PurchasesHeader(
          controller: _searchController,
          query: _query,
          enabled: false,
          counts: const {},
          onQueryChanged: (_) {},
          onClear: () {},
        ),
        Expanded(
          child: ListView.builder(
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
              24,
              AppSpacing.sm,
              24,
              bottomNavigationContentInset(context) + AppSpacing.xl2,
            ),
            itemCount: 4,
            itemBuilder: (_, index) => StaggeredEntrance(
              index: index,
              child: const ThreadCardSkeleton(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildError() {
    return Column(
      children: [
        _PurchasesHeader(
          controller: _searchController,
          query: _query,
          counts: const {},
          onQueryChanged: _setQuery,
          onClear: _clearQuery,
        ),
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl3),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const AppLineIcon(
                    AppIcons.cloudError,
                    size: AppIconSize.hero,
                    color: AppColors.error,
                  ),
                  const SizedBox(height: AppSpacing.xl2),
                  Text(
                    'No pudimos cargar tus compras',
                    style: AppTypography.h2,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Revisa tu conexión e inténtalo nuevamente.',
                    style: AppTypography.bodySm,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.xl2),
                  SizedBox(
                    width: 220,
                    height: AppSpacing.buttonHeightMd,
                    child: OutlinedButton.icon(
                      onPressed: () =>
                          ref.invalidate(consumerPurchasesProvider),
                      icon: const AppLineIcon(
                        AppIcons.retry,
                        size: AppIconSize.inline,
                      ),
                      label: const Text('Reintentar'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildData(PurchasesResult result) {
    final query = _query.trim().toLowerCase();
    final visible = query.isEmpty
        ? result.purchases
        : result.purchases.where((purchase) {
            return purchase.vehicleName.toLowerCase().contains(query) ||
                purchase.storeName.toLowerCase().contains(query) ||
                (purchase.partName?.toLowerCase().contains(query) ?? false);
          }).toList();

    return Column(
      children: [
        _PurchasesHeader(
          controller: _searchController,
          query: _query,
          counts: result.counts,
          onQueryChanged: _setQuery,
          onClear: _clearQuery,
        ),
        Expanded(
          child: RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () => ref.refresh(consumerPurchasesProvider.future),
            child: visible.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    padding: EdgeInsets.only(
                      bottom: bottomNavigationContentInset(context) +
                          AppSpacing.xl2,
                    ),
                    children: [
                      const SizedBox(height: 80),
                      EmptyState(
                        title: result.purchases.isEmpty
                            ? 'Aún no tienes compras'
                            : 'Sin resultados',
                        subtitle: result.purchases.isEmpty
                            ? 'Cuando compres un repuesto, aparecerá en esta sección.'
                            : 'No encontramos compras para “$_query”.',
                        icon: result.purchases.isEmpty
                            ? AppIcons.purchases
                            : AppIcons.searchEmpty,
                      ),
                    ],
                  )
                : ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    padding: EdgeInsets.fromLTRB(
                      24,
                      AppSpacing.sm,
                      24,
                      bottomNavigationContentInset(context) + AppSpacing.xl2,
                    ),
                    itemCount: visible.length,
                    itemBuilder: (_, index) {
                      final purchase = visible[index];
                      return StaggeredEntrance(
                        key: ValueKey('purchase-${purchase.id}'),
                        index: index,
                        child: ConsumerPurchaseCard(
                          purchase: purchase,
                          onReview: _hasReviewAction(purchase)
                              ? () => _openReview(purchase)
                              : null,
                        ),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }

  bool _hasReviewAction(ConsumerPurchase purchase) {
    final cancelledStoreReview = purchase.status == PurchaseStatus.cancelled &&
        !purchase.hasReviewed &&
        purchase.storeId?.trim().isNotEmpty == true &&
        purchase.conversationId?.trim().isNotEmpty == true;
    final canWrite = purchase.needsReview &&
        purchase.canReview &&
        purchase.conversationId?.trim().isNotEmpty == true;
    final canRead = purchase.hasReviewed &&
        purchase.reviewTargetId?.trim().isNotEmpty == true;
    return cancelledStoreReview || canWrite || canRead;
  }

  Future<void> _openReview(ConsumerPurchase purchase) async {
    if (purchase.status == PurchaseStatus.cancelled &&
        !purchase.hasReviewed &&
        purchase.storeId?.trim().isNotEmpty == true &&
        purchase.conversationId?.trim().isNotEmpty == true) {
      await context.push(
        RouteNames.storeDetailForReviewPath(
          purchase.storeId!.trim(),
          conversationId: purchase.conversationId!.trim(),
        ),
      );
      return;
    }

    final result = await context.push<bool>(
      RouteNames.reviewEditorPath(
        targetId: purchase.reviewTargetId,
        conversationId: purchase.conversationId,
        providerName: purchase.storeName,
        readOnly: purchase.hasReviewed,
      ),
    );
    if (!mounted || result != true) return;
    ref.invalidate(consumerPurchasesProvider);
  }

  void _setQuery(String value) => setState(() => _query = value);

  void _clearQuery() {
    _searchController.clear();
    setState(() => _query = '');
  }
}

class _PurchasesHeader extends ConsumerWidget {
  const _PurchasesHeader({
    required this.controller,
    required this.query,
    required this.counts,
    required this.onQueryChanged,
    required this.onClear,
    this.enabled = true,
  });

  final TextEditingController controller;
  final String query;
  final Map<String, int> counts;
  final ValueChanged<String> onQueryChanged;
  final VoidCallback onClear;
  final bool enabled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(purchaseFilterProvider);
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 14),
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(bottom: BorderSide(color: AppColors.border, width: 0.6)),
      ),
      child: Column(
        children: [
          Container(
            key: const Key('request-search-bar'),
            height: AppSpacing.buttonHeightMd,
            padding: const EdgeInsets.only(left: 14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                const AppLineIcon(
                  AppIcons.search,
                  size: AppIconSize.action,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: TextField(
                    controller: controller,
                    enabled: enabled,
                    onChanged: onQueryChanged,
                    style: AppTypography.body,
                    decoration: InputDecoration(
                      hintText: 'Buscar por tienda o repuesto...',
                      hintStyle: AppTypography.body.copyWith(
                        color: AppColors.textDisabled,
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                      filled: false,
                      isCollapsed: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
                if (query.isNotEmpty)
                  IconButton(
                    tooltip: 'Limpiar búsqueda',
                    onPressed: onClear,
                    constraints: const BoxConstraints.tightFor(
                      width: AppSpacing.buttonHeightMd,
                      height: AppSpacing.buttonHeightMd,
                    ),
                    icon: const AppLineIcon(
                      AppIcons.close,
                      size: AppIconSize.inline,
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          if (enabled) ...[
            const SizedBox(height: AppSpacing.md),
            AppStatusFilterSelector<PurchaseFilter>(
              controlKey: const Key('consumer-purchase-filter-group'),
              selected: selected,
              options: [
                for (final filter in PurchaseFilter.values)
                  StatusFilterOption(
                    value: filter,
                    label: _purchaseFilterLabel(filter),
                    count: _purchaseFilterCount(filter, counts),
                  ),
              ],
              optionKeyBuilder: (filter) =>
                  Key('purchase-filter-${filter.name}'),
              singularNoun: 'compra',
              pluralNoun: 'compras',
              onChanged: (filter) {
                ref.read(purchaseFilterProvider.notifier).state = filter;
              },
            ),
          ],
        ],
      ),
    );
  }
}

String _purchaseFilterLabel(PurchaseFilter filter) => switch (filter) {
      PurchaseFilter.all => 'Todas',
      PurchaseFilter.toReceive => 'Por recibir',
      PurchaseFilter.delivered => 'Entregadas',
      PurchaseFilter.cancelled => 'Canceladas',
    };

int _purchaseFilterCount(
  PurchaseFilter filter,
  Map<String, int> counts,
) =>
    switch (filter) {
      PurchaseFilter.all => counts['all'] ?? 0,
      PurchaseFilter.toReceive => counts['toReceive'] ?? counts['bought'] ?? 0,
      PurchaseFilter.delivered => counts['delivered'] ?? 0,
      PurchaseFilter.cancelled => counts['cancelled'] ?? 0,
    };
