import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_config.dart';
import '../../core/widgets/jaihind_brand_logo.dart';
import '../../core/widgets/real_compass_widget.dart';

class MapsScreen extends StatefulWidget {
  const MapsScreen({super.key});

  @override
  State<MapsScreen> createState() => _MapsScreenState();
}

class _MapsScreenState extends State<MapsScreen> {
  GoogleMapController? _mapController;

  // Selected Map Type: Default, Satellite, Terrain, Hybrid
  MapType _selectedMapType = MapType.normal;

  // Live or Default Location (Tamil Nadu)
  LatLng _currentLocation = const LatLng(
    AppConfig.defaultLatitude,
    AppConfig.defaultLongitude,
  );
  double _currentBearing = 0.0;
  bool _is3D = false;
  double _currentTilt = 0.0;

  // Markers on Map (e.g. Searched location pin)
  final Set<Marker> _markers = {};

  // Search State & Controllers
  bool _isSearchOpen = false;
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  List<Map<String, dynamic>> _suggestions = [];

  // Popular Tamil Nadu and Indian running cities/locations for instant search
  static const List<Map<String, dynamic>> _popularLocations = [
    {'name': 'Guziliamparai, Dindigul', 'lat': 10.6726, 'lng': 78.1189, 'sub': 'Dindigul District'},
    {'name': 'Chennai, Tamil Nadu', 'lat': 13.0827, 'lng': 80.2707, 'sub': 'Capital City'},
    {'name': 'Marina Beach, Chennai', 'lat': 13.0500, 'lng': 80.2824, 'sub': 'Popular Running Track'},
    {'name': 'Besant Nagar Beach, Chennai', 'lat': 12.9984, 'lng': 80.2673, 'sub': 'Elliot\'s Beach Running'},
    {'name': 'Dindigul, Tamil Nadu', 'lat': 10.3673, 'lng': 77.9803, 'sub': 'Dindigul Rock Fort'},
    {'name': 'Madurai, Tamil Nadu', 'lat': 9.9252, 'lng': 78.1198, 'sub': 'Temple City'},
    {'name': 'Coimbatore, Tamil Nadu', 'lat': 11.0168, 'lng': 76.9558, 'sub': 'Manchester of South India'},
    {'name': 'Race Course, Coimbatore', 'lat': 11.0065, 'lng': 76.9745, 'sub': 'Famous Jogging Track'},
    {'name': 'Tiruchirappalli (Trichy)', 'lat': 10.7905, 'lng': 78.7047, 'sub': 'Rockfort City'},
    {'name': 'Salem, Tamil Nadu', 'lat': 11.6643, 'lng': 78.1460, 'sub': 'Steel & Mango City'},
    {'name': 'Karur, Tamil Nadu', 'lat': 10.9601, 'lng': 78.0766, 'sub': 'Textile City'},
    {'name': 'Tiruppur, Tamil Nadu', 'lat': 11.1085, 'lng': 77.3411, 'sub': 'Knitwear Capital'},
    {'name': 'Erode, Tamil Nadu', 'lat': 11.3410, 'lng': 77.7172, 'sub': 'Turmeric City'},
    {'name': 'Tirunelveli, Tamil Nadu', 'lat': 8.7139, 'lng': 77.7567, 'sub': 'Halwa City'},
    {'name': 'Kanyakumari, Tamil Nadu', 'lat': 8.0883, 'lng': 77.5385, 'sub': 'Southern Tip of India'},
    {'name': 'Kodaikanal, Tamil Nadu', 'lat': 10.2381, 'lng': 77.4892, 'sub': 'Princess of Hill Stations'},
    {'name': 'Ooty (Udhagamandalam)', 'lat': 11.4102, 'lng': 76.6950, 'sub': 'Queen of Hill Stations'},
    {'name': 'Thanjavur, Tamil Nadu', 'lat': 10.7870, 'lng': 79.1378, 'sub': 'Brihadisvara Temple'},
    {'name': 'Vellore, Tamil Nadu', 'lat': 12.9165, 'lng': 79.1325, 'sub': 'Fort City'},
    {'name': 'Bengaluru (Bangalore)', 'lat': 12.9716, 'lng': 77.5946, 'sub': 'Karnataka'},
  ];

  @override
  void initState() {
    super.initState();
    _initUserLocation();
  }

  @override
  void dispose() {
    _mapController?.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  // -------------------------------------------------------------
  // INITIAL LOCATION FETCH
  // -------------------------------------------------------------
  Future<void> _initUserLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse) {
        final pos = await Geolocator.getLastKnownPosition() ??
            await Geolocator.getCurrentPosition(
              locationSettings: const LocationSettings(
                accuracy: LocationAccuracy.medium,
                timeLimit: Duration(seconds: 4),
              ),
            );

        if (mounted) {
          setState(() {
            _currentLocation = LatLng(pos.latitude, pos.longitude);
          });
          _mapController?.animateCamera(
            CameraUpdate.newLatLngZoom(_currentLocation, 14.5),
          );
        }
      }
    } catch (e) {
      debugPrint('Map location notice: $e');
    }
  }

  // -------------------------------------------------------------
  // RE-CENTER TO CURRENT GPS LOCATION
  // -------------------------------------------------------------
  Future<void> _recenterToUserLocation() async {
    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 5),
        ),
      );
      final target = LatLng(pos.latitude, pos.longitude);
      setState(() => _currentLocation = target);
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(target, 16.0),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Centered on your GPS location'),
            duration: Duration(milliseconds: 1200),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (_) {
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(_currentLocation, 16.0),
      );
    }
  }

  void _resetBearingToNorth() {
    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: _currentLocation,
          zoom: _is3D ? 18.5 : 15.5,
          bearing: 0.0,
          tilt: _currentTilt,
        ),
      ),
    );
    if (mounted) {
      setState(() => _currentBearing = 0.0);
    }
  }

  // -------------------------------------------------------------
  // 3D BUILDING MODE CONTROLS
  // -------------------------------------------------------------
  void _toggle3DMode() {
    setState(() {
      _is3D = !_is3D;
      _currentTilt = _is3D ? 65.0 : 0.0;
      if (_is3D) {
        // In Google Maps Android SDK, 3D extruded vector buildings ONLY render on MapType.normal!
        _selectedMapType = MapType.normal;
      }
    });

    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: _currentLocation,
          zoom: _is3D ? 18.5 : 15.5,
          tilt: _currentTilt,
          bearing: _currentBearing,
        ),
      ),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _is3D
              ? '🏢 3D Building Mode Active! (Default/Roadmap 3D View)'
              : '🗺️ 2D Overhead Map Active',
        ),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.primaryBlue,
      ),
    );
  }

  // -------------------------------------------------------------
  // LOCATION SEARCH ENGINE (Local + Android Native Geocoder + OpenStreetMap)
  // -------------------------------------------------------------
  void _onSearchQueryChanged(String query) {
    if (query.trim().isEmpty) {
      setState(() => _suggestions = []);
      return;
    }
    final q = query.toLowerCase().trim();
    final matched = _popularLocations.where((loc) {
      final name = (loc['name'] as String).toLowerCase();
      final sub = (loc['sub'] as String).toLowerCase();
      return name.contains(q) || sub.contains(q);
    }).take(5).toList();

    setState(() {
      _suggestions = matched;
    });
  }

  Future<void> _performSearch(String query) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) return;

    _searchFocusNode.unfocus();
    setState(() {
      _isSearching = true;
      _suggestions.clear();
    });

    // 1. Check local Tamil Nadu database first for instant exact match
    final matchedLocal = _popularLocations.where((loc) {
      final name = (loc['name'] as String).toLowerCase();
      return name.contains(cleanQuery.toLowerCase());
    }).toList();

    if (matchedLocal.isNotEmpty) {
      final top = matchedLocal.first;
      _moveToLocation(
        LatLng(top['lat'] as double, top['lng'] as double),
        top['name'] as String,
      );
      setState(() {
        _isSearching = false;
        _isSearchOpen = false;
      });
      return;
    }

    // 2. Try native Android Geocoder (package:geocoding)
    try {
      final locations = await Geocoding().locationFromAddress(cleanQuery);
      if (locations.isNotEmpty) {
        final loc = locations.first;
        final target = LatLng(loc.latitude, loc.longitude);
        _moveToLocation(target, cleanQuery);
        setState(() {
          _isSearching = false;
          _isSearchOpen = false;
        });
        return;
      }
    } catch (e) {
      debugPrint('Native geocoding notice: $e');
    }

    // 3. Fallback to OpenStreetMap Nominatim HTTP Geocoder (No API Key Required)
    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(cleanQuery)}&format=json&limit=1',
      );
      final client = HttpClient();
      final request = await client.getUrl(uri);
      request.headers.set('User-Agent', 'JaihindRunnersApp/1.0');
      final response = await request.close().timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final body = await response.transform(utf8.decoder).join();
        final jsonList = jsonDecode(body) as List;
        if (jsonList.isNotEmpty) {
          final first = jsonList.first as Map<String, dynamic>;
          final lat = double.tryParse(first['lat']?.toString() ?? '') ?? 0.0;
          final lon = double.tryParse(first['lon']?.toString() ?? '') ?? 0.0;
          final displayName = first['display_name']?.toString() ?? cleanQuery;
          if (lat != 0.0 && lon != 0.0) {
            final shortName = displayName.split(',').take(2).join(',').trim();
            _moveToLocation(LatLng(lat, lon), shortName.isNotEmpty ? shortName : cleanQuery);
            setState(() {
              _isSearching = false;
              _isSearchOpen = false;
            });
            return;
          }
        }
      }
    } catch (e) {
      debugPrint('HTTP geocoding notice: $e');
    }

    // If nothing found:
    setState(() => _isSearching = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not find "$cleanQuery". Try searching a city, town or landmark.'),
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _moveToLocation(LatLng target, String locationTitle) {
    setState(() {
      _currentLocation = target;
      _markers.clear();
      _markers.add(
        Marker(
          markerId: const MarkerId('searched_location'),
          position: target,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: InfoWindow(
            title: locationTitle,
            snippet: '📍 Searched Location',
          ),
        ),
      );
    });

    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: target,
          zoom: 15.5,
          tilt: 35.0,
        ),
      ),
    );

    // Auto-open InfoWindow on the search marker
    Future.delayed(const Duration(milliseconds: 350), () {
      _mapController?.showMarkerInfoWindow(const MarkerId('searched_location'));
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.location_on_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Showing: $locationTitle',
                style: const TextStyle(fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.primaryBlue,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // -------------------------------------------------------------
            // TOP HEADER: JAIHIND BRAND LOGO & SEARCH ACTION ICON
            // -------------------------------------------------------------
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: _isSearchOpen
                  ? Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 44,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(color: AppColors.primaryBlue.withOpacity(0.35), width: 1.2),
                            ),
                            child: Row(
                              children: [
                                _isSearching
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryBlue),
                                      )
                                    : const Icon(Icons.search_rounded, color: AppColors.primaryBlue, size: 22),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextField(
                                    controller: _searchController,
                                    focusNode: _searchFocusNode,
                                    textInputAction: TextInputAction.search,
                                    onChanged: _onSearchQueryChanged,
                                    onSubmitted: _performSearch,
                                    decoration: const InputDecoration(
                                      hintText: 'Search city, street or location...',
                                      hintStyle: TextStyle(fontSize: 13.5, color: Color(0xFF94A3B8)),
                                      border: InputBorder.none,
                                      isDense: true,
                                    ),
                                    style: const TextStyle(
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textBlack,
                                    ),
                                  ),
                                ),
                                if (_searchController.text.isNotEmpty)
                                  GestureDetector(
                                    onTap: () {
                                      _searchController.clear();
                                      _onSearchQueryChanged('');
                                    },
                                    child: const Padding(
                                      padding: EdgeInsets.all(4.0),
                                      child: Icon(Icons.close_rounded, size: 18, color: Colors.grey),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _isSearchOpen = false;
                              _suggestions.clear();
                              _searchController.clear();
                            });
                          },
                          child: const Text(
                            'Cancel',
                            style: TextStyle(
                              color: AppColors.primaryBlue,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const JaihindBrandLogo(
                          fontSize: 21,
                          emblemHeight: 28,
                          showSubtitle: true,
                        ),

                        // Search Location Pill / Icon Button at Top
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(22),
                            onTap: () {
                              setState(() {
                                _isSearchOpen = true;
                              });
                              Future.delayed(const Duration(milliseconds: 150), () {
                                _searchFocusNode.requestFocus();
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.03),
                                    blurRadius: 4,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.search_rounded, size: 19, color: AppColors.primaryBlue),
                                  SizedBox(width: 6),
                                  Text(
                                    'Search Location',
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF475569),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
            ),

            // -------------------------------------------------------------
            // FULL-SCREEN MAP WITH FLOATING CONTROLS & SEARCH SUGGESTIONS
            // -------------------------------------------------------------
            Expanded(
              child: Stack(
                children: [
                  // 1. Google Map View
                  GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: _currentLocation,
                      zoom: 14.5,
                      tilt: _currentTilt,
                      bearing: _currentBearing,
                    ),
                    mapType: _selectedMapType,
                    buildingsEnabled: true,
                    tiltGesturesEnabled: true,
                    rotateGesturesEnabled: true,
                    zoomGesturesEnabled: true,
                    scrollGesturesEnabled: true,
                    myLocationEnabled: true,
                    myLocationButtonEnabled: false,
                    zoomControlsEnabled: false,
                    compassEnabled: false, // Replaced with Real Analog Magnetic Compass
                    mapToolbarEnabled: false,
                    markers: _markers,
                    onCameraMove: (CameraPosition pos) {
                      if (mounted && _currentBearing != pos.bearing) {
                        setState(() => _currentBearing = pos.bearing);
                      }
                    },
                    onMapCreated: (controller) {
                      _mapController = controller;
                    },
                  ),

                  // 2. Top Floating Map Type Selection Pill (Default, Satellite, Terrain, Hybrid)
                  Positioned(
                    top: 14,
                    left: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.12),
                            blurRadius: 12,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          _buildMapTypeTab(
                            title: 'Default',
                            mapType: MapType.normal,
                          ),
                          _buildMapTypeTab(
                            title: 'Satellite',
                            mapType: MapType.satellite,
                          ),
                          _buildMapTypeTab(
                            title: 'Terrain',
                            mapType: MapType.terrain,
                          ),
                          _buildMapTypeTab(
                            title: 'Hybrid',
                            mapType: MapType.hybrid,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 2b. Real Analog Magnetic Compass (Rotates dynamically, tap resets True North)
                  Positioned(
                    top: 68,
                    right: 16,
                    child: RealCompassWidget(
                      bearing: _currentBearing,
                      onTap: _resetBearingToNorth,
                      size: 52,
                    ),
                  ),

                  // 2c. 3D Building Mode Toggle Button
                  Positioned(
                    top: 130,
                    right: 16,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(26),
                        onTap: _toggle3DMode,
                        child: Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: _is3D ? AppColors.primaryBlue : Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: _is3D
                                    ? AppColors.primaryBlue.withOpacity(0.38)
                                    : Colors.black.withOpacity(0.14),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                            border: Border.all(
                              color: _is3D ? Colors.white.withOpacity(0.3) : const Color(0xFFE2E8F0),
                              width: 1.2,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '3D',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                  color: _is3D ? Colors.white : Colors.black,
                                  height: 1.1,
                                ),
                              ),
                              Text(
                                'VIEW',
                                style: TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.w800,
                                  color: _is3D ? Colors.white70 : const Color(0xFF64748B),
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // 3. Search Suggestions Floating Dropdown Overlay (When Search Is Active)
                  if (_isSearchOpen && _suggestions.isNotEmpty)
                    Positioned(
                      top: 70,
                      left: 16,
                      right: 16,
                      child: Material(
                        elevation: 10,
                        borderRadius: BorderRadius.circular(18),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: ListView.separated(
                            shrinkWrap: true,
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            itemCount: _suggestions.length,
                            separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
                            itemBuilder: (context, index) {
                              final loc = _suggestions[index];
                              return ListTile(
                                dense: true,
                                leading: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryBlue.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.place_rounded, color: AppColors.primaryBlue, size: 18),
                                ),
                                title: Text(
                                  loc['name'] as String,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                                ),
                                subtitle: Text(
                                  loc['sub'] as String,
                                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                ),
                                trailing: const Icon(Icons.north_west_rounded, size: 14, color: Colors.grey),
                                onTap: () {
                                  _moveToLocation(
                                    LatLng(loc['lat'] as double, loc['lng'] as double),
                                    loc['name'] as String,
                                  );
                                  setState(() {
                                    _isSearchOpen = false;
                                    _suggestions.clear();
                                    _searchController.clear();
                                  });
                                },
                              );
                            },
                          ),
                        ),
                      ),
                    ),

                  // 4. Right Floating Zoom In / Zoom Out (+ / -) Capsule
                  Positioned(
                    right: 16,
                    top: 196,
                    child: Container(
                      width: 46,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(23),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.14),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Zoom In (+) Button
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(23)),
                              onTap: () {
                                _mapController?.animateCamera(CameraUpdate.zoomIn());
                              },
                              child: const SizedBox(
                                width: 46,
                                height: 44,
                                child: Center(
                                  child: Icon(
                                    Icons.add_rounded,
                                    size: 26,
                                    color: Color(0xFF333333),
                                  ),
                                ),
                              ),
                            ),
                          ),

                          // Divider
                          Container(
                            width: 26,
                            height: 1,
                            color: const Color(0xFFE5E7EB),
                          ),

                          // Zoom Out (-) Button
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(23)),
                              onTap: () {
                                _mapController?.animateCamera(CameraUpdate.zoomOut());
                              },
                              child: const SizedBox(
                                width: 46,
                                height: 44,
                                child: Center(
                                  child: Icon(
                                    Icons.remove_rounded,
                                    size: 26,
                                    color: Color(0xFF333333),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 5. Right Floating My Location Button
                  Positioned(
                    right: 16,
                    bottom: 24,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(26),
                        onTap: _recenterToUserLocation,
                        child: Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.14),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.my_location_rounded,
                              color: AppColors.primaryBlue,
                              size: 26,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // MAP TYPE CAPSULE TAB
  // -------------------------------------------------------------
  Widget _buildMapTypeTab({
    required String title,
    required MapType mapType,
  }) {
    final isSelected = _selectedMapType == mapType;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedMapType = mapType;
            if (mapType != MapType.normal && _is3D) {
              _is3D = false;
              _currentTilt = 0.0;
            }
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFD8EEFF) : Colors.transparent,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Center(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? AppColors.primaryBlue : const Color(0xFF666666),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
