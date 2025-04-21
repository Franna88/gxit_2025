import 'package:flutter/widgets.dart';

/// Service to handle app lifecycle events and perform cleanup
class LifecycleService with WidgetsBindingObserver {
  final VoidCallback onAppClosed;

  LifecycleService({required this.onAppClosed}) {
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.detached) {
      // App is being closed or killed
      onAppClosed();
    }
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
  }
}
