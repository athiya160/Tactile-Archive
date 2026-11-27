import 'package:flutter/material.dart';
import '../../domain/entities/faq.dart';
import 'package:libri_flow/core/design_system/design_system.dart';

class FaqItem extends StatefulWidget {
  final Faq faq;
  final bool initiallyExpanded;

  const FaqItem({super.key, required this.faq, this.initiallyExpanded = false});

  @override
  State<FaqItem> createState() => _FaqItemState();
}

class _FaqItemState extends State<FaqItem> with SingleTickerProviderStateMixin {
  late bool _isExpanded;
  late final AnimationController _controller;
  late final Animation<double> _heightFactor;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _heightFactor = _controller.drive(CurveTween(curve: Curves.easeInOut));
    if (_isExpanded) {
      _controller.value = 1.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: DSSpacing.sm),
      decoration: BoxDecoration(
        color: DSColors.border,
        borderRadius: BorderRadius.circular(DSRadius.lg),
        border: Border.all(color: DSColors.borderLight, width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          InkWell(
            onTap: _handleTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: DSSpacing.md,
                vertical: DSSpacing.md,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.faq.question,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: DSColors.textDark,
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    turns: _isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 300),
                    child: const Icon(
                      Icons.expand_more,
                      color: DSColors.textLight,
                    ),
                  ),
                ],
              ),
            ),
          ),
          ClipRect(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Align(
                  heightFactor: _heightFactor.value,
                  alignment: Alignment.topCenter,
                  child: child,
                );
              },
              child: Padding(
                padding: const EdgeInsets.only(
                  left: DSSpacing.md,
                  right: DSSpacing.md,
                  bottom: DSSpacing.md,
                ),
                child: Text(
                  widget.faq.answer,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: DSColors.textLight,
                    height: 1.6,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
