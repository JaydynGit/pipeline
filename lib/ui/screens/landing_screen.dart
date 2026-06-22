import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../widgets/gradient_button.dart';
import 'processing_screen.dart';
class LandingScreen extends ConsumerStatefulWidget {
  const LandingScreen({super.key});

  @override
  ConsumerState<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends ConsumerState<LandingScreen> {
  final ImagePicker _picker = ImagePicker();
  bool _isPicking = false;

  Future<void> _pickAndCropImages() async {
    setState(() => _isPicking = true);
    
    try {
      List<XFile> images = await _picker.pickMultiImage(limit: 10);
      if (images.isEmpty) {
        setState(() => _isPicking = false);
        return;
      }
      
      if (images.length > 10) {
        images = images.sublist(0, 10);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Maximum 10 images allowed. Only the first 10 were selected.')),
          );
        }
      }
      
      List<String> croppedPaths = [];
      
      for (var image in images) {
        final croppedFile = await ImageCropper().cropImage(
          sourcePath: image.path,

          uiSettings: [
            AndroidUiSettings(
                toolbarTitle: 'Crop Image',
                toolbarColor: AppTheme.cardColor,
                toolbarWidgetColor: Colors.white,
                initAspectRatio: CropAspectRatioPreset.square,
                lockAspectRatio: false,
                backgroundColor: AppTheme.background,
                activeControlsWidgetColor: AppTheme.primaryPurple,
                aspectRatioPresets: [
                  CropAspectRatioPreset.original,
                  CropAspectRatioPreset.square,
                  CropAspectRatioPreset.ratio3x2,
                  CropAspectRatioPreset.ratio4x3,
                  CropAspectRatioPreset.ratio16x9,
                ],
            ),
            IOSUiSettings(
              title: 'Crop Image',
              aspectRatioLockEnabled: false,
              aspectRatioPresets: [
                CropAspectRatioPreset.original,
                CropAspectRatioPreset.square,
                CropAspectRatioPreset.ratio3x2,
                CropAspectRatioPreset.ratio4x3,
                CropAspectRatioPreset.ratio16x9,
              ],
            ),
          ],
        );
        
        if (croppedFile != null) {
          croppedPaths.add(croppedFile.path);
        }
      }
      
      if (croppedPaths.isNotEmpty) {
        ref.read(selectedImagePathsProvider.notifier).updateState(croppedPaths);
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const ProcessingScreen()),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isPicking = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedCount = ref.watch(selectedImagePathsProvider).length;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              const Icon(
                Icons.image_search,
                size: 100,
                color: AppTheme.primaryBlue,
              ),
              const SizedBox(height: 32),
              const Text(
                'Compression\nChallenge',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Can you spot the difference between the original and the optimized image?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                ),
              ),
              const Spacer(),
              if (selectedCount > 0)
                Padding(
                  padding: const EdgeInsets.only(bottom: 24.0),
                  child: Text(
                    '$selectedCount image(s) selected.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppTheme.primaryPurple),
                  ),
                ),
              GradientButton(
                text: 'Select Images (Max 10)',
                isLoading: _isPicking,
                onPressed: _pickAndCropImages,
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
