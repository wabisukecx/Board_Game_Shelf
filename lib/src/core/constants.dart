class AppConstants {
  const AppConstants._();

  static const int bggThingRateLimitPerMinute = 15;
  static const int bggSearchRateLimitPerMinute = 20;

  static const double requestJitterMinSeconds = 0.2;
  static const double requestJitterMaxSeconds = 1.0;

  static const int maxRetryCount = 3;
  static const int defaultRetryAfterSeconds = 30;
  static const int retryAfterJitterMinSeconds = 1;
  static const int retryAfterJitterMaxSeconds = 5;

  static const int serverBackoffBase = 2;
  static const int serverBackoffJitterMinSeconds = 0;
  static const int serverBackoffJitterMaxSeconds = 1;

  static const int acceptedResponseRetryDelaySeconds = 3;
  static const int acceptedResponseMaxAttempts = 3;

  static const Duration thingCacheTtl = Duration(hours: 48);
  static const Duration searchCacheTtl = Duration(hours: 24);

  static const double numericDiffTolerance = 1e-6;
  static const double japaneseTranslationSkipRatio = 0.2;
  static const String fallbackLocaleCode = 'en';

  static const int recommendedPlayersMinimumVotes = 5;
  static const double bestPlayerVoteThreshold = 0.5;
  static const double recommendedPlayerVoteThreshold = 0.7;

  static const int bggIdFilenameDigits = 6;
  static const String localIdPrefix = 'L';
  static const int localIdDigits = 5;

  static const String automaticBackupDatePattern = 'YYMMDD';
  static const String manualBackupPrefix = 'backup_';
  static const String manualBackupDatePattern = 'YYYYMMDD_HHMMSS';

  static const Duration barcodeRepeatSuppressDuration = Duration(
    milliseconds: 2500,
  );
  static const Duration barcodeNoDetectionHintDuration = Duration(seconds: 8);
  static const String barcodeSourceScan = 'scan';
  static const String barcodeSourceManual = 'manual';
  static const String gameUpcBaseUrl = 'https://api.gameupc.com/test';
  static const String gameUpcVerifiedStatus = 'verified';

  static const String geminiVisionModel = 'gemini-3.5-flash';
  static const int visionImageMaxLongEdge = 1024;
  static const int shelfImageMaxLongEdge = 1600;
  static const int visionJpegQuality = 80;
  static const int visionMaxCandidates = 5;
  static const int shelfMaxDetections = 30;
  static const double visionConfidenceThreshold = 0.4;

  static const int analyticsTopN = 10;
  static const int analyticsMinPlayerCount = 1;
  static const int analyticsMaxPlayerCount = 8;
  static const List<double> analyticsWeightBucketEdges = [1.5, 2.5, 3.5, 4.5];
  static const List<int> analyticsPlayingTimeBucketEdges = [30, 60, 90, 120];
  static const double playAudienceBeginnerMaxWeight = 2.0;
  static const double playAudienceAdvancedMinWeight = 2.0;
  static const double playAudienceFutureAdvancedMinWeight = 3.0;

  static const String bggCollectionSubtype = 'boardgame';
  static const int bggCollectionOwn = 1;
  static const int bggImportConsecutiveFailureLimit = 5;
  static const String gameKindBase = 'base';
  static const String gameKindExpansion = 'expansion';
  static const String bggExpansionLinkType = 'boardgameexpansion';

  static const int playRatingMin = 1;
  static const int playRatingMax = 10;
  static const int playFavoriteRatingThreshold = 7;
  static const int playReplayDesireMin = 1;
  static const int playReplayDesireMax = 5;
  static const double playPerceivedWeightMin = 1.0;
  static const double playPerceivedWeightMax = 5.0;
  static const double playPerceivedWeightStep = 0.5;

  static const String mechanicsAnalysisAsset =
      'assets/analysis/mechanics_data.yaml';
  static const String categoriesAnalysisAsset =
      'assets/analysis/categories_data.yaml';
  static const String rankComplexityAnalysisAsset =
      'assets/analysis/rank_complexity.yaml';
  static const double analysisMinScore = 1.0;
  static const double analysisMaxScore = 5.0;
  static const double fallbackMechanicComplexity = 2.5;
  static const double fallbackMechanicStrategicValue = 3.0;
  static const double fallbackMechanicInteractionValue = 3.0;
  static const double fallbackCategoryComplexity = 2.5;
  static const double fallbackRankTypeComplexity = 3.0;
  static const double defaultGameWeight = 3.0;
  static const int defaultGameMinAge = 10;
  static const int defaultGameMinPlayers = 2;
  static const int defaultGameMaxPlayers = 4;
  static const int defaultGamePlayingTime = 60;

  static const String bggHost = 'boardgamegeek.com';
}

class FilenameRules {
  const FilenameRules._();

  static const Map<String, String> replacementMap = {
    ' ': '_',
    '/': '_',
    r'\': '_',
    ':': '_',
    ';': '_',
    '　': ' ',
  };
}
