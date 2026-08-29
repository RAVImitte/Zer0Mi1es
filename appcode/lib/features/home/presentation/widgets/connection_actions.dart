import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../couple/data/supabase_couple_repository.dart';
import '../../data/supabase_connection_repository.dart';

class IsAsleepNotifier extends Notifier<bool> {
  @override
  bool build() => false;
  void toggle() => state = !state;
}

final isAsleepProvider =
    NotifierProvider<IsAsleepNotifier, bool>(IsAsleepNotifier.new);

class ConnectionActions extends ConsumerWidget {
  const ConnectionActions({super.key});

  void _fireNetworkEvent(
      WidgetRef ref,
      BuildContext context,
      Future<void> Function(ConnectionRepository repo, String coupleId)
          action) async {
    final coupleId = ref.read(activeCoupleIdProvider).value;
    if (coupleId != null) {
      final repo = ref.read(connectionRepositoryProvider);
      try {
        await action(repo, coupleId);
        final partnerName = ref.read(partnerNameProvider).value ?? 'partner';
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Sent to $partnerName!'),
                duration: const Duration(seconds: 1)),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to send: $e')),
          );
        }
      }
    }
  }

  void _showMoodBottomSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        final moods = [
          'Happy',
          'Sad',
          'Devastated',
          'Overwhelmed',
          'Excited',
          'Tired'
        ];
        final emojis = ['😊', '😢', '😭', '🤯', '🤩', '😴'];

        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('How are you feeling?',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              Wrap(
                spacing: 16,
                runSpacing: 16,
                alignment: WrapAlignment.center,
                children: List.generate(moods.length, (index) {
                  return InkWell(
                    onTap: () {
                      Navigator.pop(context);
                      _fireNetworkEvent(ref, context,
                          (repo, id) => repo.updateMood(id, moods[index]));
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(emojis[index],
                              style: const TextStyle(fontSize: 32)),
                          const SizedBox(height: 8),
                          Text(moods[index],
                              style: const TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  void _showTalkBottomSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('I want to...',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              ListTile(
                leading: const Icon(Icons.chat),
                title: const Text('Text'),
                onTap: () {
                  Navigator.pop(context);
                  _fireNetworkEvent(
                      ref, context, (repo, id) => repo.sendSignal(id, 'text'));
                },
              ),
              ListTile(
                leading: const Icon(Icons.call),
                title: const Text('Call'),
                onTap: () {
                  Navigator.pop(context);
                  _fireNetworkEvent(
                      ref, context, (repo, id) => repo.sendSignal(id, 'call'));
                },
              ),
              ListTile(
                leading: const Icon(Icons.video_call),
                title: const Text('Video Call'),
                onTap: () {
                  Navigator.pop(context);
                  _fireNetworkEvent(ref, context,
                      (repo, id) => repo.sendSignal(id, 'video_call'));
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showLoveDropBottomSheet(BuildContext context, WidgetRef ref) {
    final textController = TextEditingController();
    final types = ['Kiss', 'Hug', 'Heart', 'Sorry'];
    final emojis = ['😽', '🤗', '💖', '🥺'];
    String selectedType = types[0];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(builder: (context, setState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              left: 24,
              right: 24,
              top: 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Send a Love Drop',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: List.generate(types.length, (index) {
                    final isSelected = selectedType == types[index];
                    return InkWell(
                      onTap: () => setState(() => selectedType = types[index]),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary.withValues(alpha: 0.2)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: isSelected
                                  ? AppColors.primary
                                  : Colors.grey.shade300),
                        ),
                        child: Column(
                          children: [
                            Text(emojis[index],
                                style: const TextStyle(fontSize: 24)),
                            const SizedBox(height: 4),
                            Text(types[index],
                                style: const TextStyle(fontSize: 12)),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: textController,
                  decoration: InputDecoration(
                    hintText: 'Add an optional message...',
                    filled: true,
                    fillColor: Colors.grey.withValues(alpha: 0.1),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      final msg = textController.text.trim();
                      _fireNetworkEvent(
                          ref,
                          context,
                          (repo, id) => repo.sendLoveDrop(id, selectedType,
                              message: msg.isNotEmpty ? msg : null));
                    },
                    child: const Text('Send'),
                  ),
                )
              ],
            ),
          );
        });
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAsleep = ref.watch(isAsleepProvider);
    final activeCoupleId = ref.watch(activeCoupleIdProvider).value;
    final isPaired = activeCoupleId != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Connect',
          style: TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                context: context,
                icon: Icons.favorite,
                label: 'Love Drop',
                color: Colors.pinkAccent,
                isPaired: isPaired,
                onTap: () => _showLoveDropBottomSheet(context, ref),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                context: context,
                icon: Icons.mood,
                label: 'Mood Sync',
                color: Colors.orangeAccent,
                isPaired: isPaired,
                onTap: () => _showMoodBottomSheet(context, ref),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                context: context,
                icon: Icons.record_voice_over,
                label: 'I Want to Talk',
                color: Colors.blueAccent,
                isPaired: isPaired,
                onTap: () => _showTalkBottomSheet(context, ref),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                context: context,
                icon: isAsleep ? Icons.wb_sunny : Icons.bedtime,
                label: isAsleep ? 'Wake Up' : 'Sleep',
                color: isAsleep ? Colors.orange : Colors.indigo,
                isPaired: isPaired,
                onTap: () {
                  final signal = isAsleep ? 'goodMorning' : 'goodNight';
                  _fireNetworkEvent(
                      ref, context, (repo, id) => repo.sendSignal(id, signal));
                  ref.read(isAsleepProvider.notifier).toggle();
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    required bool isPaired,
    required VoidCallback onTap,
  }) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: isPaired ? onTap : () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Pair with your partner first to unlock!'),
              duration: Duration(seconds: 2),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: isPaired ? color : Colors.grey, size: 28),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  color: isPaired ? AppColors.textPrimary : Colors.grey,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
