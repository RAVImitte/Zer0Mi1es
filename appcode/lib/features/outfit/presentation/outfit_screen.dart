import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';

import '../../../core/utils/color_parser.dart';
import '../../../core/widgets/app_page.dart';
import '../../avatar/domain/avatar_event.dart';
import '../../avatar/presentation/widgets/layered_person_avatar.dart';
import '../../couple/data/supabase_couple_repository.dart';
import '../data/supabase_outfit_repository.dart';
import 'providers/outfit_providers.dart';

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
  bool _prefilled = false;

  String _colorToHex(Color color) {
    return '#${color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
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
              _colorToHex(_selectedBottom!),
            );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Outfit updated')),
          );
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not save that outfit')),
          );
        }
      }
    }

    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final partnerName = ref.watch(partnerNameProvider).value ?? 'them';
    final coupleId = ref.watch(activeCoupleIdProvider).value;
    final myRole = ref.watch(myRoleProvider).value;
    final isBunny = myRole == CoupleRole.bunny;

    if (coupleId != null && !_prefilled) {
      final mine = ref.watch(myOutfitProvider(coupleId)).value;
      if (mine != null) {
        _prefilled = true;
        _selectedTop = parseHexColor(mine['top_color'] as String);
        _selectedBottom = parseHexColor(mine['bottom_color'] as String);
      }
    }

    Map<String, dynamic>? partnerOutfit;
    if (coupleId != null) {
      partnerOutfit = ref.watch(partnerOutfitProvider(coupleId)).value;
    }

    return AppPage(
      title: 'My outfit',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'What are you wearing today?',
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'They’ll see this on you.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Center(
              child: LayeredPersonAvatar(
                state: AnimationState.idle,
                topColor: _selectedTop ?? AppColors.primary.withValues(alpha: 0.3),
                bottomColor:
                    _selectedBottom ?? AppColors.primary.withValues(alpha: 0.3),
                isBunny: isBunny,
                size: 140,
              ),
            ),
            const SizedBox(height: 24),
            const Text('Top',
                style: TextStyle(
                    color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _buildColorSelector(true),
            const SizedBox(height: 24),
            const Text('Bottom',
                style: TextStyle(
                    color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _buildColorSelector(false),
            if (partnerOutfit != null) ...[
              const SizedBox(height: 20),
              OutlinedButton(
                onPressed: () {
                  setState(() {
                    _selectedTop =
                        parseHexColor(partnerOutfit!['top_color'] as String);
                    _selectedBottom =
                        parseHexColor(partnerOutfit['bottom_color'] as String);
                  });
                },
                child: Text('Match $partnerName'),
              ),
            ],
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: (_selectedTop != null &&
                      _selectedBottom != null &&
                      !_isLoading)
                  ? _saveOutfit
                  : null,
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Color(0xFF2A1614)))
                  : const Text('Save outfit'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorSelector(bool isTop) {
    final selectedColor = isTop ? _selectedTop : _selectedBottom;
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
        GestureDetector(
          onTap: () => _showColorPicker(isTop),
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isCustomSelected ? selectedColor : AppColors.surface,
              shape: BoxShape.circle,
              border: Border.all(
                color: isCustomSelected ? AppColors.primary : AppColors.hairline,
                width: isCustomSelected ? 3 : 1,
              ),
            ),
            child: Icon(AppIcons.palette, color: AppColors.primary, size: 20),
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
            color: isSelected ? AppColors.primary : AppColors.hairline,
            width: isSelected ? 3 : 1,
          ),
        ),
      ),
    );
  }

  void _showColorPicker(bool isTop) {
    Color pickerColor =
        (isTop ? _selectedTop : _selectedBottom) ?? AppColors.primary;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Custom color'),
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
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Use'),
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