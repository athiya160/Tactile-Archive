import 'package:flutter/material.dart';
import '../../../../core/theme/theme.dart';

class BookHeader extends StatelessWidget {
  final String title;
  final String author;
  final bool isStaffPick;
  final VoidCallback onReportIssue;

  const BookHeader({
    super.key,
    required this.title,
    required this.author,
    this.isStaffPick = false,
    required this.onReportIssue,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (isStaffPick)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF061B0E),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'STAFF PICK',
                  style: IvoryTheme.statusLabel.copyWith(color: Colors.white),
                ),
              )
            else
              const SizedBox.shrink(),
            TextButton.icon(
              onPressed: onReportIssue,
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              icon: const Icon(
                Icons.flag_outlined,
                size: 16,
                color: Color(0xFF586159),
              ),
              label: Text(
                'REPORT ISSUE',
                style: IvoryTheme.statusLabel.copyWith(
                  color: const Color(0xFF586159),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          title,
          style: IvoryTheme.heroHeading.copyWith(
            fontSize: 40,
            color: const Color(0xFF061B0E),
            height: 1.1,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'by $author',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: Color(0xFF434843),
          ),
        ),
      ],
    );
  }
}
