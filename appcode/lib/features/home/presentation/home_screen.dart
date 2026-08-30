import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../couple/data/supabase_couple_repository.dart';
import '../../outfit/data/supabase_outfit_repository.dart';
import 'widgets/partner_presence.dart';
import 'widgets/daily_status.dart';
import 'widgets/connection_actions.dart';
import 'providers/partner_status_provider.dart';
import '../../notifications/service/push_notification_service.dart';
import '../../auth/presentation/auth_view_model.dart';
import '../data/supabase_connection_repository.dart';

import '../../avatar/presentation/widgets/dynamic_person_avatar.dart';
import '../../avatar/presentation/avatar_view_model.dart';


final loveDropsProvider = StreamProvider.autoDispose.family<LoveDropMessage, String>((ref, coupleId) {
  return ref.watch(connectionRepositoryProvider).watchLoveDrops(coupleId);
});

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Check if outfit is selected for today, if not push to outfit screen
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final activeCoupleId = ref.read(activeCoupleIdProvider).value;
      if (activeCoupleId != null) {
        final outfitRepo = ref.read(outfitRepositoryProvider);
        final hasOutfit = await outfitRepo.hasOutfitForToday(activeCoupleId);
        if (!hasOutfit && mounted) {
          context.push('/outfit');
        }
      }
      
      // Request permissions and save FCM token for push notifications
      PushNotificationService().initialize();
    });
  }

  Color _parseColor(String str, Color defaultColor) {
    if (str.startsWith('#')) {
      final hex = str.substring(1);
      if (hex.length == 6) {
        return Color(int.parse('FF$hex', radix: 16));
      } else if (hex.length == 8) {
        return Color(int.parse(hex, radix: 16));
      }
    }
    final Map<String, Color> oldMap = {
      'Red': Colors.red, 'Blue': Colors.blue, 'Green': Colors.green,
      'Yellow': Colors.yellow, 'Orange': Colors.orange, 'Purple': Colors.purple,
      'Black': Colors.black, 'White': Colors.white, 'Pink': Colors.pink, 'Teal': Colors.teal,
    };
    return oldMap[str] ?? defaultColor;
  }

  @override
  Widget build(BuildContext context) {
    // Listen for custom love drops
    final activeCoupleId = ref.watch(activeCoupleIdProvider).value;
    if (activeCoupleId != null) {
      ref.listen<AsyncValue<LoveDropMessage>>(
        loveDropsProvider(activeCoupleId),
        (previous, next) {
          if (next.hasValue && next.value != null && mounted) {
            final drop = next.value!;
            final partnerName = ref.read(partnerNameProvider).value ?? 'Your partner';
            
            String text = '$partnerName sent a ${drop.type}!';
            if (drop.message != null && drop.message!.isNotEmpty) {
               text = '"${drop.type}" $partnerName says: "${drop.message}"';
            }
            
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(text, style: const TextStyle(fontWeight: FontWeight.bold)),
                backgroundColor: Colors.pinkAccent,
                duration: const Duration(seconds: 4),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            );
          }
        },
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Zer0Mi1es', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
        actions: [
          GestureDetector(
            onLongPress: () {
              showDialog(
                context: context,
                builder: (BuildContext dialogContext) {
                  return AlertDialog(
                    title: const Text('Delete Account'),
                    content: const Text('Are you sure you want to completely delete your account? This will permanently delete your couple and all associated data.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(dialogContext);
                          ref.read(authViewModelProvider.notifier).deleteAccount();
                        },
                        child: const Text('Delete', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  );
                },
              );
            },
            child: IconButton(
              icon: const Icon(Icons.logout, color: AppColors.secondary),
              onPressed: () {
                ref.read(authViewModelProvider.notifier).signOut();
              },
            ),
          ),
        ],
      ),
      body: const SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Spacer(flex: 1),
              
              // 1. Partner Avatar & Pet
              Expanded(
                flex: 6,
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: PartnerPresence(),
                  ),
                ),
              ),
              
              Spacer(flex: 1),
              
              // 2. Daily Rituals Status
              DailyStatus(),
              
              Spacer(flex: 1),
              
              // 3. Connection Actions
              ConnectionActions(),
              
              Spacer(flex: 1),
            ],
          ),
        ),
      ),
    );
  }
}
