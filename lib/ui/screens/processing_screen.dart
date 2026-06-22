import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers.dart';
import '../../services/pipeline_service.dart';
import '../widgets/glass_card.dart';
import 'game_screen.dart';

class ProcessingScreen extends ConsumerStatefulWidget {
  const ProcessingScreen({super.key});

  @override
  ConsumerState<ProcessingScreen> createState() => _ProcessingScreenState();
}

class _ProcessingScreenState extends ConsumerState<ProcessingScreen> {
  bool _isProcessing = true;
  double _progress = 0.0;

  @override
  void initState() {
    super.initState();
    _startPipeline();
  }

  Future<void> _startPipeline() async {
    final imagePaths = ref.read(selectedImagePathsProvider);
    if (imagePaths.isEmpty) return;

    try {
      final processed = await PipelineService.processImages(imagePaths);
      if (mounted) {
        ref.read(processedImagesProvider.notifier).updateState(processed);
        setState(() {
          _isProcessing = false;
          _progress = 1.0;
        });
        
        // Auto-navigate to game screen after a short delay
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const GameScreen()),
            );
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Processing Error: $e')));
        Navigator.pop(context); // Go back if error
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            SizedBox(
              height: 250,
              child: PageView(
                controller: PageController(viewportFraction: 0.85),
                children: [
                  _buildTutorialCard(
                    Icons.compare,
                    'Spot the Difference',
                    'You will be shown two images. One is the original, one is compressed. Try to spot the compressed one.',
                  ),
                  _buildTutorialCard(
                    Icons.science,
                    'Our Pipeline',
                    'We are currently analyzing your images using ML to selectively sharpen faces and text while blurring the background.',
                  ),
                  _buildTutorialCard(
                    Icons.speed,
                    'The Goal',
                    'If you cannot tell which image is the compressed one, our pipeline is working perfectly!',
                  ),
                ],
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48.0, vertical: 32.0),
              child: Column(
                children: [
                  Text(
                    _isProcessing ? 'Processing Images...' : 'Ready!',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 16),
                  LinearProgressIndicator(
                    value: _isProcessing ? null : _progress,
                    backgroundColor: Colors.white.withValues(alpha: 0.1),
                    color: Theme.of(context).colorScheme.secondary,
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTutorialCard(IconData icon, String title, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: GlassCard(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: Colors.white),
            const SizedBox(height: 24),
            Text(
              title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              description,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white70,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
