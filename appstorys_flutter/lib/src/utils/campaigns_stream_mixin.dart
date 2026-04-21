import 'dart:async';
import 'package:flutter/widgets.dart';

mixin CampaignsStreamMixin<T extends StatefulWidget> on State<T> {
  StreamSubscription<String>? _campaignsSub;

  void subscribeToCampaigns(
    Stream<String> stream,
    void Function(String json) onUpdate, {
    void Function()? onError,
  }) {
    _campaignsSub = stream.listen(
      onUpdate,
      onError: (Object _) => onError?.call(),
    );
  }

  @override
  void dispose() {
    _campaignsSub?.cancel();
    super.dispose();
  }
}
