import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../couple/data/supabase_couple_repository.dart';
import '../data/supabase_outfit_repository.dart';

class OutfitScreen extends ConsumerStatefulWidget {
  const OutfitScreen({super.key});

  @override
  ConsumerState<OutfitScreen> createState() => _OutfitScreenState();
}

class _OutfitScreenState extends ConsumerState<OutfitScreen> {
  final Map<String, Color> _availableColors = {
    'Black': const Color(0xFF1A1A1A),
    'White': const Color(0xFFF5F5F5),
    'Charcoal': const Color(0xFF36454F),
    'Navy': const Color(0xFF000080),
    'Denim': const Color(0xFF1560BD),
    'Khaki': const Color(0xFFC3B091),
    'Beige': const Color(0xFFF5F5DC),
    'Olive': const Color(0xFF808000),
    'Burgundy': const Color(0xFF800020),
  };

  Color? _selectedTop;
  Color? _selectedBottom;
  bool _isLoading = false;

  String _colorToHex(Color color) {
    return '#${color.value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
  }

  void _saveOutfit() async {
    if (_selectedTop == null || _selectedBottom == null) return;
    
    setState(() => _isLoading = true);
    final coupleId = ref.read(activeCoupleIdProvider).value;
    
    if (coupleId != null) {
      try {
        await ref.read(outfitRepositoryProvider).saveOutfit(
          coupleId, 
          _colorToHex(_selectedTop!), 
          _colorToHex(_selectedBottom!)
        );
        if (mounted) {
          context.go(AppRoutes.home);
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
    final partnerName = ref.watch(partnerNameProvider).value ?? 'Your partner';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Outfit', style: TextStyle(color: AppColors.primary)),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
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
              Text(
                '$partnerName\'s avatar will update to match your outfit!',
                style: const TextStyle(
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
              
              const SizedBox(height: 32),
              
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
    final selectedColor = isTop ? _selectedTop : _selectedBottom;
    
    // Check if the selected color is one of the presets
    final isPresetSelected = _availableColors.values.contains(selectedColor);
    final isCustomSelected = selectedColor != null && !isPresetSelected;

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        ..._availableColors.entries.map((entry) {
          final isSelected = selectedColor == entry.value;
          return _buildColorCircle(entry.value, isSelected, () {
            setState(() {
              if (isTop) {
                _selectedTop = entry.value;
              } else {
                _selectedBottom = entry.value;
              }
            });
          });
        }),
        // Custom Color Button
        GestureDetector(
          onTap: () => _showColorPicker(isTop),
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isCustomSelected ? selectedColor : AppColors.surface,
              shape: BoxShape.circle,
              border: Border.all(
                color: isCustomSelected ? AppColors.primary : Colors.grey.shade300,
                width: isCustomSelected ? 4 : 1,
              ),
              boxShadow: [
                if (isCustomSelected)
                  BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 8, spreadRadius: 2),
              ],
            ),
            child: Icon(
              Icons.palette,
              color: isCustomSelected 
                  ? (selectedColor.computeLuminance() > 0.5 ? Colors.black.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.4))
                  : AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildColorCircle(Color color, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: color,
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
  }

  void _showColorPicker(bool isTop) {
    Color pickerColor = (isTop ? _selectedTop : _selectedBottom) ?? AppColors.primary;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Pick a color!'),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: pickerColor,
              onColorChanged: (Color color) {
                pickerColor = color;
              },
              pickerAreaHeightPercent: 0.8,
              enableAlpha: false,
              displayThumbColor: true,
              paletteType: PaletteType.hsvWithHue,
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Got it'),
              onPressed: () {
                setState(() {
                  if (isTop) {
                    _selectedTop = pickerColor;
                  } else {
                    _selectedBottom = pickerColor;
                  }
                });
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
