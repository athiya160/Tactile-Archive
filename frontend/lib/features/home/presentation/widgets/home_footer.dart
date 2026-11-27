import 'package:flutter/material.dart';
import 'package:libri_flow/core/widgets/tactile_footer.dart';

class HomeFooter extends StatelessWidget {
  const HomeFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return const TactileFooter(showNewsletter: true);
  }
}
