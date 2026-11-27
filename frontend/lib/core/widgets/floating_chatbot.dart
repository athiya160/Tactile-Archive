import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../features/ai/presentation/pages/archive_ai_page.dart';
import '../design_system/tokens/ds_colors.dart';

/// Floating AI Chatbot widget supporting both standalone usage and
/// integration inside [GlobalChatbotOverlay].
///
/// Features:
/// - Fixed viewport positioning without page scrolling interference.
/// - Distinct desktop (pill) and mobile (circular FAB) presentation.
/// - Responsive panel modal with conversation preservation.
/// - Context-aware prompt support passed to [ArchiveAIPage].
class FloatingChatbot extends StatefulWidget {
  final String? currentRoute;
  final bool? isOpen;
  final ValueChanged<bool>? onToggle;

  const FloatingChatbot({
    super.key,
    this.currentRoute,
    this.isOpen,
    this.onToggle,
  });

  @override
  State<FloatingChatbot> createState() => _FloatingChatbotState();
}

class _FloatingChatbotState extends State<FloatingChatbot> {
  bool _internalIsOpen = false;

  bool get _isOpen => widget.isOpen ?? _internalIsOpen;

  void _toggleChat() {
    final next = !_isOpen;
    if (widget.onToggle != null) {
      widget.onToggle!(next);
    } else {
      setState(() => _internalIsOpen = next);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final isDesktop = screenWidth >= 700;

    if (!_isOpen) {
      if (!isDesktop) {
        return Semantics(
          button: true,
          label: 'Ask Archive AI Floating Launcher',
          child: Container(
            key: const ValueKey('floating_chatbot_launcher_mobile'),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: DSColors.forestGreen.withValues(alpha: 0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Tooltip(
              message: 'Ask Archive AI',
              child: SizedBox(
                width: 50,
                height: 50,
                child: ElevatedButton(
                  onPressed: _toggleChat,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.zero,
                    shape: const CircleBorder(),
                    backgroundColor: DSColors.forestGreen,
                    elevation: 5,
                    side: const BorderSide(color: Color(0xFFD4AF37), width: 1.5),
                  ),
                  child: const FaIcon(
                    FontAwesomeIcons.wandMagicSparkles,
                    size: 19,
                    color: Color(0xFFFFD700),
                  ),
                ),
              ),
            ),
          ),
        );
      }

      return Semantics(
        button: true,
        label: 'Ask Archive AI Floating Launcher',
        child: Container(
          key: const ValueKey('floating_chatbot_launcher_desktop'),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            boxShadow: [
              BoxShadow(
                color: DSColors.forestGreen.withValues(alpha: 0.35),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ElevatedButton.icon(
            onPressed: _toggleChat,
            style: ElevatedButton.styleFrom(
              backgroundColor: DSColors.forestGreen,
              foregroundColor: Colors.white,
              elevation: 4,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              side: const BorderSide(color: Color(0xFFD4AF37), width: 1.2),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
            ),
            icon: const FaIcon(FontAwesomeIcons.wandMagicSparkles, size: 14, color: Color(0xFFFFD700)),
            label: Text(
              'Ask Archive AI',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w700,
                fontSize: 13.5,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ),
      );
    }

    final dialogWidth = isDesktop
        ? 420.0
        : (screenWidth - 24.0).clamp(280.0, 480.0);
    final keyboardHeight = mediaQuery.viewInsets.bottom;
    final paddingTop = mediaQuery.padding.top;
    final availableHeight = mediaQuery.size.height - keyboardHeight - paddingTop - 32.0;
    final dialogHeight = isDesktop
        ? 600.0
        : availableHeight.clamp(280.0, 580.0);

    return Material(
      color: Colors.transparent,
      child: Container(
        key: const ValueKey('floating_chatbot_panel'),
        width: dialogWidth,
        height: dialogHeight,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFD4AF37).withValues(alpha: 0.35), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.22),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: ArchiveAIPage(
            isDrawerMode: true,
            currentRoute: widget.currentRoute,
            onClose: _toggleChat,
          ),
        ),
      ),
    );
  }
}
