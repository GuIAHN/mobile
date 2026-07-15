import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/providers/current_user_provider.dart';
import '../providers/chat_providers.dart';
import '../../domain/entities/chat_thread.dart';
import '../widgets/chat_thread_card.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/skeleton_loader.dart';
import '../../../../shared/widgets/staggered_entrance.dart';

class ChatInboxPage extends ConsumerStatefulWidget {
  const ChatInboxPage({super.key});

  @override
  ConsumerState<ChatInboxPage> createState() => _ChatInboxPageState();
}

class _ChatInboxPageState extends ConsumerState<ChatInboxPage> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ChatThread> _filterThreads(List<ChatThread> threads) {
    if (_query.trim().isEmpty) return threads;
    final q = _query.trim().toLowerCase();
    return threads.where((t) {
      return t.title.toLowerCase().contains(q) ||
          (t.clientName?.toLowerCase().contains(q) ?? false);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final threadsAsync = ref.watch(chatThreadsProvider);
    final currentRole = ref.watch(currentRoleProvider);
    final isProvider = currentRole.isProvider;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: threadsAsync.when(
          loading: () => Column(
            children: [
              _buildHeader(
                threads: const [],
                isProvider: isProvider,
                isLoading: true,
              ),
              Expanded(
                child: ListView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  children: const [
                    ThreadCardSkeleton(),
                    ThreadCardSkeleton(),
                    ThreadCardSkeleton(),
                    ThreadCardSkeleton(),
                  ],
                ),
              ),
            ],
          ),
          error: (err, _) => Column(
            children: [
              _buildHeader(
                threads: const [],
                isProvider: isProvider,
                isLoading: false,
              ),
              Expanded(
                child: Center(
                  child: Text(
                    'Error al cargar chats: $err',
                    style: GoogleFonts.hankenGrotesk(color: AppColors.error),
                  ),
                ),
              ),
            ],
          ),
          data: (threads) {
            final filtered = _filterThreads(threads);
            return Column(
              children: [
                _buildHeader(
                  threads: threads,
                  isProvider: isProvider,
                  isLoading: false,
                ),
                Expanded(
                  child: threads.isEmpty
                      ? EmptyState(
                          title: 'Sin conversaciones',
                          subtitle: isProvider
                              ? 'No hay solicitudes activas para cotizar en este momento.'
                              : 'Tus solicitudes de repuesto o servicio aparecerán aquí.',
                          icon: Icons.chat_bubble_outline_rounded,
                        )
                      : filtered.isEmpty
                          ? EmptyState(
                              title: 'Sin resultados',
                              subtitle:
                                  'No encontramos conversaciones para "$_query".',
                              icon: Icons.search_off_rounded,
                            )
                          : RefreshIndicator(
                              onRefresh: () =>
                                  ref.refresh(chatThreadsProvider.future),
                              color: AppColors.primary,
                              child: ListView.builder(
                                physics: const AlwaysScrollableScrollPhysics(
                                  parent: BouncingScrollPhysics(),
                                ),
                                padding:
                                    const EdgeInsets.fromLTRB(24, 8, 24, 24),
                                itemCount: filtered.length,
                                itemBuilder: (context, index) {
                                  final thread = filtered[index];
                                  return StaggeredEntrance(
                                    index: index,
                                    child: ChatThreadCard(
                                      thread: thread,
                                      showClientName: isProvider,
                                      onTap: () async {
                                        if (isProvider) {
                                          final convsAsync = await ref.read(
                                              chatConversationsProvider(
                                                      thread.id)
                                                  .future);
                                          if (convsAsync.isNotEmpty) {
                                            final conversation =
                                                convsAsync.first;
                                            if (context.mounted) {
                                              context.push(
                                                  '/chats/${thread.id}/${conversation.id}');
                                            }
                                          } else {
                                            if (context.mounted) {
                                              context
                                                  .push('/chats/${thread.id}');
                                            }
                                          }
                                        } else {
                                          context.push('/chats/${thread.id}');
                                        }
                                      },
                                    ),
                                  );
                                },
                              ),
                            ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader({
    required List<ChatThread> threads,
    required bool isProvider,
    required bool isLoading,
  }) {
    final subtitle = isLoading
        ? 'Cargando tus conversaciones...'
        : (isProvider
            ? 'Cotiza solicitudes y da seguimiento a tus clientes'
            : 'Sigue tus solicitudes de repuesto o servicio');

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(
          bottom: BorderSide(color: AppColors.border, width: 0.6),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: AppColors.primaryMuted,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.forum_rounded,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mensajería',
                      style: GoogleFonts.hankenGrotesk(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.hankenGrotesk(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Barra de búsqueda de conversaciones
          Container(
            height: 46,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.search_rounded,
                    color: AppColors.textSecondary, size: 19),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    enabled: !isLoading,
                    onChanged: (val) => setState(() => _query = val),
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      isCollapsed: true,
                      hintText: isProvider
                          ? 'Buscar por cliente o solicitud...'
                          : 'Buscar por tienda o solicitud...',
                      hintStyle: GoogleFonts.hankenGrotesk(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: AppColors.textDisabled,
                      ),
                    ),
                  ),
                ),
                if (_query.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      _searchController.clear();
                      setState(() => _query = '');
                    },
                    behavior: HitTestBehavior.opaque,
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(Icons.cancel_rounded,
                          color: AppColors.textDisabled, size: 17),
                    ),
                  ),
              ],
            ),
          ),
          if (!isLoading && threads.isNotEmpty) ...[
            const SizedBox(height: 14),
            _buildStatsRow(threads: threads, isProvider: isProvider),
          ],
        ],
      ),
    );
  }

  Widget _buildStatsRow({
    required List<ChatThread> threads,
    required bool isProvider,
  }) {
    final String leftLabel;
    final String leftValue;
    final String rightLabel;
    final String rightValue;

    if (isProvider) {
      final pendientes = threads.where((t) => t.conversationCount == 0).length;
      final cotizadas = threads.length - pendientes;
      leftLabel = 'Por cotizar';
      leftValue = pendientes.toString();
      rightLabel = 'Cotizadas';
      rightValue = cotizadas.toString();
    } else {
      leftLabel = 'Solicitudes';
      leftValue = threads.length.toString();
      rightLabel = 'Ofertas';
      rightValue = threads
          .fold<int>(0, (sum, t) => sum + t.conversationCount)
          .toString();
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatColumn(leftLabel, leftValue),
          Container(width: 1, height: 36, color: AppColors.border),
          _buildStatColumn(rightLabel, rightValue),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.hankenGrotesk(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: AppColors.primary,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.hankenGrotesk(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
