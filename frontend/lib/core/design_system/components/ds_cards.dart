import 'package:flutter/material.dart';
import '../tokens/ds_colors.dart';
import '../tokens/ds_radius.dart';
import '../tokens/ds_shadows.dart';

/// Base Hover Card (Generic)
class DSCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;

  const DSCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(16.0),
  });

  @override
  State<DSCard> createState() => _DSCardState();
}

class _DSCardState extends State<DSCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: widget.onTap != null
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: const Cubic(0.25, 0.8, 0.25, 1.0),
          transform: Matrix4.translationValues(0, _isHovered ? -5.0 : 0.0, 0),
          decoration: BoxDecoration(
            color: DSColors.surface,
            borderRadius: BorderRadius.circular(DSRadius.lg),
            border: Border.all(
              color: _isHovered
                  ? DSColors.primary.withValues(alpha: 0.2)
                  : DSColors.primary.withValues(alpha: 0.08),
            ),
            boxShadow: _isHovered ? DSShadows.lg : DSShadows.sm,
          ),
          padding: widget.padding,
          child: widget.child,
        ),
      ),
    );
  }
}

/// Category Card
class DSCategoryCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final VoidCallback onTap;

  const DSCategoryCard({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return DSCard(
      onTap: onTap,
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: DSColors.secondary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(DSRadius.md),
            ),
            child: Icon(icon, color: DSColors.secondary, size: 24),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: DSColors.primary),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Product / Book Card
class DSProductCard extends StatelessWidget {
  final String title;
  final String author;
  final String price;
  final String imageUrl;
  final VoidCallback onTap;
  final VoidCallback? onAddToCart;

  const DSProductCard({
    super.key,
    required this.title,
    required this.author,
    required this.price,
    required this.imageUrl,
    required this.onTap,
    this.onAddToCart,
  });

  @override
  Widget build(BuildContext context) {
    return DSCard(
      onTap: onTap,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              color: DSColors.background,
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const Center(
                  child: Icon(Icons.book, size: 48, color: DSColors.border),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(color: DSColors.primary),
                ),
                const SizedBox(height: 4),
                Text(
                  author,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      price,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: DSColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (onAddToCart != null)
                      IconButton(
                        icon: const Icon(
                          Icons.add_shopping_cart,
                          color: DSColors.secondary,
                        ),
                        onPressed: onAddToCart,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Profile Card
class DSProfileCard extends StatelessWidget {
  final String name;
  final String email;
  final String? avatarUrl;
  final VoidCallback onTap;

  const DSProfileCard({
    super.key,
    required this.name,
    required this.email,
    this.avatarUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return DSCard(
      onTap: onTap,
      child: Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: DSColors.primary.withValues(alpha: 0.1),
            backgroundImage: avatarUrl != null
                ? NetworkImage(avatarUrl!)
                : null,
            child: avatarUrl == null
                ? const Icon(Icons.person, color: DSColors.primary, size: 32)
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(color: DSColors.primary),
                ),
                const SizedBox(height: 4),
                Text(email, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: DSColors.border),
        ],
      ),
    );
  }
}
