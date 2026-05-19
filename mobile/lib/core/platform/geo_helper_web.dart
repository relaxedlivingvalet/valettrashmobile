// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

Future<Map<String, double>?> getPlatformLocation() async {
  try {
    final pos = await html.window.navigator.geolocation
        .getCurrentPosition()
        .timeout(const Duration(seconds: 10));
    return {
      'lat': pos.coords!.latitude!.toDouble(),
      'lng': pos.coords!.longitude!.toDouble(),
    };
  } catch (_) {
    return null;
  }
}
