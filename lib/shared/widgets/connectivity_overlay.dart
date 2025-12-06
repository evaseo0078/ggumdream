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
                      const EdgeInsets.symmetric(horizontal: 17, vertical: 15),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.wifi_off,
                          color: const Color.fromARGB(255, 190, 21, 21), size: 24),
                      const SizedBox(height: 6),
                      const Text(
                        'You are offline. \nPlease check your connection.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.black87, fontSize: 14),
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: () =>
                            ref.read(networkStatusProvider.notifier).retry(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromARGB(255, 204, 153, 255), // 연보라색
                          foregroundColor: Colors.white, // 흰색 텍스트와 아이콘
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('Retry', style: TextStyle(fontSize: 14)),
                            const SizedBox(width: 8),
                            const Icon(Icons.refresh, size: 16),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        status == NetworkStatus.online
                            ? 'Connection looks restored. Tap Retry to confirm.'
                            : 'Restore internet, then tap Retry.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: Colors.black54, fontSize: 11),
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
