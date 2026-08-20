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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Zer0Mi1es', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: AppColors.secondary),
            onPressed: () async {
              await Supabase.instance.client.auth.signOut();
            },
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
