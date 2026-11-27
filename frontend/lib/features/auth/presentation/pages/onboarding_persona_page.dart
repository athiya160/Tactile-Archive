import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/services/google_auth_service.dart';
import '../../../../core/design_system/design_system.dart';

class OnboardingPersonaPage extends StatefulWidget {
  const OnboardingPersonaPage({super.key});

  @override
  State<OnboardingPersonaPage> createState() => _OnboardingPersonaPageState();
}

class _OnboardingPersonaPageState extends State<OnboardingPersonaPage> {
  int _step = 1; // Step 1: Account Type, Step 2: User Type (Who are you?), Step 3: Login/Signup
  String _accountType = 'borrow'; // 'borrow' (Customer) or 'provide' (Provider)
  String _userType = 'student'; // 'student' or 'regular'
  bool _isSignUpMode = false;
  bool _obscurePassword = true;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleAuthSubmit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (_isSignUpMode) {
      final name = _nameController.text.trim();
      final phone = _phoneController.text.trim();
      final confirmPassword = _confirmPasswordController.text.trim();

      if (name.isEmpty) {
        setState(() => _errorMessage = 'Please enter your full name.');
        return;
      }
      if (email.isEmpty) {
        setState(() => _errorMessage = 'Please enter your email address.');
        return;
      }
      if (phone.isEmpty) {
        setState(() => _errorMessage = 'Please enter your mobile / phone number.');
        return;
      }
      if (phone.length < 10) {
        setState(() => _errorMessage = 'Please enter a valid 10-digit mobile number.');
        return;
      }
      if (password.isEmpty) {
        setState(() => _errorMessage = 'Please create a password.');
        return;
      }
      if (password.length < 8) {
        setState(() => _errorMessage = 'Password must be at least 8 characters.');
        return;
      }
      if (password != confirmPassword) {
        setState(() => _errorMessage = 'Passwords do not match.');
        return;
      }

      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final role = _accountType == 'provide' ? UserRole.provider : UserRole.customer;
      final selectedType = _userType == 'student' ? UserType.student : UserType.reader;
      final err = await ApiService.register(
        email: email,
        password: password,
        name: name,
        phone: phone.isEmpty ? null : phone,
        role: role,
        userType: selectedType,
      );
      if (mounted) {
        setState(() => _isLoading = false);
        if (err == null) {
          context.go('/');
        } else {
          setState(() => _errorMessage = err);
        }
      }
    } else {
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
          context.go('/');
        } else {
          setState(() => _errorMessage = err);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DSColors.warmIvory,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 20),
              // Stepper Header Bar
              _buildTopHeader(context),
              const SizedBox(height: 32),

              Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 900),
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      if (_step == 1) _buildStep1ChooseAccountType(),
                      if (_step == 2) _buildStep2ChooseUserType(),
                      if (_step == 3) _buildStep3LoginOrSignUpForm(),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 64),
            ],
          ),
        ),
      ),
    );
  }

  // STEPPER HEADER BAR
  Widget _buildTopHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
      color: DSColors.paperWhite,
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Row(
            children: [
              Row(
                children: [
                  const Icon(Icons.bookmark_border_rounded, color: DSColors.antiqueGold, size: 20),
                  const SizedBox(width: 6),
                  Text(
                    'The Tactile Archive',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: DSColors.deepForestGreen,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              InkWell(
                onTap: () {
                  if (_step > 1) {
                    setState(() => _step--);
                  } else {
                    context.go('/welcome');
                  }
                },
                child: Row(
                  children: [
                    const Icon(Icons.arrow_back, size: 16, color: DSColors.charcoal),
                    const SizedBox(width: 4),
                    Text('Back', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: DSColors.charcoal)),
                  ],
                ),
              ),
              const Spacer(),
              _buildStepCircle(1, 'Account Type', _step >= 1),
              _buildStepLine(_step >= 2),
              _buildStepCircle(2, 'Details', _step >= 2),
              _buildStepLine(_step >= 3),
              _buildStepCircle(3, 'Verify', _step >= 3),
              _buildStepLine(_step >= 4),
              _buildStepCircle(4, 'Complete', _step >= 4),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepCircle(int num, String label, bool isActiveOrDone) {
    final isCurrent = _step == num;
    final isDone = _step > num;
    return Column(
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: isActiveOrDone ? DSColors.deepForestGreen : const Color(0xFFE2E8F0),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: isDone
                ? const Icon(Icons.check, size: 14, color: Colors.white)
                : Text('$num', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: isActiveOrDone ? Colors.white : DSColors.textMuted)),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
            color: isCurrent ? DSColors.deepForestGreen : DSColors.textMuted,
          ),
        ),
      ],
    );
  }

  Widget _buildStepLine(bool isActive) {
    return Container(
      width: 28,
      height: 2,
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
      color: isActive ? DSColors.deepForestGreen : const Color(0xFFE2E8F0),
    );
  }

  // SCREEN 2: STEP 1 - CHOOSE ACCOUNT TYPE (media_1788161633352.png)
  Widget _buildStep1ChooseAccountType() {
    return Column(
      children: [
        Text(
          'Create Your Account',
          style: GoogleFonts.playfairDisplay(fontSize: 28, fontWeight: FontWeight.bold, color: DSColors.deepForestGreen),
        ),
        const SizedBox(height: 4),
        Text('Join our community and get started', style: GoogleFonts.inter(fontSize: 13, color: DSColors.textMuted)),
        const SizedBox(height: 32),

        Row(
          children: [
            Expanded(
              child: _buildAccountOptionCard(
                id: 'borrow',
                icon: Icons.person_outline,
                title: 'I want to Borrow / Rent',
                subtitle: 'I want to borrow or rent books from community providers.',
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: _buildAccountOptionCard(
                id: 'provide',
                icon: Icons.storefront_outlined,
                title: 'I want to Provide / Sell',
                subtitle: 'I want to list my books and earn by renting or selling to others.',
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Already have an account? ', style: GoogleFonts.inter(fontSize: 13, color: DSColors.textMuted)),
            InkWell(
              onTap: () => setState(() {
                _isSignUpMode = false;
                _step = 3;
              }),
              child: Text('Login', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: DSColors.deepForestGreen)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAccountOptionCard({
    required String id,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final isSelected = _accountType == id;

    return InkWell(
      onTap: () {
        setState(() {
          _accountType = id;
          _step = 2; // Auto advance to Step 2 (Who are you?)
        });
      },
      borderRadius: BorderRadius.circular(DSRadius.card),
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(DSRadius.card),
          border: Border.all(
            color: isSelected ? (id == 'provide' ? DSColors.antiqueGold : DSColors.deepForestGreen) : DSColors.softBorder,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: isSelected ? (id == 'provide' ? const Color(0xFFFFF9F0) : const Color(0xFFF0F7F4)) : const Color(0xFFF7FAFC),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 28, color: id == 'provide' ? DSColors.antiqueGold : DSColors.deepForestGreen),
            ),
            const SizedBox(height: 16),
            Text(title, textAlign: TextAlign.center, style: GoogleFonts.playfairDisplay(fontSize: 18, fontWeight: FontWeight.bold, color: DSColors.charcoal)),
            const SizedBox(height: 6),
            Text(subtitle, textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 12, color: DSColors.textMuted, height: 1.4)),
            const SizedBox(height: 16),
            Radio<String>(
              value: id,
              groupValue: _accountType,
              activeColor: id == 'provide' ? DSColors.antiqueGold : DSColors.deepForestGreen,
              onChanged: (val) {
                setState(() {
                  _accountType = val!;
                  _step = 2;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  // SCREENS 3A & 3B: STEP 2 - CHOOSE USER TYPE (media_1788161633352.png)
  Widget _buildStep2ChooseUserType() {
    final isProvider = _accountType == 'provide';
    final activeColor = isProvider ? DSColors.antiqueGold : DSColors.deepForestGreen;

    return Column(
      children: [
        Text(
          'Who are you?',
          style: GoogleFonts.playfairDisplay(fontSize: 28, fontWeight: FontWeight.bold, color: DSColors.deepForestGreen),
        ),
        const SizedBox(height: 4),
        Text('Please select the option that best describes you', style: GoogleFonts.inter(fontSize: 13, color: DSColors.textMuted)),
        const SizedBox(height: 32),

        Container(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            children: [
              _buildUserTypeCard(
                id: 'student',
                icon: Icons.school_outlined,
                title: isProvider ? "I'm a Student Provider" : "I'm a Student",
                subtitle: isProvider ? "List your books and rent or sell them to other students." : "Access student benefits, discounts, and affordable book rentals.",
                activeColor: activeColor,
              ),
              const SizedBox(height: 16),
              _buildUserTypeCard(
                id: 'regular',
                icon: isProvider ? Icons.storefront_outlined : Icons.person_outline,
                title: isProvider ? "I'm not a Student Provider" : "I'm not a Student",
                subtitle: isProvider ? "List your books for everyone in the community." : "Continue as a regular user.",
                activeColor: activeColor,
              ),
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () => setState(() => _step = 3),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: activeColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DSRadius.md)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Continue', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward, size: 16),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUserTypeCard({
    required String id,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color activeColor,
  }) {
    final isSelected = _userType == id;
    final isAmber = activeColor == DSColors.antiqueGold;

    return InkWell(
      onTap: () => setState(() => _userType = id),
      borderRadius: BorderRadius.circular(DSRadius.card),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? (isAmber ? const Color(0xFFFFF9F0) : const Color(0xFFF0F7F4)) : Colors.white,
          borderRadius: BorderRadius.circular(DSRadius.card),
          border: Border.all(
            color: isSelected ? activeColor : DSColors.softBorder,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected ? activeColor.withValues(alpha: 0.12) : const Color(0xFFF7FAFC),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 24, color: activeColor),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: DSColors.charcoal)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: GoogleFonts.inter(fontSize: 11, color: DSColors.textMuted)),
                ],
              ),
            ),
            Radio<String>(
              value: id,
              groupValue: _userType,
              activeColor: activeColor,
              onChanged: (val) => setState(() => _userType = val!),
            ),
          ],
        ),
      ),
    );
  }

  // SCREENS 4A & 4B: STEP 3 - LOGIN OR SIGN UP FORM (media_1788161633352.png)
  Widget _buildStep3LoginOrSignUpForm() {
    final isProvider = _accountType == 'provide';

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 750;

        final formSide = Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: isDesktop
                ? const BorderRadius.only(topLeft: Radius.circular(DSRadius.card), bottomLeft: Radius.circular(DSRadius.card))
                : BorderRadius.circular(DSRadius.card),
            border: Border.all(color: DSColors.softBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _isSignUpMode ? 'Create Account' : 'Welcome Back!',
                style: GoogleFonts.playfairDisplay(fontSize: 26, fontWeight: FontWeight.bold, color: DSColors.deepForestGreen),
              ),
              Text(
                _isSignUpMode ? 'Sign up to start your journey' : 'Login to continue',
                style: GoogleFonts.inter(fontSize: 12, color: DSColors.textMuted),
              ),
              const SizedBox(height: 20),

              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF5F5),
                    borderRadius: BorderRadius.circular(DSRadius.sm),
                    border: Border.all(color: const Color(0xFFFEB2B2)),
                  ),
                  child: Text(_errorMessage!, style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFFE53E3E))),
                ),
                const SizedBox(height: 14),
              ],

              if (_isSignUpMode) ...[
                // Full Name input
                Text('Full Name', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: DSColors.charcoal)),
                const SizedBox(height: 6),
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    hintText: 'Enter your full name',
                    hintStyle: GoogleFonts.inter(fontSize: 12, color: const Color(0xFFA0AEC0)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(DSRadius.md), borderSide: const BorderSide(color: DSColors.softBorder)),
                  ),
                ),
                const SizedBox(height: 14),
              ],

              // Email input
              Text(_isSignUpMode ? 'Email Address' : 'Email or Phone Number', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: DSColors.charcoal)),
              const SizedBox(height: 6),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: _isSignUpMode ? 'Enter your email address' : 'Enter email or phone number',
                  hintStyle: GoogleFonts.inter(fontSize: 12, color: const Color(0xFFA0AEC0)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(DSRadius.md), borderSide: const BorderSide(color: DSColors.softBorder)),
                ),
              ),
              const SizedBox(height: 14),

              if (_isSignUpMode) ...[
                // Phone Number input (Mandatory)
                Text('Phone Number *', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: DSColors.charcoal)),
                const SizedBox(height: 6),
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    hintText: 'Enter 10-digit mobile number',
                    hintStyle: GoogleFonts.inter(fontSize: 12, color: const Color(0xFFA0AEC0)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(DSRadius.md), borderSide: const BorderSide(color: DSColors.softBorder)),
                  ),
                ),
                const SizedBox(height: 14),
              ],

              // Password input
              Text(_isSignUpMode ? 'Create Password' : 'Password', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: DSColors.charcoal)),
              const SizedBox(height: 6),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  hintText: _isSignUpMode ? 'Create a strong password (min 8 chars)' : 'Enter your password',
                  hintStyle: GoogleFonts.inter(fontSize: 12, color: const Color(0xFFA0AEC0)),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                      size: 18,
                      color: const Color(0xFFA0AEC0),
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(DSRadius.md), borderSide: const BorderSide(color: DSColors.softBorder)),
                ),
              ),
              const SizedBox(height: 14),

              if (_isSignUpMode) ...[
                // Confirm Password input
                Text('Confirm Password', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: DSColors.charcoal)),
                const SizedBox(height: 6),
                TextField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  decoration: InputDecoration(
                    hintText: 'Re-enter your password',
                    hintStyle: GoogleFonts.inter(fontSize: 12, color: const Color(0xFFA0AEC0)),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        size: 18,
                        color: const Color(0xFFA0AEC0),
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureConfirmPassword = !_obscureConfirmPassword;
                        });
                      },
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(DSRadius.md), borderSide: const BorderSide(color: DSColors.softBorder)),
                  ),
                ),
                const SizedBox(height: 8),
              ] else ...[
                Align(
                  alignment: Alignment.centerRight,
                  child: InkWell(
                    onTap: () => context.go('/forgot-password'),
                    child: Text('Forgot Password?', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: DSColors.deepForestGreen)),
                  ),
                ),
              ],
              const SizedBox(height: 16),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleAuthSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DSColors.deepForestGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DSRadius.md)),
                  ),
                  child: _isLoading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text(_isSignUpMode ? 'Sign Up' : 'Login', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14)),
                ),
              ),
              const SizedBox(height: 14),

              Row(
                children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text('or', style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFFA0AEC0))),
                  ),
                  const Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 14),

              // Social Sign-in Buttons
              GoogleSignInButton(
                label: 'Continue with Google',
                isLoading: _isLoading,
                onPressed: () async {
                  setState(() => _isLoading = true);
                  final persona = _accountType == 'provide' ? 'provider' : (_userType == 'student' ? 'student' : 'reader');
                  await GoogleAuthService.signInWithGoogle(context, personaHint: persona);
                  if (mounted) setState(() => _isLoading = false);
                },
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  onPressed: () => context.go('/'),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DSRadius.md)),
                    side: const BorderSide(color: DSColors.softBorder),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const FaIcon(FontAwesomeIcons.apple, size: 18, color: Colors.black),
                      const SizedBox(width: 10),
                      Text('Continue with Apple', style: GoogleFonts.inter(fontSize: 12, color: DSColors.charcoal, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(_isSignUpMode ? 'Already have an account? ' : "Don't have an account? ", style: GoogleFonts.inter(fontSize: 12, color: DSColors.textMuted)),
                    InkWell(
                      onTap: () => setState(() => _isSignUpMode = !_isSignUpMode),
                      child: Text(_isSignUpMode ? 'Login' : 'Sign Up', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: DSColors.deepForestGreen)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );

        final featureSide = Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF9F0),
            borderRadius: isDesktop
                ? const BorderRadius.only(topRight: Radius.circular(DSRadius.card), bottomRight: Radius.circular(DSRadius.card))
                : BorderRadius.circular(DSRadius.card),
            border: Border.all(color: const Color(0xFFFFE8D6)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: isProvider
                    ? [
                        _buildRightFeatureItem(Icons.storefront_outlined, 'Earn by sharing', 'List your books and earn extra income.', DSColors.antiqueGold),
                        const SizedBox(height: 20),
                        _buildRightFeatureItem(Icons.people_outline, 'Reach more readers', 'Connect with students and book lovers.', DSColors.antiqueGold),
                        const SizedBox(height: 20),
                        _buildRightFeatureItem(Icons.verified_user_outlined, 'Secure & easy', 'We handle payments and returns safely.', DSColors.antiqueGold),
                      ]
                    : [
                        _buildRightFeatureItem(Icons.local_offer_outlined, 'Affordable rentals', 'Save more with community pricing.', DSColors.deepForestGreen),
                        const SizedBox(height: 20),
                        _buildRightFeatureItem(Icons.person_outline, 'Trusted members', 'Connect with verified book owners.', DSColors.deepForestGreen),
                        const SizedBox(height: 20),
                        _buildRightFeatureItem(Icons.shield_outlined, 'Easy & secure', 'Safe payments and hassle-free returns.', DSColors.deepForestGreen),
                      ],
              ),
              const SizedBox(height: 32),
              // Book Illustration
              Center(
                child: Container(
                  height: 120,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(DSRadius.md),
                    image: const DecorationImage(
                      image: AssetImage('assets/images/hero.png'),
                      fit: BoxFit.contain,
                    ),
                  ),
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
            const SizedBox(height: 20),
            featureSide,
          ],
        );
      },
    );
  }

  Widget _buildRightFeatureItem(IconData icon, String title, String subtitle, Color themeColor) {
    final isAmber = themeColor == DSColors.antiqueGold;
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isAmber ? const Color(0xFFFFF3DC) : const Color(0xFFE6F4EE),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 20, color: themeColor),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: DSColors.charcoal)),
              Text(subtitle, style: GoogleFonts.inter(fontSize: 11, color: DSColors.textMuted)),
            ],
          ),
        ),
      ],
    );
  }
}

