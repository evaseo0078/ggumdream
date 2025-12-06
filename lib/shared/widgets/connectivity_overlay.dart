import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/network_connectivity.dart';
import 'package:ggumdream/app/theme.dart';

class ConnectivityOverlay extends ConsumerWidget {
  final Widget child;
  const ConnectivityOverlay({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(networkStatusProvider);
    final isOffline = status == NetworkStatus.offline;
    final needsDismiss = ref.watch(overlayNeedsDismissProvider);

    return Stack(
      children: [
        child,
        if (isOffline || needsDismiss)
          Positioned.fill(
            child: IgnorePointer(
              ignoring: false,
              child: Container(
                alignment: Alignment.center,
                color: Colors.black.withOpacity(0.25),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.85),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.wifi_off,
                          color: AppTheme.primaryColor, size: 28),
                      const SizedBox(height: 8),
                      const Text(
                        'You are offline. Please check your connection.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.black87),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 40,
                        child: ElevatedButton(
                          onPressed: () =>
                              ref.read(networkStatusProvider.notifier).retry(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text('Retry'),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        status == NetworkStatus.online
                            ? 'Connection looks restored. Tap Retry to confirm.'
                            : 'Restore internet, then tap Retry.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: Colors.black54, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
