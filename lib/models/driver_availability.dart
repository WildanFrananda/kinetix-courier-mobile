enum DriverAvailability {
  offline,
  online,
  busy;

  static DriverAvailability? fromWire(Object? value) {
    for (final DriverAvailability availability in DriverAvailability.values) {
      if (availability.name == value) {
        return availability;
      }
    }

    return null;
  }
}
