import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/providers/paged_list_notifier.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

/// Virtualized list with viewport prefetch and a visible retry/load-more action.
/// Local searches walk pending pages before reporting an empty result.
class PagedListBody<T> extends StatefulWidget {
  const PagedListBody(
      {super.key,
      required this.state,
      required this.itemCount,
      required this.itemBuilder,
      required this.empty,
      required this.onLoadMore,
      required this.onRefresh,
      required this.padding,
      this.completeSearch = false});

  final PagedListState<T> state;
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final Widget empty;
  final Future<void> Function() onLoadMore;
  final Future<void> Function() onRefresh;
  final EdgeInsets padding;
  final bool completeSearch;

  @override
  State<PagedListBody<T>> createState() => _PagedListBodyState<T>();
}

class _PagedListBodyState<T> extends State<PagedListBody<T>> {
  final _controller = ScrollController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_prefetch);
  }

  void _prefetch() {
    final state = widget.state;
    if (!mounted ||
        !state.hasMore ||
        state.isLoadingMore ||
        state.loadMoreError != null) {
      return;
    }
    if (widget.completeSearch ||
        (_controller.hasClients && _controller.position.extentAfter < 600)) {
      unawaited(widget.onLoadMore());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _prefetch();
    });
    final state = widget.state;
    final footer = state.hasMore || state.loadMoreError != null;
    final empty = widget.itemCount == 0 && !state.hasMore;
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: widget.onRefresh,
      child: ListView.builder(
        controller: _controller,
        physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics()),
        padding: widget.padding,
        itemCount: empty ? 1 : widget.itemCount + (footer ? 1 : 0),
        itemBuilder: (context, index) {
          if (empty) {
            return Padding(
                padding: const EdgeInsets.only(top: 80), child: widget.empty);
          }
          if (index < widget.itemCount) {
            return widget.itemBuilder(context, index);
          }
          return SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Semantics(
                    liveRegion: true,
                    child: Text(
                      state.loadMoreError != null
                          ? 'No pudimos cargar más resultados.'
                          : state.isLoadingMore
                              ? 'Cargando más resultados…'
                              : widget.completeSearch
                                  ? 'Buscando en más resultados…'
                                  : 'Hay más resultados disponibles.',
                      style: AppTypography.bodySm
                          .copyWith(color: AppColors.textPrimary),
                      textAlign: TextAlign.center,
                    )),
                const SizedBox(height: 8),
                if (state.isLoadingMore)
                  Semantics(
                      label: 'Cargando más resultados',
                      child: const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2)))
                else
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(160, 48),
                      foregroundColor: AppColors.textPrimary,
                      side: const BorderSide(
                          color: AppColors.primary, width: 1.5),
                      shape: const StadiumBorder(),
                    ),
                    onPressed: widget.onLoadMore,
                    child: Text(state.loadMoreError != null
                        ? 'Reintentar'
                        : 'Cargar más'),
                  ),
              ]),
            ),
          );
        },
      ),
    );
  }
}
