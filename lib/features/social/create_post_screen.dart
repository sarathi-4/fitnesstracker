import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/animations/app_animations.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/social_service.dart';
import '../../core/services/user_service.dart';
import '../../core/widgets/strava_workout_overlay.dart';

class CreatePostScreen extends StatefulWidget {
  final WorkoutActivity? prefilledWorkout;

  const CreatePostScreen({super.key, this.prefilledWorkout});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _captionController = TextEditingController();

  File? _selectedImage;
  String _selectedActivityType = 'Running';
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  String? _errorMessage;

  // Real workout session metrics
  double _rawDistanceKm = 0.0;
  int _rawDurationSeconds = 0;
  String _rawPace = '6:23 /km';
  List<LatLng> _routePoints = [];

  final ImagePicker _picker = ImagePicker();

  final List<String> _activityTypes = [
    'Running',
    'Walking',
    'Cycling',
    'Hike',
    'Workout',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.prefilledWorkout != null) {
      final w = widget.prefilledWorkout!;
      _selectedActivityType = w.mode;
      _rawDistanceKm = w.distanceKm;
      _rawDurationSeconds = w.durationSeconds;
      _rawPace = w.avgPace;
      _routePoints = w.gpsRoutePoints;

      if (w.notes != null && w.notes!.isNotEmpty) {
        _captionController.text = w.notes!;
      } else {
        _captionController.text = 'Completed ${w.mode.toLowerCase()} session with JAIHIND! 🏃‍♂️⚡ #JAIHIND #RunnersClub';
      }
      if (w.imagePath != null && File(w.imagePath!).existsSync()) {
        _selectedImage = File(w.imagePath!);
      }
    }
  }

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 1440,
        maxHeight: 1440,
        imageQuality: 85,
      );
      if (picked != null) {
        setState(() {
          _selectedImage = File(picked.path);
          _errorMessage = null;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Could not access image: $e';
      });
    }
  }

  Future<void> _publishPost() async {
    if (_isUploading) return;

    final caption = _captionController.text.trim();
    if (caption.isEmpty && _selectedImage == null) {
      setState(() {
        _errorMessage = 'Please add a photo or write a caption for your post.';
      });
      return;
    }

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
      _errorMessage = null;
    });

    final dist = _rawDistanceKm > 0 ? _rawDistanceKm : null;
    final durSeconds = _rawDurationSeconds > 0 ? _rawDurationSeconds : null;
    final cal = widget.prefilledWorkout?.calories;

    String? calculatedPace = _rawPace;
    if (calculatedPace == '-:--' || calculatedPace.isEmpty) {
      if (dist != null && dist > 0 && durSeconds != null && durSeconds > 0) {
        final totalPaceSeconds = (durSeconds / dist).round();
        final pMin = totalPaceSeconds ~/ 60;
        final pSec = totalPaceSeconds % 60;
        calculatedPace = "$pMin:${pSec.toString().padLeft(2, '0')} /km";
      }
    }

    try {
      final post = await SocialService.instance.createPost(
        imageFile: _selectedImage,
        caption: caption,
        activityType: _selectedActivityType,
        distanceKm: dist,
        durationSeconds: durSeconds,
        calories: cal,
        pace: calculatedPace,
        routePoints: _routePoints.length >= 2 ? _routePoints : null,
        onProgress: (progress) {
          if (mounted) setState(() => _uploadProgress = progress);
        },
      );

      if (!mounted) return;

      if (post != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Post published to JAIHIND Community Feed! 🚀'),
            backgroundColor: AppColors.accentGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context, true);
      } else {
        setState(() {
          _isUploading = false;
          _errorMessage = 'Failed to publish post. Please try again.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUploading = false;
          _errorMessage = 'Error publishing post: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'New Post',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: Colors.black,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _isUploading ? null : _publishPost,
            child: _isUploading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryBlue),
                  )
                : const Text(
                    'Share',
                    style: TextStyle(
                      color: AppColors.primaryBlue,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Upload Progress
            if (_isUploading) ...[
              LinearProgressIndicator(
                value: _uploadProgress > 0 ? _uploadProgress : null,
                backgroundColor: const Color(0xFFEFF6FF),
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryBlue),
              ),
              const SizedBox(height: 6),
              Text(
                'Publishing post... ${(_uploadProgress * 100).toInt()}%',
                style: const TextStyle(fontSize: 12, color: AppColors.primaryBlue, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
            ],

            // Error banner
            if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFFCA5A5)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Color(0xFF991B1B), fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
            ],

            // Photo Selection Section with Strava-Style Athletic Overlay
            Container(
              width: double.infinity,
              height: 400,
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: _selectedImage != null
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(17),
                          child: Image.file(_selectedImage!, fit: BoxFit.cover),
                        ),

                        // Subtle contrast gradient
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(17),
                            gradient: LinearGradient(
                              colors: [
                                Colors.black.withOpacity(0.15),
                                Colors.transparent,
                                Colors.black.withOpacity(0.35),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),

                        // Strava-Style Athletic Overlay: Distance, Pace, Time, Mini Route, JAIHIND
                        StravaWorkoutOverlay(
                          distanceKm: _rawDistanceKm,
                          pace: _rawPace,
                          durationSeconds: _rawDurationSeconds,
                          routePoints: _routePoints,
                          brandName: 'JAIHIND',
                        ),

                        // Top Left: Change Photo Button
                        Positioned(
                          top: 12,
                          left: 12,
                          child: GestureDetector(
                            onTap: () => _pickImage(ImageSource.camera),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.65),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.camera_alt_rounded, color: Colors.white, size: 15),
                                  SizedBox(width: 6),
                                  Text(
                                    'Change Photo',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        // Top Right: Remove Photo Button
                        Positioned(
                          top: 12,
                          right: 12,
                          child: GestureDetector(
                            onTap: () => setState(() => _selectedImage = null),
                            child: Container(
                              padding: const EdgeInsets.all(7),
                              decoration: const BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close_rounded, size: 18, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    )
                  : Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.primaryBlue.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.camera_alt_rounded, size: 36, color: AppColors.primaryBlue),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Capture Workout Photo 📸',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: AppColors.textBlack,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 24),
                            child: Text(
                              'Feature your running route, distance & pace like Strava!',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 12.5, color: AppColors.textGrey, height: 1.3),
                            ),
                          ),
                          const SizedBox(height: 18),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primaryBlue,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                                ),
                                icon: const Icon(Icons.camera_alt_outlined, size: 18),
                                label: const Text('Open Camera', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold)),
                                onPressed: () => _pickImage(ImageSource.camera),
                              ),
                              const SizedBox(width: 12),
                              OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.textDark,
                                  side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.4),
                                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                                ),
                                icon: const Icon(Icons.photo_library_outlined, size: 18),
                                label: const Text('Gallery', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold)),
                                onPressed: () => _pickImage(ImageSource.gallery),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
            ),

            const SizedBox(height: 20),

            // Caption Text Field
            TextField(
              controller: _captionController,
              maxLines: 4,
              style: const TextStyle(fontSize: 14),
              decoration: const InputDecoration(
                hintText: 'Write an inspiring caption for your run or workout...',
                hintStyle: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13.5),
                border: InputBorder.none,
              ),
            ),

            const Divider(color: Color(0xFFE5E7EB)),
            const SizedBox(height: 10),

            // Activity Type Selector
            const Text(
              'Activity Type',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textBlack),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _activityTypes.map((type) {
                final isSel = _selectedActivityType == type;
                return ChoiceChip(
                  label: Text(type),
                  selected: isSel,
                  onSelected: (val) {
                    if (val) setState(() => _selectedActivityType = type);
                  },
                  selectedColor: AppColors.primaryBlue,
                  labelStyle: TextStyle(
                    color: isSel ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.bold,
                    fontSize: 12.5,
                  ),
                  backgroundColor: const Color(0xFFF1F5F9),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                );
              }).toList(),
            ),

            const SizedBox(height: 28),

            // Publish Button
            BouncingTap(
              onTap: _isUploading ? null : _publishPost,
              child: Container(
                width: double.infinity,
                height: 52,
                decoration: BoxDecoration(
                  gradient: AppColors.brandGradient,
                  borderRadius: BorderRadius.circular(26),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryBlue.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: _isUploading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.send_rounded, color: Colors.white, size: 18),
                            SizedBox(width: 8),
                            Text(
                              'PUBLISH POST',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14.5,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
