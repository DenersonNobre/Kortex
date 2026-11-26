import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';

import 'reactive.dart' show NotifierBuilder;

class BusyOverlay extends StatelessWidget {
  const BusyOverlay({
    super.key,
    required this.isBusy,
    required this.child,
    this.barrierColor = const Color(0x42000000),
    this.progressIndicator,
  });

  final ValueListenable<bool> isBusy;
  final Widget child;
  final Color barrierColor;
  final Widget? progressIndicator;

  @override
  Widget build(BuildContext context) {
    return NotifierBuilder<bool>(
      listenable: isBusy,
      builder: (context, busy) => Stack(
        fit: StackFit.expand,
        children: [
          child,
          if (busy) ...[
            ModalBarrier(dismissible: false, color: barrierColor),
            Center(
              child: progressIndicator ?? const CircularProgressIndicator(),
            ),
          ],
        ],
      ),
    );
  }
}
