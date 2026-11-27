import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/services/google_auth_service.dart';
import '../../../../core/design_system/design_system.dart';

class LoginPage extends StatefulWidget {
  final UserRole role;
  const LoginPage({super.key, this.role = UserRole.customer});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _routeAfterLogin() {
    if (!mounted) return;
    if (ApiService.role == UserRole.provider) {
      context.go('/provider');
    } else if (ApiService.activeExperience == UserType.student) {
      if (!ApiService.onboardingCompleted) {
        context.go('/onboarding/student-preferences');
      } else {
        context.go('/student');
      }
    } else {
      context.go('/reader');
    }
  }

  Future<void> _handleSubmit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'Please enter both email and password.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final err = await ApiService.login(email, password);

    if (mounted) {
      setState(() => _isLoading = false);
      if (err == null) {
        _routeAfterLogin();
      } else {
        setState(() => _errorMessage = err);
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    await GoogleAuthService.signInWithGoogle(
      context,
      personaHint: 'reader',
    );
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildTopHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      color: DSColors.paperWhite,
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: InkWell(
                  onTap: () => context.go('/'),
                  borderRadius: BorderRadius.circular(8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0D697).withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const FaIcon(
                          FontAwesomeIcons.bookOpen,
                          color: Color(0xFFC88A1A),
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'The Tactile Archive',
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: DSColors.deepForestGreen,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/');
                  }
                },
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.arrow_back, size: 16, color: DSColors.charcoal),
                      const SizedBox(width: 4),
                      Text(
                        'Browse Store',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: DSColors.charcoal,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DSColors.warmIvory,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildTopHeader(context),
              const SizedBox(height: 24),

              Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 880),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final isDesktop = constraints.maxWidth >= 740;

                      final formSide = Container(
                        padding: EdgeInsets.all(isDesktop ? 32 : 20),
                        decoration: BoxDecoration(
                          color: DSColors.paperWhite,
                          borderRadius: isDesktop
                              ? const BorderRadius.only(
                                  topLeft: Radius.circular(DSRadius.card),
                                  bottomLeft: Radius.circular(DSRadius.card),
                                )
                              : BorderRadius.circular(DSRadius.card),
                          border: Border.all(
                            color: DSColors.softBorder.withValues(alpha: 0.8),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Sign In / Create Account Navigation Pill
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF3F4F6),
                                borderRadius: BorderRadius.circular(DSRadius.md),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(DSRadius.sm),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.06),
                                            blurRadius: 4,
                                            offset: const Offset(0, 1),
                                          ),
                                        ],
                                      ),
                                      child: Center(
                                        child: Text(
                                          'Sign In',
                                          style: GoogleFonts.inter(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: DSColors.deepForestGreen,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () => context.push('/register'),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(vertical: 8),
                                        decoration: BoxDecoration(
                                          color: Colors.transparent,
                                          borderRadius: BorderRadius.circular(DSRadius.sm),
                                        ),
                                        child: Center(
                                          child: FittedBox(
                                            fit: BoxFit.scaleDown,
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  'Create Account',
                                                  style: GoogleFonts.inter(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w500,
                                                    color: DSColors.textMuted,
                                                  ),
                                                ),
                                                const SizedBox(width: 4),
                                                const Icon(
                                                  Icons.arrow_forward_rounded,
                                                  size: 13,
                                                  color: DSColors.textMuted,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Heading
                            Text(
                              'Welcome Back',
                              style: GoogleFonts.playfairDisplay(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: DSColors.deepForestGreen,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Sign in to access your library, study planner, and AI concierge.',
                              style: GoogleFonts.inter(fontSize: 12, color: DSColors.textMuted),
                            ),
                            const SizedBox(height: 20),

                            // Google Sign-In Button
                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: OutlinedButton(
                                onPressed: _isLoading ? null : _handleGoogleSignIn,
                                style: OutlinedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DSRadius.md)),
                                  side: const BorderSide(color: DSColors.softBorder),
                                  elevation: 0,
                                ),
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const FaIcon(FontAwesomeIcons.google, size: 16, color: Color(0xFFEA4335)),
                                      const SizedBox(width: 12),
                                      Text(
                                        'Continue with Google',
                                        style: GoogleFonts.inter(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: DSColors.charcoal,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 16),
                            Row(
                              children: [
                                const Expanded(child: Divider(color: Color(0xFFE5E7EB))),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  child: Text(
                                    'or continue with email',
                                    style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF9CA3AF)),
                                  ),
                                ),
                                const Expanded(child: Divider(color: Color(0xFFE5E7EB))),
                              ],
                            ),
                            const SizedBox(height: 16),

                            if (_errorMessage != null) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEF2F2),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: const Color(0xFFFECACA)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.error_outline, size: 16, color: Color(0xFFDC2626)),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _errorMessage!,
                                        style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFFDC2626)),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 14),
                            ],

                            // Email input
                            Text(
                              'Email Address',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: DSColors.charcoal,
                              ),
                            ),
                            const SizedBox(height: 6),
                            TextField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: InputDecoration(
                                hintText: 'name@example.com',
                                hintStyle: GoogleFonts.inter(fontSize: 12, color: const Color(0xFFA0AEC0)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(DSRadius.md),
                                  borderSide: const BorderSide(color: DSColors.softBorder),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(DSRadius.md),
                                  borderSide: const BorderSide(color: DSColors.deepForestGreen, width: 1.5),
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),

                            // Password input
                            Text(
                              'Password',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: DSColors.charcoal,
                              ),
                            ),
                            const SizedBox(height: 6),
                            TextField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              decoration: InputDecoration(
                                hintText: 'Enter your password',
                                hintStyle: GoogleFonts.inter(fontSize: 12, color: const Color(0xFFA0AEC0)),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                    size: 18,
                                    color: const Color(0xFFA0AEC0),
                                  ),
                                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(DSRadius.md),
                                  borderSide: const BorderSide(color: DSColors.softBorder),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(DSRadius.md),
                                  borderSide: const BorderSide(color: DSColors.deepForestGreen, width: 1.5),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),

                            Align(
                              alignment: Alignment.centerRight,
                              child: InkWell(
                                onTap: () => context.go('/forgot-password'),
                                child: Text(
                                  'Forgot Password?',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: DSColors.deepForestGreen,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 18),

                            // Submit Button
                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _handleSubmit,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: DSColors.deepForestGreen,
                                  foregroundColor: Colors.white,
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DSRadius.md)),
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                      )
                                    : Text(
                                        'Sign In',
                                        style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      );

                      // Feature banner on desktop
                      final featureSide = Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF9F0),
                          borderRadius: isDesktop
                              ? const BorderRadius.only(
                                  topRight: Radius.circular(DSRadius.card),
                                  bottomRight: Radius.circular(DSRadius.card),
                                )
                              : BorderRadius.circular(DSRadius.card),
                          border: Border.all(color: const Color(0xFFFFE8D6)),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF0D697).withValues(alpha: 0.5),
                                        borderRadius: BorderRadius.circular(DSRadius.sm),
                                      ),
                                      child: const FaIcon(FontAwesomeIcons.featherPointed, size: 14, color: DSColors.deepForestGreen),
                                    ),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        'THE TACTILE ARCHIVE',
                                        style: GoogleFonts.inter(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 1,
                                          color: DSColors.terracotta,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                Text(
                                  'One world.\nDifferent ways to read.',
                                  style: GoogleFonts.playfairDisplay(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                    color: DSColors.deepForestGreen,
                                    height: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 18),
                                _buildRightFeatureItem(
                                  Icons.school_outlined,
                                  'Student Experience',
                                  'Discover textbooks, track syllabi, and save with campus exchanges.',
                                ),
                                const SizedBox(height: 16),
                                _buildRightFeatureItem(
                                  Icons.auto_stories_outlined,
                                  'Reader Experience',
                                  'Build your personal bookshelf, track reading goals, and discover curated titles.',
                                ),
                                const SizedBox(height: 16),
                                _buildRightFeatureItem(
                                  Icons.storefront_outlined,
                                  'Community Sharing',
                                  'List physical books for rent, sale, or community donation with zero escrow risk.',
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            // Trust badge
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(DSRadius.md),
                                border: Border.all(color: DSColors.softBorder),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.lock_outline_rounded, size: 16, color: DSColors.deepForestGreen),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      '256-Bit SSL Encrypted • Community Escrow Protection',
                                      style: GoogleFonts.inter(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: DSColors.textLight,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );

                      if (isDesktop) {
                        return IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(flex: 6, child: formSide),
                              Expanded(flex: 5, child: featureSide),
                            ],
                          ),
                        );
                      }

                      return Column(
                        children: [
                          formSide,
                          const SizedBox(height: 16),
                          featureSide,
                        ],
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRightFeatureItem(IconData icon, String title, String subtitle) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: DSColors.deepForestGreen.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(DSRadius.md),
          ),
          child: Icon(icon, size: 20, color: DSColors.deepForestGreen),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: DSColors.charcoal),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: GoogleFonts.inter(fontSize: 11, color: DSColors.textMuted, height: 1.35),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
