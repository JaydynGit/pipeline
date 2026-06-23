import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import 'package:google_mlkit_subject_segmentation/google_mlkit_subject_segmentation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import '../core/models.dart';

class PipelineService {
  static Future<List<ProcessedImagePair>> processImages(List<String> imagePaths) async {
    List<ProcessedImagePair> results = [];
    // Smart Concurrency Manager
    // Calculate safe concurrency limit based on hardware
    // Budget devices (4 or less cores) -> 1 or 2 images to prevent RAM crashes
    // Flagship devices (6 or more cores) -> 3 or 4 images to speed up processing
    int processors = Platform.numberOfProcessors;
    int chunkLimit = (processors <= 4) ? 1 : 3; 

    for (int i = 0; i < imagePaths.length; i += chunkLimit) {
      final chunk = imagePaths.skip(i).take(chunkLimit);
      
      final futures = chunk.map((path) => _processSingleImage(path));
      final chunkResults = await Future.wait(futures);
      
      for (final result in chunkResults) {
        if (result != null) {
          results.add(result);
        }
      }
    }
    
    return results;
  }

  static Future<ProcessedImagePair?> _processSingleImage(String originalPath) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final uuid = const Uuid().v4();
      
      final baselinePath = '${tempDir.path}/${uuid}_baseline.jpg';
      final resizedPath = '${tempDir.path}/${uuid}_resized.png';
      
      // Step 1: Decode, bake EXIF, and scale to 1080p natively using OS libraries
      final baselineFile = await FlutterImageCompress.compressAndGetFile(
        originalPath,
        baselinePath,
        format: CompressFormat.jpeg,
        quality: 100, // 100% quality JPEG is visually lossless and extremely fast to encode
        minWidth: 1080,
        minHeight: 1080,
      );
      
      if (baselineFile == null) return null;

      // Get the resulting dimensions of the baseline image
      final Uint8List baselineBytes = await File(baselinePath).readAsBytes();
      final ui.Codec baselineCodec = await ui.instantiateImageCodec(baselineBytes);
      final ui.FrameInfo baselineFrame = await baselineCodec.getNextFrame();
      final ui.Image decodedBaselineImage = baselineFrame.image;
      
      final int targetWidth = decodedBaselineImage.width;
      final int targetHeight = decodedBaselineImage.height;
      decodedBaselineImage.dispose(); // Free memory, we'll reload if needed for compositing
      
      // Step 2: ML Kit Subject Segmentation and Text Recognition
      final inputImage = InputImage.fromFilePath(baselinePath);
      final segmenter = SubjectSegmenter(
        options: SubjectSegmenterOptions(
          enableForegroundBitmap: false,
          enableForegroundConfidenceMask: true,
          enableMultipleSubjects: SubjectResultOptions(
            enableConfidenceMask: false,
            enableSubjectBitmap: false,
          ),
        ),
      );
      
      final textRecognizer = TextRecognizer();
      
      final imageLabeler = ImageLabeler(options: ImageLabelerOptions(confidenceThreshold: 0.70));
      
      final faceDetector = FaceDetector(options: FaceDetectorOptions(performanceMode: FaceDetectorMode.fast));
      
      // Run all ML models concurrently
      final mlResults = await Future.wait([
        segmenter.processImage(inputImage),
        textRecognizer.processImage(inputImage),
        imageLabeler.processImage(inputImage),
        faceDetector.processImage(inputImage),
      ]);
      
      final maskResult = mlResults[0] as SubjectSegmentationResult;
      final textResult = mlResults[1] as RecognizedText;
      final labelResults = mlResults[2] as List<ImageLabel>;
      final faceResults = mlResults[3] as List<Face>;
      
      await segmenter.close();
      await textRecognizer.close();
      await imageLabeler.close();
      await faceDetector.close();
      
      final mask = maskResult.foregroundConfidenceMask;
      if (mask == null || mask.length != targetWidth * targetHeight) return null;
      
      // Calculate Subject Percentage for Dynamic Quality
      double totalConfidence = 0.0;
      final Uint8List maskPixels = Uint8List(mask.length * 4);
      for (int i = 0; i < mask.length; i++) {
        final double c = mask[i];
        totalConfidence += c;
        final int alpha = (c * 255).round();
        maskPixels[i * 4 + 0] = 0; // R
        maskPixels[i * 4 + 1] = 0; // G
        maskPixels[i * 4 + 2] = 0; // B
        maskPixels[i * 4 + 3] = alpha; // A
      }
      double subjectPercentage = totalConfidence / mask.length;
      
      // Extract bounding boxes for all detected text blocks
      List<Rect> textBoundingBoxes = [];
      for (final block in textResult.blocks) {
        textBoundingBoxes.add(block.boundingBox);
      }
      
      int webpQuality = 80;
      if (subjectPercentage < 0.3) {
        webpQuality = 70;
      } else if (subjectPercentage > 0.7) {
        webpQuality = 88;
      }
      
      // Check if image is a Poster or Art based on Image Labeling
      bool isPosterOrArt = false;
      final posterTags = ['poster', 'graphic design', 'illustration', 'art', 'font', 'text', 'drawing', 'painting'];
      for (final label in labelResults) {
        if (posterTags.contains(label.label.toLowerCase())) {
          isPosterOrArt = true;
          break;
        }
      }
      
      String sourcePathToCompress = baselinePath;
      
      // Smart Bypass: If image is a screenshot, meme, landscape (almost no subject),
      // OR if the Image Labeler explicitly tags it as a Poster/Art/Design,
      // OR if it's a Group Photo (3 or more faces),
      // completely skip the blur phase to protect UI icons, artistic details, and background people.
      if (subjectPercentage >= 0.05 && !isPosterOrArt && faceResults.length < 3) {
        // Step 3: GPU Compositing with dart:ui
        // Load baseline image
        final Uint8List baselineBytes = await File(baselinePath).readAsBytes();
        final ui.Codec baselineCodec = await ui.instantiateImageCodec(baselineBytes);
        final ui.FrameInfo baselineFrame = await baselineCodec.getNextFrame();
        final ui.Image baselineImage = baselineFrame.image;
        
        // Load mask image
        final ui.ImmutableBuffer buffer = await ui.ImmutableBuffer.fromUint8List(maskPixels);
        final ui.ImageDescriptor descriptor = ui.ImageDescriptor.raw(
          buffer,
          width: targetWidth,
          height: targetHeight,
          pixelFormat: ui.PixelFormat.rgba8888,
        );
        final ui.Codec maskCodec = await descriptor.instantiateCodec();
        final ui.FrameInfo maskFrame = await maskCodec.getNextFrame();
        final ui.Image maskImage = maskFrame.image;
        buffer.dispose();
        descriptor.dispose();
        
        // Composite using Canvas
        final ui.PictureRecorder recorder = ui.PictureRecorder();
        final ui.Canvas canvas = ui.Canvas(recorder);
        
        // 1. Draw blurred background
        final ui.Paint backgroundPaint = ui.Paint()
          ..imageFilter = ui.ImageFilter.blur(sigmaX: 1.5, sigmaY: 1.5);
        canvas.drawImage(baselineImage, Offset.zero, backgroundPaint);
        
        // 2. Draw sharp foreground using saveLayer and SrcIn
        canvas.saveLayer(null, ui.Paint());
        
        // Feather the mask
        final ui.Paint maskPaint = ui.Paint()
          ..imageFilter = ui.ImageFilter.blur(sigmaX: 2.0, sigmaY: 2.0);
        canvas.drawImage(maskImage, Offset.zero, maskPaint);
        
        // Protect Text Regions by drawing them opaque on the mask layer
        final ui.Paint textMaskPaint = ui.Paint()
          ..color = const Color.fromARGB(255, 0, 0, 0)
          ..style = ui.PaintingStyle.fill;
          
        for (final rect in textBoundingBoxes) {
          final inflated = rect.inflate(8.0); // Give text some breathing room
          canvas.drawRect(inflated, textMaskPaint);
        }
        
        // Blend original over mask
        final ui.Paint foregroundPaint = ui.Paint()
          ..blendMode = ui.BlendMode.srcIn;
        canvas.drawImage(baselineImage, Offset.zero, foregroundPaint);
        
        canvas.restore();
        
        final ui.Picture picture = recorder.endRecording();
        final ui.Image finalUiImage = await picture.toImage(targetWidth, targetHeight);
        
        final ByteData? byteData = await finalUiImage.toByteData(format: ui.ImageByteFormat.png);
        if (byteData == null) return null;
        
        await File(resizedPath).writeAsBytes(byteData.buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));
        
        // Cleanup ui images to prevent memory leaks
        baselineImage.dispose();
        maskImage.dispose();
        finalUiImage.dispose();
        
        sourcePathToCompress = resizedPath;
      }
      
      // Step 4: Compress to WebP (Dynamic Quality)
      final compressedPath = '${tempDir.path}/${uuid}_compressed.webp';
      
      final compressedFile = await FlutterImageCompress.compressAndGetFile(
        sourcePathToCompress,
        compressedPath,
        format: CompressFormat.webp,
        quality: webpQuality,
      );
      
      if (compressedFile == null) return null;
      
      try {
        await File(resizedPath).delete();
      } catch (_) {}
      
      return ProcessedImagePair(
        id: uuid,
        originalPath: baselinePath,
        compressedPath: compressedFile.path,
      );
    } catch (e) {
      // ignore: avoid_print
      print('Pipeline error: $e');
      return null;
    }
  }

  static Future<void> cleanupAllTemporaryFiles(List<String> selectedPaths, List<ProcessedImagePair> processedImages) async {
    final tempDir = await getTemporaryDirectory();
    final tempPath = tempDir.path;

    Future<void> deleteIfTemp(String path) async {
      try {
        // Only delete if it's in the temporary directory to absolutely protect the user's gallery
        if (path.contains(tempPath)) {
          final file = File(path);
          if (file.existsSync()) {
            await file.delete();
          }
        }
      } catch (_) {}
    }

    for (var path in selectedPaths) {
      await deleteIfTemp(path);
    }
    
    for (var image in processedImages) {
      await deleteIfTemp(image.originalPath);
      await deleteIfTemp(image.compressedPath);
    }
  }
}
