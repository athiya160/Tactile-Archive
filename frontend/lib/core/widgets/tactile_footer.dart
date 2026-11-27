import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:libri_flow/core/design_system/tokens/ds_colors.dart';
import 'package:libri_flow/core/services/api_service.dart';
import 'package:libri_flow/core/widgets/login_required_dialog.dart';

class TactileFooter extends StatefulWidget {
  final bool showNewsletter;

  const TactileFooter({super.key, this.showNewsletter = false});

  @override
  State<TactileFooter> createState() => _TactileFooterState();
}

class _TactileFooterState extends State<TactileFooter> {
  final TextEditingController _newsletterController = TextEditingController();
  bool _isSubscribed = false;
  bool _isCategoriesExpanded = false;
  bool _isPoliciesExpanded = false;

  @override
  void dispose() {
    _newsletterController.dispose();
    super.dispose();
  }

  void _handleSubscribe() {
    final email = _newsletterController.text.trim();
    if (email.isEmpty || !email.contains('@') || !email.contains('.')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid email address.'),
          backgroundColor: Color(0xFFE53E3E),
        ),
      );
      return;
    }

    setState(() {
      _isSubscribed = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.mark_email_read, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Welcome to the Reader Circle! Check $email for your welcome guide.',
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF2E7D32),
      ),
    );

    _newsletterController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 1024;
        final isTablet = constraints.maxWidth >= 650 && constraints.maxWidth < 1024;

        return Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            color: Color(0xFF0B2B22), // Ultra-deep luxury forest green
            border: Border(
              top: BorderSide(
                color: Color(0x33D4AF37), // Subtle gold accent border
                width: 1.5,
              ),
            ),
          ),
          child: Column(
            children: [
              // 1. NEWSLETTER / READER CIRCLE BANNER (Only on HomePage)
              if (widget.showNewsletter)
                _buildNewsletterBanner(context, isDesktop),

              // 2. MAIN FOOTER CONTENT COLUMNS
              Padding(
                padding: EdgeInsets.fromLTRB(
                  isDesktop ? 48 : 24,
                  40,
                  isDesktop ? 48 : 24,
                  36,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1300),
                    child: isDesktop
                        ? _buildDesktopColumns(context)
                        : isTablet
                            ? _buildTabletColumns(context)
                            : _buildMobileColumns(context),
                  ),
                ),
              ),

              // 3. BOTTOM BAR (COPYRIGHT & EXTRA SPACING FOR FLOATING CHATBOT)
              _buildBottomBar(context, isDesktop),
            ],
          ),
        );
      },
    );
  }

  // --- NEWSLETTER BANNER ---
  Widget _buildNewsletterBanner(BuildContext context, bool isDesktop) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF08221B),
        border: Border(
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.07)),
        ),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 48 : 24,
        vertical: 28,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1300),
          child: isDesktop
              ? Row(
                  children: [
                    Expanded(
                      flex: 6,
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: DSColors.secondary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: DSColors.secondary.withValues(alpha: 0.3),
                              ),
                            ),
                            child: const FaIcon(
                              FontAwesomeIcons.envelopeOpenText,
                              color: DSColors.secondary,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Join the Archive Reader Circle',
                                  style: GoogleFonts.playfairDisplay(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Weekly curated literary drops, rare print notifications, and 24/7 locker codes.',
                                  style: GoogleFonts.inter(
                                    color: Colors.white.withValues(alpha: 0.65),
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 32),
                    Expanded(
                      flex: 5,
                      child: _buildNewsletterInput(),
                    ),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: DSColors.secondary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: DSColors.secondary.withValues(alpha: 0.3),
                            ),
                          ),
                          child: const FaIcon(
                            FontAwesomeIcons.envelopeOpenText,
                            color: DSColors.secondary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            'Join the Archive Reader Circle',
                            style: GoogleFonts.playfairDisplay(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Weekly curated literary drops, rare print alerts, and 24/7 smart locker codes.',
                      style: GoogleFonts.inter(
                        color: Colors.white.withValues(alpha: 0.65),
                        fontSize: 12.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildNewsletterInput(),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildNewsletterInput() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: Row(
        children: [
          const SizedBox(width: 12),
          const Icon(Icons.email_outlined, color: Colors.white54, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _newsletterController,
              onSubmitted: (_) => _handleSubscribe(),
              style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Enter your email address...',
                hintStyle: GoogleFonts.inter(
                  color: Colors.white.withValues(alpha: 0.45),
                  fontSize: 13,
                ),
                isDense: true,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: _handleSubscribe,
            style: ElevatedButton.styleFrom(
              backgroundColor: DSColors.secondary,
              foregroundColor: const Color(0xFF0B2B22),
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              _isSubscribed ? 'Subscribed ✓' : 'Subscribe',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleSellTap(BuildContext context) {
    if (ApiService.isLoggedIn) {
      if (ApiService.isProvider) {
        context.go('/sell');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Only registered providers can list books for sale.'),
            backgroundColor: Color(0xFFE53E3E),
          ),
        );
      }
    } else {
      LoginRequiredDialog.show(context);
    }
  }

  // --- DESKTOP LAYOUT ---
  Widget _buildDesktopColumns(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Col 1: Brand & Philosophy (Flex 3.5)
        Expanded(
          flex: 4,
          child: _buildBrandCol(context),
        ),
        const SizedBox(width: 48),

        // Col 2: Explore (Flex 2.2)
        Expanded(
          flex: 2,
          child: _buildExploreCol(context),
        ),
        const SizedBox(width: 36),

        // Col 3: Company & Policies (Flex 2.2)
        Expanded(
          flex: 2,
          child: _buildCompanyCol(context),
        ),
        const SizedBox(width: 36),

        // Col 4: Contact Us & Hub Lockers (Flex 3.2)
        Expanded(
          flex: 3,
          child: _buildContactCol(context),
        ),
      ],
    );
  }

  // --- TABLET LAYOUT ---
  Widget _buildTabletColumns(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildBrandCol(context),
        const SizedBox(height: 40),
        const Divider(color: Colors.white12),
        const SizedBox(height: 32),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _buildExploreCol(context)),
            const SizedBox(width: 24),
            Expanded(child: _buildCompanyCol(context)),
            const SizedBox(width: 24),
            Expanded(child: _buildContactCol(context)),
          ],
        ),
      ],
    );
  }

  // --- MOBILE LAYOUT (LUXURY MOBILE-FIRST DESIGN) ---
  Widget _buildMobileColumns(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Sleek Brand Badge
        _buildMobileBrandSection(context),
        const SizedBox(height: 24),

        // 2. Verified Exchange Hubs Spotlight Card
        _buildMobileHubHighlightCard(context),
        const SizedBox(height: 24),

        // 3. Tactile Quick-Touch Directory Bento
        _buildMobileQuickNavGrid(context),
        const SizedBox(height: 24),

        // 4. Expandable Accordions for Deep Navigation
        _buildMobileAccordion(
          title: 'Explore Genres & Swaps',
          icon: Icons.auto_stories_outlined,
          isExpanded: _isCategoriesExpanded,
          onTap: () => setState(() => _isCategoriesExpanded = !_isCategoriesExpanded),
          children: [
            _AccordionLinkItem(
              title: 'Fiction & Literature',
              onTap: () => context.go('/browse?category=Fiction'),
            ),
            _AccordionLinkItem(
              title: 'Tech & Engineering',
              onTap: () => context.go('/browse?category=Tech+%26+Engineering'),
            ),
            _AccordionLinkItem(
              title: 'Academic Textbooks',
              onTap: () => context.go('/browse?category=Academic+%26+Textbooks'),
            ),
            _AccordionLinkItem(
              title: 'Rare & Collector Prints',
              onTap: () => context.go('/browse?category=Rare+%26+Collector'),
            ),
            _AccordionLinkItem(
              title: 'Free Community Swaps',
              isHighlighted: true,
              onTap: () => context.go('/browse?category=Free+Swaps'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildMobileAccordion(
          title: 'Company & Trust Policies',
          icon: Icons.shield_outlined,
          isExpanded: _isPoliciesExpanded,
          onTap: () => setState(() => _isPoliciesExpanded = !_isPoliciesExpanded),
          children: [
            _AccordionLinkItem(
              title: 'Our Literary Philosophy',
              onTap: () => context.go('/about'),
            ),
            _AccordionLinkItem(
              title: 'Reader FAQs & Help',
              onTap: () => context.go('/faqs'),
            ),
            _AccordionLinkItem(
              title: 'Terms & Exchange Charter',
              onTap: () => context.go('/terms-and-conditions'),
            ),
            _AccordionLinkItem(
              title: 'Privacy & Data Ethics',
              onTap: () => context.go('/privacy-policy'),
            ),
            _AccordionLinkItem(
              title: 'Secure Courier Shipping',
              onTap: () => context.go('/shipping-policy'),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // 5. Concierge & Support Card with 1-Tap Actions
        _buildMobileConciergeCard(context),
      ],
    );
  }

  Widget _buildMobileBrandSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: DSColors.secondary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: DSColors.secondary.withValues(alpha: 0.3),
                ),
              ),
              child: const Icon(Icons.menu_book, color: DSColors.secondary, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'The Tactile Archive',
                    style: GoogleFonts.playfairDisplay(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.2,
                    ),
                  ),
                  Text(
                    'Curated Physical Book Exchange',
                    style: GoogleFonts.inter(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.star, color: DSColors.secondary, size: 14),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  '4.9/5 Rating • 4,800+ Verified Exchanges in Bangalore',
                  style: GoogleFonts.inter(
                    color: Colors.white.withValues(alpha: 0.75),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileHubHighlightCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0F3B2E),
            Color(0xFF07241C),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: DSColors.secondary.withValues(alpha: 0.35),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF48BB78),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'ONLINE • 4 VERIFIED HUBS',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          color: const Color(0xFF48BB78),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '24/7 Smart Lockers',
                  style: GoogleFonts.inter(
                    color: Colors.white70,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Tactile Exchange Hubs',
            style: GoogleFonts.playfairDisplay(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Drop off or pick up books securely at Central Sanctuary (Brigade Rd) or campus smart lockers.',
            style: GoogleFonts.inter(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 12.5,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => context.go('/exchange-map'),
              icon: const Icon(Icons.map_outlined, size: 16),
              label: const Text('Interactive Hub Map & Desks →'),
              style: ElevatedButton.styleFrom(
                backgroundColor: DSColors.secondary,
                foregroundColor: const Color(0xFF0B2B22),
                padding: const EdgeInsets.symmetric(vertical: 12),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileQuickNavGrid(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'QUICK DIRECTORY',
          style: GoogleFonts.inter(
            color: DSColors.secondary,
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMobileQuickTile(
                context: context,
                icon: Icons.auto_stories_outlined,
                label: 'Browse Books',
                onTap: () => context.go('/browse'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildMobileQuickTile(
                context: context,
                icon: Icons.storefront_outlined,
                label: 'Exchange Hubs',
                isHighlighted: true,
                onTap: () => context.go('/exchange-map'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildMobileQuickTile(
                context: context,
                icon: Icons.monetization_on_outlined,
                label: 'Sell or Lend',
                onTap: () => _handleSellTap(context),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildMobileQuickTile(
                context: context,
                icon: Icons.military_tech_outlined,
                label: 'Reader Passport',
                onTap: () => context.go('/profile'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildMobileQuickTile(
                context: context,
                icon: Icons.swap_horiz_rounded,
                label: 'Free Swaps',
                onTap: () => context.go('/browse?category=Free+Swaps'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildMobileQuickTile(
                context: context,
                icon: Icons.school_outlined,
                label: 'Textbooks',
                onTap: () => context.go('/browse?category=Academic+%26+Textbooks'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMobileQuickTile({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isHighlighted = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: isHighlighted
              ? DSColors.secondary.withValues(alpha: 0.12)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isHighlighted
                ? DSColors.secondary.withValues(alpha: 0.45)
                : Colors.white.withValues(alpha: 0.1),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: isHighlighted ? DSColors.secondary : Colors.white70,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.inter(
                  color: isHighlighted ? DSColors.secondary : Colors.white,
                  fontSize: 12.5,
                  fontWeight: isHighlighted ? FontWeight.bold : FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileAccordion({
    required String title,
    required IconData icon,
    required bool isExpanded,
    required VoidCallback onTap,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isExpanded
              ? DSColors.secondary.withValues(alpha: 0.3)
              : Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              child: Row(
                children: [
                  Icon(icon, size: 18, color: DSColors.secondary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      title,
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.keyboard_arrow_down,
                      color: Colors.white.withValues(alpha: 0.6),
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded) ...[
            Divider(height: 1, color: Colors.white.withValues(alpha: 0.08)),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: children,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMobileConciergeCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.support_agent_outlined, color: DSColors.secondary, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Sanctuary Concierge & Support',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Central Sanctuary: Brigade Road, Bangalore • 24/7 Smart Lockers',
            style: GoogleFonts.inter(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => launchUrlString('tel:+919986474220'),
                  icon: const Icon(Icons.phone_outlined, size: 15),
                  label: const Text('Call Desk'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    textStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => launchUrlString('mailto:athiya160@gmail.com'),
                  icon: const Icon(Icons.email_outlined, size: 15),
                  label: const Text('Email Help'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    textStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              Text(
                'Follow the Archive:',
                style: GoogleFonts.inter(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 11.5,
                ),
              ),
              Wrap(
                spacing: 8,
                children: [
                  _SocialIconButton(
                    icon: FontAwesomeIcons.xTwitter,
                    tooltip: 'X',
                    url: 'https://twitter.com',
                  ),
                  _SocialIconButton(
                    icon: FontAwesomeIcons.instagram,
                    tooltip: 'Instagram',
                    url: 'https://instagram.com',
                  ),
                  _SocialIconButton(
                    icon: FontAwesomeIcons.linkedinIn,
                    tooltip: 'LinkedIn',
                    url: 'https://linkedin.com',
                  ),
                  _SocialIconButton(
                    icon: FontAwesomeIcons.discord,
                    tooltip: 'Discord',
                    url: 'https://discord.com',
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- COLUMN 1: BRAND SECTION ---
  Widget _buildBrandCol(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: DSColors.secondary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: DSColors.secondary.withValues(alpha: 0.3),
                ),
              ),
              child: const Icon(Icons.menu_book, color: DSColors.secondary, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'The Tactile Archive',
                style: GoogleFonts.playfairDisplay(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.3,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Text(
          'Discover affordable books from readers near you. Make reading accessible, affordable, and sustainable for everyone through peer-to-peer exchanges and secure smart lockers.',
          style: GoogleFonts.inter(
            color: Colors.white.withValues(alpha: 0.72),
            fontSize: 14,
            height: 1.6,
          ),
        ),
        const SizedBox(height: 24),

        // Social Icons Row (Authentic FontAwesome)
        Wrap(
          spacing: 12,
          runSpacing: 10,
          children: [
            _SocialIconButton(
              icon: FontAwesomeIcons.facebookF,
              tooltip: 'Facebook',
              url: 'https://facebook.com',
            ),
            _SocialIconButton(
              icon: FontAwesomeIcons.xTwitter,
              tooltip: 'X (Twitter)',
              url: 'https://twitter.com',
            ),
            _SocialIconButton(
              icon: FontAwesomeIcons.instagram,
              tooltip: 'Instagram',
              url: 'https://instagram.com',
            ),
            _SocialIconButton(
              icon: FontAwesomeIcons.linkedinIn,
              tooltip: 'LinkedIn',
              url: 'https://linkedin.com',
            ),
            _SocialIconButton(
              icon: FontAwesomeIcons.discord,
              tooltip: 'Community Discord',
              url: 'https://discord.com',
            ),
          ],
        ),

        const SizedBox(height: 24),

        // Trust Badges Pill Row
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildTrustBadge('🛡️ Verified Hubs'),
            _buildTrustBadge('📦 24/7 Smart Lockers'),
            _buildTrustBadge('🔒 Escrow Protected'),
          ],
        ),
      ],
    );
  }

  Widget _buildTrustBadge(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          color: Colors.white.withValues(alpha: 0.7),
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  // --- COLUMN 2: EXPLORE ---
  Widget _buildExploreCol(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Explore',
          style: GoogleFonts.playfairDisplay(
            color: DSColors.secondary,
            fontSize: 19,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 20),
        _FooterLink(
          title: 'Browse Books',
          onTap: () => context.go('/browse'),
        ),
        _FooterLink(
          title: 'Tactile Exchange Hubs',
          onTap: () => context.go('/exchange-map'),
          isHighlighted: true,
        ),
        _FooterLink(
          title: 'Sell a Book',
          onTap: () => _handleSellTap(context),
        ),
        _FooterLink(
          title: 'Fiction & Literature',
          onTap: () => context.go('/browse?category=Fiction'),
        ),
        _FooterLink(
          title: 'Academic & Textbooks',
          onTap: () => context.go('/browse?category=Academic+%26+Textbooks'),
        ),
        _FooterLink(
          title: 'Reader Passport',
          onTap: () => context.go('/profile'),
        ),
      ],
    );
  }

  // --- COLUMN 3: COMPANY & POLICIES ---
  Widget _buildCompanyCol(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Company',
          style: GoogleFonts.playfairDisplay(
            color: DSColors.secondary,
            fontSize: 19,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 20),
        _FooterLink(
          title: 'About Us',
          onTap: () => context.go('/about'),
        ),
        _FooterLink(
          title: 'Contact Concierge',
          onTap: () => context.go('/contact'),
        ),
        _FooterLink(
          title: 'Help & FAQs',
          onTap: () => context.go('/faqs'),
        ),
        _FooterLink(
          title: 'Terms & Conditions',
          onTap: () => context.go('/terms-and-conditions'),
        ),
        _FooterLink(
          title: 'Privacy Policy',
          onTap: () => context.go('/privacy-policy'),
        ),
        _FooterLink(
          title: 'Shipping & Delivery',
          onTap: () => context.go('/shipping-policy'),
        ),
      ],
    );
  }

  // --- COLUMN 4: CONTACT US & LOCKERS ---
  Widget _buildContactCol(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Contact Us',
          style: GoogleFonts.playfairDisplay(
            color: DSColors.secondary,
            fontSize: 19,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 20),

        // Address
        _ContactRow(
          icon: Icons.location_on,
          title: 'Safe Hub Central Desk',
          subtitle: 'Brigade Road, Bangalore, KA 560001',
          onTap: () => context.go('/exchange-map'),
        ),
        const SizedBox(height: 16),

        // Email
        _ContactRow(
          icon: Icons.email_outlined,
          title: 'Concierge Desk',
          subtitle: 'athiya160@gmail.com',
          onTap: () => launchUrlString('mailto:athiya160@gmail.com'),
        ),
        const SizedBox(height: 16),

        // Phone
        _ContactRow(
          icon: Icons.phone_in_talk_outlined,
          title: 'Hotline',
          subtitle: '+91 99864 74220',
          onTap: () => launchUrlString('tel:+919986474220'),
        ),
        const SizedBox(height: 22),

        // Live Locker Status Pill
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF38A169).withValues(alpha: 0.4)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFF38A169),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  '24/7 Smart Lockers: Online',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: const Color(0xFF9AE6B4),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- BOTTOM COPYRIGHT BAR (WITH ANTI-OVERLAP SPACING) ---
  Widget _buildBottomBar(BuildContext context, bool isDesktop) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF071C16),
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
      ),
      padding: EdgeInsets.only(
        left: isDesktop ? 48 : 20,
        right: isDesktop ? 48 : 20,
        top: 20,
        bottom: isDesktop ? 24 : (MediaQuery.of(context).padding.bottom + 85),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1300),
          child: isDesktop
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        '© 2026 The Tactile Archive. All rights reserved.',
                        style: GoogleFonts.inter(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 12.5,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 220),
                      child: Text(
                        'Made for readers, by readers.',
                        style: GoogleFonts.inter(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                )
              : Column(
                  children: [
                    Text(
                      '© 2026 The Tactile Archive. All rights reserved.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        color: Colors.white.withValues(alpha: 0.55),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Made for readers, by readers.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        color: Colors.white.withValues(alpha: 0.4),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

// --- HOVERABLE SOCIAL ICON BUTTON ---
class _SocialIconButton extends StatefulWidget {
  final dynamic icon;
  final String tooltip;
  final String url;

  const _SocialIconButton({
    required this.icon,
    required this.tooltip,
    required this.url,
  });

  @override
  State<_SocialIconButton> createState() => _SocialIconButtonState();
}

class _SocialIconButtonState extends State<_SocialIconButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: () => launchUrlString(widget.url),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            transform: Matrix4.translationValues(0, _isHovered ? -3 : 0, 0),
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: _isHovered
                  ? DSColors.secondary
                  : Colors.white.withValues(alpha: 0.08),
              shape: BoxShape.circle,
              border: Border.all(
                color: _isHovered
                    ? DSColors.secondary
                    : Colors.white.withValues(alpha: 0.15),
              ),
            ),
            child: Center(
              child: FaIcon(
                widget.icon,
                color: _isHovered ? const Color(0xFF0B2B22) : Colors.white,
                size: 15,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// --- HOVERABLE FOOTER LINK ---
class _FooterLink extends StatefulWidget {
  final String title;
  final VoidCallback onTap;
  final bool isHighlighted;

  const _FooterLink({
    required this.title,
    required this.onTap,
    this.isHighlighted = false,
  });

  @override
  State<_FooterLink> createState() => _FooterLinkState();
}

class _FooterLinkState extends State<_FooterLink> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: EdgeInsets.only(left: _isHovered ? 6 : 0),
            child: Row(
              children: [
                if (widget.isHighlighted) ...[
                  Container(
                    width: 5,
                    height: 5,
                    decoration: const BoxDecoration(
                      color: DSColors.secondary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
                Expanded(
                  child: Text(
                    widget.title,
                    style: GoogleFonts.inter(
                      color: _isHovered
                          ? DSColors.secondary
                          : widget.isHighlighted
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.72),
                      fontSize: 13.5,
                      fontWeight: _isHovered || widget.isHighlighted
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// --- CONTACT ITEM ROW ---
class _ContactRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const _ContactRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 2),
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: DSColors.secondary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: DSColors.secondary, size: 15),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: GoogleFonts.inter(
                  color: Colors.white.withValues(alpha: 0.65),
                  fontSize: 12.5,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );

    if (onTap != null) {
      return MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          child: content,
        ),
      );
    }

    return content;
  }
}

// --- ACCORDION LINK ITEM (MOBILE-OPTIMIZED TOUCH TARGET) ---
class _AccordionLinkItem extends StatelessWidget {
  final String title;
  final VoidCallback onTap;
  final bool isHighlighted;

  const _AccordionLinkItem({
    required this.title,
    required this.onTap,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 8),
        child: Row(
          children: [
            Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                color: isHighlighted ? DSColors.secondary : Colors.white38,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.inter(
                  color: isHighlighted ? DSColors.secondary : Colors.white70,
                  fontSize: 13,
                  fontWeight: isHighlighted ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              size: 16,
              color: Colors.white.withValues(alpha: 0.3),
            ),
          ],
        ),
      ),
    );
  }
}
