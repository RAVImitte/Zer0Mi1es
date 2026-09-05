abstract class OutfitRepository {
  Future<void> saveOutfit(String coupleId, String topColor, String bottomColor);

  Future<bool> hasOutfitForToday(String coupleId);

  Stream<Map<String, dynamic>?> watchPartnerOutfit(String coupleId);

  Stream<Map<String, dynamic>?> watchMyOutfit(String coupleId);
}
