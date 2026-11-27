import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'api_service.dart';

/// Real Google Authentication Service for LibriFlow (The Tactile Archive).
/// Supports Flutter Web and Android with genuine OAuth 2.0 OpenID Connect (OIDC) ID tokens.
class GoogleAuthService {
  /// Optional build-time / runtime Web & Server OAuth Client ID.
  /// Pass via `--dart-define=GOOGLE_CLIENT_ID=your_client_id.apps.googleusercontent.com`
  static const String configuredClientId = String.fromEnvironment(
    'GOOGLE_CLIENT_ID',
    defaultValue: 'tactile-archive-web-client-id.apps.googleusercontent.com',
  );

  static GoogleSignIn? _instance;
  static bool _isSigningIn = false;

  /// Returns the singleton GoogleSignIn client instance.
  static GoogleSignIn get googleSignIn {
    if (_instance != null) {
      return _instance!;
    }

    final effectiveClientId = configuredClientId.isNotEmpty ? configuredClientId : null;

    _instance = GoogleSignIn(
      clientId: kIsWeb ? effectiveClientId : null,
      serverClientId: kIsWeb ? null : effectiveClientId,
      scopes: const <String>[
        'email',
        'profile',
        'openid',
      ],
    );
    return _instance!;
  }

  /// Allows injecting a mock GoogleSignIn instance for automated tests.
  @visibleForTesting
  static void setMockGoogleSignIn(GoogleSignIn? mock) {
    _instance = mock;
  }

  /// Whether a Google sign-in operation is currently in progress.
  static bool get isSigningIn => _isSigningIn;

  /// Initiates genuine Google OAuth 2.0 Sign-In.
  ///
  /// On Web: Opens Google Identity Services (GIS) One-Tap / Popup.
  /// On Android: Launches the native Google Play Services Account Chooser.
  ///
  /// Returns `true` on successful authentication and session creation; `false` on cancel or error.
  static Future<bool> signInWithGoogle(
    BuildContext context, {
    String personaHint = 'reader',
    bool redirectOnSuccess = true,
  }) async {
    if (_isSigningIn) {
      debugPrint('[GoogleAuthService] Sign-in already in progress. Ignoring duplicate tap.');
      return false;
    }

    _isSigningIn = true;

    try {
      // 1. Request Google Account selection
      final GoogleSignInAccount? googleAccount;
      try {
        googleAccount = await googleSignIn.signIn();
      } on PlatformException catch (e) {
        debugPrint('[GoogleAuthService] PlatformException during signIn: ${e.code} - ${e.message}');
        if (!context.mounted) return false;

        String userMsg = 'Google Sign-In failed.';
        if (e.code == 'network_error') {
          userMsg = 'Network error: Please check your internet connection.';
        } else if (e.code == 'sign_in_canceled') {
          return false; // User cancelled, no error message needed
        } else if (e.code == 'sign_in_failed' || e.code == '10') {
          userMsg = 'Google OAuth configuration required. Please ensure OAuth Client ID is registered in Google Cloud Console.';
        } else {
          userMsg = e.message ?? userMsg;
        }

        _showSnackBar(context, userMsg, isError: true);
        return false;
      } catch (e) {
        debugPrint('[GoogleAuthService] Unexpected error during Google signIn: $e');
        if (!context.mounted) return false;
        _showSnackBar(context, 'Unable to launch Google Sign-In ($e).', isError: true);
        return false;
      }

      // User dismissed or cancelled the Google account picker
      if (googleAccount == null) {
        debugPrint('[GoogleAuthService] Google account selection cancelled by user.');
        return false;
      }

      if (!context.mounted) return false;

      // Show in-flight progress snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Text(
                'Authenticating with Google...',
                style: GoogleFonts.inter(fontSize: 13, color: Colors.white),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF0D3B2E),
          duration: const Duration(seconds: 4),
        ),
      );

      // 2. Retrieve genuine Google OpenID Connect ID token
      final GoogleSignInAuthentication auth;
      try {
        auth = await googleAccount.authentication;
      } catch (e) {
        debugPrint('[GoogleAuthService] Failed to retrieve authentication tokens: $e');
        if (!context.mounted) return false;
        _showSnackBar(context, 'Failed to retrieve Google identity token: $e', isError: true);
        return false;
      }

      final idToken = auth.idToken;

      if (idToken == null || idToken.isEmpty) {
        debugPrint('[GoogleAuthService] idToken is null. Check serverClientId configuration.');
        if (!context.mounted) return false;
        _showSnackBar(
          context,
          'Google did not return an ID token. Ensure OAuth serverClientId is configured for your environment.',
          isError: true,
          duration: const Duration(seconds: 5),
        );
        return false;
      }

      // 3. Send ID token to secured FastAPI backend
      final error = await ApiService.loginWithGoogle(
        credential: idToken,
        personaHint: personaHint,
        email: googleAccount.email,
        name: googleAccount.displayName,
      );

      if (!context.mounted) return false;

      // 4. Handle backend response
      if (error == null) {
        final displayName = (ApiService.userName != null && ApiService.userName!.isNotEmpty)
            ? ApiService.userName!
            : (googleAccount.displayName ?? 'Reader');

        _showSnackBar(
          context,
          '🎉 Welcome, $displayName! Signed in successfully with Google.',
          isError: false,
          duration: const Duration(seconds: 3),
        );

        if (redirectOnSuccess) {
          if (ApiService.role == UserRole.provider) {
            context.go('/provider');
          } else if (ApiService.userType == UserType.student) {
            if (!ApiService.onboardingCompleted) {
              context.go('/onboarding/student-preferences');
            } else {
              context.go('/student');
            }
          } else {
            context.go('/');
          }
        }
        return true;
      } else {
        _showSnackBar(context, 'Google Sign-In failed: $error', isError: true, duration: const Duration(seconds: 5));
        return false;
      }
    } finally {
      _isSigningIn = false;
    }
  }

  /// Backward-compatible alias for existing screens calling `showGoogleSignInSheet`.
  static Future<bool> showGoogleSignInSheet(
    BuildContext context, {
    String personaHint = 'reader',
    bool redirectOnSuccess = true,
  }) async {
    return signInWithGoogle(
      context,
      personaHint: personaHint,
      redirectOnSuccess: redirectOnSuccess,
    );
  }

  /// Signs out of both Google OAuth and the LibriFlow backend session.
  static Future<void> signOut() async {
    try {
      await googleSignIn.signOut();
    } catch (e) {
      debugPrint('[GoogleAuthService] Error during Google signOut: $e');
    }
    await ApiService.logout();
  }

  static void _showSnackBar(BuildContext context, String message, {bool isError = false, Duration duration = const Duration(seconds: 3)}) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.inter(
            fontSize: 13,
            color: Colors.white,
            fontWeight: isError ? FontWeight.normal : FontWeight.w600,
          ),
        ),
        backgroundColor: isError ? const Color(0xFF991B1B) : const Color(0xFF166534),
        duration: duration,
      ),
    );
  }
}

/// A standard, beautifully branded "Continue with Google" button widget.
class GoogleSignInButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String label;
  final bool isLoading;

  const GoogleSignInButton({
    super.key,
    required this.onPressed,
    this.label = 'Continue with Google',
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          side: const BorderSide(color: Color(0xFFD1D5DB), width: 1.2),
          elevation: 0,
        ),
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0D3B2E)),
              )
            : FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const FaIcon(FontAwesomeIcons.google, size: 16, color: Color(0xFFEA4335)),
                    const SizedBox(width: 12),
                    Text(
                      label,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1F2937),
                        letterSpacing: 0.1,
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
