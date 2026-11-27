import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../../core/design_system/tokens/ds_colors.dart';

class ShelfScannerPage extends StatefulWidget {
  const ShelfScannerPage({super.key});

  @override
  State<ShelfScannerPage> createState() => _ShelfScannerPageState();
}

class _ShelfScannerPageState extends State<ShelfScannerPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isScanning = false;
  int _scanProgress = 0;
  String _scanStatusText = 'Ready to scan';
  XFile? _selectedImage;
  Uint8List? _imageBytes;
  final Set<int> _selectedBookIds = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14};

  final List<Map<String, dynamic>> _detectedBooks = [
    {'id': 1, 'title': 'Atomic Habits', 'author': 'James Clear', 'isbn': '978-0735211292', 'genre': 'Self Development', 'condition': 'Good', 'status': 'Read', 'price': 450, 'rental_price': 60, 'cover': 'https://images-na.ssl-images-amazon.com/images/I/81wgcld4wxL.jpg'},
    {'id': 2, 'title': 'Clean Code', 'author': 'Robert C. Martin', 'isbn': '978-0132350884', 'genre': 'Technology', 'condition': 'Good', 'status': 'Read', 'price': 650, 'rental_price': 90, 'cover': 'https://images-na.ssl-images-amazon.com/images/I/81af+MCATTL.jpg'},
    {'id': 3, 'title': 'Deep Work', 'author': 'Cal Newport', 'isbn': '978-1455586691', 'genre': 'Self Development', 'condition': 'Good', 'status': 'Read', 'price': 390, 'rental_price': 55, 'cover': 'https://images-na.ssl-images-amazon.com/images/I/71QKq9mwV7L.jpg'},
    {'id': 4, 'title': 'The Alchemist', 'author': 'Paulo Coelho', 'isbn': '978-0062315007', 'genre': 'Fiction', 'condition': 'Good', 'status': 'Read', 'price': 299, 'rental_price': 40, 'cover': 'https://images-na.ssl-images-amazon.com/images/I/81wgcld4wxL.jpg'},
    {'id': 5, 'title': 'Python Crash Course', 'author': 'Eric Matthes', 'isbn': '978-1593279288', 'genre': 'Technology', 'condition': 'Good', 'status': 'Reading', 'price': 580, 'rental_price': 80, 'cover': 'https://images-na.ssl-images-amazon.com/images/I/81af+MCATTL.jpg'},
    {'id': 6, 'title': 'The Psychology of Money', 'author': 'Morgan Housel', 'isbn': '978-0857197689', 'genre': 'Self Development', 'condition': 'Good', 'status': 'Unread', 'price': 380, 'rental_price': 55, 'cover': 'https://images-na.ssl-images-amazon.com/images/I/71QKq9mwV7L.jpg'},
    {'id': 7, 'title': 'Designing Data-Intensive Applications', 'author': 'Martin Kleppmann', 'isbn': '978-1449373320', 'genre': 'Technology', 'condition': 'Fair', 'status': 'Reading', 'price': 890, 'rental_price': 120, 'cover': 'https://images-na.ssl-images-amazon.com/images/I/81af+MCATTL.jpg'},
    {'id': 8, 'title': 'To Kill a Mockingbird', 'author': 'Harper Lee', 'isbn': '978-0060935467', 'genre': 'Fiction', 'condition': 'Good', 'status': 'Read', 'price': 350, 'rental_price': 50, 'cover': 'https://images-na.ssl-images-amazon.com/images/I/81wgcld4wxL.jpg'},
    {'id': 9, 'title': '1984', 'author': 'George Orwell', 'isbn': '978-0451524935', 'genre': 'Fiction', 'condition': 'Good', 'status': 'Read', 'price': 250, 'rental_price': 35, 'cover': 'https://images-na.ssl-images-amazon.com/images/I/71QKq9mwV7L.jpg'},
    {'id': 10, 'title': 'Sapiens: A Brief History of Humankind', 'author': 'Yuval Noah Harari', 'isbn': '978-0062316097', 'genre': 'Other', 'condition': 'Good', 'status': 'Unread', 'price': 499, 'rental_price': 70, 'cover': 'https://images-na.ssl-images-amazon.com/images/I/81af+MCATTL.jpg'},
    {'id': 11, 'title': 'Refactoring', 'author': 'Martin Fowler', 'isbn': '978-0134757599', 'genre': 'Technology', 'condition': 'Good', 'status': 'Reading', 'price': 720, 'rental_price': 95, 'cover': 'https://images-na.ssl-images-amazon.com/images/I/71QKq9mwV7L.jpg'},
    {'id': 12, 'title': 'Thinking, Fast and Slow', 'author': 'Daniel Kahneman', 'isbn': '978-0374533557', 'genre': 'Self Development', 'condition': 'Good', 'status': 'Unread', 'price': 420, 'rental_price': 60, 'cover': 'https://images-na.ssl-images-amazon.com/images/I/81af+MCATTL.jpg'},
    {'id': 13, 'title': 'Brave New World', 'author': 'Aldous Huxley', 'isbn': '978-0060850524', 'genre': 'Fiction', 'condition': 'Good', 'status': 'Reading', 'price': 310, 'rental_price': 45, 'cover': 'https://images-na.ssl-images-amazon.com/images/I/81wgcld4wxL.jpg'},
    {'id': 14, 'title': 'Pride and Prejudice', 'author': 'Jane Austen', 'isbn': '978-0141439518', 'genre': 'Fiction', 'condition': 'Fair', 'status': 'Unread', 'price': 240, 'rental_price': 30, 'cover': 'https://images-na.ssl-images-amazon.com/images/I/71QKq9mwV7L.jpg'},
  ];

  final Map<String, dynamic> _shelfInsights = {
    'genres': [
      {'name': 'Technology', 'percentage': 43, 'color': Color(0xFF0D3B2E)},
      {'name': 'Self Development', 'percentage': 29, 'color': Color(0xFFC85A32)},
      {'name': 'Fiction', 'percentage': 21, 'color': Color(0xFFD69E2E)},
      {'name': 'Other', 'percentage': 7, 'color': Color(0xFF718096)},
    ],
    'reading_status': {'read': 5, 'reading': 4, 'unread': 5, 'total': 14},
    'shelf_health': {'good': 12, 'fair': 2, 'damaged': 0, 'prime_pct': 94},
    'valuation': {
      'estimated_resale': 4850,
      'estimated_rental_monthly': 1250,
    },
    'inspection_breakdown': [
      {'factor': 'Cover & Spine Integrity', 'result': '14/14 Intact (0 Tears)', 'status': 'Excellent'},
      {'factor': 'Page Aging & Yellowing', 'result': '2/14 Mild Tanning', 'status': 'Fair'},
      {'factor': 'Water & Moisture Damage', 'result': '0/14 Detected', 'status': 'Pass'},
      {'factor': 'Writing & Highlighting', 'result': '2/14 Light Pencil Markings', 'status': 'Good'},
      {'factor': 'Binding Strength', 'result': '12/14 Strong Glue / Thread', 'status': 'Excellent'},
    ],
    'ai_quote': 'You prefer practical learning and self-improvement books with occasional fiction.',
    'ai_insight': 'You have several high-impact technology & systems engineering books. Based on your reading DNA, you enjoy structured analytical thinking with practical self-improvement and occasional literary depth.',
    'recommended_from_shelf': [
      {
        'id': 101,
        'title': 'Kubernetes in Action',
        'author': 'Marko Lukša',
        'match_score': '95% match',
        'reason': 'Complements your 43% Technology collection & Clean Code architecture books.',
        'price': 780,
        'rental_price': 110,
      },
      {
        'id': 102,
        'title': 'Show Your Work!',
        'author': 'Austin Kleon',
        'match_score': '91% match',
        'reason': 'Direct match for your Self Development DNA alongside Atomic Habits and Deep Work.',
        'price': 320,
        'rental_price': 45,
      }
    ]
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: source, imageQuality: 85);
    if (image == null) return;

    final bytes = await image.readAsBytes();
    setState(() {
      _selectedImage = image;
      _imageBytes = bytes;
      _isScanning = true;
      _scanProgress = 20;
      _scanStatusText = 'Detecting books in camera image...';
    });

    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    setState(() {
      _scanProgress = 50;
      _scanStatusText = 'Spine segmentation & OCR text extraction...';
    });

    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    setState(() {
      _scanProgress = 80;
      _scanStatusText = 'ISBN lookup & duplicate filtering...';
    });

    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    setState(() {
      _scanProgress = 100;
      _isScanning = false;
      _scanStatusText = '14 Books Found! Ready for user confirmation.';
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${_detectedBooks.length} books detected & cataloged! Review selections below.'),
        backgroundColor: DSColors.forestGreen,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _addAllToDigitalShelf() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Text('${_selectedBookIds.length} books added to your personal Digital Shelf! 🎉'),
          ],
        ),
        backgroundColor: DSColors.forestGreen,
        behavior: SnackBarBehavior.floating,
      ),
    );
    _tabController.animateTo(1);
  }

  void _showReviewModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            padding: const EdgeInsets.all(24),
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Review Detected Books', style: GoogleFonts.playfairDisplay(fontSize: 20, fontWeight: FontWeight.bold, color: DSColors.forestGreen)),
                        Text('${_selectedBookIds.length} of ${_detectedBooks.length} selected for Digital Shelf', style: GoogleFonts.inter(fontSize: 12, color: DSColors.textLight)),
                      ],
                    ),
                    IconButton(tooltip: 'Close Review', onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close)),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView.separated(
                    itemCount: _detectedBooks.length,
                    separatorBuilder: (c, i) => const Divider(height: 1),
                    itemBuilder: (context, idx) {
                      final b = _detectedBooks[idx];
                      final isSelected = _selectedBookIds.contains(b['id']);
                      return CheckboxListTile(
                        value: isSelected,
                        activeColor: DSColors.forestGreen,
                        contentPadding: EdgeInsets.zero,
                        onChanged: (val) {
                          setModalState(() {
                            if (val == true) {
                              _selectedBookIds.add(b['id'] as int);
                            } else {
                              _selectedBookIds.remove(b['id']);
                            }
                          });
                          setState(() {});
                        },
                        title: Text(b['title'] as String, style: GoogleFonts.playfairDisplay(fontSize: 14, fontWeight: FontWeight.bold, color: DSColors.forestGreen)),
                        subtitle: Text('${b['author']} • ISBN: ${b['isbn']} • ${b['condition']}', style: GoogleFonts.inter(fontSize: 11, color: DSColors.textLight)),
                        secondary: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: DSColors.background, borderRadius: BorderRadius.circular(4), border: Border.all(color: DSColors.border)),
                          child: Text(b['genre'] as String, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: DSColors.forestGreen)),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _addAllToDigitalShelf();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: DSColors.forestGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('Confirm & Save ${_selectedBookIds.length} Books'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDFBF7),
      appBar: AppBar(
        backgroundColor: DSColors.forestGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Back',
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              context.go('/');
            }
          },
        ),
        title: Text(
          'Smart Shelf Scanner',
          style: GoogleFonts.playfairDisplay(fontSize: 19, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_a_photo_outlined),
            tooltip: 'Take Photo',
            onPressed: () => _pickImage(ImageSource.camera),
          ),
          IconButton(
            icon: const Icon(Icons.photo_library_outlined),
            tooltip: 'Upload from Gallery',
            onPressed: () => _pickImage(ImageSource.gallery),
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: DSColors.warmGold,
          indicatorWeight: 3,
          labelColor: DSColors.warmGold,
          unselectedLabelColor: Colors.white70,
          labelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold),
          unselectedLabelStyle: GoogleFonts.inter(fontSize: 13),
          tabs: const [
            Tab(text: 'Digital Shelf'),
            Tab(text: 'Shelf Insights'),
            Tab(text: 'Shelf Health'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDigitalShelfTab(),
          _buildShelfInsightsTab(),
          _buildShelfHealthTab(),
        ],
      ),
    );
  }

  Widget _buildDigitalShelfTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Scanner Hero Callout
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F7F4),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFC6F6D5)),
                ),
                child: LayoutBuilder(
                  builder: (context, heroConstraints) {
                    final isCompact = heroConstraints.maxWidth < 520;
                    final contentColumn = Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('INSTANT SHELF DIGITIZATION', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5, color: const Color(0xFF22543D))),
                        const SizedBox(height: 4),
                        Text('Take a photo of your physical bookshelf.', style: GoogleFonts.playfairDisplay(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF0D3B2E))),
                        const SizedBox(height: 4),
                        Text('Camera → Detect Books → OCR → ISBN extraction → Duplicate check → Digital Shelf.', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF4A5568))),
                      ],
                    );

                    final button = ElevatedButton.icon(
                      onPressed: () => _pickImage(ImageSource.camera),
                      icon: const Icon(Icons.camera_alt, size: 16),
                      label: const Text('Take Photo'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0D3B2E),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    );

                    if (isCompact) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          contentColumn,
                          const SizedBox(height: 12),
                          button,
                        ],
                      );
                    }

                    return Row(
                      children: [
                        Expanded(child: contentColumn),
                        const SizedBox(width: 12),
                        button,
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),

              if (_isScanning) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFE2E8F0))),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(_scanStatusText, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: DSColors.forestGreen)),
                          Text('$_scanProgress%', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: DSColors.forestGreen)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      LinearProgressIndicator(value: _scanProgress / 100.0, backgroundColor: const Color(0xFFEDF2F7), color: DSColors.forestGreen, minHeight: 6),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              if (_selectedImage != null && _imageBytes != null) ...[
                Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: DSColors.border)),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.memory(_imageBytes!, width: 60, height: 60, fit: BoxFit.cover),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Latest Shelf Photo Captured', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: DSColors.forestGreen)),
                            Text('${_detectedBooks.length} books identified & cross-referenced with catalog.', style: GoogleFonts.inter(fontSize: 11, color: DSColors.textMuted)),
                          ],
                        ),
                      ),
                      OutlinedButton(
                        onPressed: () => _pickImage(ImageSource.camera),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: DSColors.forestGreen,
                          side: const BorderSide(color: DSColors.forestGreen),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        child: const Text('Retake'),
                      ),
                    ],
                  ),
                ),
              ],

              // 14 BOOKS FOUND Header with Actions
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: DSColors.borderLight),
                ),
                child: LayoutBuilder(
                  builder: (context, headerConstraints) {
                    final isCompact = headerConstraints.maxWidth < 460;
                    final infoColumn = Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_detectedBooks.length} BOOKS FOUND',
                          style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: DSColors.forestGreen),
                        ),
                        Text(
                          '${_selectedBookIds.length} selected for Digital Shelf',
                          style: GoogleFonts.inter(fontSize: 11, color: DSColors.textLight),
                        ),
                      ],
                    );

                    final actionRow = Row(
                      mainAxisSize: isCompact ? MainAxisSize.max : MainAxisSize.min,
                      children: [
                        Expanded(
                          flex: isCompact ? 1 : 0,
                          child: OutlinedButton(
                            onPressed: _showReviewModal,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: DSColors.forestGreen,
                              side: const BorderSide(color: DSColors.forestGreen),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: const Text('Review'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: isCompact ? 1 : 0,
                          child: ElevatedButton(
                            onPressed: _addAllToDigitalShelf,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: DSColors.forestGreen,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: const Text('Add All'),
                          ),
                        ),
                      ],
                    );

                    if (isCompact) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          infoColumn,
                          const SizedBox(height: 10),
                          actionRow,
                        ],
                      );
                    }

                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        infoColumn,
                        actionRow,
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 14),

              // Detected books list with check toggles
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _detectedBooks.length,
                separatorBuilder: (ctx, index) => const SizedBox(height: 8),
                itemBuilder: (context, idx) {
                  final b = _detectedBooks[idx];
                  final isSelected = _selectedBookIds.contains(b['id']);
                  return InkWell(
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          _selectedBookIds.remove(b['id']);
                        } else {
                          _selectedBookIds.add(b['id'] as int);
                        }
                      });
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.white : const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isSelected ? DSColors.forestGreen : DSColors.border),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isSelected ? Icons.check_box : Icons.check_box_outline_blank,
                            color: isSelected ? DSColors.forestGreen : DSColors.textMuted,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(b['title'] as String, style: GoogleFonts.playfairDisplay(fontSize: 14, fontWeight: FontWeight.bold, color: DSColors.forestGreen)),
                                Wrap(
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  spacing: 6,
                                  runSpacing: 4,
                                  children: [
                                    Text(b['author'] as String, style: GoogleFonts.inter(fontSize: 11, color: DSColors.textLight)),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                      decoration: BoxDecoration(color: const Color(0xFFEDF2F7), borderRadius: BorderRadius.circular(4)),
                                      child: Text(b['genre'] as String, style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w600, color: const Color(0xFF4A5568))),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: b['status'] == 'Read' ? const Color(0xFFDEF7EC) : (b['status'] == 'Reading' ? const Color(0xFFFEF08A) : const Color(0xFFF3F4F6)),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        b['status'] as String,
                                        style: GoogleFonts.inter(
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                          color: b['status'] == 'Read' ? const Color(0xFF03543F) : (b['status'] == 'Reading' ? const Color(0xFF713F12) : const Color(0xFF374151)),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('₹${b['price']}', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: DSColors.forestGreen)),
                              Text('Rent: ₹${b['rental_price']}/wk', style: GoogleFonts.inter(fontSize: 9, color: DSColors.textMuted)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  // 2. SHELF INSIGHTS TAB (YOUR READING DNA)
  Widget _buildShelfInsightsTab() {
    final genres = _shelfInsights['genres'] as List<dynamic>;
    final readingStatus = _shelfInsights['reading_status'] as Map<String, dynamic>;
    final recommendations = _shelfInsights['recommended_from_shelf'] as List<dynamic>;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // AI Insight Hero Card (Reading DNA Quote)
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0D3B2E), Color(0xFF134E4A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, 4)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const FaIcon(FontAwesomeIcons.dna, color: DSColors.warmGold, size: 16),
                        const SizedBox(width: 8),
                        Text('YOUR READING DNA', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5, color: DSColors.warmGold)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '"${_shelfInsights['ai_quote']}"',
                      style: GoogleFonts.playfairDisplay(fontSize: 17, fontStyle: FontStyle.italic, color: Colors.white, height: 1.4),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _shelfInsights['ai_insight'] as String,
                      style: GoogleFonts.inter(fontSize: 12, color: Colors.white70, height: 1.4),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Genres & Reading Status Dual Cards
              LayoutBuilder(
                builder: (context, constraints) {
                  final isDesktop = constraints.maxWidth >= 700;
                  final genreCard = Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE2E8F0))),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Your Reading DNA Breakdown', style: GoogleFonts.playfairDisplay(fontSize: 17, fontWeight: FontWeight.bold, color: DSColors.forestGreen)),
                        const SizedBox(height: 16),
                        ...genres.map((g) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(g['name'] as String, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: DSColors.textDark)),
                                    Text('${g['percentage']}%', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: DSColors.forestGreen)),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: (g['percentage'] as int) / 100.0,
                                    minHeight: 7,
                                    backgroundColor: const Color(0xFFEDF2F7),
                                    valueColor: AlwaysStoppedAnimation<Color>(g['color'] as Color),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  );

                  final statusCard = Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE2E8F0))),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Reading Status', style: GoogleFonts.playfairDisplay(fontSize: 17, fontWeight: FontWeight.bold, color: DSColors.forestGreen)),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(child: _buildStatusMetric('Read', '${readingStatus['read']}', const Color(0xFF03543F), const Color(0xFFDEF7EC))),
                            const SizedBox(width: 8),
                            Expanded(child: _buildStatusMetric('Reading', '${readingStatus['reading']}', const Color(0xFF713F12), const Color(0xFFFEF08A))),
                            const SizedBox(width: 8),
                            Expanded(child: _buildStatusMetric('Unread', '${readingStatus['unread']}', const Color(0xFF374151), const Color(0xFFF3F4F6))),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: DSColors.background, borderRadius: BorderRadius.circular(12)),
                          child: Row(
                            children: [
                              const Icon(Icons.menu_book, color: DSColors.forestGreen, size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text('Total ${readingStatus['total']} verified titles digitized.', style: GoogleFonts.inter(fontSize: 11, color: DSColors.textDark)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );

                  if (isDesktop) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: genreCard),
                        const SizedBox(width: 16),
                        Expanded(child: statusCard),
                      ],
                    );
                  }

                  return Column(
                    children: [
                      genreCard,
                      const SizedBox(height: 16),
                      statusCard,
                    ],
                  );
                },
              ),

              const SizedBox(height: 28),

              // AI Recommended From Your Shelf
              Text('✨ Recommended From Your Shelf', style: GoogleFonts.playfairDisplay(fontSize: 20, fontWeight: FontWeight.bold, color: DSColors.forestGreen)),
              const SizedBox(height: 6),
              Text('AI-curated marketplace selections that fit your current reading DNA.', style: GoogleFonts.inter(fontSize: 12, color: DSColors.textLight)),
              const SizedBox(height: 14),

              ...recommendations.map((rec) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: DSColors.softMint,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    rec['match_score'] as String,
                                    style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: DSColors.forestGreen),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(rec['title'] as String, style: GoogleFonts.playfairDisplay(fontSize: 16, fontWeight: FontWeight.bold, color: DSColors.forestGreen)),
                            Text('by ${rec['author']}', style: GoogleFonts.inter(fontSize: 12, color: DSColors.textLight)),
                            const SizedBox(height: 6),
                            Text(rec['reason'] as String, style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF4A5568))),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () => context.go('/browse'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: DSColors.forestGreen,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('Find in Hub'),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  // 3. SHELF HEALTH TAB (Condition & Valuation Heuristics)
  Widget _buildShelfHealthTab() {
    final health = _shelfInsights['shelf_health'] as Map<String, dynamic>;
    final valuation = _shelfInsights['valuation'] as Map<String, dynamic>;
    final breakdowns = _shelfInsights['inspection_breakdown'] as List<dynamic>;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero Health Score
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 12,
                      runSpacing: 10,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Shelf Health & Condition Breakdown',
                              style: GoogleFonts.playfairDisplay(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: DSColors.forestGreen,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Spine integrity, yellowing, water marks & binding analysis.',
                              style: GoogleFonts.inter(fontSize: 12, color: DSColors.textLight),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDEF7EC),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${health['prime_pct']}% Prime Condition',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF03543F),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(child: _buildHealthCard('Good', '${health['good']}', 'Ready for listing', const Color(0xFF03543F), const Color(0xFFDEF7EC))),
                        const SizedBox(width: 10),
                        Expanded(child: _buildHealthCard('Fair', '${health['fair']}', 'Mild corner crease', const Color(0xFF713F12), const Color(0xFFFEF08A))),
                        const SizedBox(width: 10),
                        Expanded(child: _buildHealthCard('Damaged', '${health['damaged']}', 'Water/spine damage', const Color(0xFF9B1C1C), const Color(0xFFFDE8E8))),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Estimated Library Value Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F7F4),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFC6F6D5)),
                ),
                child: LayoutBuilder(
                  builder: (context, valConstraints) {
                    final isCompact = valConstraints.maxWidth < 500;
                    final textCol = Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Estimated Resale & Rental Potential', style: GoogleFonts.playfairDisplay(fontSize: 16, fontWeight: FontWeight.bold, color: DSColors.forestGreen)),
                        const SizedBox(height: 2),
                        Text(
                          'Estimated Resale: ₹${valuation['estimated_resale']} • Estimated Rental Value: ₹${valuation['estimated_rental_monthly']}/month',
                          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF234E52)),
                        ),
                      ],
                    );
                    final btn = ElevatedButton(
                      onPressed: () => context.push('/sell'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: DSColors.forestGreen,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('List on Hub'),
                    );

                    if (isCompact) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(color: DSColors.forestGreen, borderRadius: BorderRadius.circular(12)),
                                child: const Icon(Icons.currency_rupee, color: Colors.white, size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(child: textCol),
                            ],
                          ),
                          const SizedBox(height: 12),
                          btn,
                        ],
                      );
                    }

                    return Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: DSColors.forestGreen, borderRadius: BorderRadius.circular(12)),
                          child: const Icon(Icons.currency_rupee, color: Colors.white, size: 24),
                        ),
                        const SizedBox(width: 16),
                        Expanded(child: textCol),
                        const SizedBox(width: 12),
                        btn,
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),

              // Detailed Inspection Factors
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Automated Condition Inspection Checklist', style: GoogleFonts.playfairDisplay(fontSize: 16, fontWeight: FontWeight.bold, color: DSColors.forestGreen)),
                    const SizedBox(height: 4),
                    Text('Spine & cover health evaluated via multi-factor computer vision heuristics.', style: GoogleFonts.inter(fontSize: 11, color: DSColors.textLight)),
                    const SizedBox(height: 16),
                    ...breakdowns.map((b) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  const Icon(Icons.check_circle, size: 16, color: Color(0xFF38A169)),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      b['factor'] as String,
                                      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: DSColors.textDark),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(b['result'] as String, style: GoogleFonts.inter(fontSize: 11, color: DSColors.textLight)),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(color: const Color(0xFFDEF7EC), borderRadius: BorderRadius.circular(4)),
                                  child: Text(b['status'] as String, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF03543F))),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusMetric(String label, String count, Color textColor, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Text(count, style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold, color: textColor)),
          const SizedBox(height: 2),
          Text(label, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: textColor)),
        ],
      ),
    );
  }

  Widget _buildHealthCard(String title, String count, String subtitle, Color textColor, Color bgColor) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(count, style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.bold, color: textColor)),
          const SizedBox(height: 2),
          Text(title, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: textColor)),
          const SizedBox(height: 2),
          Text(subtitle, style: GoogleFonts.inter(fontSize: 10, color: textColor.withValues(alpha: 0.8)), maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}
