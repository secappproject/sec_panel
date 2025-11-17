

class ProductionSlot {
  final String positionCode;
  final bool isOccupied;
  final String? panelNoPp;
  final String? panelNoPanel; 

  ProductionSlot({
    required this.positionCode,
    required this.isOccupied,
    this.panelNoPp,
    this.panelNoPanel, 
  });

  factory ProductionSlot.fromJson(Map<String, dynamic> json) {
    return ProductionSlot(
      positionCode: json['position_code'],
      isOccupied: json['is_occupied'],
      panelNoPp: json['panel_no_pp'],
      panelNoPanel: json['panel_no_panel'],
    );
  }
}