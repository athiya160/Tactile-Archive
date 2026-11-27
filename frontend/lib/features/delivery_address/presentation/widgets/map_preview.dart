import 'package:flutter/material.dart';
import '../../../../core/theme/theme.dart';
import 'package:libri_flow/core/design_system/design_system.dart';

class MapPreview extends StatelessWidget {
  const MapPreview({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 160,
      width: double.infinity,
      decoration: BoxDecoration(
        color: DSColors.borderLight,
        borderRadius: BorderRadius.circular(DSRadius.xl),
      ),
      child: Stack(
        children: [
          // City Grid Image
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(DSRadius.xl),
              child: Opacity(
                opacity: 0.5,
                child: ColorFiltered(
                  colorFilter: const ColorFilter.matrix([
                    0.2126,
                    0.7152,
                    0.0722,
                    0,
                    0,
                    0.2126,
                    0.7152,
                    0.0722,
                    0,
                    0,
                    0.2126,
                    0.7152,
                    0.0722,
                    0,
                    0,
                    0,
                    0,
                    0,
                    1,
                    0,
                  ]),
                  child: Image.network(
                    'https://lh3.googleusercontent.com/aida-public/AB6AXuDj_3Juv-OwokeeafnhaDpChSvwQ-KMMe8_WXJW0cI6XtaBVmIyuuFZ-CA7P2-kQ7hcN47459VI__RyAebElLWJq4xN6Hrb5nNaRVlwcvPRHPxEGj9WTwJ7rR_PZ2sHT_w-63gyx5jn6IrC41ReF8j9Cpjh3YGuZqusZjnq-eYv_VolW76vIYoYlt9lyKyL-Z3ggjkCtabCtTpPuoriM21iL9XCRrRId-Zp22vC7zYAbY2ibp0BwwvTqWSq5k1KpsXfBBEBAD5K09-M',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ),
          // Legend (Bottom Left)
          Positioned(
            bottom: 16,
            left: 24,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.location_on,
                  color: DSColors.primary,
                  size: 14,
                ),
                const SizedBox(width: 8),
                Text(
                  'PREVIEW DELIVERY RADIUS',
                  style: IvoryTheme.formFieldLabel.copyWith(
                    color: DSColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
