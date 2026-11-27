import 'package:flutter/material.dart';
import '../../../../core/theme/theme.dart';

class PublicationDetailsCard extends StatelessWidget {
  final String title;
  final List<DetailItem> items;
  final IconData? icon;

  const PublicationDetailsCard({
    super.key,
    required this.title,
    required this.items,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F4F0),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0x80C3C8C1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title.toUpperCase(),
                style: IvoryTheme.statusLabel.copyWith(
                  color: const Color(0xFF586159),
                ),
              ),
              if (icon != null)
                Icon(icon, size: 20, color: const Color(0xFF737973)),
            ],
          ),
          const SizedBox(height: 8),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  item.label == ''
                      ? const SizedBox.shrink()
                      : Text(
                          item.label.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                            color: Color(0xFF737973),
                          ),
                        ),
                  Text(
                    item.value,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF061B0E),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class DetailItem {
  final String label;
  final String value;

  DetailItem(this.label, this.value);
}
