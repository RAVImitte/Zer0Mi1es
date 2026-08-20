import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../couple/data/supabase_couple_repository.dart';
import '../data/supabase_outfit_repository.dart';

class OutfitScreen extends ConsumerStatefulWidget {
  const OutfitScreen({super.key});

  @override
  ConsumerState<OutfitScreen> createState() => _OutfitScreenState();
}

class _OutfitScreenState extends ConsumerState<OutfitScreen> {
  final Map<String, Color> _availableColors = {
    'Red': Colors.red,
    'Blue': Colors.blue,
    'Green': Colors.green,
    'Yellow': Colors.yellow,
    'Orange': Colors.orange,
    'Purple': Colors.purple,
    'Black': Colors.black,
    'White': Colors.white,
    'Pink': Colors.pink,
    'Teal': Colors.teal,
  };

  String? _selectedTop;
  String? _selectedBottom;
  bool _isLoading = false;

  void _saveOutfit() async {
    if (_selectedTop == null || _selectedBottom == null) return;
    
    setState(() => _isLoading = true);
    final coupleId = ref.read(activeCoupleIdProvider).value;
    
    if (coupleId != null) {
      try {
        await ref.read(outfitRepositoryProvider).saveOutfit(coupleId, _selectedTop!, _selectedBottom!);
        if (mounted) {
          context.go('/');
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saving outfit: $e')));
        }
      }
    }
    
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Outfit'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'What are you wearing today?',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Your partner\'s avatar will update to match your outfit!',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              
              const Text('Top Color', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              _buildColorSelector(true),
              
              const SizedBox(height: 32),
              
              const Text('Bottom Color', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              _buildColorSelector(false),
              
              const Spacer(),
              
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: (_selectedTop != null && _selectedBottom != null && !_isLoading) ? _saveOutfit : null,
                child: _isLoading 
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Save Outfit', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildColorSelector(bool isTop) {
    final selectedColorName = isTop ? _selectedTop : _selectedBottom;
    
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: _availableColors.entries.map((entry) {
        final isSelected = selectedColorName == entry.key;
        return GestureDetector(
          onTap: () {
            setState(() {
              if (isTop) {
                _selectedTop = entry.key;
              } else {
                _selectedBottom = entry.key;
              }
            });
          },
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: entry.value,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? AppColors.primary : Colors.grey.shade300,
                width: isSelected ? 4 : 1,
              ),
              boxShadow: [
                if (isSelected)
                  BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 8, spreadRadius: 2),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
