import 'package:flutter/material.dart';

class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;
  final bool constrainWidth;
  final double maxWidth;

  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
    this.constrainWidth = true,
    this.maxWidth = 1200,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        Widget child;
        if (constraints.maxWidth < 600) {
          child = mobile;
        } else if (constraints.maxWidth < 1024) {
          child = tablet ?? mobile;
        } else {
          child = desktop ?? tablet ?? mobile;
        }

        if (constrainWidth) {
          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: child,
            ),
          );
        }

        return child;
      },
    );
  }
}

/// Responsive Page Container for Luxury Editorial Bookstore
/// Enforces consistent content max-width, balanced margins, and safe-area margins.
class DSResponsiveContainer extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry? padding;
  final bool useSafeArea;

  const DSResponsiveContainer({
    super.key,
    required this.child,
    this.maxWidth = 1200.0,
    this.padding,
    this.useSafeArea = true,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = LayoutBuilder(
      builder: (context, constraints) {
        EdgeInsets effectivePadding;
        if (padding != null) {
          effectivePadding = padding!.resolve(Directionality.of(context));
        } else if (constraints.maxWidth < 600) {
          effectivePadding = const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0);
        } else if (constraints.maxWidth < 1024) {
          effectivePadding = const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0);
        } else {
          effectivePadding = const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0);
        }

        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Padding(
              padding: effectivePadding,
              child: child,
            ),
          ),
        );
      },
    );

    if (useSafeArea) {
      return SafeArea(child: content);
    }
    return content;
  }
}
