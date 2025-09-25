// lib/models/production_slot.dart

class ProductionSlot {
  final String positionCode;
  final bool isOccupied;
  final String? panelNoPp;

  ProductionSlot({
    required this.positionCode,
    required this.isOccupied,
    this.panelNoPp,
  });

  factory ProductionSlot.fromJson(Map<String, dynamic> json) {
    return ProductionSlot(
      positionCode: json['position_code'],
      isOccupied: json['is_occupied'],
      panelNoPp: json['panel_no_pp'],
    );
  }
}