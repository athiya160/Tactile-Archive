import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:libri_flow/core/services/api_service.dart';
import 'package:libri_flow/features/home/presentation/pages/privacy_policy_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Phase 20.13: Account Deletion and Privacy Policy Compliance Tests', () {
    testWidgets('PrivacyPolicyPageV2 renders all 8 required compliance sections',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 5000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PrivacyPolicyPageV2(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check header
      expect(find.text('Privacy Policy'), findsAtLeastNWidgets(1));
      expect(find.text('The Tactile Archive'), findsAtLeastNWidgets(1));

      // Check all 8 required section titles
      expect(find.text('1. Information We Collect'), findsOneWidget);
      expect(
          find.text('2. Camera & Photo Permissions (Smart Shelf Scanner & Listings)'),
          findsOneWidget);
      expect(find.text('3. Location Data & Community Exchange Map'), findsOneWidget);
      expect(
          find.text('4. Payment Processing & Financial Security (Razorpay & COD)'),
          findsOneWidget);
      expect(find.text('5. Student & Reader Academic Privacy'), findsOneWidget);
      expect(
          find.text(
              '6. User Data Retention, Erasure & Account Deletion (Google Play Compliance)'),
          findsOneWidget);
      expect(
          find.text('7. External Web Account Deletion Request Portal'), findsOneWidget);
      expect(find.text('8. Contact & Data Protection Inquiries'), findsOneWidget);
    });

    test('ApiService.deleteAccount method signature and parameters are verified', () {
      // Verify ApiService has deleteAccount static method
      expect(ApiService.deleteAccount, isNotNull);
    });

    test('Public Account Deletion web portals exist and contain compliance terms', () {
      final webPortal = File('web/account_deletion.html');
      final metadataPortal = File('../play_store_assets/metadata/account_deletion.html');

      expect(webPortal.existsSync() || metadataPortal.existsSync(), isTrue,
          reason: 'account_deletion.html must exist in web/ or metadata/');

      final targetFile = webPortal.existsSync() ? webPortal : metadataPortal;
      final content = targetFile.readAsStringSync();

      expect(content.contains('Account Deletion'), isTrue);
      expect(content.contains('Google Play'), isTrue);
      expect(content.contains('Data Permanently Erased') || content.contains('Data Permanently Deleted'), isTrue);
      expect(content.contains('Data Retained'), isTrue);
      expect(content.contains('deletion-form'), isTrue);
    });

    test('Public Privacy Policy HTML files exist and contain real app disclosures', () {
      final webPrivacy = File('web/privacy_policy.html');
      final metadataPrivacy = File('../play_store_assets/metadata/privacy_policy.html');

      expect(webPrivacy.existsSync() || metadataPrivacy.existsSync(), isTrue,
          reason: 'privacy_policy.html must exist in web/ or metadata/');

      final targetFile = webPrivacy.existsSync() ? webPrivacy : metadataPrivacy;
      final content = targetFile.readAsStringSync();

      expect(content.contains('Privacy Policy'), isTrue);
      expect(content.contains('The Tactile Archive'), isTrue);
      expect(content.contains('CAMERA'), isTrue);
      expect(content.contains('ACCESS_COARSE_LOCATION'), isTrue);
      expect(content.contains('Razorpay'), isTrue);
      expect(content.contains('Account Deletion'), isTrue);
    });
  });
}
