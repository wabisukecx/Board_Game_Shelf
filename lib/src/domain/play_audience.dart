import '../core/constants.dart';

enum PlayAudience { beginner, advanced, unknown }

PlayAudience classifyPlayAudience(double? weight) {
  if (weight == null) {
    return PlayAudience.unknown;
  }
  if (weight < AppConstants.playAudienceBeginnerMaxWeight) {
    return PlayAudience.beginner;
  }
  return PlayAudience.advanced;
}
