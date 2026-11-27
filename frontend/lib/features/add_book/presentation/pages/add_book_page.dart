import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/tokens/app_tokens.dart';
import 'package:libri_flow/core/widgets/ivory_scaffold.dart';
import '../widgets/listing_type_selector.dart';
import '../widgets/condition_selector.dart';
import '../widgets/live_book_preview.dart';
import '../widgets/modern_image_uploader.dart';

class AddBookPage extends StatefulWidget {
  const AddBookPage({super.key});

  @override
  State<AddBookPage> createState() => _AddBookPageState();
}

class _AddBookPageState extends State<AddBookPage> {
  int _currentStep = 0;
  final _formKey = GlobalKey<FormState>();

  // Form Controllers
  final _titleController = TextEditingController();
  final _authorController = TextEditingController();
  final _isbnController = TextEditingController();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _houseNumberController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _postcodeController = TextEditingController();
  
  // State variables
  String? _coverUrl;
  bool _isFetchingIsbn = false;
  bool _isDetectingLocation = false;
  String _selectedCategory = 'Fiction';
  String _selectedCondition = 'Like New';
  String _selectedListingType = 'Sell';
  List<XFile> _selectedImages = [];
  bool _isLoading = false;

  final List<String> _categories = [
    'Textbooks', 'Fiction', 'Non-Fiction', 'Technology', 'Psychology', 'Romance', 'Science Fiction'
  ];

  @override
  void initState() {
    super.initState();
    // Add listeners to trigger live preview rebuilds
    _titleController.addListener(() => setState(() {}));
    _authorController.addListener(() => setState(() {}));
    _priceController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    _isbnController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    _houseNumberController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _postcodeController.dispose();
    super.dispose();
  }

  Future<void> _fetchBookByISBN() async {
    final isbn = _isbnController.text.trim();
    if (isbn.isEmpty) return;

    setState(() => _isFetchingIsbn = true);

    try {
      final response = await http.get(Uri.parse('https://openlibrary.org/api/books?bibkeys=ISBN:$isbn&jscmd=data&format=json'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final bookKey = 'ISBN:$isbn';
        
        if (data.containsKey(bookKey)) {
          final bookData = data[bookKey];
          setState(() {
            _titleController.text = bookData['title'] ?? '';
            
            if (bookData['authors'] != null && (bookData['authors'] as List).isNotEmpty) {
              _authorController.text = (bookData['authors'] as List).map((a) => a['name']).join(', ');
            }
            
            if (bookData['cover'] != null) {
              _coverUrl = bookData['cover']['large'] ?? bookData['cover']['medium'];
            }
          });
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No book found for this ISBN.')));
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error fetching book: ${response.statusCode}')));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Network error: Could not fetch book.')));
      }
    } finally {
      if (mounted) setState(() => _isFetchingIsbn = false);
    }
  }

  Future<void> _detectLocation() async {
    setState(() => _isDetectingLocation = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied');
      }

      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      
      // Use OpenStreetMap Nominatim for reliable reverse geocoding (works on Web!)
      final response = await http.get(Uri.parse(
          'https://nominatim.openstreetmap.org/reverse?lat=${position.latitude}&lon=${position.longitude}&format=json'),
          headers: {'User-Agent': 'TactileArchiveApp/1.0'});
          
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final address = data['address'];
        if (address != null) {
          final road = address['road'] ?? address['suburb'] ?? '';
          final houseNumber = address['house_number'] ?? '';
          final city = address['city'] ?? address['town'] ?? address['village'] ?? '';
          final state = address['state'] ?? '';
          final postcode = address['postcode'] ?? '';
          
          setState(() {
            _houseNumberController.text = houseNumber.isNotEmpty ? '$houseNumber $road' : road;
            _cityController.text = city;
            _stateController.text = state;
            _postcodeController.text = postcode;
          });
        }
      } else {
        setState(() {
          _houseNumberController.text = 'Lat: ${position.latitude.toStringAsFixed(4)}, Lng: ${position.longitude.toStringAsFixed(4)}';
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _isDetectingLocation = false);
    }
  }

  void _nextStep() {
    if (_currentStep < 4) {
      if (_currentStep == 0 && !_formKey.currentState!.validate()) return;
      setState(() => _currentStep++);
    } else {
      _submitForm();
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    try {
      final addressParts = [
        _houseNumberController.text,
        _cityController.text,
        _stateController.text,
        _postcodeController.text
      ].where((e) => e.trim().isNotEmpty).join(', ');
      
      List<String> uploadedImageUrls = [];
      if (_selectedImages.isNotEmpty) {
        final imagePayloads = <Map<String, dynamic>>[];
        for (final x in _selectedImages) {
          final bytes = await x.readAsBytes();
          imagePayloads.add({'name': x.name, 'bytes': bytes});
        }
        uploadedImageUrls = await ApiService.uploadBookImageBytes(imagePayloads);
      }
      
      await sl<ApiClient>().postJson(
        "/books",
        body: {
          "title": _titleController.text,
          "author": _authorController.text,
          "isbn": _isbnController.text,
          "category": _selectedCategory,
          "condition": _selectedCondition,
          "price": double.tryParse(_priceController.text) ?? 0.0,
          "description": _descriptionController.text,
          "listingType": _selectedListingType,
          "coverUrl": uploadedImageUrls.isNotEmpty ? uploadedImageUrls.first : (_coverUrl ?? ""),
          "pickupAddress": addressParts,
          "images": uploadedImageUrls,
        },
      );

      if (mounted) {
        // ApiClient throws an exception if the status is not 200/201, 
        // so if we reach here, the book was added successfully!
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Book listed successfully!'),
            backgroundColor: AppColors.primary,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return IvoryScaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth >= 1024;
          
          return Column(
            children: [
              // Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(bottom: BorderSide(color: AppColors.outline.withOpacity(0.1))),
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1200),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'List a Book',
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Turn your physical books into cash, rentals, or community loans.',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 32),
                        _buildStepIndicator(isDesktop),
                      ],
                    ),
                  ),
                ),
              ),
              // Main Content
              isDesktop
                  ? Container(
                      color: const Color(0xFFF9FAFB),
                      width: double.infinity,
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1200),
                          child: Padding(
                            padding: const EdgeInsets.all(32.0),
                            child: Form(
                              key: _formKey,
                              child: _buildDesktopLayout(),
                            ),
                          ),
                        ),
                      ),
                    )
                  : Expanded(
                      child: Container(
                        color: const Color(0xFFF9FAFB),
                        width: double.infinity,
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 1200),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Form(
                                key: _formKey,
                                child: _buildMobileLayout(),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStepIndicator(bool isDesktop) {
    final steps = ['Basic Details', 'Condition', 'Images', 'Pricing', 'Publish'];
    return Row(
      children: List.generate(steps.length, (index) {
        final isActive = index <= _currentStep;
        return Expanded(
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isActive ? AppColors.tertiary : Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isActive ? AppColors.tertiary : AppColors.outline.withOpacity(0.3),
                  ),
                ),
                child: Center(
                  child: isActive && index < _currentStep
                      ? const FaIcon(FontAwesomeIcons.check, size: 14, color: AppColors.primary)
                      : Text(
                          '${index + 1}',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.bold,
                            color: isActive ? AppColors.primary : AppColors.onSurfaceVariant,
                          ),
                        ),
                ),
              ),
              if (isDesktop) const SizedBox(width: 12),
              if (isDesktop)
                Text(
                  steps[index],
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    color: isActive ? AppColors.primary : AppColors.onSurfaceVariant,
                  ),
                ),
              if (index < steps.length - 1)
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    height: 2,
                    color: isActive ? AppColors.tertiary : AppColors.outline.withOpacity(0.1),
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left Column (Form)
        Expanded(
          flex: 6,
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCurrentStep(),
                const SizedBox(height: 32),
                _buildFormActions(),
              ],
            ),
          ),
        ),
        const SizedBox(width: 48),
        // Right Column (Live Preview)
        Expanded(
          flex: 4,
          child: Column(
            children: [
              LiveBookPreview(
                title: _titleController.text,
                author: _authorController.text,
                category: _selectedCategory,
                condition: _selectedCondition,
                price: double.tryParse(_priceController.text) ?? 0.0,
                listingType: _selectedListingType,
                coverImagePath: _coverUrl,
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const FaIcon(FontAwesomeIcons.circleInfo, color: AppColors.primary, size: 16),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'This is how your book will appear to buyers. Make sure the cover is clear and details are accurate.',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: _buildCurrentStep(),
            ),
          ),
          const SizedBox(height: 24),
          _buildFormActions(),
        ],
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _buildStep1BasicDetails();
      case 1:
        return _buildStep2Condition();
      case 2:
        return _buildStep3Images();
      case 3:
        return _buildStep4Pricing();
      case 4:
        return _buildStep5Publish();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildStep1BasicDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Basic Details', style: GoogleFonts.playfairDisplay(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primary)),
        const SizedBox(height: 24),
        ListingTypeSelector(
          selectedType: _selectedListingType,
          onChanged: (val) => setState(() => _selectedListingType = val),
        ),
        const SizedBox(height: 32),
        _buildTextField(
          label: 'Book Title',
          controller: _titleController,
          hintText: 'E.g., The Great Gatsby',
          validator: (val) => val == null || val.isEmpty ? 'Title is required' : null,
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                label: 'Author',
                controller: _authorController,
                hintText: 'Author Name',
                validator: (val) => val == null || val.isEmpty ? 'Author is required' : null,
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: _buildTextField(
                label: 'ISBN (Optional)',
                controller: _isbnController,
                hintText: '10 or 13 digits',
                suffixIcon: IconButton(
                  icon: _isFetchingIsbn 
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) 
                      : const FaIcon(FontAwesomeIcons.wandMagicSparkles, size: 16, color: AppColors.primary),
                  onPressed: _isFetchingIsbn ? null : _fetchBookByISBN,
                  tooltip: 'Auto-fill details',
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        _buildDropdownField(
          label: 'Category',
          value: _selectedCategory,
          items: _categories,
          onChanged: (val) => setState(() => _selectedCategory = val!),
        ),
        const SizedBox(height: 24),
        _buildTextField(
          label: 'Description',
          controller: _descriptionController,
          hintText: 'Provide a brief summary and note any specific flaws.',
          maxLines: 4,
        ),
      ],
    );
  }

  Widget _buildStep2Condition() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Book Condition', style: GoogleFonts.playfairDisplay(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primary)),
        const SizedBox(height: 24),
        ConditionSelector(
          selectedCondition: _selectedCondition,
          onChanged: (val) => setState(() => _selectedCondition = val),
        ),
        const SizedBox(height: 32),
        _buildTextField(
          label: 'Additional Condition Notes (Optional)',
          controller: TextEditingController(), // Placeholder
          hintText: 'E.g., Highlighting on chapter 2, slightly bent corner.',
          maxLines: 3,
        ),
      ],
    );
  }

  Widget _buildStep3Images() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Images', style: GoogleFonts.playfairDisplay(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primary)),
        const SizedBox(height: 24),
        ModernImageUploader(
          images: _selectedImages,
          onImagesChanged: (imgs) => setState(() => _selectedImages = imgs),
        ),
      ],
    );
  }

  Widget _buildStep4Pricing() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Pricing & Delivery', style: GoogleFonts.playfairDisplay(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primary)),
        const SizedBox(height: 24),
        if (_selectedListingType == 'Borrow')
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.tertiary.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
            child: Text('Borrowing is free for the community. You are helping build a better reading culture!', style: GoogleFonts.inter(color: AppColors.primary)),
          )
        else
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  label: _selectedListingType == 'Rent' ? 'Rental Price per Week' : 'Selling Price',
                  controller: _priceController,
                  hintText: '0.00',
                  prefixText: '\$ ',
                  keyboardType: TextInputType.number,
                  validator: (val) => val == null || val.isEmpty ? 'Price is required' : null,
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: AppColors.surfaceContainerHighest, borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Suggested Price', style: GoogleFonts.inter(fontSize: 12, color: AppColors.onSurfaceVariant)),
                      const SizedBox(height: 4),
                      Text('\$12.00 - \$15.00', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: AppColors.primary)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        const SizedBox(height: 32),
        Text('Delivery Method', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 16,
          children: [
            Chip(label: const Text('Local Pickup'), backgroundColor: AppColors.primary.withOpacity(0.1), labelStyle: const TextStyle(color: AppColors.primary)),
            const Chip(label: Text('Shipping (Coming Soon)'), backgroundColor: Color(0xFFEEEEEE)),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Pickup Address', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
            TextButton.icon(
              icon: _isDetectingLocation 
                  ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                  : const FaIcon(FontAwesomeIcons.locationCrosshairs, size: 14, color: AppColors.primary),
              label: Text('Auto-Detect Location', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
              onPressed: _isDetectingLocation ? null : _detectLocation,
            )
          ],
        ),
        const SizedBox(height: 12),
        _buildTextField(
          label: 'House No. & Street',
          controller: _houseNumberController,
          hintText: 'e.g. 123 Main St',
          validator: (val) => val == null || val.isEmpty ? 'Required' : null,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                label: 'City',
                controller: _cityController,
                hintText: 'City',
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildTextField(
                label: 'State',
                controller: _stateController,
                hintText: 'State',
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildTextField(
          label: 'Postcode',
          controller: _postcodeController,
          hintText: 'ZIP or Postcode',
          validator: (val) => val == null || val.isEmpty ? 'Required' : null,
        ),
      ],
    );
  }

  Widget _buildStep5Publish() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 40),
        const FaIcon(FontAwesomeIcons.rocket, size: 64, color: AppColors.tertiary),
        const SizedBox(height: 24),
        Text('Ready to Publish!', style: GoogleFonts.playfairDisplay(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.primary)),
        const SizedBox(height: 16),
        Text('Please review your listing details in the live preview panel on the right. Once you publish, your book will immediately be visible to the community.', textAlign: TextAlign.center, style: GoogleFonts.inter(color: AppColors.onSurfaceVariant, fontSize: 16)),
      ],
    );
  }

  Widget _buildFormActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (_currentStep > 0)
          TextButton(
            onPressed: _prevStep,
            style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20)),
            child: Text('Back', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppColors.onSurfaceVariant)),
          )
        else
          const SizedBox.shrink(),
        ElevatedButton(
          onPressed: _isLoading ? null : _nextStep,
          style: ElevatedButton.styleFrom(
            backgroundColor: _currentStep == 4 ? AppColors.tertiary : AppColors.primary,
            foregroundColor: _currentStep == 4 ? AppColors.primary : Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
          ),
          child: _isLoading
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : Text(
                  _currentStep == 4 ? 'Publish Listing' : 'Next Step',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w700),
                ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    String? hintText,
    String? prefixText,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    Widget? suffixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppColors.primary, fontSize: 14)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          validator: validator,
          style: GoogleFonts.inter(fontSize: 15),
          decoration: InputDecoration(
            hintText: hintText,
            prefixText: prefixText,
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: AppColors.surfaceContainerHighest.withOpacity(0.3),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.outline.withOpacity(0.2))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.outline.withOpacity(0.2))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String value,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppColors.primary, fontSize: 14)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerHighest.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.outline.withOpacity(0.2)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              icon: const FaIcon(FontAwesomeIcons.chevronDown, size: 14),
              items: items.map((item) => DropdownMenuItem(value: item, child: Text(item, style: GoogleFonts.inter(fontSize: 15)))).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}
