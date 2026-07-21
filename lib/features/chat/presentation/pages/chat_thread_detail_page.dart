import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/providers/current_user_provider.dart';
import '../../../../core/domain/enums/user_role.dart';
import '../providers/chat_providers.dart';
import '../widgets/chat_conversation_card.dart';
import '../widgets/quote_input_dialog.dart';
import '../../domain/entities/chat_thread.dart';
import '../../../../shared/widgets/skeleton_loader.dart';
import '../../../../shared/widgets/staggered_entrance.dart';

class ChatThreadDetailPage extends ConsumerWidget {
  final String threadId;

  const ChatThreadDetailPage({
    super.key,
    required this.threadId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final threadsAsync = ref.watch(chatThreadsProvider);
    final conversationsAsync = ref.watch(chatConversationsProvider(threadId));
    final currentRole = ref.watch(currentRoleProvider);
    final isStore = currentRole == UserRole.store;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Detalle de Solicitud',
          style: GoogleFonts.hankenGrotesk(
            fontSize: 16.5,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(chatThreadsProvider);
          ref.invalidate(chatConversationsProvider(threadId));
        },
        color: AppColors.primary,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics()),
          slivers: [
            // 1. Resumen de la Solicitud
            SliverToBoxAdapter(
              child: threadsAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  child: OfferCardSkeleton(),
                ),
                error: (_, __) => const SizedBox.shrink(),
                data: (threads) {
                  final thread = threads.cast<ChatThread>().firstWhere(
                        (t) => t.id == threadId,
                        orElse: () => threads.first,
                      );
                  return Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    child: _RequestSummaryCard(
                      thread: thread,
                      isStore: isStore,
                      ref: ref,
                    ),
                  );
                },
              ),
            ),

            // 2. Encabezado "X Ofertas Recibidas"
            SliverToBoxAdapter(
              child: conversationsAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
                data: (conversations) {
                  if (conversations.isEmpty) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                    child: _OffersCountHeader(
                      count: conversations.length,
                      isStore: isStore,
                    ),
                  );
                },
              ),
            ),

            // 3. Lista de Ofertas o Estado Vacío
            conversationsAsync.when(
              loading: () => SliverList(
                delegate: SliverChildListDelegate(const [
                  Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 24, vertical: 6),
                      child: OfferCardSkeleton()),
                  Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 24, vertical: 6),
                      child: OfferCardSkeleton()),
                  Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 24, vertical: 6),
                      child: OfferCardSkeleton()),
                ]),
              ),
              error: (err, _) => SliverToBoxAdapter(
                child: Center(
                  child: Text(
                    'Error al cargar ofertas: $err',
                    style: GoogleFonts.hankenGrotesk(color: AppColors.error),
                  ),
                ),
              ),
              data: (conversations) {
                if (conversations.isEmpty) {
                  if (isStore) return const SliverToBoxAdapter(child: SizedBox.shrink());

                  return SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 40, vertical: 40),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: const BoxDecoration(
                              color: AppColors.primaryMuted,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.forum_outlined,
                                size: 40, color: AppColors.primary),
                          ),
                          const SizedBox(height: 18),
                          Text(
                            'Esperando ofertas',
                            style: GoogleFonts.hankenGrotesk(
                              fontSize: 16.5,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Las tiendas de repuestos empezarán a cotizar y responder pronto. Te notificaremos.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.hankenGrotesk(
                              fontSize: 13.5,
                              color: AppColors.textSecondary,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final conv = conversations[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 6),
                        child: StaggeredEntrance(
                          index: index,
                          child: ChatConversationCard(
                            conversation: conv,
                            onTap: () async {
                              if (isStore) {
                                context.push('/chats/$threadId/${conv.id}');
                              } else {
                                showDialog(
                                  context: context,
                                  barrierDismissible: false,
                                  builder: (_) => const Center(
                                      child: CircularProgressIndicator(
                                          color: AppColors.primary)),
                                );

                                final repo = ref.read(chatRepositoryProvider);
                                final res =
                                    await repo.startChatFromOffer(conv.id);

                                if (context.mounted) {
                                  Navigator.of(context).pop();
                                }

                                res.fold(
                                  (failure) {
                                    if (context.mounted) {
                                      context.showSnackBar(
                                          'Error al abrir chat: ${failure.message}',
                                          isError: true);
                                    }
                                  },
                                  (realConversationId) {
                                    if (context.mounted) {
                                      context.push(
                                          '/chats/$threadId/$realConversationId');
                                    }
                                  },
                                );
                              }
                            },
                          ),
                        ),
                      );
                    },
                    childCount: conversations.length,
                  ),
                );
              },
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        ),
      ),
    );
  }
}

class _RequestSummaryCard extends StatelessWidget {
  final ChatThread thread;
  final bool isStore;
  final WidgetRef ref;

  const _RequestSummaryCard({
    required this.thread,
    required this.isStore,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    String partTypeLabel = 'Cualquiera';
    if (thread.partType != null) {
      if (thread.partType == 'ORIGINAL') {
        partTypeLabel = 'Original';
      } else if (thread.partType == 'GENERIC') {
        partTypeLabel = 'Genérico';
      } else if (thread.partType == 'PERFORMANCE') {
        partTypeLabel = 'Performance';
      }
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.05),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.inventory_2_outlined,
                    color: AppColors.primary, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'DATOS DE LA SOLICITUD',
                          style: GoogleFonts.hankenGrotesk(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: AppColors.primary,
                            letterSpacing: 1.2,
                          ),
                        ),
                        if (!thread.isOpen)
                           Container(
                             padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                             decoration: BoxDecoration(
                               color: AppColors.grey200,
                               borderRadius: BorderRadius.circular(99),
                             ),
                             child: Text(
                               'CERRADA',
                               style: GoogleFonts.hankenGrotesk(
                                 fontSize: 9,
                                 fontWeight: FontWeight.w900,
                                 color: AppColors.textSecondary,
                               ),
                             ),
                           ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      thread.subcategory ?? 'Solicitud de Repuesto',
                      style: GoogleFonts.hankenGrotesk(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.grey50,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.directions_car_outlined,
                    color: AppColors.textSecondary, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Vehículo',
                        style: GoogleFonts.hankenGrotesk(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${thread.title} ${thread.vehicleYear != null ? "• ${thread.vehicleYear}" : ""}',
                        style: GoogleFonts.hankenGrotesk(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildDetailChip(
                  icon: Icons.category_outlined,
                  label: 'Categoría',
                  value: thread.subcategory ?? 'Repuesto',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDetailChip(
                  icon: Icons.extension_outlined,
                  label: 'Tipo',
                  value: partTypeLabel,
                ),
              ),
            ],
          ),
          if (thread.details != null && thread.details!.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text(
              'Detalles adicionales:',
              style: GoogleFonts.hankenGrotesk(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.1)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.format_quote_rounded,
                      color: AppColors.primary, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      thread.details!,
                      style: GoogleFonts.hankenGrotesk(
                        fontSize: 14,
                        color: AppColors.textPrimary,
                        height: 1.5,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),
          if (thread.fotoUrl != null && thread.fotoUrl!.isNotEmpty) ...[
            Text(
              'Imagen de referencia:',
              style: GoogleFonts.hankenGrotesk(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.grey50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Image.network(
                  thread.fotoUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.broken_image_outlined,
                              color: AppColors.textSecondary, size: 40),
                          const SizedBox(height: 8),
                          Text(
                            'Imagen no disponible',
                            style: GoogleFonts.hankenGrotesk(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.primary),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 32),
          ] else
            const SizedBox(height: 10),
          if (isStore) ...[
            if (thread.hasOffer)
              ElevatedButton.icon(
                onPressed: () {
                  context.showSnackBar(
                    'Ya enviaste una cotización para esta solicitud.',
                  );
                },
                icon: const Icon(Icons.check_circle_rounded,
                    color: Colors.white),
                label: Text(
                  thread.offerPrice != null
                      ? 'COTIZACIÓN ENVIADA (L. ${thread.offerPrice!.toStringAsFixed(2)})'
                      : 'COTIZACIÓN ENVIADA',
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(32),
                  ),
                ),
              )
            else
              ElevatedButton(
                onPressed: () async {
                  final result =
                      await QuoteInputDialog.show(context, thread.title);
                  if (result != null) {
                    final isFixed = result['isFixedPrice'] as bool;
                    final price = result['price'] as double?;
                    final minPrice = result['minPrice'] as double?;
                    final maxPrice = result['maxPrice'] as double?;
                    final brand = result['brand'] as String?;
                    final photoPath = result['photoPath'] as String?;

                    final useCase = ref.read(createQuoteUseCaseProvider);
                    final quoteRes = await useCase(
                      threadId: thread.id,
                      isFixedPrice: isFixed,
                      price: price,
                      minPrice: minPrice,
                      maxPrice: maxPrice,
                      brand: brand,
                      photoPath: photoPath,
                    );

                    quoteRes.fold(
                      (failure) {
                        context.showSnackBar(
                          'Error al enviar cotización: ${failure.message}',
                          isError: true,
                        );
                      },
                      (newConv) {
                        context.showSnackBar('¡Oferta enviada con éxito!');
                        ref.invalidate(chatConversationsProvider(thread.id));
                        ref.invalidate(chatThreadsProvider);
                        ref.invalidate(myConversationsProvider);
                        context.pushReplacement(
                            '/chats/${thread.id}/${newConv.id}');
                      },
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  elevation: 4,
                  shadowColor: AppColors.primary.withValues(alpha: 0.4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(32),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.send_rounded, size: 20),
                    const SizedBox(width: 10),
                    Text(
                      'ENVIAR OFERTA AL CLIENTE',
                      style: GoogleFonts.hankenGrotesk(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailChip(
      {required IconData icon, required String label, required String value}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.hankenGrotesk(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _OffersCountHeader extends StatelessWidget {
  final int count;
  final bool isStore;

  const _OffersCountHeader({required this.count, required this.isStore});

  @override
  Widget build(BuildContext context) {
    final label = isStore
        ? (count == 1 ? '1 cotización' : '$count cotizaciones')
        : (count == 1 ? '1 oferta recibida' : '$count ofertas recibidas');

    return Padding(
      padding: const EdgeInsets.only(bottom: 14, top: 4),
      child: Row(
        children: [
          Text(
            label,
            style: GoogleFonts.hankenGrotesk(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          if (!isStore) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.primaryMuted,
                borderRadius: BorderRadius.circular(99),
              ),
              child: Text(
                'Compara y elige',
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
