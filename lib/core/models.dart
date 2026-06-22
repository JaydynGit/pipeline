class ProcessedImagePair {
  final String id;
  final String originalPath;
  final String compressedPath;

  ProcessedImagePair({
    required this.id,
    required this.originalPath,
    required this.compressedPath,
  });
}

enum PairState {
  compressedOriginal, // 1: Compressed, 2: Original
  originalCompressed, // 1: Original, 2: Compressed
  originalOriginal,   // 1: Original, 2: Original (Placebo)
}

enum GuessResult {
  firstImage,
  secondImage,
  neither,
}

class GameResult {
  final String id;
  final DateTime timestamp;
  final int totalImages;
  final int correctGuesses;
  final List<ImageGuessDetail> details;

  GameResult({
    required this.id,
    required this.timestamp,
    required this.totalImages,
    required this.correctGuesses,
    required this.details,
  });

  double get score => totalImages == 0 ? 0.0 : correctGuesses / totalImages;

  Map<String, dynamic> toJson() => {
        'id': id,
        'timestamp': timestamp.toIso8601String(),
        'totalImages': totalImages,
        'correctGuesses': correctGuesses,
        'details': details.map((e) => e.toJson()).toList(),
      };

  factory GameResult.fromJson(Map<String, dynamic> json) => GameResult(
        id: json['id'],
        timestamp: DateTime.parse(json['timestamp']),
        totalImages: json['totalImages'],
        correctGuesses: json['correctGuesses'],
        details: (json['details'] as List)
            .map((e) => ImageGuessDetail.fromJson(e))
            .toList(),
      );
}

class ImageGuessDetail {
  final String originalPath;
  final String compressedPath;
  final PairState actualState;
  final GuessResult userGuess;
  final bool isCorrect;
  final Duration timeTaken;

  ImageGuessDetail({
    required this.originalPath,
    required this.compressedPath,
    required this.actualState,
    required this.userGuess,
    required this.isCorrect,
    required this.timeTaken,
  });

  Map<String, dynamic> toJson() => {
        'originalPath': originalPath,
        'compressedPath': compressedPath,
        'actualState': actualState.index,
        'userGuess': userGuess.index,
        'isCorrect': isCorrect,
        'timeTakenMs': timeTaken.inMilliseconds,
      };

  factory ImageGuessDetail.fromJson(Map<String, dynamic> json) =>
      ImageGuessDetail(
        originalPath: json['originalPath'],
        compressedPath: json['compressedPath'],
        actualState: PairState.values[json['actualState']],
        userGuess: GuessResult.values[json['userGuess']],
        isCorrect: json['isCorrect'],
        timeTaken: Duration(milliseconds: json['timeTakenMs']),
      );
}
