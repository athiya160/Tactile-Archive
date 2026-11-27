import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:http_parser/http_parser.dart';
import 'package:libri_flow/core/widgets/ivory_scaffold.dart';
import 'package:libri_flow/core/design_system/design_system.dart';
import 'package:libri_flow/core/utils/app_constants.dart';
import '../../../../core/services/api_service.dart';
import '../../../../features/home/presentation/bloc/home_bloc.dart';
import '../bloc/add_book_step_2_bloc.dart';
import '../../domain/entities/book_copy.dart';
import '../widgets/step_indicator.dart';
import '../widgets/category_chip_group.dart';

class AddBookStep2Page extends StatelessWidget {
  const AddBookStep2Page({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AddBookStep2Bloc, AddBookStep2State>(
      listener: (context, state) {
        if (state.status == AddBookStep2Status.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Book added successfully!'),
              backgroundColor: DSColors.primary,
            ),
          );
          context.read<HomeBloc>().add(HomeStarted());
          context.go('/');
        } else if (state.status == AddBookStep2Status.error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.errorMessage ?? 'An error occurred')),
          );
        }
      },
      builder: (context, state) {
        return IvoryScaffold(
          title: 'Add Copies',
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
          body: Stack(
            children: [
              CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: EdgeInsets.only(
                      top: 100 + MediaQuery.of(context).padding.top,
                      left: DSSpacing.lg,
                      right: DSSpacing.lg,
                      bottom: 120, // Space for bottom bar
                    ),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        const StepIndicator(
                          currentStep: 2,
                          totalSteps: 3,
                          title: 'Continue..',
                          progressOverride: 0.33,
                        ),
                        const SizedBox(height: DSSpacing.xxl),
                        _buildInventorySection(context, state),
                        const SizedBox(height: DSSpacing.xl),
                        _buildAddCopyButton(context),
                        const SizedBox(height: DSSpacing.xxl),
                        _buildCuratorialNotesSection(context, state),
                      ]),
                    ),
                  ),
                ],
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: _buildBottomBar(context, state),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInventorySection(BuildContext context, AddBookStep2State state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.inventory_2_outlined,
              size: 20,
              color: DSColors.primary,
            ),
            const SizedBox(width: DSSpacing.sm),
            Text(
              'VOLUME INVENTORY',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: 2.0,
                color: DSColors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: DSSpacing.lg),
        ...state.draft.copies.asMap().entries.map((entry) {
          final index = entry.key;
          final copy = entry.value;
          final isExpanded = state.expandedCopyId == copy.id;
          return Padding(
            padding: const EdgeInsets.only(bottom: DSSpacing.md),
            child: _CopyCard(
              index: index + 1,
              copy: copy,
              isExpanded: isExpanded,
              onToggle: () {
                context.read<AddBookStep2Bloc>().add(
                  AddBookStep2CopyExpansionToggled(copy.id),
                );
              },
              onRemove: () {
                context.read<AddBookStep2Bloc>().add(
                  AddBookStep2RemoveCopyPressed(copy.id),
                );
              },
              onUpdate: (updatedCopy) {
                context.read<AddBookStep2Bloc>().add(
                  AddBookStep2CopyUpdated(updatedCopy),
                );
              },
            ),
          );
        }),
      ],
    );
  }

  Widget _buildAddCopyButton(BuildContext context) {
    return GestureDetector(
      onTap: () {
        context.read<AddBookStep2Bloc>().add(AddBookStep2AddCopyPressed());
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: DSSpacing.lg),
        decoration: BoxDecoration(
          color: DSColors.surface,
          borderRadius: BorderRadius.circular(DSRadius.xl),
          border: Border.all(
            color: DSColors.border.withValues(alpha: 0.2),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.add_circle,
              size: 20,
              color: DSColors.textLight,
            ),
            const SizedBox(width: DSSpacing.sm),
            Text(
              'REGISTER ANOTHER COPY',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
                color: DSColors.textLight,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCuratorialNotesSection(
    BuildContext context,
    AddBookStep2State state,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _LocationAndCategorySection(state: state),
        const SizedBox(height: DSSpacing.xxl),
        Row(
          children: [
            const Icon(
              Icons.edit_note_outlined,
              size: 20,
              color: DSColors.primary,
            ),
            const SizedBox(width: DSSpacing.sm),
            Text(
              'GLOBAL CURATORIAL NOTES',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: 2.0,
                color: DSColors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: DSSpacing.sm),
        Text(
          "Overarching notes about this book's provenance or historical significance.",
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: DSColors.textLight,
            height: 1.5,
          ),
        ),
        const SizedBox(height: DSSpacing.lg),
        Container(
          decoration: BoxDecoration(
            color: DSColors.surface,
            borderRadius: BorderRadius.circular(DSRadius.lg),
          ),
          child: TextField(
            maxLines: 4,
            style: const TextStyle(fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Enter curatorial notes...',
              hintStyle: TextStyle(
                color: DSColors.textLight.withValues(alpha: 0.4),
              ),
              contentPadding: const EdgeInsets.all(DSSpacing.md),
              border: InputBorder.none,
            ),
            onChanged: (v) {
              context.read<AddBookStep2Bloc>().add(
                AddBookStep2CuratorialNotesUpdated(v),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar(BuildContext context, AddBookStep2State state) {
    return Container(
      padding: const EdgeInsets.all(DSSpacing.lg),
      decoration: BoxDecoration(
        color: DSColors.surface.withValues(alpha: 0.95),
        border: Border(
          top: BorderSide(color: DSColors.borderLight, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          TextButton.icon(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.chevron_left, size: 20),
            label: Text(
              'BACK',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
              ),
            ),
            style: TextButton.styleFrom(
              foregroundColor: DSColors.textLight,
            ),
          ),
          const SizedBox(width: DSSpacing.md),
          Expanded(
            child: Container(
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [DSColors.primary, DSColors.primaryHover]),
                borderRadius: BorderRadius.circular(DSRadius.xl),
                boxShadow: DSShadows.md,
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: state.status == AddBookStep2Status.submitting
                      ? null
                      : () {
                          context.read<AddBookStep2Bloc>().add(
                            AddBookStep2FinalizePressed(),
                          );
                        },
                  borderRadius: BorderRadius.circular(DSRadius.xl),
                  child: Center(
                    child: state.status == AddBookStep2Status.submitting
                        ? const CircularProgressIndicator(
                            color: DSColors.textInverse,
                            strokeWidth: 2,
                          )
                        : const Text(
                            'FINALIZE LISTING',
                            style: TextStyle(
                              color: DSColors.textInverse,
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                              letterSpacing: 2.0,
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CopyCard extends StatelessWidget {
  final int index;
  final BookCopy copy;
  final bool isExpanded;
  final VoidCallback onToggle;
  final VoidCallback onRemove;
  final Function(BookCopy) onUpdate;

  const _CopyCard({
    required this.index,
    required this.copy,
    required this.isExpanded,
    required this.onToggle,
    required this.onRemove,
    required this.onUpdate,
  });

  Future<void> _pickAndUploadImage(
    BuildContext context,
    BookCopy copy,
    Function(BookCopy) onUpdate,
  ) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      if (image == null) return;

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                CircularProgressIndicator(color: Colors.white),
                SizedBox(width: 16),
                Expanded(child: Text("Uploading photo to Tactile Archive...")),
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

      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final String? url = data['url'];
        if (url != null) {
          final newPaths = List<String>.from(copy.imagePaths)..add(url);
          onUpdate(copy.copyWith(imagePaths: newPaths));
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Photo uploaded successfully!'),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      if (context.mounted) {
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

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: DSColors.border,
        borderRadius: BorderRadius.circular(DSRadius.xl),
        boxShadow: DSShadows.md,
      ),
      child: Column(
        children: [
          // Header / Collapsed View
          GestureDetector(
            onTap: onToggle,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.all(DSSpacing.lg),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 24,
                    decoration: BoxDecoration(
                      color: DSColors.primary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: DSSpacing.md),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'COPY ${index.toString().padLeft(2, '0')}',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          fontSize: 8,
                          letterSpacing: 1.0,
                          color: DSColors.textLight,
                        ),
                      ),
                      if (!isExpanded)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            '${copy.condition.label} · ${copy.listingType.label}${copy.price != null ? ' · \$${copy.price}' : ''}',
                            style: const TextStyle(
                              fontFamily: 'Manrope',
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: DSColors.primary,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const Spacer(),
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: DSColors.textLight,
                  ),
                ],
              ),
            ),
          ),
          // Expanded View
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                DSSpacing.lg,
                0,
                DSSpacing.lg,
                DSSpacing.lg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(height: 1, color: Colors.black12),
                  const SizedBox(height: DSSpacing.lg),

                  // Media per copy
                  const _Label(text: 'BOOK PAGES (PREVIEW GALLERY)'),
                  const SizedBox(height: 4),
                  const Text(
                    "Upload photos of the book's pages (e.g., table of contents, sample pages) so users can check them before buying/borrowing.",
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 11,
                      color: DSColors.textLight,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: DSSpacing.md),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        // Current Photos
                        ...copy.imagePaths.asMap().entries.map((entry) {
                          final imgIndex = entry.key;
                          final path = entry.value;
                          return Padding(
                            padding: const EdgeInsets.only(
                              right: DSSpacing.sm,
                            ),
                            child: _SmallMediaCard(
                              label: 'PAGE ${imgIndex + 1}',
                              imageUrl: path,
                              onTap: () {
                                showDialog(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('Delete Page Photo'),
                                    content: const Text(
                                      'Are you sure you want to remove this page photo?',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(ctx),
                                        child: const Text(
                                          'Cancel',
                                          style: TextStyle(color: Colors.black),
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          Navigator.pop(ctx);
                                          final newPaths =
                                              List<String>.from(copy.imagePaths)
                                                ..remove(path);
                                          onUpdate(
                                            copy.copyWith(imagePaths: newPaths),
                                          );
                                        },
                                        child: const Text(
                                          'Delete',
                                          style: TextStyle(
                                            color: DSColors.error,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          );
                        }),
                        // Add Button
                        _SmallMediaCard(
                          label: 'ADD PAGE',
                          isPlaceholder: true,
                          onTap: () {
                            _pickAndUploadImage(context, copy, onUpdate);
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: DSSpacing.lg),
                  const _Label(text: 'CONDITION'),
                  const SizedBox(height: DSSpacing.sm),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: BookCondition.values.map((v) {
                        final isSelected = copy.condition == v;
                        return Padding(
                          padding: const EdgeInsets.only(right: DSSpacing.sm),
                          child: ChoiceChip(
                            label: Text(v.label),
                            selected: isSelected,
                            onSelected: (selected) {
                              if (selected) {
                                onUpdate(copy.copyWith(condition: v));
                              }
                            },
                            backgroundColor: DSColors.surface,
                            selectedColor: DSColors.primary,
                            labelStyle: TextStyle(
                              color: isSelected
                                  ? DSColors.textInverse
                                  : DSColors.textDark,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(100.0),
                              side: BorderSide(
                                color: isSelected
                                    ? Colors.transparent
                                    : DSColors.border.withValues(alpha: 0.2),
                              ),
                            ),
                            showCheckmark: false,
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  const SizedBox(height: DSSpacing.lg),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const _Label(text: 'LISTING TYPE'),
                            const SizedBox(height: DSSpacing.sm),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              decoration: BoxDecoration(
                                color: DSColors.surface,
                                borderRadius: BorderRadius.circular(
                                  DSRadius.lg,
                                ),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<ListingType>(
                                  value: copy.listingType,
                                  isExpanded: true,
                                  icon: const Icon(
                                    Icons.keyboard_arrow_down,
                                    size: 20,
                                  ),
                                  items: ListingType.values.map((v) {
                                    return DropdownMenuItem(
                                      value: v,
                                      child: Text(
                                        v.label,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (v) {
                                    if (v != null) {
                                      onUpdate(copy.copyWith(listingType: v));
                                    }
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (copy.listingType == ListingType.sell) ...[
                        const SizedBox(width: DSSpacing.md),
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const _Label(text: 'SALE PRICE'),
                              const SizedBox(height: DSSpacing.sm),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: DSColors.surface,
                                  borderRadius: BorderRadius.circular(
                                    DSRadius.lg,
                                  ),
                                ),
                                child: TextField(
                                  keyboardType: TextInputType.number,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                  decoration: const InputDecoration(
                                    icon: Text(
                                      r'$',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    border: InputBorder.none,
                                    hintText: '0.00',
                                  ),
                                  onChanged: (v) {
                                    onUpdate(
                                      copy.copyWith(price: double.tryParse(v)),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),

                  const SizedBox(height: DSSpacing.lg),
                  const _Label(text: 'INTERNAL NOTES'),
                  const SizedBox(height: DSSpacing.sm),
                  Container(
                    decoration: BoxDecoration(
                      color: DSColors.surface,
                      borderRadius: BorderRadius.circular(DSRadius.lg),
                    ),
                    child: TextField(
                      maxLines: 2,
                      style: const TextStyle(fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'e.g., Slight foxing on page 14...',
                        hintStyle: TextStyle(
                          color: DSColors.textLight.withValues(alpha: 0.4),
                        ),
                        contentPadding: const EdgeInsets.all(12),
                        border: InputBorder.none,
                      ),
                      onChanged: (v) {
                        onUpdate(copy.copyWith(notes: v));
                      },
                    ),
                  ),

                  const SizedBox(height: DSSpacing.lg),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: onRemove,
                      icon: const Icon(Icons.delete_outline, size: 16),
                      label: const Text('REMOVE COPY'),
                      style: TextButton.styleFrom(
                        foregroundColor: DSColors.error,
                        textStyle: const TextStyle(
                          fontSize: 10,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _SmallMediaCard extends StatelessWidget {
  final String label;
  final String? imageUrl;
  final bool isPlaceholder;
  final VoidCallback? onTap;

  const _SmallMediaCard({
    required this.label,
    this.imageUrl,
    this.isPlaceholder = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        height: 100,
        decoration: BoxDecoration(
          color: DSColors.surface,
          borderRadius: BorderRadius.circular(DSRadius.lg),
          image: imageUrl != null
              ? DecorationImage(
                  image: NetworkImage(ApiService.resolveImageUrl(imageUrl!)),
                  fit: BoxFit.cover,
                )
              : null,
        ),
        child: isPlaceholder || imageUrl == null
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isPlaceholder ? Icons.add_a_photo : Icons.photo_camera,
                      size: 20,
                      color: DSColors.textLight.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w800,
                        color: DSColors.textLight,
                      ),
                    ),
                  ],
                ),
              )
            : null,
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;

  const _Label({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        fontWeight: FontWeight.w800,
        fontSize: 9,
        letterSpacing: 1.5,
        color: DSColors.textLight.withValues(alpha: 0.7),
      ),
    );
  }
}

class _LocationAndCategorySection extends StatefulWidget {
  final AddBookStep2State state;

  const _LocationAndCategorySection({required this.state});

  @override
  State<_LocationAndCategorySection> createState() =>
      _LocationAndCategorySectionState();
}

class _LocationAndCategorySectionState
    extends State<_LocationAndCategorySection> {
  final TextEditingController _streetController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _pincodeController = TextEditingController();
  bool _isLocating = false;
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.state.draft.category ??
        (widget.state.draft.book?.categories.isNotEmpty == true
            ? widget.state.draft.book?.categories.first
            : null);

    final initialAddress = widget.state.draft.address ?? '';
    if (initialAddress.isNotEmpty) {
      final parts = initialAddress.split(', ');
      if (parts.length >= 4) {
        _streetController.text = parts.sublist(0, parts.length - 3).join(', ');
        _cityController.text = parts[parts.length - 3];
        _stateController.text = parts[parts.length - 2];
        _pincodeController.text = parts[parts.length - 1];
      } else {
        _streetController.text = initialAddress;
      }
    }
  }

  @override
  void dispose() {
    _streetController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    super.dispose();
  }

  void _updateAddress() {
    final street = _streetController.text.trim();
    final city = _cityController.text.trim();
    final state = _stateController.text.trim();
    final pincode = _pincodeController.text.trim();

    final parts = [street, city, state, pincode].where((e) => e.isNotEmpty).toList();
    final fullAddress = parts.join(', ');

    context.read<AddBookStep2Bloc>().add(AddBookStep2AddressUpdated(fullAddress));
  }

  void _fetchCurrentLocation() async {
    setState(() {
      _isLocating = true;
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled.');
      }

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

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );

      if (kIsWeb) {
        final url = Uri.parse(
          'https://nominatim.openstreetmap.org/reverse?format=json&lat=${position.latitude}&lon=${position.longitude}&zoom=18&addressdetails=1',
        );
        final response = await http.get(url, headers: {'User-Agent': 'FlutterApp/1.0'});

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final address = data['address'];
          if (address != null && mounted) {
            setState(() {
              final streetParts = [
                address['house_number'],
                address['road'],
                address['residential'],
                address['building'],
                address['neighbourhood'],
                address['suburb'],
              ].where((e) => e != null && e.toString().trim().isNotEmpty).toList();

              _streetController.text =
                  streetParts.isNotEmpty ? streetParts.join(', ') : (data['display_name'] ?? '');

              _cityController.text =
                  address['city'] ?? address['town'] ?? address['village'] ?? address['county'] ?? address['state_district'] ?? '';
              _stateController.text = address['state'] ?? '';
              _pincodeController.text = address['postcode'] ?? '';
              _isLocating = false;
            });
            _updateAddress();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Location found successfully!'),
                backgroundColor: Colors.green,
              ),
            );
            return;
          }
        }
      }

      List<Placemark> placemarks = await Geocoding().placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];

        if (mounted) {
          setState(() {
            _streetController.text = place.street ?? place.name ?? '';
            _cityController.text = place.locality ?? place.subAdministrativeArea ?? '';
            _stateController.text = place.administrativeArea ?? '';
            _pincodeController.text = place.postalCode ?? '';
            _isLocating = false;
          });
          _updateAddress();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location found successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw Exception('Could not find address for your location.');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLocating = false;
        });

        String errorMsg = e.toString().replaceAll('Exception: ', '');
        if (errorMsg.contains('Unexpected null value') ||
            errorMsg.contains('Null check operator')) {
          errorMsg =
              'Location auto-fetch is not fully supported on this platform. Please enter manually.';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.category_outlined,
              size: 20,
              color: DSColors.primary,
            ),
            const SizedBox(width: DSSpacing.sm),
            Text(
              'CATEGORY & LOCATION',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: 2.0,
                color: DSColors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: DSSpacing.md),

        // Category Selection
        CategoryChipGroup(
          categories: AppConstants.bookCategories,
          selectedCategory: _selectedCategory,
          onSelected: (category) {
            setState(() => _selectedCategory = category);
            context.read<AddBookStep2Bloc>().add(
              AddBookStep2CategoryUpdated(category),
            );
          },
        ),
        const SizedBox(height: DSSpacing.xl),

        // Address Field
        Text(
          'PICKUP ADDRESS',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: DSColors.textLight,
            fontWeight: FontWeight.w800,
            letterSpacing: 2.0,
          ),
        ),
        const SizedBox(height: DSSpacing.sm),
        Container(
          decoration: BoxDecoration(
            color: DSColors.surface,
            borderRadius: BorderRadius.circular(DSRadius.lg),
          ),
          child: Column(
            children: [
              TextField(
                controller: _streetController,
                decoration: InputDecoration(
                  hintText: 'Street Address',
                  hintStyle: TextStyle(
                    color: DSColors.border.withValues(alpha: 0.6),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: DSSpacing.md,
                    vertical: DSSpacing.md,
                  ),
                  border: InputBorder.none,
                ),
                style: const TextStyle(
                  fontFamily: 'Manrope',
                  fontWeight: FontWeight.w500,
                  color: DSColors.textDark,
                ),
                onChanged: (_) => _updateAddress(),
              ),
              const Divider(height: 1),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _cityController,
                      decoration: InputDecoration(
                        hintText: 'City',
                        hintStyle: TextStyle(
                          color: DSColors.border.withValues(alpha: 0.6),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: DSSpacing.md,
                          vertical: DSSpacing.md,
                        ),
                        border: InputBorder.none,
                      ),
                      style: const TextStyle(
                        fontFamily: 'Manrope',
                        fontWeight: FontWeight.w500,
                        color: DSColors.textDark,
                      ),
                      onChanged: (_) => _updateAddress(),
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 48,
                    color: DSColors.borderLight,
                  ),
                  Expanded(
                    child: TextField(
                      controller: _stateController,
                      decoration: InputDecoration(
                        hintText: 'State',
                        hintStyle: TextStyle(
                          color: DSColors.border.withValues(alpha: 0.6),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: DSSpacing.md,
                          vertical: DSSpacing.md,
                        ),
                        border: InputBorder.none,
                      ),
                      style: const TextStyle(
                        fontFamily: 'Manrope',
                        fontWeight: FontWeight.w500,
                        color: DSColors.textDark,
                      ),
                      onChanged: (_) => _updateAddress(),
                    ),
                  ),
                ],
              ),
              const Divider(height: 1),
              TextField(
                controller: _pincodeController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'Pincode / Zip',
                  hintStyle: TextStyle(
                    color: DSColors.border.withValues(alpha: 0.6),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: DSSpacing.md,
                    vertical: DSSpacing.md,
                  ),
                  border: InputBorder.none,
                ),
                style: const TextStyle(
                  fontFamily: 'Manrope',
                  fontWeight: FontWeight.w500,
                  color: DSColors.textDark,
                ),
                onChanged: (_) => _updateAddress(),
              ),
              const Divider(height: 1),
              InkWell(
                onTap: _isLocating ? null : _fetchCurrentLocation,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 16,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_isLocating)
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      else
                        const Icon(
                          Icons.my_location,
                          size: 18,
                          color: DSColors.primary,
                        ),
                      const SizedBox(width: 8),
                      Text(
                        _isLocating ? 'LOCATING...' : 'USE CURRENT LOCATION',
                        style: const TextStyle(
                          color: DSColors.primary,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                          fontSize: 12,
                        ),
                      ),
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
}
