import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../core/models.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import 'results_screen.dart';

class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({super.key});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  late List<ProcessedImagePair> _pairs;
  late List<PairState> _assignedStates;
  final List<ImageGuessDetail> _guessDetails = [];
  
  int _currentIndex = 0;
  
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _timer;
  final ValueNotifier<Duration> _elapsedTimeNotifier = ValueNotifier(Duration.zero);
  
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _pairs = ref.read(processedImagesProvider);
    _initializeStates();
    _startStopwatch();
  }
  
  void _initializeStates() {
    final random = Random();
    _assignedStates = _pairs.map((_) {
      int stateVal = random.nextInt(3);
      return PairState.values[stateVal];
    }).toList();
  }

  void _startStopwatch() {
    _timer?.cancel();
    _stopwatch.reset();
    _stopwatch.start();
    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (mounted) _elapsedTimeNotifier.value = _stopwatch.elapsed;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _stopwatch.stop();
    _elapsedTimeNotifier.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _handleGuess(GuessResult guess) {
    _stopwatch.stop();
    final timeTaken = _stopwatch.elapsed;
    
    final currentPair = _pairs[_currentIndex];
    final currentState = _assignedStates[_currentIndex];
    
    bool isCorrect = false;
    if (currentState == PairState.compressedOriginal && guess == GuessResult.firstImage) isCorrect = true;
    if (currentState == PairState.originalCompressed && guess == GuessResult.secondImage) isCorrect = true;
    if (currentState == PairState.originalOriginal && guess == GuessResult.neither) isCorrect = true;
    
    _guessDetails.add(ImageGuessDetail(
      originalPath: currentPair.originalPath,
      compressedPath: currentPair.compressedPath,
      actualState: currentState,
      userGuess: guess,
      isCorrect: isCorrect,
      timeTaken: timeTaken,
    ));
    
    if (_currentIndex < _pairs.length - 1) {
      setState(() {
        _currentIndex++;
      });
      _pageController.jumpToPage(0);
      _startStopwatch();
    } else {
      _finishGame();
    }
  }

  Future<void> _finishGame() async {
    int correctGuesses = _guessDetails.where((g) => g.isCorrect).length;
    final result = GameResult(
      id: const Uuid().v4(),
      timestamp: DateTime.now(),
      totalImages: _pairs.length,
      correctGuesses: correctGuesses,
      details: _guessDetails,
    );
    
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => ResultsScreen(result: result)),
      );
    }
  }

  String _formatStopwatch(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    final milliseconds = (duration.inMilliseconds.remainder(1000) / 100).floor();
    return "$minutes:$seconds.$milliseconds";
  }

  @override
  Widget build(BuildContext context) {
    if (_pairs.isEmpty) return const Scaffold(body: Center(child: Text('No images to process.')));

    final currentPair = _pairs[_currentIndex];
    final currentState = _assignedStates[_currentIndex];
    
    String option1Path;
    String option2Path;
    
    switch (currentState) {
      case PairState.compressedOriginal:
        option1Path = currentPair.compressedPath;
        option2Path = currentPair.originalPath;
        break;
      case PairState.originalCompressed:
        option1Path = currentPair.originalPath;
        option2Path = currentPair.compressedPath;
        break;
      case PairState.originalOriginal:
        option1Path = currentPair.originalPath;
        option2Path = currentPair.originalPath;
        break;
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header: Timer and Progress
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Image ${_currentIndex + 1} of ${_pairs.length}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.cardColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: ValueListenableBuilder<Duration>(
                      valueListenable: _elapsedTimeNotifier,
                      builder: (context, duration, child) {
                        return Text(
                          _formatStopwatch(duration),
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryBlue,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            
            // Image Viewer
            Expanded(
              child: Stack(
                children: [
                  PageView(
                    controller: _pageController,
                    children: [
                      _buildImageViewer(option1Path, "Option 1"),
                      _buildImageViewer(option2Path, "Option 2"),
                    ],
                  ),
                  // Pagination indicators
                  Positioned(
                    bottom: 20,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('Swipe to compare', style: TextStyle(color: Colors.white70)),
                            const SizedBox(width: 8),
                            const Icon(Icons.swipe, color: Colors.white70, size: 20),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Controls
            Container(
              padding: const EdgeInsets.all(24.0),
              decoration: BoxDecoration(
                color: AppTheme.background,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Which image is compressed?',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.cardColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () => _handleGuess(GuessResult.firstImage),
                          child: const Text('Option 1'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.cardColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () => _handleGuess(GuessResult.secondImage),
                          child: const Text('Option 2'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: Colors.white70,
                      side: const BorderSide(color: Colors.white30),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => _handleGuess(GuessResult.neither),
                    child: const Text('Neither (They look the same)'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageViewer(String imagePath, String label) {
    return InteractiveViewer(
      minScale: 1.0,
      maxScale: 4.0,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.file(
            File(imagePath),
            fit: BoxFit.contain,
          ),
          Positioned(
            top: 16,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
