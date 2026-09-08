import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/app_colors.dart';
import '../theme/app_icons.dart';
import '../theme/app_radii.dart';

final connectivityProvider = StreamProvider<List<ConnectivityResult>>((ref) async* {
  final connectivity = Connectivity();
  yield await connectivity.checkConnectivity();
  yield* connectivity.onConnectivityChanged;
});

class AppOfflineBanner extends ConsumerWidget {
  const AppOfflineBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(connectivityProvider);
    final results = async.asData?.value;
    if (results == null) return const SizedBox.shrink();
    final offline = results.isEmpty ||
        results.every((r) => r == ConnectivityResult.none);
    if (!offline) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppColors.elevated,
        borderRadius: BorderRadius.circular(AppRadii.card),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              Icon(AppIcons.wifiSlash, size: 18, color: AppColors.waiting),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'You’re offline. We’ll catch up when you’re back.',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.textPrimary,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}