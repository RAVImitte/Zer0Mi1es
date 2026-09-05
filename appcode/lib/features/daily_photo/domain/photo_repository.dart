import 'dart:io';

import 'daily_photo.dart';

abstract class PhotoRepository {
  Future<void> uploadDailyPhoto(String coupleId, File imageFile, {String? comment});

  Stream<List<DailyPhoto>> watchTodayPhotos(String coupleId);

  Future<String> getSignedUrl(String path);

  Future<bool> hasPartnerUploadedPhoto(String coupleId);

  Future<void> reactToPhoto(String photoId, {String? emoji, String? text});
}
