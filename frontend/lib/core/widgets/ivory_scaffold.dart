import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../tokens/app_tokens.dart';

class IvoryScaffold extends StatelessWidget {
  final Widget body;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final String? title;
  final Widget? titleWidget;
  final List<Widget>? actions;
  final Widget? leading;
  final bool showAppBar;

  const IvoryScaffold({
    super.key,
    required this.body,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.title,
    this.titleWidget,
    this.actions,
    this.leading,
    this.showAppBar = true,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 1024;

        if (isDesktop) {
          return Scaffold(
            backgroundColor: AppColors.surface,
            body: Material(
              color: Colors.transparent,
              child: body,
            ),
          );
        }

        Widget content = Column(
          children: [
            if (showAppBar)
              _IvoryGlassHeader(
                title: title,
                titleWidget: titleWidget,
                actions: actions,
                leading: leading,
              ),
            Expanded(child: body),
            ?bottomNavigationBar,
          ],
        );

        return Scaffold(
          backgroundColor: AppColors.surface,
          floatingActionButton: floatingActionButton,
          body: Material(
            color: Colors.transparent,
            child: content,
          ),
        );
      },
    );
  }
}

class _IvoryGlassHeader extends StatelessWidget {
  final String? title;
  final Widget? titleWidget;
  final List<Widget>? actions;
  final Widget? leading;

  const _IvoryGlassHeader({
    this.title,
    this.titleWidget,
    this.actions,
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();
    Widget? effectiveLeading = leading;
    if (effectiveLeading == null && canPop) {
      effectiveLeading = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Navigator.of(context).maybePop(),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black.withValues(alpha: 0.04),
              border: Border.all(color: const Color(0xFFE5DDD0), width: 1),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 15,
              color: Color(0xFF1B1E1B),
            ),
          ),
        ),
      );
    }

    return Container(
      height: 54 + MediaQuery.of(context).padding.top,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top,
        left: 14,
        right: 14,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        border: const Border(
          bottom: BorderSide(color: Color(0xFFE7E1D6), width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (titleWidget != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48.0),
              child: titleWidget!,
            )
          else if (title != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48.0),
              child: Text(
                title!,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: GoogleFonts.playfairDisplay(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF252923),
                  letterSpacing: -0.2,
                ),
              ),
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (effectiveLeading != null) effectiveLeading else const SizedBox(width: 36),
              if (actions != null)
                Row(mainAxisSize: MainAxisSize.min, children: actions!)
              else
                const SizedBox(width: 36),
            ],
          ),
        ],
      ),
    );
  }
}
