/// Property occupancy + billable-door rules (85% minimum for PM contracts).
abstract final class PropertyBilling {
  static const double defaultMinimumBillablePercent = 0.85;
  static const double defaultMonthlyFeePerDoor = 25.0;

  /// Doors the property pays for: at least [minPercent] of total units, or
  /// actual occupied count if higher.
  static int billableDoors({
    required int totalUnits,
    required int occupiedUnits,
    double minPercent = defaultMinimumBillablePercent,
  }) {
    if (totalUnits <= 0) return 0;
    final minimum = (totalUnits * minPercent).ceil();
    return occupiedUnits > minimum ? occupiedUnits : minimum;
  }

  static double occupancyPercent(int totalUnits, int occupiedUnits) {
    if (totalUnits <= 0) return 0;
    return occupiedUnits / totalUnits;
  }

  static double monthlyContractAmount({
    required int billableDoors,
    required double feePerDoor,
  }) =>
      billableDoors * feePerDoor;

  static double revenuePerBillableDoor({
    required double totalRevenue,
    required int billableDoors,
  }) {
    if (billableDoors <= 0) return 0;
    return totalRevenue / billableDoors;
  }

  static double readFeePerDoor(Map<String, dynamic> property) {
    final v = property['monthly_fee_per_door'];
    if (v is num) return v.toDouble();
    return defaultMonthlyFeePerDoor;
  }

  static double readMinBillablePercent(Map<String, dynamic> property) {
    final v = property['minimum_billable_occupancy_percent'];
    if (v is num) return v.toDouble();
    return defaultMinimumBillablePercent;
  }
}
