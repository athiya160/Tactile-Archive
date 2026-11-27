import 'package:flutter/material.dart';

class ResponsiveLayout extends StatelessWidget {
  final Widget? mobile;
  final Widget? tablet;
  final Widget desktop;
  final bool constrainWidth;

  const ResponsiveLayout({
    super.key,
    this.mobile,
    this.tablet,
    required this.desktop,
    this.constrainWidth = true,
  });

  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width <= 768;
  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width > 768 &&
      MediaQuery.of(context).size.width <= 1024;
  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width > 1024;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        Widget child;
        if (constraints.maxWidth <= 768) {
          child = mobile ?? tablet ?? desktop;
        } else if (constraints.maxWidth <= 1024) {
          child = tablet ?? desktop;
        } else {
          child = desktop;
        }

        if (constrainWidth) {
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: child,
              ),
            ),
          );
        }

        return child;
      },
    );
  }
}
