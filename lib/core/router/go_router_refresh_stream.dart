import 'dart:async';

import 'package:flutter/foundation.dart';

/// Adapter, der einen beliebigen Stream (hier: Supabase Auth-State-Changes)
/// in ein `Listenable` für go_router's `refreshListenable` umwandelt, damit
/// die Redirect-Logik bei Login/Logout neu ausgewertet wird.
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
