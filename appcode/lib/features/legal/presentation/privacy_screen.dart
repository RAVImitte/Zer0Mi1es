import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        children: const [
          _Section(
            title: 'Two people only',
            body:
                'Zero Miles is a two-person couple app. There is no social graph, public profile, or feed. A third person cannot join a full couple.',
          ),
          _Section(
            title: 'Couple-scoped data',
            body:
                'Photos, moods, daily answers, and other couple rows are readable only by you and your paired partner. The database enforces this with row-level security (RLS).',
          ),
          _Section(
            title: 'What we store',
            body:
                'Display name and email for your account; photos; voice notes (table rows hidden after 24 hours; storage files may remain); pairing codes (24 hours, stored hashed); moods; daily answers; and an FCM push token on your profile. We do not sell this data.',
          ),
          _Section(
            title: 'In transit and processors',
            body:
                'Traffic uses TLS. Infrastructure is Supabase (auth, database, storage) and Firebase Cloud Messaging (push). We do not run analytics on couple content.',
          ),
          _Section(
            title: 'Crash reports',
            body:
                'When crash reports are collected, names, emails, and photo URLs are stripped.',
          ),
          _Section(
            title: 'Delete your account',
            body:
                'Settings → Delete account, then type DELETE. That deletes your auth account and the couple row (Postgres cascade). Storage objects become unreachable via RLS but are not purged. The on-device Android widget snapshot is not cleared. Sign out does not delete the couple.',
          ),
          _Section(
            title: 'Support',
            body:
                'Email ${SupportContact.email}. The mailbox is operated by the Zero Miles operator.',
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(body, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}
