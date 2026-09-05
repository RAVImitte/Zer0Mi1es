import 'package:flutter/material.dart';

import '../avatar_view_model.dart';
import 'layered_person_avatar.dart';

class DynamicPersonAvatar extends StatelessWidget {
  const DynamicPersonAvatar({
    super.key,
    required this.state,
    required this.topColor,
    required this.bottomColor,
    this.isBunny = false,
    this.size = 150.0,
  });

  final AnimationState state;
  final Color topColor;
  final Color bottomColor;
  final bool isBunny;
  final double size;

  @override
  Widget build(BuildContext context) {
    return LayeredPersonAvatar(
      state: state,
      topColor: topColor,
      bottomColor: bottomColor,
      isBunny: isBunny,
      size: size,
    );
  }
}
