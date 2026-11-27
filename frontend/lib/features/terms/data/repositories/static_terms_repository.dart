import '../../domain/entities/terms_section.dart';
import '../../domain/repositories/terms_repository.dart';

class StaticTermsRepository implements TermsRepository {
  @override
  Future<List<TermsSection>> getTerms() async {
    // Simulating a small delay
    await Future.delayed(const Duration(milliseconds: 300));

    return [
      const TermsSection(
        title: '1. User Accounts',
        paragraphs: [
          'Users must provide accurate registration information.',
          'Users are responsible for maintaining the security of their accounts and passwords.',
        ],
      ),
      const TermsSection(
        title: '2. Buying and Selling',
        paragraphs: [
          'Sellers must provide accurate descriptions and images of books.',
          'Users must not list prohibited, illegal, or misleading content.',
          'The platform reserves the right to remove inappropriate listings.',
        ],
      ),
      const TermsSection(
        title: '3. Renting and Borrowing',
        paragraphs: [
          'Users must return rented or borrowed books within the agreed period.',
          'Late returns may result in penalties or account restrictions.',
        ],
      ),
      const TermsSection(
        title: '4. Book Condition',
        paragraphs: [
          'Book condition descriptions should be truthful and accurate.',
          'The platform is not responsible for disputes arising from incorrect descriptions provided by users.',
        ],
      ),
      const TermsSection(
        title: '5. Payments',
        paragraphs: [
          'All payments must be completed through approved payment methods.',
          'Refunds will be handled according to the platform\'s refund policy.',
        ],
      ),
      const TermsSection(
        title: '6. User Conduct',
        paragraphs: [
          'Users must communicate respectfully.',
          'Harassment, fraud, spam, or abusive behavior is strictly prohibited.',
        ],
      ),
      const TermsSection(
        title: '7. Privacy',
        paragraphs: [
          'User information will be handled securely and only used for platform operations.',
          'Personal information will not be shared with unauthorized third parties.',
        ],
      ),
      const TermsSection(
        title: '8. Intellectual Property',
        paragraphs: [
          'All website content, branding, and design elements belong to The Tactile Archive.',
          'Unauthorized copying or redistribution is prohibited.',
        ],
      ),
      const TermsSection(
        title: '9. Limitation of Liability',
        paragraphs: [
          'The Tactile Archive acts as a marketplace connecting readers and sellers.',
          'The platform is not responsible for disputes between users.',
        ],
      ),
      const TermsSection(
        title: '10. Changes to Terms',
        paragraphs: [
          'The platform reserves the right to update these terms at any time.',
          'Continued use of the platform indicates acceptance of any updated terms.',
        ],
      ),
    ];
  }

  @override
  Future<void> acknowledgeTerms() async {
    // In a real app, this would send an API request
    await Future.delayed(const Duration(milliseconds: 500));
  }
}
