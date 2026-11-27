import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/tokens/app_tokens.dart';
import '../../../../core/design_system/design_system.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  bool _isLoading = false;
  bool _emailSent = false;
  bool _isPasswordResetSuccess = false;

  void _navigateBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/login');
    }
  }

  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;
  late AnimationController _slideCtrl;
  late Animation<Offset> _slideAnim;

  static const Color _primary = DSColors.deepForestGreen;
  static const Color _gold = DSColors.antiqueGold;
  static const Color _bg = DSColors.warmIvory;
  static const Color _textLight = DSColors.textLight;
  static const Color _white = Color(0xFFFFFFFF);
  static const Curve _transitionCurve = Cubic(0.25, 0.8, 0.25, 1);

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: _transitionCurve);
    _slideCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideCtrl, curve: _transitionCurve));
    _fadeCtrl.forward();
    _slideCtrl.forward();
  }

  final _otpCtrl = TextEditingController();
  final _newPasswordCtrl = TextEditingController();
  bool _useOtpMode = false;
  bool _otpSent = false;
  bool _obscureNewPassword = true;

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _slideCtrl.dispose();
    _emailCtrl.dispose();
    _otpCtrl.dispose();
    _newPasswordCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleSendOtp() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final error = await ApiService.sendOtp(_emailCtrl.text.trim(), purpose: "password_reset");
    if (!mounted) return;

    setState(() => _isLoading = false);
    if (error == null) {
      setState(() => _otpSent = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("A 6-digit OTP code has been sent to your email or phone."),
          backgroundColor: DSColors.secondaryGreen,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 5),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: const Color(0xFFE74C3C),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _handleVerifyOtpReset() async {
    if (_otpCtrl.text.trim().length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter a valid 6-digit OTP code."),
          backgroundColor: Color(0xFFE74C3C),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    final newPassword = _newPasswordCtrl.text;
    if (newPassword.length < 8 ||
        !RegExp(r'[A-Z]').hasMatch(newPassword) ||
        !RegExp(r'[a-z]').hasMatch(newPassword) ||
        !RegExp(r'\d').hasMatch(newPassword) ||
        !RegExp(r'[\W_]').hasMatch(newPassword)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Password must be at least 8 characters long and contain uppercase, lowercase, number, and special character.",
          ),
          backgroundColor: Color(0xFFE74C3C),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    final error = await ApiService.verifyOtpReset(
      _emailCtrl.text.trim(),
      _otpCtrl.text.trim(),
      newPassword,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (error == null) {
      setState(() => _isPasswordResetSuccess = true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: const Color(0xFFE74C3C),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final error = await ApiService.forgotPassword(_emailCtrl.text.trim());

    if (!mounted) return;
    
    if (error == null) {
      setState(() {
        _isLoading = false;
        _emailSent = true;
      });
    } else {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: const Color(0xFFE74C3C),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SlideTransition(
            position: _slideAnim,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isDesktop = constraints.maxWidth > 900;

                return Row(
                  children: [
                    if (isDesktop)
                      Expanded(
                        flex: 1,
                        child: Container(
                          decoration: const BoxDecoration(
                            color: _primary,
                            image: DecorationImage(
                              image: NetworkImage(
                                'https://images.unsplash.com/photo-1491841550275-ad7854e35ca6?q=80&w=1000&auto=format&fit=crop',
                              ),
                              fit: BoxFit.cover,
                              colorFilter: ColorFilter.mode(
                                Colors.black45,
                                BlendMode.darken,
                              ),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(64.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.menu_book_rounded,
                                      color: _gold,
                                      size: 32,
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      'The Tactile Archive',
                                      style: GoogleFonts.playfairDisplay(
                                        fontSize: 28,
                                        fontWeight: FontWeight.w700,
                                        color: _white,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 32),
                                Text(
                                  'Get back to your books.',
                                  style: GoogleFonts.playfairDisplay(
                                    fontSize: 56,
                                    fontWeight: FontWeight.w700,
                                    color: _white,
                                    height: 1.1,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                Text(
                                  'Don\'t let a forgotten password stop you from discovering affordable books from readers near you.',
                                  style: GoogleFonts.inter(
                                    fontSize: 18,
                                    color: _white.withValues(alpha: 0.8),
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                    Expanded(
                      flex: 1,
                      child: Center(
                        child: SingleChildScrollView(
                          padding: EdgeInsets.symmetric(
                            horizontal: isDesktop ? 64 : 24,
                            vertical: 32,
                          ),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 440),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (!isDesktop) ...[
                                  Row(
                                    children: [
                                      IconButton(
                                        tooltip: 'Back to Login',
                                        onPressed: _navigateBack,
                                        icon: const Icon(
                                          Icons.arrow_back,
                                          color: _primary,
                                        ),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                      ),
                                      const Spacer(),
                                      const Icon(
                                        Icons.menu_book_rounded,
                                        color: _gold,
                                        size: 24,
                                      ),
                                      const SizedBox(width: 8),
                                      Flexible(
                                        child: Text(
                                          'The Tactile Archive',
                                          style: GoogleFonts.playfairDisplay(
                                            fontSize: 20,
                                            fontWeight: FontWeight.w700,
                                            color: _primary,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 32),
                                ] else ...[
                                  IconButton(
                                    tooltip: 'Back to Login',
                                    onPressed: _navigateBack,
                                    icon: const Icon(
                                      Icons.arrow_back,
                                      color: _primary,
                                    ),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                  const SizedBox(height: 32),
                                ],

                                if (_isPasswordResetSuccess)
                                  _SuccessView(
                                    email: _emailCtrl.text.trim(),
                                    isOtpReset: true,
                                  )
                                else if (_emailSent)
                                  _SuccessView(
                                    email: _emailCtrl.text.trim(),
                                    isOtpReset: false,
                                  )
                                else ...[
                                  Text(
                                    'Reset Password',
                                    style: GoogleFonts.playfairDisplay(
                                      fontSize: 36,
                                      fontWeight: FontWeight.w700,
                                      color: _primary,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _useOtpMode
                                        ? 'Reset your password instantly using a 6-digit OTP code.'
                                        : 'We\'ll email you a link to reset your password.',
                                    style: GoogleFonts.inter(
                                      fontSize: 16,
                                      color: _textLight,
                                    ),
                                  ),
                                  const SizedBox(height: 40),
                                  Form(
                                    key: _formKey,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        Wrap(
                                          spacing: 8,
                                          runSpacing: 8,
                                          children: [
                                            ChoiceChip(
                                              label: const Text('Email Reset Link'),
                                              selected: !_useOtpMode,
                                              selectedColor: _primary,
                                              backgroundColor: Colors.white,
                                              labelStyle: GoogleFonts.inter(
                                                fontSize: 12,
                                                color: !_useOtpMode ? Colors.white : _primary,
                                                fontWeight: FontWeight.w600,
                                              ),
                                              onSelected: (selected) {
                                                if (selected) setState(() => _useOtpMode = false);
                                              },
                                            ),
                                            ChoiceChip(
                                              label: const Text('Instant OTP Code'),
                                              selected: _useOtpMode,
                                              selectedColor: _primary,
                                              backgroundColor: Colors.white,
                                              labelStyle: GoogleFonts.inter(
                                                fontSize: 12,
                                                color: _useOtpMode ? Colors.white : _primary,
                                                fontWeight: FontWeight.w600,
                                              ),
                                              onSelected: (selected) {
                                                if (selected) setState(() => _useOtpMode = true);
                                              },
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          _useOtpMode ? 'Email or Phone Number' : 'Email Address',
                                          style: GoogleFonts.inter(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: _primary,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        TextFormField(
                                          controller: _emailCtrl,
                                          keyboardType: _useOtpMode
                                              ? TextInputType.text
                                              : TextInputType.emailAddress,
                                          autocorrect: false,
                                          style: GoogleFonts.inter(
                                            fontSize: 15,
                                          ),
                                          validator: (v) {
                                            if (v == null || v.trim().isEmpty) {
                                              return _useOtpMode
                                                  ? 'Enter your email or phone number'
                                                  : 'Enter your email address';
                                            }
                                            return null;
                                          },
                                          decoration: InputDecoration(
                                            prefixIcon: Icon(
                                              _useOtpMode ? Icons.contact_mail_outlined : Icons.email_outlined,
                                              size: 18,
                                              color: _textLight,
                                            ),
                                            filled: true,
                                            fillColor: Colors.white,
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(DSRadius.md),
                                              borderSide: const BorderSide(color: DSColors.softBorder),
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(DSRadius.md),
                                              borderSide: const BorderSide(color: DSColors.softBorder),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(DSRadius.md),
                                              borderSide: const BorderSide(color: _primary),
                                            ),
                                            errorBorder: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(DSRadius.md),
                                              borderSide: const BorderSide(color: AppColors.error),
                                            ),
                                            contentPadding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 14,
                                            ),
                                          ),
                                        ),
                                        if (_useOtpMode && _otpSent) ...[
                                          const SizedBox(height: 20),
                                          Text(
                                            'Enter 6-Digit OTP Code',
                                            style: GoogleFonts.inter(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: _primary,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          TextFormField(
                                            controller: _otpCtrl,
                                            keyboardType: TextInputType.number,
                                            maxLength: 6,
                                            style: GoogleFonts.inter(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 8,
                                            ),
                                            decoration: InputDecoration(
                                              prefixIcon: const Icon(
                                                Icons.pin_outlined,
                                                size: 18,
                                                color: _textLight,
                                              ),
                                              hintText: '123456',
                                              filled: true,
                                              fillColor: Colors.white,
                                              border: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(DSRadius.md),
                                                borderSide: const BorderSide(color: DSColors.softBorder),
                                              ),
                                              enabledBorder: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(DSRadius.md),
                                                borderSide: const BorderSide(color: DSColors.softBorder),
                                              ),
                                              focusedBorder: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(DSRadius.md),
                                                borderSide: const BorderSide(color: _primary),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 16),
                                          Text(
                                            'New Password',
                                            style: GoogleFonts.inter(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: _primary,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          TextFormField(
                                            controller: _newPasswordCtrl,
                                            obscureText: _obscureNewPassword,
                                            style: GoogleFonts.inter(fontSize: 15),
                                            decoration: InputDecoration(
                                              prefixIcon: const Icon(
                                                Icons.lock_outline,
                                                size: 18,
                                                color: _textLight,
                                              ),
                                              suffixIcon: IconButton(
                                                tooltip: _obscureNewPassword ? 'Show password' : 'Hide password',
                                                icon: Icon(
                                                  _obscureNewPassword ? Icons.visibility_off : Icons.visibility,
                                                  size: 18,
                                                  color: _textLight,
                                                ),
                                                onPressed: () => setState(() => _obscureNewPassword = !_obscureNewPassword),
                                              ),
                                              filled: true,
                                              fillColor: Colors.white,
                                              border: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(DSRadius.md),
                                                borderSide: const BorderSide(color: DSColors.softBorder),
                                              ),
                                              enabledBorder: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(DSRadius.md),
                                                borderSide: const BorderSide(color: DSColors.softBorder),
                                              ),
                                              focusedBorder: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(DSRadius.md),
                                                borderSide: const BorderSide(color: _primary),
                                              ),
                                            ),
                                          ),
                                        ],
                                        const SizedBox(height: 28),
                                        SizedBox(
                                          height: 48,
                                          child: ElevatedButton(
                                            onPressed: _isLoading
                                                ? null
                                                : (_useOtpMode
                                                    ? (_otpSent ? _handleVerifyOtpReset : _handleSendOtp)
                                                    : _handleSubmit),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: _primary,
                                              foregroundColor: _white,
                                              disabledBackgroundColor: _primary.withValues(alpha: 0.6),
                                              elevation: 0,
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(DSRadius.md),
                                              ),
                                            ),
                                            child: _isLoading
                                                ? const SizedBox(
                                                    width: 24,
                                                    height: 24,
                                                    child: CircularProgressIndicator(
                                                      strokeWidth: 2.5,
                                                      color: _white,
                                                    ),
                                                  )
                                                : Text(
                                                    _useOtpMode
                                                        ? (_otpSent ? 'Verify OTP & Reset Password' : 'Send 6-Digit OTP Code')
                                                        : 'Send Reset Link',
                                                    style: GoogleFonts.inter(
                                                      fontSize: 16,
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                          ),
                                        ),
                                        const SizedBox(height: 32),
                                        Center(
                                          child: GestureDetector(
                                            onTap: _navigateBack,
                                            child: RichText(
                                              text: TextSpan(
                                                text:
                                                    'Remember your password? ',
                                                style: GoogleFonts.inter(
                                                  color: _textLight,
                                                  fontSize: 15,
                                                ),
                                                children: [
                                                  TextSpan(
                                                    text: 'Sign In',
                                                    style: GoogleFonts.inter(
                                                      color: _primary,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      decoration: TextDecoration
                                                          .underline,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _SuccessView extends StatelessWidget {
  final String email;
  final bool isOtpReset;

  const _SuccessView({
    required this.email,
    this.isOtpReset = false,
  });

  static const Color _primary = DSColors.deepForestGreen;
  static const Color _textLight = DSColors.textLight;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: DSColors.secondaryGreen.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            isOtpReset ? Icons.check_circle_outline_rounded : Icons.mark_email_read_outlined,
            color: DSColors.secondaryGreen,
            size: 36,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          isOtpReset ? 'Password Reset Successful!' : 'Email Sent!',
          style: GoogleFonts.playfairDisplay(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: _primary,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          isOtpReset
              ? 'Your password has been successfully updated.\nYou can now sign in with your new password.'
              : 'We\'ve sent a password reset link to\n$email',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 15,
            color: _textLight,
            height: 1.5,
          ),
        ),
        if (!isOtpReset) ...[
          const SizedBox(height: 8),
          Text(
            'Please check your inbox (and spam folder).',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 13, color: _textLight),
          ),
        ],
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: () => context.go('/login'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(DSRadius.md),
              ),
            ),
            child: Text(
              isOtpReset ? 'Sign In with New Password' : 'Back to Sign In',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: () => context.go('/'),
          child: Text(
            'Continue as Guest',
            style: GoogleFonts.inter(
              color: _textLight,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
