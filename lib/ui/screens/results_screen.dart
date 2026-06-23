import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers.dart';
import '../../core/models.dart';
import '../../core/theme.dart';
import '../../services/pipeline_service.dart';
import 'landing_screen.dart';

import 'dart:io';

class ResultsScreen extends ConsumerWidget {
  final GameResult result;

  const ResultsScreen({super.key, required this.result});

  Widget _buildResultItem(ImageGuessDetail detail, int index) {
    String getCorrectText(PairState state) {
      switch (state) {
        case PairState.compressedOriginal: return "Correct: Option 1";
        case PairState.originalCompressed: return "Correct: Option 2";
        case PairState.originalOriginal: return "Correct: Neither";
      }
    }
    
    String getGuessText(GuessResult guess) {
      switch (guess) {
        case GuessResult.firstImage: return "You picked: Option 1";
        case GuessResult.secondImage: return "You picked: Option 2";
        case GuessResult.neither: return "You picked: Neither";
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: detail.isCorrect ? Colors.greenAccent.withValues(alpha: 0.5) : Colors.redAccent.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(
              File(detail.originalPath),
              width: 50,
              height: 50,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Image ${index + 1}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  getCorrectText(detail.actualState),
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
                Text(
                  getGuessText(detail.userGuess),
                  style: TextStyle(
                    color: detail.isCorrect ? Colors.greenAccent : Colors.redAccent,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 6),
                Builder(
                  builder: (context) {
                    String formatBytes(int bytes) {
                      if (bytes < 1024) return '$bytes B';
                      if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
                      return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
                    }
                    int oSize = 0;
                    int cSize = 0;
                    try {
                      oSize = File(detail.originalPath).lengthSync();
                      cSize = File(detail.compressedPath).lengthSync();
                    } catch (_) {}
                    return Text(
                      'Size: ${formatBytes(oSize)} ➔ ${formatBytes(cSize)}',
                      style: const TextStyle(color: Colors.white54, fontSize: 12),
                    );
                  }
                ),
              ],
            ),
          ),
          Icon(
            detail.isCorrect ? Icons.check_circle : Icons.cancel,
            color: detail.isCorrect ? Colors.greenAccent : Colors.redAccent,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    int compressionPresent = result.details.where((d) => d.actualState != PairState.originalOriginal).length;
    int compressionSpotted = result.details.where((d) => 
      d.actualState != PairState.originalOriginal && d.isCorrect
    ).length;

    final double percentage = compressionPresent == 0 ? 0.0 : (compressionSpotted / compressionPresent) * 100;
    
    int totalMilliseconds = result.details.fold(0, (sum, detail) => sum + detail.timeTaken.inMilliseconds);
    Duration totalTime = Duration(milliseconds: totalMilliseconds);
    String formatTime(Duration d) {
      String twoDigits(int n) => n.toString().padLeft(2, '0');
      final minutes = twoDigits(d.inMinutes.remainder(60));
      final seconds = twoDigits(d.inSeconds.remainder(60));
      return "$minutes:$seconds";
    }

    // Inverted scoring logic
    bool isSuccess = percentage <= 40.0;
    Color scoreColor = isSuccess ? Colors.greenAccent : Colors.redAccent;
    String message = isSuccess 
        ? "Success!\nThe pipeline is practically invisible." 
        : "Failed.\nYou could spot the compression too easily.";

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(24.0),
                children: [
                  const Text(
                    'Compression Spotted',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '${percentage.toStringAsFixed(0)}%',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 80,
                      fontWeight: FontWeight.bold,
                      color: scoreColor,
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 18,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.cardColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          children: [
                            Text(
                              '${result.correctGuesses}/${result.totalImages}',
                              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                            ),
                            const Text('Score', style: TextStyle(color: Colors.white70)),
                          ],
                        ),
                        Column(
                          children: [
                            Text(
                              formatTime(totalTime),
                              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                            ),
                            const Text('Time Taken', style: TextStyle(color: Colors.white70)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'Details',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  ...result.details.asMap().entries.map((e) => _buildResultItem(e.value, e.key)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: TextButton(
                onPressed: () {
                  final selected = ref.read(selectedImagePathsProvider);
                  final processed = ref.read(processedImagesProvider);
                  PipelineService.cleanupAllTemporaryFiles(selected, processed);
                  
                  ref.read(selectedImagePathsProvider.notifier).updateState([]);
                  ref.read(processedImagesProvider.notifier).updateState([]);
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LandingScreen()),
                    (route) => false,
                  );
                },
                child: const Text(
                  'Play Again',
                  style: TextStyle(fontSize: 18, color: Colors.white70),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
