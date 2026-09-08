import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_radii.dart';

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
  static const _tops = <String, Color>{
    'White': Color(0xFFF3F0EA),
    'Heather': Color(0xFFB2B4B8),
    'Black': Color(0xFF222222),
    'Navy': Color(0xFF2A3F5F),
    'Sky': Color(0xFF8FB5D4),
    'Cream': Color(0xFFE8D9C4),
    'Olive': Color(0xFF6A704C),
    'Burgundy': Color(0xFF7A3542),
    'Blush': Color(0xFFD9A8A8),
    'Brown': Color(0xFF6B4A36),
    'Sage': Color(0xFF8A9A78),
  };

  static const _bottoms = <String, Color>{
    'Denim': Color(0xFF3C5680),
    'Light denim': Color(0xFF8AA4C4),
    'Black': Color(0xFF222222),
    'Khaki': Color(0xFFC2AE84),
    'Charcoal': Color(0xFF4A4E56),
    'Grey': Color(0xFF9A9B9F),
    'Olive': Color(0xFF5C6448),
    'Cream': Color(0xFFE8D9C4),
    'Tan': Color(0xFFC4A574),
    'Brown': Color(0xFF6B4A36),
    'Navy': Color(0xFF2A3F5F),
  };

  Color? _selectedTop = _tops['White'];
  Color? _selectedBottom = _bottoms['Denim'];
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
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'What are you wearing today?',
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              'They’ll see this on you.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Center(
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadii.card),
                  border: Border.all(color: AppColors.hairline),
                ),
                child: LayeredPersonAvatar(
                  state: AnimationState.idle,
                  topColor: _selectedTop ?? _tops['White']!,
                  bottomColor: _selectedBottom ?? _bottoms['Denim']!,
                  isBunny: isBunny,
                  size: 128,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text('Top', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 10),
            _buildColorSelector(true),
            const SizedBox(height: 16),
            Text('Bottom', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 10),
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
    final colors = isTop ? _tops : _bottoms;
    final selectedColor = isTop ? _selectedTop : _selectedBottom;
    final isPresetSelected = selectedColor != null &&
        colors.values.contains(selectedColor);
    final isCustomSelected = selectedColor != null && !isPresetSelected;
    final paletteColor = selectedColor ?? AppColors.elevated;

    final tiles = <Widget>[
      ...colors.entries.map((entry) {
        return Tooltip(
          message: entry.key,
          child: _swatch(
            color: entry.value,
            selected: selectedColor == entry.value,
            onTap: () {
              setState(() {
                if (isTop) {
                  _selectedTop = entry.value;
                } else {
                  _selectedBottom = entry.value;
                }
              });
            },
          ),
        );
      }),
      _swatch(
        color: isCustomSelected ? paletteColor : AppColors.elevated,
        selected: isCustomSelected,
        onTap: () => _showColorPicker(isTop),
        child: Icon(AppIcons.palette, color: AppColors.primary, size: 16),
      ),
    ];

    return GridView.count(
      crossAxisCount: 6,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 1,
      children: tiles,
    );
  }

  Widget _swatch({
    required Color color,
    required bool selected,
    required VoidCallback onTap,
    Widget? child,
  }) {
    final isLight = color.computeLuminance() > 0.62;
    return GestureDetector(
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: selected
                ? AppColors.primary
                : (isLight
                    ? const Color(0x66F6F0E8)
                    : AppColors.hairline),
            width: selected ? 2.5 : 1,
          ),
        ),
        child: child == null ? null : Center(child: child),
      ),
    );
  }

  void _showColorPicker(bool isTop) {
    Color pickerColor =
        (isTop ? _selectedTop : _selectedBottom) ??
            (isTop ? _tops['White']! : _bottoms['Denim']!);

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