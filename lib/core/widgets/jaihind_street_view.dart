import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../constants/app_colors.dart';

/// Controller for live updates to the native Android 360° Google Street View.
class JaihindStreetViewController {
  MethodChannel? _channel;

  void _attach(MethodChannel channel) {
    _channel = channel;
  }

  void _detach() {
    _channel = null;
  }

  /// Move Street View to a new GPS location (e.g. while running/cycling live).
  Future<void> updatePosition(
    LatLng target, {
    double? bearing,
    int radius = 250,
  }) async {
    final ch = _channel;
    if (ch == null) return;
    try {
      await ch.invokeMethod('updatePosition', <String, dynamic>{
        'lat': target.latitude,
        'lng': target.longitude,
        if (bearing != null) 'bearing': bearing,
        'radius': radius,
      });
    } catch (_) {}
  }

  /// Smoothly rotate the Street View camera bearing (e.g. North reset on compass tap).
  Future<void> setBearing(double bearing) async {
    final ch = _channel;
    if (ch == null) return;
    try {
      await ch.invokeMethod('setBearing', <String, dynamic>{
        'bearing': bearing,
      });
    } catch (_) {}
  }

  /// Zoom in inside the 360° panorama.
  Future<void> zoomIn() async {
    final ch = _channel;
    if (ch == null) return;
    try {
      await ch.invokeMethod('zoomIn');
    } catch (_) {}
  }

  /// Zoom out inside the 360° panorama.
  Future<void> zoomOut() async {
    final ch = _channel;
    if (ch == null) return;
    try {
      await ch.invokeMethod('zoomOut');
    } catch (_) {}
  }
}

/// Native 360° Google Street View widget powered by Android StreetViewPanoramaView.
class JaihindStreetView extends StatefulWidget {
  final LatLng initialPosition;
  final double initialBearing;
  final int searchRadiusMeters;
  final ValueChanged<JaihindStreetViewController>? onCreated;
  final ValueChanged<double>? onBearingChanged;
  final void Function(bool available, LatLng? snappedPoint)? onAvailabilityChanged;
  final VoidCallback? onFallbackToMap;

  const JaihindStreetView({
    super.key,
    required this.initialPosition,
    this.initialBearing = 0.0,
    this.searchRadiusMeters = 250,
    this.onCreated,
    this.onBearingChanged,
    this.onAvailabilityChanged,
    this.onFallbackToMap,
  });

  @override
  State<JaihindStreetView> createState() => _JaihindStreetViewState();
}

class _JaihindStreetViewState extends State<JaihindStreetView> {
  static const String _viewType = 'com.inpand.jaihindrunnerclub/street_view';

  final JaihindStreetViewController _controller = JaihindStreetViewController();
  MethodChannel? _channel;
  bool _isLoading = true;
  bool _isAvailable = true;

  @override
  void dispose() {
    _channel?.setMethodCallHandler(null);
    _controller._detach();
    super.dispose();
  }

  void _onPlatformViewCreated(int id) {
    final ch = MethodChannel('com.inpand.jaihindrunnerclub/street_view_$id');
    _channel = ch;
    _controller._attach(ch);

    ch.setMethodCallHandler((MethodCall call) async {
      if (!mounted) return;
      if (call.method == 'onAvailabilityChanged') {
        final args = (call.arguments as Map?) ?? {};
        final bool available = args['available'] == true;
        LatLng? snapped;
        if (available && args['lat'] is num && args['lng'] is num) {
          snapped = LatLng(
            (args['lat'] as num).toDouble(),
            (args['lng'] as num).toDouble(),
          );
        }
        setState(() {
          _isLoading = false;
          _isAvailable = available;
        });
        widget.onAvailabilityChanged?.call(available, snapped);
      } else if (call.method == 'onCameraBearingChanged') {
        final args = (call.arguments as Map?) ?? {};
        final bearing = (args['bearing'] as num?)?.toDouble();
        if (bearing != null) {
          widget.onBearingChanged?.call(bearing);
        }
      }
    });

    widget.onCreated?.call(_controller);
  }

  @override
  Widget build(BuildContext context) {
    final isTest = WidgetsBinding.instance.runtimeType.toString().contains('Test');
    final isAndroid = !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

    if (isTest || !isAndroid) {
      return Container(
        color: const Color(0xFF0F172A),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.streetview_rounded, color: Colors.white, size: 54),
              const SizedBox(height: 12),
              const Text(
                '360° Google Street View',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${widget.initialPosition.latitude.toStringAsFixed(4)}, ${widget.initialPosition.longitude.toStringAsFixed(4)}',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }

    final creationParams = <String, dynamic>{
      'lat': widget.initialPosition.latitude,
      'lng': widget.initialPosition.longitude,
      'bearing': widget.initialBearing,
      'radius': widget.searchRadiusMeters,
    };

    return Stack(
      children: [
        Positioned.fill(
          child: PlatformViewLink(
            viewType: _viewType,
            surfaceFactory: (context, controller) {
              return AndroidViewSurface(
                controller: controller as AndroidViewController,
                gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                  Factory<OneSequenceGestureRecognizer>(
                    () => EagerGestureRecognizer(),
                  ),
                },
                hitTestBehavior: PlatformViewHitTestBehavior.opaque,
              );
            },
            onCreatePlatformView: (PlatformViewCreationParams params) {
              final controller = PlatformViewsService.initExpensiveAndroidView(
                id: params.id,
                viewType: _viewType,
                layoutDirection: TextDirection.ltr,
                creationParams: creationParams,
                creationParamsCodec: const StandardMessageCodec(),
                onFocus: () => params.onFocusChanged(true),
              );
              controller.addOnPlatformViewCreatedListener((id) {
                params.onPlatformViewCreated(id);
                _onPlatformViewCreated(id);
              });
              controller.create();
              return controller;
            },
          ),
        ),

        // Loading Pill
        if (_isLoading)
          Positioned(
            top: 136,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.72),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Loading 360° Street View...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

        // Smart Fallback Card when no Street View imagery exists nearby (e.g. inside field/park)
        if (!_isLoading && !_isAvailable)
          Positioned.fill(
            child: Container(
              color: const Color(0xFF0F172A).withValues(alpha: 0.88),
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.streetview_rounded,
                          color: Colors.orange,
                          size: 32,
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Street View Unavailable Here',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Google Street View is available on main roads & highways (like SH74). Move closer to a road or switch back to 3D Map.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF64748B),
                          height: 1.45,
                        ),
                      ),
                      if (widget.onFallbackToMap != null) ...[
                        const SizedBox(height: 18),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryBlue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            onPressed: widget.onFallbackToMap,
                            icon: const Icon(Icons.map_rounded, size: 19),
                            label: const Text(
                              'Switch to 3D Map',
                              style: TextStyle(fontWeight: FontWeight.w800),
                            ),
                          ),
                        ),
                      ],
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
