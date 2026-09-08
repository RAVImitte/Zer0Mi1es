import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/widgets/app_sheet.dart';
import '../../../auth/data/supabase_auth_repository.dart';
import '../../../auth/presentation/auth_view_model.dart';
import '../../../couple/data/supabase_couple_repository.dart';

/// Returns `true` when the user asked to replay the home guide.
Future<bool> showSettingsSheet(BuildContext context, WidgetRef ref) async {
  final partner = ref.read(partnerNameProvider).value;
  final paired = ref.read(activeCoupleIdProvider).value != null;
  final replay = await showAppSheet<bool>(
    context: context,
    builder: (context) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(AppIcons.person, color: AppColors.primary),
              title: const Text('You'),
              onTap: () {
                Navigator.pop(context);
                _editName(context, ref);
              },
            ),
            ListTile(
              leading: Icon(AppIcons.love, color: AppColors.primary),
              title: const Text('Partner'),
              subtitle: Text(
                paired
                    ? (partner ?? 'Paired')
                    : 'Not paired yet',
              ),
              onTap: () {
                Navigator.pop(context);
                context.push(AppRoutes.couple);
              },
            ),
            if (Platform.isAndroid)
              ListTile(
                leading: Icon(AppIcons.widget, color: AppColors.primary),
                title: const Text('Home screen widget'),
                onTap: () {},
              ),
            ListTile(
              leading: Icon(AppIcons.bell, color: AppColors.textSecondary),
              title: const Text('Notifications'),
              onTap: () => launchUrl(Uri.parse(
                Platform.isIOS
                    ? 'app-settings:'
                    : 'package:com.example.zer0mi1es',
              )),
            ),
            ListTile(
              leading: Icon(AppIcons.help, color: AppColors.primary),
              title: const Text('Help'),
              subtitle: const Text('See the home guide again'),
              onTap: () => Navigator.pop(context, true),
            ),
            ListTile(
              leading: Icon(AppIcons.logout, color: AppColors.textSecondary),
              title: const Text('Sign out'),
              onTap: () async {
                Navigator.pop(context);
                final ok = await _confirm(
                  context,
                  title: 'Sign out?',
                  body: 'You can sign back in anytime.',
                  action: 'Sign out',
                );
                if (ok) {
                  HapticFeedback.lightImpact();
                  ref.read(authViewModelProvider.notifier).signOut();
                }
              },
            ),
            ListTile(
              leading: Icon(AppIcons.trash, color: AppColors.danger),
              title: const Text('Delete account',
                  style: TextStyle(color: AppColors.danger)),
              onTap: () async {
                Navigator.pop(context);
                await _confirmDeleteAccount(context, ref);
              },
            ),
            const SizedBox(height: 8),
            Text(
              'Zero Miles 2.0.0+2',
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
        ),
      );
    },
  );
  return replay == true;
}

Future<void> _editName(BuildContext context, WidgetRef ref) async {
  final controller = TextEditingController();
  final saved = await showAppSheet<bool>(
    context: context,
    isScrollControlled: true,
    builder: (context) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Your name', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              maxLength: 24,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Display name'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                if (controller.text.trim().isEmpty) return;
                Navigator.pop(context, true);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      );
    },
  );
  final name = controller.text.trim();
  controller.dispose();
  if (saved == true && name.isNotEmpty) {
    await ref.read(authRepositoryProvider).updateDisplayName(name);
  }
}

Future<bool> _confirm(
  BuildContext context, {
  required String title,
  required String body,
  required String action,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(action),
          ),
        ],
      );
    },
  );
  return result == true;
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