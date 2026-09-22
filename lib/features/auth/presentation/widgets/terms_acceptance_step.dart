import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';

enum TermsAudience {
  consumer,
  serviceProvider,
}

extension TermsAudienceDetails on TermsAudience {
  String get assetPath => switch (this) {
        TermsAudience.consumer => 'assets/legal/terms_consumer.txt',
        TermsAudience.serviceProvider =>
          'assets/legal/terms_service_provider.txt',
      };

  String get documentTitle => switch (this) {
        TermsAudience.consumer => 'Términos para usuarios',
        TermsAudience.serviceProvider => 'Términos para prestadores',
      };

  String get accountDescription => switch (this) {
        TermsAudience.consumer => 'tu cuenta de usuario',
        TermsAudience.serviceProvider => 'tu perfil como prestador',
      };
}

class TermsAcceptanceStep extends StatelessWidget {
  const TermsAcceptanceStep({
    super.key,
    required this.audience,
    required this.isAccepted,
    required this.onAcceptedChanged,
  });

  final TermsAudience audience;
  final bool isAccepted;
  final ValueChanged<bool> onAcceptedChanged;

  Future<void> _openDocument(BuildContext context) async {
    final accepted = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => TermsDocumentViewerPage(audience: audience),
      ),
    );

    if (accepted == true && context.mounted) {
      onAcceptedChanged(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primaryMuted,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.description_outlined,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'DOCUMENTO LEGAL',
                      style: GoogleFonts.hankenGrotesk(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      audience.documentTitle,
                      style: GoogleFonts.hankenGrotesk(
                        fontSize: 17,
                        height: 1.2,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Lee el documento correspondiente a ${audience.accountDescription} antes de completar el registro.',
            style: GoogleFonts.hankenGrotesk(
              fontSize: 14,
              height: 1.5,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          Semantics(
            button: true,
            label: 'Abrir ${audience.documentTitle}',
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _openDocument(context),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  constraints: const BoxConstraints(minHeight: 72),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.menu_book_outlined,
                        color: AppColors.primary,
                        size: 22,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Abrir documento',
                              style: GoogleFonts.hankenGrotesk(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Visualiza el texto completo',
                              style: GoogleFonts.hankenGrotesk(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.open_in_new,
                        color: AppColors.textSecondary,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          AnimatedContainer(
            duration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: isAccepted ? AppColors.successLight : AppColors.background,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isAccepted ? AppColors.successInk : AppColors.border,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(14),
              clipBehavior: Clip.antiAlias,
              child: CheckboxListTile(
                key: const Key('terms-step-checkbox'),
                value: isAccepted,
                onChanged: (value) {
                  if (isAccepted) {
                    onAcceptedChanged(false);
                  } else {
                    _openDocument(context);
                  }
                },
                controlAffinity: ListTileControlAffinity.leading,
                activeColor: AppColors.successInk,
                checkColor: Colors.white,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                title: Text(
                  isAccepted
                      ? 'Términos y condiciones aceptados'
                      : 'He leído y acepto los términos y condiciones',
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 14,
                    height: 1.35,
                    fontWeight: FontWeight.w700,
                    color: isAccepted
                        ? AppColors.successInk
                        : AppColors.textPrimary,
                  ),
                ),
                subtitle: isAccepted
                    ? Text(
                        'Puedes abrir el documento nuevamente antes de registrarte.',
                        style: GoogleFonts.hankenGrotesk(
                          fontSize: 12,
                          height: 1.35,
                          color: AppColors.textSecondary,
                        ),
                      )
                    : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class TermsDocumentViewerPage extends StatefulWidget {
  const TermsDocumentViewerPage({
    super.key,
    required this.audience,
    this.assetLoader,
  });

  final TermsAudience audience;
  final Future<String> Function(String assetPath)? assetLoader;

  @override
  State<TermsDocumentViewerPage> createState() =>
      _TermsDocumentViewerPageState();
}

class _TermsDocumentViewerPageState extends State<TermsDocumentViewerPage> {
  late Future<String> _document;
  bool _confirmed = false;

  @override
  void initState() {
    super.initState();
    _loadDocument();
  }

  void _loadDocument() {
    final loader = widget.assetLoader;
    _document = loader == null
        ? rootBundle.loadString(widget.audience.assetPath)
        : loader(widget.audience.assetPath);
  }

  void _retry() {
    setState(_loadDocument);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _ViewerHeader(title: widget.audience.documentTitle),
            Expanded(
              child: FutureBuilder<String>(
                future: _document,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const _DocumentLoadingState();
                  }
                  if (snapshot.hasError) {
                    return _DocumentUnavailableState(
                      message: 'No pudimos abrir este documento.',
                      onRetry: _retry,
                    );
                  }

                  final content = snapshot.data?.trim() ?? '';
                  if (content.isEmpty) {
                    return _DocumentUnavailableState(
                      message: 'El documento está vacío o no está disponible.',
                      onRetry: _retry,
                    );
                  }

                  return _TermsDocumentContent(content: content);
                },
              ),
            ),
            FutureBuilder<String>(
              future: _document,
              builder: (context, snapshot) {
                final canAccept =
                    snapshot.connectionState == ConnectionState.done &&
                        !snapshot.hasError &&
                        (snapshot.data?.trim().isNotEmpty ?? false);
                if (!canAccept) return const SizedBox.shrink();

                return _AcceptanceBar(
                  confirmed: _confirmed,
                  onConfirmedChanged: (value) {
                    setState(() => _confirmed = value);
                  },
                  onAccept:
                      _confirmed ? () => Navigator.of(context).pop(true) : null,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ViewerHeader extends StatelessWidget {
  const _ViewerHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(12, 8, 24, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            tooltip: 'Volver al registro',
            constraints: const BoxConstraints.tightFor(width: 48, height: 48),
            icon: const Icon(
              Icons.arrow_back_ios_new,
              color: AppColors.textPrimary,
              size: 22,
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.hankenGrotesk(
                fontSize: 17,
                height: 1.2,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TermsDocumentContent extends StatelessWidget {
  const _TermsDocumentContent({required this.content});

  final String content;

  @override
  Widget build(BuildContext context) {
    final paragraphs = content
        .split(RegExp(r'\r?\n'))
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList(growable: false);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680),
        child: Scrollbar(
          child: ListView.separated(
            key: const Key('terms-document-content'),
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
            itemCount: paragraphs.length,
            separatorBuilder: (_, index) => SizedBox(
              height: _isSectionHeading(paragraphs[index]) ? 10 : 14,
            ),
            itemBuilder: (context, index) {
              final paragraph = paragraphs[index];
              if (index == 0) {
                return SelectableText(
                  paragraph,
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 20,
                    height: 1.3,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                );
              }
              if (_isSectionHeading(paragraph)) {
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: SelectableText(
                    paragraph,
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 16,
                      height: 1.35,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                );
              }

              final isBullet = paragraph.startsWith('•');
              return Padding(
                padding: EdgeInsets.only(left: isBullet ? 8 : 0),
                child: SelectableText(
                  paragraph,
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 15,
                    height: 1.55,
                    color: AppColors.textPrimary,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  static bool _isSectionHeading(String text) {
    return RegExp(r'^\d+\.\s+[A-ZÁÉÍÓÚÜÑ]').hasMatch(text);
  }
}

class _DocumentLoadingState extends StatelessWidget {
  const _DocumentLoadingState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Semantics(
        liveRegion: true,
        label: 'Cargando términos y condiciones',
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: AppColors.primary),
            const SizedBox(height: 16),
            Text(
              'Cargando documento…',
              style: GoogleFonts.hankenGrotesk(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DocumentUnavailableState extends StatelessWidget {
  const _DocumentUnavailableState({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Semantics(
          liveRegion: true,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.errorLight,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.description_outlined,
                  color: AppColors.errorInk,
                  size: 28,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 16,
                  height: 1.4,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh, size: 20),
                label: const Text('Intentar de nuevo'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(180, 48),
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(32),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AcceptanceBar extends StatelessWidget {
  const _AcceptanceBar({
    required this.confirmed,
    required this.onConfirmedChanged,
    required this.onAccept,
  });

  final bool confirmed;
  final ValueChanged<bool> onConfirmedChanged;
  final VoidCallback? onAccept;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Material(
            color: AppColors.surface,
            child: CheckboxListTile(
              key: const Key('viewer-accept-checkbox'),
              value: confirmed,
              onChanged: (value) => onConfirmedChanged(value ?? false),
              controlAffinity: ListTileControlAffinity.leading,
              activeColor: AppColors.primary,
              contentPadding: EdgeInsets.zero,
              title: Text(
                'He leído y acepto estos términos y condiciones',
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 14,
                  height: 1.35,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              key: const Key('accept-terms-button'),
              onPressed: onAccept,
              icon: const Icon(Icons.check_circle_outline, size: 20),
              label: Text(
                'ACEPTAR Y VOLVER',
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFFD9DCE1),
                disabledForegroundColor: const Color(0xFF9AA0A8),
                elevation: 0,
                minimumSize: const Size.fromHeight(52),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(32),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
