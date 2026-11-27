import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/theme.dart';
import 'package:libri_flow/core/design_system/design_system.dart';
import '../../../../core/services/api_service.dart';
import '../bloc/profile_bloc.dart';
import '../bloc/profile_event.dart';

class ProfileHero extends StatefulWidget {
  final String name;
  final String level;
  final String avatarUrl;

  const ProfileHero({
    super.key,
    required this.name,
    required this.level,
    required this.avatarUrl,
  });

  @override
  State<ProfileHero> createState() => _ProfileHeroState();
}

class _ProfileHeroState extends State<ProfileHero> {
  bool _isUploading = false;
  final ImagePicker _picker = ImagePicker();

  Future<void> _uploadAvatar(BuildContext context) async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() => _isUploading = true);
        final file = File(image.path);
        final url = await ApiService.uploadAvatar(file);
        await ApiService.updateProfile({"avatar_url": url});
        if (context.mounted) {
          context.read<ProfileBloc>().add(ProfileStarted());
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Avatar updated successfully!")),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to upload avatar: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      children: [
        GestureDetector(
          onTap: () => _uploadAvatar(context),
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: Stack(
              alignment: Alignment.bottomRight,
              children: [
                Container(
                  padding: const EdgeInsets.all(DSSpacing.xs), // 4px ring thickness
                  decoration: const BoxDecoration(
                    color: DSColors.borderLight,
                    shape: BoxShape.circle,
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(4), // Ring offset
                    decoration: BoxDecoration(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      shape: BoxShape.circle,
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircleAvatar(
                          radius: 64, // 128 height
                          backgroundImage: NetworkImage(widget.avatarUrl),
                          backgroundColor: DSColors.borderLight,
                        ),
                        if (_isUploading)
                          const CircularProgressIndicator(color: DSColors.primary),
                      ],
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: DSColors.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: DSSpacing.lg),
        Text(
          widget.name,
          style: textTheme.displaySmall?.copyWith(
            fontSize: 30.0, // Match text-3xl precisely
          ),
        ),
        const SizedBox(height: DSSpacing.xs),
        Text(
          widget.level.toUpperCase(),
          style: IvoryTheme.smallCapsLabel.copyWith(color: DSColors.textLight),
        ),
      ],
    );
  }
}
