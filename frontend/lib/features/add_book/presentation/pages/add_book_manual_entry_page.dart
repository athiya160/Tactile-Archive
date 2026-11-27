import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:libri_flow/core/widgets/ivory_scaffold.dart';
import 'package:libri_flow/core/design_system/design_system.dart';
import 'package:libri_flow/core/utils/app_constants.dart';
import '../../../../core/services/api_service.dart';
import '../../../home/domain/entities/book.dart';
import '../bloc/add_book_bloc.dart';
import '../widgets/category_chip_group.dart';
import '../../domain/entities/book_copy.dart' as copy;

class AddBookManualEntryPage extends StatefulWidget {
  const AddBookManualEntryPage({super.key});

  @override
  State<AddBookManualEntryPage> createState() => _AddBookManualEntryPageState();
}

class _AddBookManualEntryPageState extends State<AddBookManualEntryPage> {
  late final TextEditingController _isbnController;
  late final TextEditingController _titleController;
  late final TextEditingController _authorController;
  late final TextEditingController _descController;
  late final TextEditingController _publisherController;
  late final TextEditingController _yearController;
  late final TextEditingController _pagesController;
  late final TextEditingController _langController;
  late final TextEditingController _priceController;

  String? _selectedCategory;
  copy.BookCondition _selectedCondition = copy.BookCondition.good;
  String _coverUrl = '';

  @override
  void initState() {
    super.initState();
    final state = context.read<AddBookBloc>().state;

    _isbnController = TextEditingController(text: state.draft.book?.isbn ?? state.isbn);
    _titleController = TextEditingController(text: state.draft.book?.title);
    _authorController = TextEditingController(text: state.draft.book?.author);
    _descController = TextEditingController(text: state.draft.book?.description);
    _publisherController = TextEditingController(text: state.draft.book?.publisher);
    _yearController = TextEditingController(text: state.draft.book?.edition);
    _pagesController = TextEditingController(text: state.draft.book?.pages);
    _langController = TextEditingController(text: state.draft.book?.language);
    _priceController = TextEditingController(text: (state.draft.book?.price ?? 0.0).toString());

    _selectedCategory = state.draft.category ??
        (state.draft.book?.categories.isNotEmpty == true
            ? state.draft.book?.categories.first
            : null);

    _coverUrl = state.draft.book?.coverUrl ?? '';
  }

  @override
  void dispose() {
    _isbnController.dispose();
    _titleController.dispose();
    _authorController.dispose();
    _descController.dispose();
    _publisherController.dispose();
    _yearController.dispose();
    _pagesController.dispose();
    _langController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadCoverImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      if (image == null) return;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                CircularProgressIndicator(color: Colors.white),
                SizedBox(width: 16),
                Expanded(child: Text("Uploading cover photo to Tactile Archive...")),
              ],
            ),
            duration: Duration(seconds: 10),
          ),
        );
      }

      final uri = Uri.parse('${ApiService.baseUrl}/uploads/image');
      final request = http.MultipartRequest('POST', uri);

      if (ApiService.token != null) {
        request.headers['Authorization'] = 'Bearer ${ApiService.token}';
      }

      final bytes = await image.readAsBytes();
      String filename = image.name;
      if (!filename.contains('.')) {
        filename = '$filename.jpeg';
      }
      final extension = filename.split('.').last.toLowerCase();
      MediaType mediaType;
      if (extension == 'png') {
        mediaType = MediaType('image', 'png');
      } else if (extension == 'jpg' || extension == 'jpeg') {
        mediaType = MediaType('image', 'jpeg');
      } else if (extension == 'gif') {
        mediaType = MediaType('image', 'gif');
      } else if (extension == 'webp') {
        mediaType = MediaType('image', 'webp');
      } else {
        mediaType = MediaType('image', 'jpeg');
      }

      final multipartFile = http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: filename,
        contentType: mediaType,
      );
      request.files.add(multipartFile);

      final streamedResponse = await request.send().timeout(const Duration(seconds: 25));
      final response = await http.Response.fromStream(streamedResponse);

      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final String? url = data['url'];
        if (url != null) {
          setState(() {
            _coverUrl = url;
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Cover photo uploaded successfully!'),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return IvoryScaffold(
      title: 'Book Details',
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Navigator.of(context).pop(),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.only(
          top: 100 + MediaQuery.of(context).padding.top,
          left: DSSpacing.lg,
          right: DSSpacing.lg,
          bottom: DSSpacing.xxl,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Center(
              child: Column(
                children: [
                  Text(
                    'Sell a Book',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontFamily: 'Playfair Display',
                          fontWeight: FontWeight.bold,
                          fontSize: 40,
                          color: const Color(0xFF1A1A1A),
                        ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Give your book a second life. Fill out the details below to list it for sale, rent, or borrowing.',
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF757575),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 48),

            // Form container
            Container(
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _InputField(
                          label: 'Book Title',
                          controller: _titleController,
                          hint: 'Enter the exact title',
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: _InputField(
                          label: 'Author',
                          controller: _authorController,
                          hint: 'Author\'s name',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  Row(
                    children: [
                      Expanded(
                        child: _InputField(
                          label: 'ISBN',
                          controller: _isbnController,
                          hint: 'e.g. 978-3-16-148410-0',
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: _InputField(
                          label: 'Publisher',
                          controller: _publisherController,
                          hint: 'Penguin Books',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  Row(
                    children: [
                      Expanded(
                        child: _InputField(
                          label: 'Edition / Year',
                          controller: _yearController,
                          hint: '2021',
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: _InputField(
                          label: 'Language',
                          controller: _langController,
                          hint: 'English',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Category',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF0B3D2E),
                              ),
                            ),
                            const SizedBox(height: 8),
                            CategoryChipGroup(
                              categories: AppConstants.bookCategories,
                              selectedCategory: _selectedCategory,
                              onSelected: (category) {
                                setState(() => _selectedCategory = category);
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  Row(
                    children: [
                      Expanded(
                        child: _InputField(
                          label: 'Price (₹)',
                          controller: _priceController,
                          hint: 'e.g. 250.00',
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: _InputField(
                          label: 'Pages',
                          controller: _pagesController,
                          hint: 'e.g. 350',
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  const Text(
                    'Condition',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0B3D2E),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: copy.BookCondition.values.map((v) {
                        final isSelected = _selectedCondition == v;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(v.label),
                            selected: isSelected,
                            onSelected: (selected) {
                              if (selected) {
                                setState(() => _selectedCondition = v);
                              }
                            },
                            backgroundColor: Colors.white,
                            selectedColor: const Color(0xFF0B3D2E),
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : const Color(0xFF4A4A4A),
                              fontWeight: FontWeight.bold,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: BorderSide(
                                color: isSelected ? Colors.transparent : const Color(0xFFDDDDDD),
                              ),
                            ),
                            showCheckmark: false,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 24),

                  _InputField(
                    label: 'Description',
                    controller: _descController,
                    hint: 'Describe the book, any highlights, marks, or why you loved it...',
                    maxLines: 5,
                  ),
                  const SizedBox(height: 24),

                  const Text(
                    'Upload Book Images',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0B3D2E),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: _coverUrl.isNotEmpty
                        ? GestureDetector(
                            onTap: _pickAndUploadCoverImage,
                            child: Container(
                              height: 250,
                              width: 170,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                image: DecorationImage(
                                  image: NetworkImage(_coverUrl),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          )
                        : GestureDetector(
                            onTap: _pickAndUploadCoverImage,
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 48),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF9F9F9),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFFDDDDDD), width: 2),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(
                                    Icons.cloud_upload_outlined,
                                    size: 48,
                                    color: Color(0xFFBDBDBD),
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    'Drag and drop images here, or click to browse',
                                    style: TextStyle(color: Color(0xFF757575), fontSize: 16),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Supports JPG, PNG, WEBP (Max 5MB)',
                                    style: TextStyle(color: Color(0xFF9E9E9E), fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ),
                  ),
                  const SizedBox(height: 32),

                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [DSColors.primary, DSColors.primaryHover]),
                      borderRadius: BorderRadius.circular(DSRadius.lg),
                      boxShadow: DSShadows.md,
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          if (_selectedCategory == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please select a category'),
                              ),
                            );
                            return;
                          }

                          final double price = double.tryParse(_priceController.text) ?? 0.0;
                          context.read<AddBookBloc>().add(
                                AddBookManualBookSubmitted(
                                  title: _titleController.text,
                                  author: _authorController.text,
                                  description: _descController.text,
                                  category: _selectedCategory!,
                                  publisher: _publisherController.text,
                                  year: _yearController.text,
                                  pages: _pagesController.text,
                                  language: _langController.text,
                                  isbn: _isbnController.text,
                                  price: price,
                                  condition: _selectedCondition,
                                  coverUrl: _coverUrl,
                                ),
                              );

                          final currentDraft = context.read<AddBookBloc>().state.draft;
                          final updatedDraft = currentDraft.copyWith(
                            book: Book(
                              id: 'manual_${DateTime.now().millisecondsSinceEpoch}',
                              title: _titleController.text,
                              author: _authorController.text,
                              description: _descController.text,
                              categories: [_selectedCategory!],
                              publisher: _publisherController.text,
                              edition: _yearController.text,
                              pages: _pagesController.text,
                              language: _langController.text,
                              isbn: _isbnController.text,
                              coverUrl: _coverUrl,
                              listingType: ListingType.forSale,
                              rating: 0,
                            ),
                            category: _selectedCategory!,
                            isbn: _isbnController.text,
                            copies: [
                              copy.BookCopy(
                                id: 'copy_${DateTime.now().millisecondsSinceEpoch}',
                                condition: _selectedCondition,
                                listingType: copy.ListingType.sell,
                                price: price,
                              ),
                            ],
                          );
                          context.push(
                            '/add-book/step-2',
                            extra: updatedDraft,
                          );
                        },
                        borderRadius: BorderRadius.circular(DSRadius.lg),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: DSSpacing.md),
                          child: Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.campaign, color: Colors.white, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'Publish Listing',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
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
          ],
        ),
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String hint;
  final int maxLines;
  final TextInputType keyboardType;

  const _InputField({
    required this.label,
    required this.controller,
    required this.hint,
    this.maxLines = 1,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF0B3D2E),
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF9F9F9),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: const Color(0xFFDDDDDD)),
          ),
          child: TextField(
            controller: controller,
            maxLines: maxLines,
            keyboardType: keyboardType,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(
                color: Color(0xFF9E9E9E),
                fontSize: 16,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: InputBorder.none,
            ),
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF1A1A1A),
            ),
          ),
        ),
      ],
    );
  }
}
