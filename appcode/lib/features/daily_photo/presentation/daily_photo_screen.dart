import 'dart:io';
import 'dart:ui' as dart_ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/widgets/app_error_state.dart';
import '../../../core/widgets/app_page.dart';
import '../../couple/data/supabase_couple_repository.dart';
import '../data/supabase_photo_repository.dart';
import '../domain/daily_photo.dart';
import 'full_screen_photo_view.dart';
import 'providers/photo_providers.dart';

class DailyPhotoScreen extends ConsumerStatefulWidget {
  const DailyPhotoScreen({super.key});

  @override
  ConsumerState<DailyPhotoScreen> createState() => _DailyPhotoScreenState();
}

class _DailyPhotoScreenState extends ConsumerState<DailyPhotoScreen> {
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _commentController = TextEditingController();
  bool _isUploading = false;
  
  final Map<String, String> _signedUrls = {};

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _fetchSignedUrl(DailyPhoto photo) async {
    if (!_signedUrls.containsKey(photo.id)) {
      final url = await ref.read(photoRepositoryProvider).getSignedUrl(photo.storagePath);
      if (mounted) {
        setState(() {
          _signedUrls[photo.id] = url;
        });
      }
    }
  }

  Future<void> _pickPhoto(ImageSource source) async {
    final XFile? image = await _picker.pickImage(
      source: source,
      maxWidth: 1080,
      maxHeight: 1080,
      imageQuality: 75,
    );
    if (image == null) return;
    
    if (!mounted) return;
    final coupleId = ref.read(activeCoupleIdProvider).value;
    if (coupleId == null) return;

    _showCommentDialog(File(image.path), coupleId);
  }

  Future<void> _chooseSource() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('Camera'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                title: const Text('Library'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
        );
      },
    );
    if (source != null) await _pickPhoto(source);
  }

  void _showCommentDialog(File imageFile, String coupleId) {
    _commentController.clear();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Add a Comment?', style: TextStyle(color: AppColors.textPrimary)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.file(imageFile, height: 250, fit: BoxFit.cover),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _commentController,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  hintText: 'Optional caption...',
                  hintStyle: TextStyle(color: AppColors.textSecondary),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.primary)),
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.accent)),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () {
              Navigator.pop(context);
              _uploadPhoto(imageFile, coupleId, _commentController.text.trim());
            },
            child: const Text('Upload', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _uploadPhoto(File imageFile, String coupleId, String comment) async {
    setState(() => _isUploading = true);
    
    try {
      await ref.read(photoRepositoryProvider).uploadDailyPhoto(
        coupleId, 
        imageFile, 
        comment: comment.isEmpty ? null : comment,
      );
      
      // Force refresh the stream to fetch the partner's photo which is now unlocked by RLS
      ref.invalidate(todayPhotosProvider(coupleId));
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _openFullScreen(String url, DailyPhoto photo, bool isMyPhoto) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FullScreenPhotoView(
          imageUrl: url,
          photo: photo,
          isMyPhoto: isMyPhoto,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final coupleId = ref.watch(activeCoupleIdProvider).value;
    final uid = Supabase.instance.client.auth.currentUser?.id;
    
    if (coupleId == null || uid == null) {
      return const AppPage(
        title: 'Today’s photo',
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final photosStream = ref.watch(todayPhotosProvider(coupleId));
    final partnerHasUploaded =
        ref.watch(partnerPhotoStatusProvider(coupleId)).value ?? false;
    final partnerName = ref.watch(partnerNameProvider).value ?? 'them';
    final first = partnerName.trim().split(RegExp(r'\s+')).first;

    return AppPage(
      title: 'Today’s photo',
      body: photosStream.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => AppErrorState(
          message: 'Couldn’t load today’s photos.',
          onRetry: () => ref.invalidate(todayPhotosProvider(coupleId)),
        ),
        data: (photos) {
          final myPhoto = photos.where((p) => p.userId == uid).firstOrNull;
          final partnerPhoto = photos.where((p) => p.userId != uid).firstOrNull;
          final hasMyPhoto = myPhoto != null;

          return Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                children: [
                  Expanded(
                    child: _buildLargePhotoCard(
                      title: '$first’s moment',
                      photo: partnerPhoto,
                      isMyPhoto: false,
                      isUnlocked: hasMyPhoto,
                      isPartnerUploadedHidden:
                          partnerHasUploaded && !hasMyPhoto,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: _buildLargePhotoCard(
                      title: 'Your moment',
                      photo: myPhoto,
                      isMyPhoto: true,
                      isUnlocked: true,
                      isPartnerUploadedHidden: false,
                    ),
                  ),
                  if (!hasMyPhoto) ...[
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 4,
                        ),
                        icon: _isUploading
                          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 3, color: Color(0xFF2A1614)))
                          : Icon(AppIcons.camera, size: 22),
                        label: Text(_isUploading ? 'Uploading…' : 'Share today’s photo'),
                        onPressed: _isUploading ? null : _chooseSource,
                      ),
                    ),
                  ],
                ],
              ),
            );
        },
      ),
    );
  }

  Widget _buildLargePhotoCard({
    required String title,
    required DailyPhoto? photo,
    required bool isMyPhoto,
    required bool isUnlocked,
    required bool isPartnerUploadedHidden,
  }) {
    if (photo != null) {
      _fetchSignedUrl(photo);
    }

    final hasUrl = photo != null && _signedUrls.containsKey(photo.id);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8.0, bottom: 12.0),
          child: Text(
            title.toUpperCase(),
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.2),
          ),
        ),
        Expanded(
          child: GestureDetector(
            onTap: () {
              if (photo != null && isUnlocked && hasUrl) {
                _openFullScreen(_signedUrls[photo.id]!, photo, isMyPhoto);
              }
            },
          child: Hero(
            tag: photo != null ? 'photo_${photo.id}' : 'photo_empty_$title',
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 5)),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (photo != null && isUnlocked) ...[
                      if (hasUrl)
                        Image.network(_signedUrls[photo.id]!, fit: BoxFit.cover)
                      else
                        const Center(child: CircularProgressIndicator(color: AppColors.primary)),
                      
                      // Gradient overlay for text readability
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [Colors.black.withOpacity(0.8), Colors.transparent],
                              stops: const [0.0, 0.4],
                            ),
                          ),
                        ),
                      ),
                      
                      // Comment & Reactions Overlay
                      Positioned(
                        bottom: 20,
                        left: 20,
                        right: 20,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (photo.comment != null && photo.comment!.isNotEmpty)
                              Text(
                                '"${photo.comment}"',
                                style: const TextStyle(color: Colors.white, fontSize: 16, fontStyle: FontStyle.italic),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            
                            if (photo.reactionEmoji != null || photo.reactionText != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 12.0),
                                child: Row(
                                  children: [
                                    if (photo.reactionEmoji != null)
                                      Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                                        child: Text(photo.reactionEmoji!, style: const TextStyle(fontSize: 20)),
                                      ),
                                    if (photo.reactionText != null) ...[
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          photo.reactionText!,
                                          style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ]
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ] else if (isPartnerUploadedHidden) ...[
                      // Blurred locked state
                      ImageFiltered(
                        imageFilter: dart_ui.ImageFilter.blur(sigmaX: 25, sigmaY: 25),
                        child: Container(
                          color: AppColors.primary.withOpacity(0.2),
                          child: const Center(child: Icon(Icons.image, size: 150, color: Colors.white24)),
                        ),
                      ),
                      Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.primary.withOpacity(0.5)),
                          ),
                          child: const Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.lock_outline, size: 48, color: AppColors.primary),
                              SizedBox(height: 12),
                              Text(
                                'Share your moment to see theirs',
                                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ] else if (photo != null && !isUnlocked) ...[
                      // Fallback
                      const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.lock, color: AppColors.textSecondary, size: 64),
                            SizedBox(height: 16),
                            Text('Upload yours to unlock', style: TextStyle(color: AppColors.textSecondary, fontSize: 18), textAlign: TextAlign.center),
                          ],
                        ),
                      ),
                    ] else ...[
                      // Empty state
                      Container(
                        color: AppColors.background,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(isMyPhoto ? Icons.camera_alt_outlined : Icons.hourglass_empty, color: AppColors.textSecondary.withOpacity(0.5), size: 64),
                              const SizedBox(height: 16),
                              Text(
                                isMyPhoto ? 'Take or choose today’s photo' : 'Waiting on them…',
                                style: TextStyle(color: AppColors.textSecondary.withOpacity(0.5), fontSize: 16),
                              )
                            ],
                          ),
                        ),
                      ),
                    ]
                  ],
                ),
              ),
            ),
          ),
        ),
        ),
      ],
    );
  }
}
