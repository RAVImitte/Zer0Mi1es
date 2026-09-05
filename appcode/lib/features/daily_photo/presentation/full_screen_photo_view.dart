import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../data/supabase_photo_repository.dart';
import '../domain/daily_photo.dart';

class FullScreenPhotoView extends ConsumerStatefulWidget {
  final String imageUrl;
  final DailyPhoto photo;
  final bool isMyPhoto;

  const FullScreenPhotoView({
    super.key,
    required this.imageUrl,
    required this.photo,
    required this.isMyPhoto,
  });

  @override
  ConsumerState<FullScreenPhotoView> createState() => _FullScreenPhotoViewState();
}

class _FullScreenPhotoViewState extends ConsumerState<FullScreenPhotoView> {
  final TextEditingController _reactionController = TextEditingController();
  final List<String> _quickEmojis = ['💖', '🔥', '😂', '🥺', '😍'];
  bool _isSubmitting = false;

  @override
  void dispose() {
    _reactionController.dispose();
    super.dispose();
  }

  Future<void> _downloadImage() async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saving photo...')));
      final request = await HttpClient().getUrl(Uri.parse(widget.imageUrl));
      final response = await request.close();
      final bytes = await consolidateHttpClientResponseBytes(response);
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/zeromiles_photo_${widget.photo.id}.jpg');
      await file.writeAsBytes(bytes);
      await Gal.putImage(file.path);
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved to Gallery! 🖼️')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save: $e')));
      }
    }
  }

  Future<void> _submitReaction({String? emoji, String? text}) async {
    if (_isSubmitting) return;
    
    // Don't submit if both are null/empty
    if ((emoji == null || emoji.isEmpty) && (text == null || text.trim().isEmpty)) return;
    
    setState(() => _isSubmitting = true);
    
    try {
      await ref.read(photoRepositoryProvider).reactToPhoto(
        widget.photo.id,
        emoji: emoji,
        text: text?.trim(),
      );
      
      if (mounted) {
        if (text != null) _reactionController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reaction sent! 💌'), duration: Duration(seconds: 1)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to react: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.download, color: Colors.white),
            onPressed: _downloadImage,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Zoomable Image
          InteractiveViewer(
            panEnabled: true,
            minScale: 0.5,
            maxScale: 4.0,
            child: Center(
              child: Hero(
                tag: 'photo_${widget.photo.id}',
                child: Image.network(
                  widget.imageUrl,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          
          // 2. Reaction Display (Top Right Chat Bubble)
          if (widget.photo.reactionEmoji != null || widget.photo.reactionText != null)
            Positioned(
              top: kToolbarHeight + 20,
              right: 20,
              child: Container(
                constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.7),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                    topRight: Radius.circular(4),
                  ),
                  border: Border.all(color: Colors.white.withOpacity(0.3)),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.photo.reactionEmoji != null)
                      Text(widget.photo.reactionEmoji!, style: const TextStyle(fontSize: 20)),
                    if (widget.photo.reactionEmoji != null && widget.photo.reactionText != null)
                      const SizedBox(width: 8),
                    if (widget.photo.reactionText != null)
                      Flexible(
                        child: Text(
                          widget.photo.reactionText!,
                          style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          // 3. Bottom UI (Reactions & Inputs)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + MediaQuery.of(context).viewPadding.bottom + 20,
                top: 40,
                left: 16,
                right: 16,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.black.withOpacity(0.95), Colors.transparent],
                  stops: const [0.3, 1.0],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [


                  // React Interaction Area (Only if it's the partner's photo)
                  if (!widget.isMyPhoto) ...[
                    // Quick Emojis
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: _quickEmojis.map((emoji) => _buildEmojiButton(emoji)).toList(),
                    ),
                    const SizedBox(height: 20),
                    // Custom Text Reply
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: TextField(
                              controller: _reactionController,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                hintText: 'Send a reply...',
                                hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: _isSubmitting 
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Icon(Icons.send, color: Colors.white),
                            onPressed: () {
                              if (_reactionController.text.trim().isNotEmpty) {
                                _submitReaction(text: _reactionController.text);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ],

                  // Photo Caption (Very short non bg text)
                  if (widget.photo.comment != null && widget.photo.comment!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      '${widget.isMyPhoto ? "You" : "Partner"}: ${widget.photo.comment}',
                      style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w400),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmojiButton(String emoji) {
    return GestureDetector(
      onTap: () => _submitReaction(emoji: emoji),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Text(emoji, style: const TextStyle(fontSize: 28)),
      ),
    );
  }
}
