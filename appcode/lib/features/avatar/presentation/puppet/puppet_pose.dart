import '../../domain/avatar_event.dart';

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

  static PuppetPose forState(AnimationState state, {bool leftSeat = true}) {
    switch (state) {
      case AnimationState.sleeping:
        return const PuppetPose(
          headTilt: 0.2,
          headY: 0.01,
          bodySquash: 0.99,
          armL: 0.35,
          armR: -0.35,
          eyeOpen: 0,
          mouthSmile: 0.12,
          blush: 0.18,
        );
      case AnimationState.moodHappy:
        return const PuppetPose(
          headY: -0.012,
          armL: -0.35,
          armR: 0.35,
          mouthSmile: 1,
          blush: 0.7,
          squashY: 1.015,
        );
      case AnimationState.moodExcited:
        return const PuppetPose(
          headY: -0.018,
          armL: -0.85,
          armR: 0.85,
          mouthSmile: 1,
          mouthOpen: 0.45,
          blush: 0.9,
          sparkle: 1,
          browWorry: 0.35,
          squashY: 1.03,
        );
      case AnimationState.moodSad:
        return const PuppetPose(
          headTilt: 0.16,
          headY: 0.012,
          bodySquash: 0.99,
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
          headY: 0.014,
          bodySquash: 0.985,
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
      case AnimationState.moodAngry:
        return const PuppetPose(
          headTilt: -0.05,
          headY: 0.006,
          bodySquash: 0.99,
          armL: 0.45,
          armR: -0.45,
          eyeOpen: 1,
          eyeScaleY: 0.82,
          browDown: 1,
          mouthSmile: -0.3,
          blush: 0.9,
          squashX: 1.025,
          squashY: 0.985,
        );
      case AnimationState.moodTired:
        return const PuppetPose(
          headTilt: 0.12,
          headY: 0.008,
          bodySquash: 0.99,
          eyeOpen: 1,
          eyeScaleY: 1,
          lidDrop: 0.52,
          browDown: 0.55,
          mouthSmile: 0.08,
          blush: 0.2,
        );
      case AnimationState.idle:
        return const PuppetPose();
      case AnimationState.giving:
        return leftSeat
            ? const PuppetPose(
                headTilt: 0.1,
                armR: -1.05,
                mouthSmile: 0.9,
                mouthOpen: 0.22,
                blush: 1,
              )
            : const PuppetPose(
                headTilt: -0.1,
                armL: 1.05,
                mouthSmile: 0.9,
                mouthOpen: 0.22,
                blush: 1,
              );
      case AnimationState.receiving:
        return const PuppetPose(
          headTilt: -0.04,
          armL: -0.55,
          armR: 0.55,
          mouthSmile: 1,
          blush: 1,
          heartEyes: 1,
          squashX: 1.02,
          squashY: 1.02,
        );
      case AnimationState.leanIn:
        return leftSeat
            ? const PuppetPose(
                headTilt: 0.16,
                armR: -0.95,
                armL: 0.32,
                mouthSmile: 1,
                blush: 0.85,
              )
            : const PuppetPose(
                headTilt: -0.16,
                armL: 0.95,
                armR: -0.32,
                mouthSmile: 1,
                blush: 0.85,
              );
      case AnimationState.sorry:
        return leftSeat
            ? const PuppetPose(
                headTilt: 0.28,
                headY: 0.01,
                armL: 0.4,
                armR: -0.15,
                mouthSmile: 0.05,
                blush: 0.55,
                sweat: 0.7,
              )
            : const PuppetPose(
                headTilt: -0.28,
                headY: 0.01,
                armR: -0.4,
                armL: 0.15,
                mouthSmile: 0.05,
                blush: 0.55,
                sweat: 0.7,
              );
    }
  }
}
