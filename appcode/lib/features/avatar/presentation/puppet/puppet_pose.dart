import '../avatar_view_model.dart';

/// Continuous puppet parameters. All motion lerps toward these — never snaps.
class PuppetPose {
  const PuppetPose({
    this.headTilt = 0,
    this.headY = 0,
    this.bodySquash = 1,
    this.armL = 0.18,
    this.armR = -0.18,
    this.eyeOpen = 1,
    this.eyeScaleY = 1,
    this.lidDrop = 0,
    this.browDown = 0,
    this.browWorry = 0,
    this.mouthSmile = 0.72,
    this.mouthOpen = 0,
    this.blush = 0.4,
    this.heartEyes = 0,
    this.sparkle = 0,
    this.sweat = 0,
    this.tear = 0,
    this.squashX = 1,
    this.squashY = 1,
  });

  final double headTilt;
  final double headY;
  final double bodySquash;
  final double armL;
  final double armR;
  final double eyeOpen;
  final double eyeScaleY;
  final double lidDrop;
  final double browDown;
  final double browWorry;
  final double mouthSmile;
  final double mouthOpen;
  final double blush;
  final double heartEyes;
  final double sparkle;
  final double sweat;
  final double tear;
  final double squashX;
  final double squashY;

  static PuppetPose lerp(PuppetPose a, PuppetPose b, double t) {
    double mix(double x, double y) => x + (y - x) * t;
    return PuppetPose(
      headTilt: mix(a.headTilt, b.headTilt),
      headY: mix(a.headY, b.headY),
      bodySquash: mix(a.bodySquash, b.bodySquash),
      armL: mix(a.armL, b.armL),
      armR: mix(a.armR, b.armR),
      eyeOpen: mix(a.eyeOpen, b.eyeOpen),
      eyeScaleY: mix(a.eyeScaleY, b.eyeScaleY),
      lidDrop: mix(a.lidDrop, b.lidDrop),
      browDown: mix(a.browDown, b.browDown),
      browWorry: mix(a.browWorry, b.browWorry),
      mouthSmile: mix(a.mouthSmile, b.mouthSmile),
      mouthOpen: mix(a.mouthOpen, b.mouthOpen),
      blush: mix(a.blush, b.blush),
      heartEyes: mix(a.heartEyes, b.heartEyes),
      sparkle: mix(a.sparkle, b.sparkle),
      sweat: mix(a.sweat, b.sweat),
      tear: mix(a.tear, b.tear),
      squashX: mix(a.squashX, b.squashX),
      squashY: mix(a.squashY, b.squashY),
    );
  }

  static PuppetPose forState(AnimationState state) {
    switch (state) {
      case AnimationState.sleeping:
      case AnimationState.resting:
        return const PuppetPose(
          headTilt: 0.2,
          headY: 0.012,
          bodySquash: 0.96,
          armL: 0.35,
          armR: -0.35,
          eyeOpen: 0,
          mouthSmile: 0.12,
          blush: 0.18,
        );
      case AnimationState.reaction:
        return const PuppetPose(
          headTilt: -0.04,
          armL: -0.85,
          armR: 0.85,
          eyeOpen: 1,
          mouthSmile: 1,
          blush: 1,
          heartEyes: 1,
          squashX: 1.04,
          squashY: 1.08,
        );
      case AnimationState.talking:
        return const PuppetPose(
          headY: -0.004,
          mouthSmile: 0.35,
          mouthOpen: 0.55,
          blush: 0.45,
        );
      case AnimationState.moodHappy:
      case AnimationState.playing:
        return const PuppetPose(
          headY: -0.01,
          armL: -0.35,
          armR: 0.35,
          mouthSmile: 1,
          blush: 0.7,
          squashY: 1.04,
        );
      case AnimationState.moodExcited:
        return const PuppetPose(
          headY: -0.02,
          armL: -0.85,
          armR: 0.85,
          mouthSmile: 1,
          mouthOpen: 0.45,
          blush: 0.9,
          sparkle: 1,
          browWorry: 0.35,
          squashY: 1.12,
        );
      case AnimationState.moodSad:
        return const PuppetPose(
          headTilt: 0.16,
          headY: 0.014,
          bodySquash: 0.97,
          armL: 0.4,
          armR: -0.4,
          eyeOpen: 0.72,
          eyeScaleY: 0.72,
          mouthSmile: -0.75,
          blush: 0.2,
        );
      case AnimationState.moodDevastated:
        return const PuppetPose(
          headTilt: 0.18,
          headY: 0.016,
          bodySquash: 0.95,
          armL: 0.45,
          armR: -0.45,
          eyeOpen: 1,
          eyeScaleY: 1,
          lidDrop: 0.18,
          browDown: 1,
          mouthSmile: -1,
          blush: 0.15,
          tear: 1,
        );
      case AnimationState.moodOverwhelmed:
        return const PuppetPose(
          headTilt: -0.08,
          armL: -0.7,
          armR: 0.7,
          eyeOpen: 1,
          eyeScaleY: 1.06,
          browWorry: 1,
          mouthSmile: -0.15,
          mouthOpen: 0.55,
          blush: 0.65,
          sweat: 1,
        );
      case AnimationState.moodTired:
        return const PuppetPose(
          headTilt: 0.12,
          headY: 0.008,
          bodySquash: 0.97,
          eyeOpen: 1,
          eyeScaleY: 1,
          lidDrop: 0.52,
          browDown: 0.55,
          mouthSmile: 0.08,
          blush: 0.2,
        );
      case AnimationState.petting:
      case AnimationState.feeding:
        return const PuppetPose(
          armR: 0.9,
          mouthSmile: 0.85,
          blush: 0.5,
        );
      case AnimationState.walking:
        return const PuppetPose(
          mouthSmile: 0.6,
          squashY: 1.02,
        );
      case AnimationState.idle:
      case AnimationState.sitting:
        return const PuppetPose();
    }
  }
}
