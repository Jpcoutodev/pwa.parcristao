import 'package:geolocator/geolocator.dart';

/// Stub implementation for non-web platforms
class WebGeolocation {
  static Future<Position?> getCurrentPosition() async {
    // This should never be called on non-web platforms
    throw UnsupportedError('Web geolocation is only available on web platform');
  }

  /// No-op on native platforms
  static void trackCompleteRegistration() {
    // Facebook Pixel only works on web
  }
}
