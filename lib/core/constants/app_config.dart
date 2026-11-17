/// Application Configuration
class AppConfig {
  AppConfig._();

  /// Google Maps Platform API Key (Can be passed via --dart-define=MAPS_API_KEY=...)
  /// Note: Android Google Maps SDK uses the key securely injected into AndroidManifest.xml from local.properties.
  static const String googleMapsApiKey = String.fromEnvironment(
    'MAPS_API_KEY',
    defaultValue: '',
  );

  /// Default GPS coordinates (Gujiliamparai, Tamil Nadu)
  static const double defaultLatitude = 10.5186;
  static const double defaultLongitude = 77.9803;
}
