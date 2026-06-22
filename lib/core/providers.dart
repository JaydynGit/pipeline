import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'models.dart';

class SelectedImagePathsNotifier extends Notifier<List<String>> {
  @override
  List<String> build() => [];
  
  void updateState(List<String> paths) {
    state = paths;
  }
}
final selectedImagePathsProvider = NotifierProvider<SelectedImagePathsNotifier, List<String>>(SelectedImagePathsNotifier.new);

// Processed Image Pairs (ready for Game Loop)
class ProcessedImagesNotifier extends Notifier<List<ProcessedImagePair>> {
  @override
  List<ProcessedImagePair> build() => [];

  void updateState(List<ProcessedImagePair> images) {
    state = images;
  }
}
final processedImagesProvider = NotifierProvider<ProcessedImagesNotifier, List<ProcessedImagePair>>(ProcessedImagesNotifier.new);

