import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/skeleton_loader.dart';
import '../providers/chat_providers.dart';
import '../widgets/chat_conversation_card.dart';

/// Historial de compras del usuario: conversaciones cuya oferta ya fue
/// comprada (BOUGHT) o entregada (DELIVERED). Estilo Mercado Libre.
class MisComprasPage extends ConsumerWidget {
  const MisComprasPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversationsAsync = ref.watch(myConversationsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 14, 24, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Mis Compras',
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Ofertas que ya compraste o recibiste',
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: conversationsAsync.when(
                loading: () => ListView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                  itemCount: 3,
                  itemBuilder: (_, __) => const ThreadCardSkeleton(),
                ),
                error: (err, _) => Center(
                  child: Text(
                    'Error al cargar compras: $err',
                    style: GoogleFonts.hankenGrotesk(color: AppColors.error),
                  ),
                ),
                data: (conversations) {
                  final compras = conversations
                      .where((c) =>
                          c.offerStatus == 'BOUGHT' ||
                          c.offerStatus == 'DELIVERED')
                      .toList();

                  if (compras.isEmpty) {
                    return RefreshIndicator(
                      onRefresh: () =>
                          ref.refresh(myConversationsProvider.future),
                      color: AppColors.primary,
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(
                            parent: BouncingScrollPhysics()),
                        children: const [
                          SizedBox(height: 80),
                          EmptyState(
                            title: 'Aún no tienes compras',
                            subtitle:
                                'Cuando aceptes una oferta y compres, aparecerá aquí tu historial.',
                            icon: Icons.shopping_bag_outlined,
                          ),
                        ],
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () =>
                        ref.refresh(myConversationsProvider.future),
                    color: AppColors.primary,
                    child: ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics()),
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                      itemCount: compras.length,
                      itemBuilder: (context, index) {
                        final conv = compras[index];
                        return ChatConversationCard(
                          conversation: conv,
                          onTap: () {
                            context.push('/chats/${conv.threadId}/${conv.id}');
                          },
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
