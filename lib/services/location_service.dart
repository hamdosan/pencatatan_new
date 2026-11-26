import 'package:flutter/widgets.dart' show Locale;
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

/// Hasil pengambilan lokasi.
class PickedLocation {
  const PickedLocation({
    required this.latitude,
    required this.longitude,
    this.address,
  });

  final double latitude;
  final double longitude;
  final String? address;
}

/// Error yang pesannya siap ditampilkan ke pengguna.
class LocationException implements Exception {
  const LocationException(this.message);
  final String message;

  @override
  String toString() => message;
}

class LocationService {
  LocationService._();
  static final LocationService instance = LocationService._();

  late final Geocoding _geocoding = Geocoding(locale: const Locale('id', 'ID'));

  /// Ambil posisi saat ini beserta alamatnya. Melempar [LocationException]
  /// jika GPS mati atau izin ditolak.
  Future<PickedLocation> getCurrentLocation() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const LocationException(
          'GPS tidak aktif. Nyalakan lokasi di pengaturan HP.');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      throw const LocationException('Izin lokasi ditolak.');
    }
    if (permission == LocationPermission.deniedForever) {
      throw const LocationException(
          'Izin lokasi ditolak permanen. Aktifkan di pengaturan aplikasi.');
    }

    final Position pos;
    try {
      pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 20),
        ),
      );
    } catch (_) {
      final last = await Geolocator.getLastKnownPosition();
      if (last == null) {
        throw const LocationException(
            'Gagal mendapatkan lokasi. Coba lagi di tempat terbuka.');
      }
      return _withAddress(last.latitude, last.longitude);
    }
    return _withAddress(pos.latitude, pos.longitude);
  }

  Future<PickedLocation> _withAddress(double lat, double lng) async {
    return PickedLocation(
      latitude: lat,
      longitude: lng,
      address: await _reverseGeocode(lat, lng),
    );
  }

  /// Alamat ringkas dari koordinat. Null jika offline / tidak ditemukan.
  Future<String?> _reverseGeocode(double lat, double lng) async {
    try {
      final places = await _geocoding.placemarkFromCoordinates(lat, lng);
      if (places.isEmpty) return null;
      final p = places.first;
      final parts = <String?>[
        p.street,
        p.subLocality,
        p.locality,
        p.subAdministrativeArea,
      ]
          .whereType<String>()
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toSet()
          .toList();
      return parts.isEmpty ? null : parts.join(', ');
    } catch (_) {
      return null;
    }
  }

  /// Buka koordinat di aplikasi peta (Google Maps / browser).
  Future<bool> openInMaps(double lat, double lng) {
    final uri = Uri.https('www.google.com', '/maps/search/', {
      'api': '1',
      'query': '$lat,$lng',
    });
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  static String formatCoordinates(double lat, double lng) =>
      '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}';
}
