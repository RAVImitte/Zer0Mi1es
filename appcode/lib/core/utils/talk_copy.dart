String incomingTalkTitle(String name, String type) {
  return switch (type) {
    'call' => '$name wants to call',
    'video_call' => '$name wants to video chat',
    _ => '$name wants to text',
  };
}

String outgoingTalkTitle(String name, String status) {
  return switch (status) {
    'yes' => '$name said okay',
    'soon' || 'give_me_10' => '$name will be there in a bit',
    'tonight' => '$name said tonight',
    'not_now' || 'cant_today' => '$name can’t right now',
    _ => '$name replied',
  };
}
