import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:libri_flow/core/design_system/design_system.dart';

class ProfileAvatarUpload extends StatelessWidget {
  final String avatarUrl;
  final Function(ImageSource) onEditPressed;

  const ProfileAvatarUpload({
    super.key,
    required this.avatarUrl,
    required this.onEditPressed,
  });

  void _showImagePickerBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: DSColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(DSRadius.xl)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  onEditPressed(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Camera'),
                onTap: () {
                  Navigator.pop(context);
                  onEditPressed(ImageSource.camera);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(DSSpacing.xl),
      decoration: BoxDecoration(
        color: DSColors.surface,
        borderRadius: BorderRadius.circular(DSRadius.lg),
        border: Border.all(color: DSColors.borderLight.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                padding: const EdgeInsets.all(4), // Ring offset
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: DSColors.surface, // Ring offset background
                ),
                child: Container(
                  padding: const EdgeInsets.all(4), // Ring
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: DSColors.borderLight,
                  ),
                  child: CircleAvatar(
                    radius: 56,
                    backgroundImage: NetworkImage(avatarUrl),
                    backgroundColor: DSColors.borderLight,
                  ),
                ),
              ),
              Positioned(
                bottom: 4,
                right: 4,
                child: GestureDetector(
                  onTap: () => _showImagePickerBottomSheet(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: DSColors.primary,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.edit,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: DSSpacing.lg),
          GestureDetector(
            onTap: () => _showImagePickerBottomSheet(context),
            child: Text(
              'CHANGE PROFILE PHOTO',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
                color: DSColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
