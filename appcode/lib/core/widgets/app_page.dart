import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../theme/app_icons.dart';

class AppPage extends StatelessWidget {
  const AppPage({
    super.key,
    required this.title,
    required this.body,
    this.actions,
    this.floatingActionButton,
    this.resizeToAvoidBottomInset = true,
    this.backgroundColor,
    this.foregroundColor,
  });

  final String title;
  final Widget body;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final bool resizeToAvoidBottomInset;
  final Color? backgroundColor;
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) {
    final bg = backgroundColor ?? AppColors.background;
    final fg = foregroundColor ?? AppColors.textPrimary;
    final overlay = bg.computeLuminance() > 0.5
        ? SystemUiOverlayStyle.dark
        : SystemUiOverlayStyle.light;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlay,
      child: Scaffold(
        backgroundColor: bg,
        resizeToAvoidBottomInset: resizeToAvoidBottomInset,
        appBar: AppBar(
          systemOverlayStyle: overlay,
          leading: ModalRoute.of(context)?.canPop == true
              ? IconButton(
                  tooltip: 'Back',
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: Icon(AppIcons.back, color: fg),
                )
              : null,
          title: Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(color: fg),
          ),
          actions: actions,
        ),
        floatingActionButton: floatingActionButton,
        body: SafeArea(child: body),
      ),
    );
  }
}