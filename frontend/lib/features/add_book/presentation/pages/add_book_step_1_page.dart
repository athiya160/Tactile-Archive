import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../../../../core/services/api_service.dart';
import 'package:libri_flow/core/widgets/tactile_footer.dart';
import '../../domain/entities/book_copy.dart' as copy;
import 'package:libri_flow/core/design_system/design_system.dart';

class AddBookStep1Page extends StatefulWidget {
  const AddBookStep1Page({super.key});

  @override
  State<AddBookStep1Page> createState() => _AddBookStep1PageState();
}

class _AddBookStep1PageState extends State<AddBookStep1Page> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _authorController = TextEditingController();
  final TextEditingController _isbnController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _descController = TextEditingController();

  String? _selectedCategory;
  copy.BookCondition _selectedCondition = copy.BookCondition.good;
  String _coverUrl = '';

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    _isbnController.dispose();
    _priceController.dispose();
    _descController.dispose();
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
                Expanded(
                  child: Text("Uploading cover photo to Tactile Archive..."),
                ),
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

      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 25),
      );
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
          SnackBar(
            content: Text('Upload failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _handleSubmit() {
    if (_titleController.text.trim().isEmpty ||
        _authorController.text.trim().isEmpty ||
        _selectedCategory == null ||
        _priceController.text.trim().isEmpty ||
        _descController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill out all required fields.')),
      );
      return;
    }

    // Since this is just visual parity with React's Sell form,
    // we'll simulate the "alert('Book listed successfully!')" behavior.
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Success'),
        content: const Text('Book listed successfully!'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.go('/');
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 48.0,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sell a Book',
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(
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
                        ),
                      ],
                    ),
                    const SizedBox(height: 48),

                    // Form container
                    Container(
                      padding: const EdgeInsets.all(40),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: DSColors.primary.withValues(alpha: 0.1),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
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
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: _InputField(
                                  label: 'ISBN',
                                  controller: _isbnController,
                                  hint: 'e.g. 978-3-16-148410-0',
                                  required: false,
                                ),
                              ),
                              const SizedBox(width: 24),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Category',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF1A1A1A),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: const Color(0xFFDDDDDD),
                                        ),
                                      ),
                                      child: DropdownButtonHideUnderline(
                                        child: DropdownButton<String>(
                                          isExpanded: true,
                                          value: _selectedCategory,
                                          hint: const Text(
                                            'Select a category',
                                            style: TextStyle(
                                              color: Color(0xFF9E9E9E),
                                            ),
                                          ),
                                          items:
                                              [
                                                    'Fiction',
                                                    'Technology',
                                                    'Psychology',
                                                    'Textbooks',
                                                    'Romance',
                                                    'Science Fiction',
                                                  ]
                                                  .map(
                                                    (c) => DropdownMenuItem(
                                                      value: c,
                                                      child: Text(c),
                                                    ),
                                                  )
                                                  .toList(),
                                          onChanged: (val) => setState(
                                            () => _selectedCategory = val,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Condition',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF1A1A1A),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: const Color(0xFFDDDDDD),
                                        ),
                                      ),
                                      child: DropdownButtonHideUnderline(
                                        child:
                                            DropdownButton<copy.BookCondition>(
                                              isExpanded: true,
                                              value: _selectedCondition,
                                              items: copy.BookCondition.values
                                                  .map(
                                                    (c) => DropdownMenuItem(
                                                      value: c,
                                                      child: Text(c.label),
                                                    ),
                                                  )
                                                  .toList(),
                                              onChanged: (val) {
                                                if (val != null) {
                                                  setState(
                                                    () => _selectedCondition =
                                                        val,
                                                  );
                                                }
                                              },
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 24),
                              Expanded(
                                child: _InputField(
                                  label: 'Price (\$)',
                                  controller: _priceController,
                                  hint: 'e.g. 15.00',
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          _InputField(
                            label: 'Description',
                            controller: _descController,
                            hint:
                                'Describe the book, any highlights, marks, or why you loved it...',
                            maxLines: 5,
                          ),
                          const SizedBox(height: 24),

                          const Text(
                            'Upload Book Images',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1A1A1A),
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
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 48,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: const Color(0xFFDDDDDD),
                                          width: 1,
                                        ),
                                      ),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          const Icon(
                                            Icons.cloud_upload_outlined,
                                            size: 48,
                                            color: Color(0xFFBDBDBD),
                                          ),
                                          const SizedBox(height: 16),
                                          const Text(
                                            'Drag and drop images here, or click to browse',
                                            style: TextStyle(
                                              color: Color(0xFF757575),
                                              fontSize: 16,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          const Text(
                                            'Supports JPG, PNG, WEBP (Max 5MB)',
                                            style: TextStyle(
                                              color: Color(0xFF9E9E9E),
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                          ),
                          const SizedBox(height: 48),

                          Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: DSColors.primary,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: _handleSubmit,
                                borderRadius: BorderRadius.circular(8),
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 16),
                                  child: Center(
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.campaign,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          'Publish Listing',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
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
            ),
          ),
          const SizedBox(height: 48),
          const TactileFooter(),
        ],
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
  final bool required;

  const _InputField({
    required this.label,
    required this.controller,
    required this.hint,
    this.maxLines = 1,
    this.keyboardType = TextInputType.text,
    this.required = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF1A1A1A),
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
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
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              border: InputBorder.none,
            ),
            style: const TextStyle(fontSize: 16, color: Color(0xFF1A1A1A)),
          ),
        ),
      ],
    );
  }
}
