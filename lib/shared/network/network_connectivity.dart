import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

enum NetworkStatus { online, offline }

class NetworkNotifier extends StateNotifier<NetworkStatus> {
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  final Ref _ref;

  NetworkNotifier(this._ref) : super(NetworkStatus.online) {
    _init();
  }

  Future<void> _init() async {
    // initial check
    final initial = await _connectivity.checkConnectivity();
    await _updateFromConnectivity(initial);
    // listen for changes
    _subscription = _connectivity.onConnectivityChanged.listen(
      (results) async {
        await _updateFromConnectivity(results);
      },
    );
  }

  Future<void> _updateFromConnectivity(List<ConnectivityResult> results) async {
    final isDisconnected =
        results.isEmpty || results.every((r) => r == ConnectivityResult.none);
    if (isDisconnected) {
      state = NetworkStatus.offline;
      // Require user confirmation to dismiss overlay once offline occurs
      _ref.read(overlayNeedsDismissProvider.notifier).state = true;
      return;
    }
    // Verify actual internet reachability
    final ok = await _hasInternet();
    state = ok ? NetworkStatus.online : NetworkStatus.offline;
    if (!ok) {
      _ref.read(overlayNeedsDismissProvider.notifier).state = true;
    }
  }

  Future<bool> _hasInternet() async {
    try {
      final resp = await http
          .head(Uri.parse('https://www.google.com'))
          .timeout(const Duration(seconds: 3));
      return resp.statusCode >= 200 && resp.statusCode < 400;
    } catch (_) {
      return false;
    }
  }

  Future<void> retry() async {
    final current = await _connectivity.checkConnectivity();
    await _updateFromConnectivity(current);
    // If now online after explicit retry, dismiss overlay
    if (state == NetworkStatus.online) {
      _ref.read(overlayNeedsDismissProvider.notifier).state = false;
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

final networkStatusProvider =
    StateNotifierProvider<NetworkNotifier, NetworkStatus>((ref) {
  return NetworkNotifier(ref);
});

/// Tracks whether the offline caption should remain visible
/// even if connectivity is restored automatically. It is set to true
/// when an offline state is detected, and only set to false when the user
/// taps Retry and connectivity is confirmed.
final overlayNeedsDismissProvider = StateProvider<bool>((ref) => false);
