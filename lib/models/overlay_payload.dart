/// Actions that can be requested from the floating overlay pet.
enum OverlayPayload {
  feed('feed'),
  play('play'),
  pet('pet'),
  learn('learn'),
  focus('focus'),
  openApp('open_app'),
  overLimit('over_limit'),
  focusComplete('focus_complete'),
  evolution('evolution'),
  openAppLimits('open_app_limits'),
  openTimeSlots('open_time_slots');

  final String value;
  const OverlayPayload(this.value);

  static OverlayPayload? fromValue(String? value) {
    if (value == null) return null;
    for (final payload in values) {
      if (payload.value == value) return payload;
    }
    return null;
  }
}

/// Scenes that automatically show the overlay pet.
enum OverlayTrigger {
  focusComplete,
  overLimit,
  evolution,
  timeSlotBlock,
  complianceReward,
  feed,
  play,
  pet,
  learn;

  String get message {
    return switch (this) {
      OverlayTrigger.focusComplete => '专注完成啦！太棒了~',
      OverlayTrigger.overLimit => '你用手机有点久啦，休息一下吧~',
      OverlayTrigger.evolution => '我进化啦！快回来看看~',
      OverlayTrigger.timeSlotBlock => '现在是限制时段，不要玩啦~',
      OverlayTrigger.complianceReward => '今天表现超棒！所有限额都遵守了~',
      OverlayTrigger.feed => ' yummy~ 吃饱啦，更有精神学习啦！',
      OverlayTrigger.play => '玩得真开心！谢谢主人陪我~',
      OverlayTrigger.pet => '被摸摸好舒服，心情变好了呢~',
      OverlayTrigger.learn => '又学会新知识啦，主人好棒！',
    };
  }

  String get analyticsName => name;
}
