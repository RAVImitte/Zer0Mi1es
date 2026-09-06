import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_sheet.dart';
import '../../../auth/presentation/auth_view_model.dart';

Future<void> showSettingsSheet(BuildContext context, WidgetRef ref) {
  return showAppSheet(
    context: context,
    builder: (context) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.favorite_outline, color: AppColors.primary),
              title: const Text('Partner'),
              subtitle: const Text('Pair or manage your connection'),
              onTap: () {
                Navigator.pop(context);
                context.push(AppRoutes.couple);
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: AppColors.textSecondary),
              title: const Text('Sign out'),
              onTap: () {
                Navigator.pop(context);
                HapticFeedback.lightImpact();
                ref.read(authViewModelProvider.notifier).signOut();
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: AppColors.danger),
              title: const Text('Delete account',
                  style: TextStyle(color: AppColors.danger)),
              onTap: () async {
                Navigator.pop(context);
                await _confirmDeleteAccount(context, ref);
              },
            ),
            if (kDebugMode)
              ListTile(
                leading: const Icon(Icons.bug_report_outlined,
                    color: AppColors.textSecondary),
                title: const Text('Send test crash'),
                onTap: () => FirebaseCrashlytics.instance.crash(),
              ),
          ],
        ),
      );
    },
  );
}

Future<void> _confirmDeleteAccount(BuildContext context, WidgetRef ref) async {
  final controller = TextEditingController();
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text('Delete account'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This permanently deletes your couple and all shared data. Type DELETE to confirm.',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(hintText: 'DELETE'),
              textCapitalization: TextCapitalization.characters,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.trim() == 'DELETE') {
                Navigator.pop(dialogContext, true);
              }
            },
            child: const Text('Delete', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      );
    },
  );
  controller.dispose();
  if (confirmed == true) {
    await ref.read(authViewModelProvider.notifier).deleteAccount();
  }
}