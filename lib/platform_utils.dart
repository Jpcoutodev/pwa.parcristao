import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';

// Conditional import for web-specific APIs
import 'platform_utils_web.dart' if (dart.library.io) 'platform_utils_stub.dart' as web_utils;

/// Platform utilities for cross-platform compatibility
/// Provides fallbacks for web platform where native APIs don't work
class PlatformUtils {
  /// Check if running on web platform
  static bool get isWeb => kIsWeb;

  /// Safe haptic feedback - does nothing on web
  static void hapticLight() {
    if (!kIsWeb) {
      HapticFeedback.lightImpact();
    }
  }

  static void hapticMedium() {
    if (!kIsWeb) {
      HapticFeedback.mediumImpact();
    }
  }

  static void hapticHeavy() {
    if (!kIsWeb) {
      HapticFeedback.heavyImpact();
    }
  }

  static void hapticSelection() {
    if (!kIsWeb) {
      HapticFeedback.selectionClick();
    }
  }

  static void hapticVibrate() {
    if (!kIsWeb) {
      HapticFeedback.vibrate();
    }
  }

  /// Get current position with web fallback
  static Future<Position?> getCurrentPosition() async {
    try {
      if (kIsWeb) {
        // Web: Use HTML5 Geolocation API
        return await _getPositionWeb();
      } else {
        // Native: Use geolocator
        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) {
          print('⚠️ Location services are disabled');
          return null;
        }

        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
          if (permission == LocationPermission.denied) {
            print('⚠️ Location permissions are denied');
            return null;
          }
        }

        if (permission == LocationPermission.deniedForever) {
          print('⚠️ Location permissions are permanently denied');
          return null;
        }

        return await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
      }
    } catch (e) {
      print('❌ Error getting position: $e');
      return null;
    }
  }

  /// Web-specific geolocation using HTML5 API
  static Future<Position?> _getPositionWeb() async {
    return await web_utils.WebGeolocation.getCurrentPosition();
  }

  /// Check if location permission is granted
  static Future<bool> hasLocationPermission() async {
    if (kIsWeb) {
      // On web, we can't check permission status before requesting
      // So we just return true and let the browser handle it
      return true;
    } else {
      LocationPermission permission = await Geolocator.checkPermission();
      return permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse;
    }
  }

  /// Request location permission
  static Future<bool> requestLocationPermission() async {
    if (kIsWeb) {
      // On web, permission is requested when getCurrentPosition is called
      final position = await getCurrentPosition();
      return position != null;
    } else {
      LocationPermission permission = await Geolocator.requestPermission();
      return permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse;
    }
  }

  /// Get platform name for debugging
  static String get platformName {
    if (kIsWeb) return 'Web';
    if (defaultTargetPlatform == TargetPlatform.android) return 'Android';
    if (defaultTargetPlatform == TargetPlatform.iOS) return 'iOS';
    if (defaultTargetPlatform == TargetPlatform.windows) return 'Windows';
    if (defaultTargetPlatform == TargetPlatform.macOS) return 'macOS';
    if (defaultTargetPlatform == TargetPlatform.linux) return 'Linux';
    return 'Unknown';
  }

  /// Check if camera is available (limited on web)
  static bool get hasCameraSupport {
    if (kIsWeb) {
      // Web has limited camera support via getUserMedia
      return true; // We'll handle the actual check when needed
    }
    return true; // Native platforms have full camera support
  }

  /// Check if haptic feedback is supported
  static bool get hasHapticSupport {
    return !kIsWeb; // Only native platforms support haptic
  }

  /// Check if precise location is supported
  static bool get hasPreciseLocation {
    return !kIsWeb; // Web location is less precise than native GPS
  }

  /// Track Facebook Pixel CompleteRegistration event (web only)
  static void trackCompleteRegistration() {
    if (kIsWeb) {
      web_utils.WebGeolocation.trackCompleteRegistration();
    }
  }
}
