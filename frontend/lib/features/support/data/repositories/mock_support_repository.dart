import '../../domain/entities/faq.dart';
import '../../domain/repositories/support_repository.dart';

class MockSupportRepository implements SupportRepository {
  final List<Faq> _faqs = [
    const Faq(
      question: 'How do I borrow a book?',
      answer:
          'You can borrow books by presenting your library card at the circulation desk or by using the self-checkout kiosks located near the entrance. You must have a valid library account.',
    ),
    const Faq(
      question: 'What is the late fee policy?',
      answer:
          'Late fees vary by item type. Standard books are \$0.25 per day, while specialized equipment or reserved items may have higher daily fees.',
    ),
    const Faq(
      question: 'Can I renew my books online?',
      answer:
          'Yes, you can renew most items online through your account dashboard, provided they are not on hold for another patron.',
    ),
    const Faq(
      question: 'How can I donate books?',
      answer:
          'We accept donations of gently used books at the library entrance during operating hours. Tax receipts are available upon request.',
    ),
    const Faq(
      question: 'Is there a limit on how many books I can borrow?',
      answer:
          'Standard members can borrow up to 20 items at a time. Premium members have a limit of 50 items.',
    ),
  ];

  @override
  Future<List<Faq>> getFaqs() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return _faqs;
  }

  @override
  Future<List<Faq>> searchFaqs(String query) async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (query.isEmpty) return _faqs;
    return _faqs
        .where(
          (faq) =>
              faq.question.toLowerCase().contains(query.toLowerCase()) ||
              faq.answer.toLowerCase().contains(query.toLowerCase()),
        )
        .toList();
  }
}
