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
import '../../../../shared/widgets/loading_indicator.dart';

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
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: threadsAsync.when(
          loading: () => const Text('Cargando...'),
          error: (_, __) => const Text('Detalle de Solicitud'),
          data: (threads) {
            final thread = threads.cast<ChatThread>().firstWhere(
              (t) => t.id == threadId,
              orElse: () => threads.first,
            );
            return Text(
              thread.title,
              style: GoogleFonts.hankenGrotesk(
                fontSize: 16.5,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            );
          },
        ),
      ),
      body: conversationsAsync.when(
        loading: () => const LoadingIndicator(),
        error: (err, _) => Center(
          child: Text(
            'Error al cargar ofertas: $err',
            style: GoogleFonts.hankenGrotesk(color: AppColors.error),
          ),
        ),
        data: (conversations) {
          if (isStore && conversations.isEmpty) {
            // Store has not responded yet -> Show big invitation card with "Quote" button
            return _buildStoreTakeRequestView(context, ref);
          }

          if (conversations.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: const BoxDecoration(
                        color: AppColors.primaryMuted,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.forum_outlined, size: 40, color: AppColors.primary),
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

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            itemCount: conversations.length,
            itemBuilder: (context, index) {
              final conv = conversations[index];
              return ChatConversationCard(
                conversation: conv,
                onTap: () {
                  context.push('/chats/$threadId/${conv.id}');
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildStoreTakeRequestView(BuildContext context, WidgetRef ref) {
    final threads = ref.read(chatThreadsProvider).valueOrNull ?? [];
    final thread = threads.cast<ChatThread>().firstWhere((t) => t.id == threadId, orElse: () => threads.first);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Info
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                    color: AppColors.primaryMuted,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.build_circle_outlined, color: AppColors.primary, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SOLICITUD PENDIENTE',
                        style: GoogleFonts.hankenGrotesk(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w900,
                          color: AppColors.primary,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        thread.clientName ?? 'Cliente del sistema',
                        style: GoogleFonts.hankenGrotesk(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 30, color: AppColors.border),
            
            // Description/Instructions
            Text(
              'Detalles del repuesto solicitado:',
              style: GoogleFonts.hankenGrotesk(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              thread.title,
              style: GoogleFonts.hankenGrotesk(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.grey50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Text(
                'Nota del cliente: Favor cotizar repuesto original o en marcas homologadas de buena calidad. Enviar precio estimado o fijo.',
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  fontStyle: FontStyle.italic,
                  height: 1.45,
                ),
              ),
            ),
            
            const SizedBox(height: 36),
            
            // Action Button to Open QuoteInputDialog
            ElevatedButton(
              onPressed: () async {
                final result = await QuoteInputDialog.show(context, thread.title);
                if (result != null) {
                  // Submit initial quote
                  final isFixed = result['isFixedPrice'] as bool;
                  final price = result['price'] as double?;
                  final minPrice = result['minPrice'] as double?;
                  final maxPrice = result['maxPrice'] as double?;

                  final useCase = ref.read(createQuoteUseCaseProvider);
                  final quoteRes = await useCase(
                    threadId: threadId,
                    isFixedPrice: isFixed,
                    price: price,
                    minPrice: minPrice,
                    maxPrice: maxPrice,
                  );

                  quoteRes.fold(
                    (failure) {
                      context.showSnackBar(
                        'Error al enviar cotización: ${failure.message}',
                        isError: true,
                      );
                    },
                    (newConv) {
                      // Refresh conversations list
                      ref.invalidate(chatConversationsProvider(threadId));
                      // Refresh inbox
                      ref.invalidate(chatThreadsProvider);
                      // Navigate straight to the chat conversation
                      context.pushReplacement('/chats/$threadId/${newConv.id}');
                    },
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(32),
                ),
              ),
              child: Text(
                'TOMAR SOLICITUD Y COTIZAR',
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
