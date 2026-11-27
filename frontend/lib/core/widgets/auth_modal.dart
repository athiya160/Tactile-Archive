import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../services/api_service.dart';

class AuthModal extends StatefulWidget {
  final bool initialLoginMode;

  const AuthModal({super.key, this.initialLoginMode = true});

  static Future<void> show(
    BuildContext context, {
    bool initialLoginMode = true,
  }) async {
    if (initialLoginMode) {
      context.push('/login');
    } else {
      context.push('/register');
    }
  }

  @override
  State<AuthModal> createState() => _AuthModalState();
}

class _AuthModalState extends State<AuthModal> {
  late bool _isLoginMode;
  
  // State for forms
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  // Registration specific
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  UserRole _selectedRole = UserRole.customer;

  final _formKey = GlobalKey<FormState>();
  final _passwordFocusNode = FocusNode();

  bool _isLoading = false;
  String? _error;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isPasswordFocused = false;

  static const Color _primary = Color(0xFF0B3D2E);
  static const Color _bg = Color(0xFFFDFDFB);
  static const Color _textLight = Color(0xFF586159);
  static const Color _white = Color(0xFFFFFFFF);

  @override
  void initState() {
    super.initState();
    _isLoginMode = widget.initialLoginMode;
    _passwordFocusNode.addListener(() {
      setState(() {
        _isPasswordFocused = _passwordFocusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _confirmPasswordController.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_isLoginMode && _passwordController.text != _confirmPasswordController.text) {
      setState(() => _error = "Passwords do not match");
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    if (_isLoginMode) {
      final error = await ApiService.login(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
      if (mounted) {
        setState(() => _isLoading = false);
        if (error == null) {
          Navigator.of(context).pop();
          context.go('/');
        } else {
          setState(() => _error = error);
        }
      }
    } else {
      final error = await ApiService.register(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        name: _nameController.text.trim(),
        role: _selectedRole,
        phone: _phoneController.text.trim(),
      );
      if (mounted) {
        setState(() => _isLoading = false);
        if (error == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Account created successfully! Please log in."),
              backgroundColor: _primary,
            ),
          );
          setState(() {
            _isLoginMode = true;
          });
        } else {
          setState(() => _error = error);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = MediaQuery.of(context).size.width > 800;
    
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        width: _isLoginMode ? 480 : (isDesktop ? 1000 : 800),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        decoration: BoxDecoration(
          color: _bg,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 50,
              offset: const Offset(0, 20),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Dark Header for Sign Up
            if (!_isLoginMode)
              Container(
                color: _primary,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _selectedRole == UserRole.customer ? 'Join as Customer' : 'Join as Provider',
                            style: GoogleFonts.inter(
                              color: _white,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Create your profile to get started.',
                            style: GoogleFonts.inter(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: const Icon(Icons.close, color: Colors.white70),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              )
            else
              // Light header for login
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  padding: const EdgeInsets.all(16),
                  icon: const Icon(Icons.close, color: _textLight),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),

            // Body
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(isDesktop ? 48 : 32),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_error != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Text(
                            _error!,
                            style: GoogleFonts.inter(
                              color: Colors.red.shade800,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      if (_isLoginMode) ...[
                        Text(
                          'Welcome Back',
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: _primary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Log in to access your account.',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: _textLight,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),
                      ],

                      if (!_isLoginMode) ...[
                        // Role Selection
                        Text(
                          'Register as:',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: _textLight,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildRoleCard(
                                role: UserRole.customer,
                                icon: Icons.person_outline,
                                label: 'Customer',
                                isSelected: _selectedRole == UserRole.customer,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildRoleCard(
                                role: UserRole.provider,
                                icon: Icons.storefront_outlined,
                                label: 'Provider',
                                isSelected: _selectedRole == UserRole.provider,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),

                        _buildTextField(
                          controller: _nameController,
                          label: 'Full Name',
                          hintText: '',
                          icon: Icons.person_outline,
                          validator: (v) => v!.isEmpty ? 'Enter your name' : null,
                        ),
                        const SizedBox(height: 16),
                      ],

                      _buildTextField(
                        controller: _emailController,
                        label: 'Email Address',
                        hintText: '',
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) => v!.isEmpty ? 'Enter your email' : null,
                      ),
                      const SizedBox(height: 16),

                      if (!_isLoginMode) ...[
                        _buildTextField(
                          controller: _phoneController,
                          label: 'Phone Number (optional)',
                          hintText: '',
                          icon: Icons.phone_outlined,
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 16),
                      ],

                      _buildTextField(
                        controller: _passwordController,
                        label: 'Password',
                        hintText: '',
                        icon: Icons.lock_outline,
                        obscureText: _obscurePassword,
                        focusNode: _passwordFocusNode,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                            size: 20,
                            color: _textLight,
                          ),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Enter your password';
                          if (!_isLoginMode) {
                            if (v.length < 8) return 'Password must be at least 8 characters';
                            if (!RegExp(r'(?=.*[A-Z])').hasMatch(v)) return 'Must contain uppercase letter';
                            if (!RegExp(r'(?=.*[a-z])').hasMatch(v)) return 'Must contain lowercase letter';
                            if (!RegExp(r'(?=.*[0-9])').hasMatch(v)) return 'Must contain a number';
                            if (!RegExp(r'(?=.*[!@#\$&*~])').hasMatch(v)) return 'Must contain special character';
                          }
                          return null;
                        },
                      ),
                      if (!_isLoginMode && _isPasswordFocused)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0, left: 4.0),
                          child: Text(
                            'Password should contain uppercase letter, lowercase letter, number and special character (min 8 characters).',
                            style: GoogleFonts.inter(
                              color: const Color(0xFF6B7280),
                              fontSize: 12,
                              height: 1.4,
                            ),
                          ),
                        ),
                      const SizedBox(height: 16),

                      if (!_isLoginMode) ...[
                        _buildTextField(
                          controller: _confirmPasswordController,
                          label: 'Confirm Password',
                          hintText: '',
                          icon: Icons.lock_outline,
                          obscureText: _obscureConfirmPassword,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirmPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                              size: 20,
                              color: _textLight,
                            ),
                            onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                          ),
                          validator: (v) => v!.isEmpty ? 'Confirm your password' : null,
                        ),
                        const SizedBox(height: 16),
                      ],

                      if (_isLoginMode)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                                context.push('/forgot-password');
                              },
                              child: Text(
                                'Forgot Password?',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: _primary,
                                ),
                              ),
                            ),
                          ],
                        ),

                      const SizedBox(height: 24),
                      SizedBox(
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleSubmit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primary,
                            foregroundColor: _white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 0,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: _white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  _isLoginMode ? 'Log In' : 'Create Account',
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      Center(
                        child: Wrap(
                          alignment: WrapAlignment.center,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              _isLoginMode ? "Don't have an account? " : "Already have an account? ",
                              style: GoogleFonts.inter(
                                color: _textLight,
                                fontSize: 14,
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _isLoginMode = !_isLoginMode;
                                  _error = null;
                                });
                              },
                              child: Text(
                                _isLoginMode ? "Sign Up" : "Sign In",
                                style: GoogleFonts.inter(
                                  color: _primary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (!_isLoginMode)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            "By registering you agree to our Terms & Privacy Policy.",
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              color: const Color(0xFF9CA3AF),
                              fontSize: 12,
                            ),
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
    );
  }

  Widget _buildRoleCard({
    required UserRole role,
    required IconData icon,
    required String label,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedRole = role;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE8ECEB) : const Color(0xFFF7F7F5),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? _primary : const Color(0xFFE5E5E5),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? _primary : _textLight,
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? _primary : _textLight,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hintText,
    IconData? icon,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    FocusNode? focusNode,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        obscureText: obscureText,
        keyboardType: keyboardType,
        validator: validator,
        style: GoogleFonts.inter(fontSize: 15),
        decoration: InputDecoration(
          prefixIcon: icon != null ? Icon(icon, size: 20, color: _textLight) : null,
          hintText: hintText.isEmpty ? label : hintText, // Use label as fallback hint
          hintStyle: GoogleFonts.inter(color: const Color(0xFF999999)),
          filled: true,
          fillColor: Colors.transparent,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          suffixIcon: suffixIcon,
          border: InputBorder.none,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFE5E5E5)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: _primary),
          ),
        ),
      ),
    );
  }
}
