import 'package:fleet_pulse_mobile/models/models.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:injectable/injectable.dart';
import 'package:permission_handler/permission_handler.dart' as ph;

@lazySingleton
class LocationService {
  static const Duration _interval = Duration(seconds: 4);

  Future<void> openAppSettings() => Geolocator.openAppSettings();
  Future<void> openLocationSettings() => Geolocator.openLocationSettings();

  Future<LocationPermissionStatus> ensurePermission({
    bool background = false,
  }) async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return LocationPermissionStatus.serviceDisabled;
    }

    LocationPermission perm = await Geolocator.checkPermission();

    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }

    final LocationPermissionStatus foreground = switch (perm) {
      LocationPermission.always ||
      LocationPermission.whileInUse => LocationPermissionStatus.granted,
      LocationPermission.deniedForever =>
        LocationPermissionStatus.deniedForever,
      LocationPermission.denied ||
      LocationPermission.unableToDetermine => LocationPermissionStatus.denied,
    };

    if (foreground != LocationPermissionStatus.granted) {
      return foreground;
    }

    if (background) {
      await ph.Permission.locationAlways.request();
    }

    return LocationPermissionStatus.granted;
  }

  Future<void> requestNotificationPermission() async {
    await ph.Permission.notification.request();
  }

  Stream<Position> positions() {
    return Geolocator.getPositionStream(locationSettings: _settings());
  }

  LocationSettings _settings() {
    if (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      return new AppleSettings(
        accuracy: LocationAccuracy.medium,
        allowBackgroundLocationUpdates: true,
        showBackgroundLocationIndicator: true,
        pauseLocationUpdatesAutomatically: false,
        activityType: ActivityType.automotiveNavigation,
      );
    }

    return new AndroidSettings(
      accuracy: LocationAccuracy.medium,
      intervalDuration: _interval,
      foregroundNotificationConfig: const ForegroundNotificationConfig(
        notificationTitle: 'FleetPulse is on duty',
        notificationText: 'Sharing your location with dispatch while on duty',
        notificationChannelName: 'Duty tracking',
        enableWakeLock: true,
        enableWifiLock: true,
        setOngoing: true,
      ),
    );
  }
}
