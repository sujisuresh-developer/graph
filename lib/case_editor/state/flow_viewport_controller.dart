import 'package:flutter/foundation.dart';

/// FlowCanvas "attaches" its real zoom/fit implementations to this at
/// startup; anything holding a reference (like the toolbar) can then call
/// [zoomIn]/[zoomOut]/[fitToScreen] without needing a GlobalKey into the
/// canvas's State object. Keeps the two widgets decoupled and reusable.
class FlowViewportController {
  VoidCallback? _zoomInImpl;
  VoidCallback? _zoomOutImpl;
  VoidCallback? _fitToScreenImpl;
  VoidCallback? _resetImpl;

  void attach({
    required VoidCallback zoomIn,
    required VoidCallback zoomOut,
    required VoidCallback fitToScreen,
    required VoidCallback reset,
  }) {
    _zoomInImpl = zoomIn;
    _zoomOutImpl = zoomOut;
    _fitToScreenImpl = fitToScreen;
    _resetImpl = reset;
  }

  void detach() {
    _zoomInImpl = null;
    _zoomOutImpl = null;
    _fitToScreenImpl = null;
    _resetImpl = null;
  }

  void zoomIn() => _zoomInImpl?.call();
  void zoomOut() => _zoomOutImpl?.call();
  void fitToScreen() => _fitToScreenImpl?.call();
  void reset() => _resetImpl?.call();
}
