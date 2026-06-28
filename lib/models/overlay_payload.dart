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
  evolution('evolution');

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
  evolution;

  String get message {
    return switch (this) {
      OverlayTrigger.focusComplete => '专注完成啦！太棒了~',
      OverlayTrigger.overLimit => '你用手机有点久啦，休息一下吧~',
      OverlayTrigger.evolution => '我进化啦！快回来看看~',
    };
  }

  String get analyticsName => name;
}
