import 'dart:html' as html;
import 'package:geolocator/geolocator.dart';

/// Web-specific implementation for geolocation and tracking
class WebGeolocation {
  static Future<Position?> getCurrentPosition() async {
    try {
      final position = await html.window.navigator.geolocation.getCurrentPosition();
      
      return Position(
        latitude: position.coords!.latitude!.toDouble(),
        longitude: position.coords!.longitude!.toDouble(),
        timestamp: DateTime.fromMillisecondsSinceEpoch(position.timestamp!),
        accuracy: position.coords!.accuracy!.toDouble(),
        altitude: (position.coords?.altitude ?? 0.0).toDouble(),
        heading: (position.coords?.heading ?? 0.0).toDouble(),
        speed: (position.coords?.speed ?? 0.0).toDouble(),
        speedAccuracy: 0.0,
        altitudeAccuracy: 0.0,
        headingAccuracy: 0.0,
      );
    } catch (e) {
      print('❌ Web geolocation error: $e');
      return null;
    }
  }

  /// Track Facebook Pixel CompleteRegistration event
  static void trackCompleteRegistration() {
    try {
      // Dispatch a custom event that index.html JavaScript will catch
      final event = html.CustomEvent('fbPixelCompleteRegistration');
      html.window.dispatchEvent(event);
      print('✅ Dispatched fbPixelCompleteRegistration event');
    } catch (e) {
      print('❌ Error dispatching Pixel event: $e');
    }
  }
}
