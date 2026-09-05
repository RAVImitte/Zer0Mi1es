abstract final class RegistrationStatus {
  static const signedUp = 'signed_up';
  static const nameEntered = 'name_entered';
  static const allDone = 'all_done';
}

abstract final class CacheKeys {
  static const registrationStatus = 'registration_status_cache';
  static const activeCoupleId = 'active_couple_id_cache';
  static const partnerName = 'partner_name';
  static const partnerAnimationTable = 'cached_partner_animation_table';
  static const partnerAnimationType = 'cached_partner_animation_type';
}

abstract final class NotificationConstants {
  static const channelId = 'zer0mi1es_channel';
  static const channelName = 'Zer0Mi1es Notifications';
}

abstract final class CoupleRole {
  static const bear = 'bear';
  static const bunny = 'bunny';
}
