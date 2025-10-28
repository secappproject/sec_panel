// lib/models/additionalsr.dart

import 'dart:convert';
String? _parseString(dynamic jsonValue) {
  if (jsonValue == null) {
    return null;
  }
  
  if (jsonValue is Map<String, dynamic>) {
    if (jsonValue['Valid'] == true) {
      return jsonValue['String'];
    }
    return null; 
  }
  
  if (jsonValue is String) {
    return jsonValue.isEmpty ? null : jsonValue;
  }
  
  return jsonValue.toString();
}
class AdditionalSR {
  final int? id;
  final String panelNoPp;
  final String poNumber;
  final String item;
  final int quantity;
  final String? supplier;
  final String status;
  final String remarks;
  final DateTime? createdAt;
  final DateTime? receivedDate; // [BARU] Tambahkan field ini

  AdditionalSR({
    this.id,
    required this.panelNoPp,
    required this.poNumber,
    required this.item,
    required this.quantity,
    this.supplier,
    required this.status,
    required this.remarks,
    this.createdAt,
    this.receivedDate, // [BARU] Tambahkan di constructor
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'panel_no_pp': panelNoPp,
      'po_number': poNumber,
      'item': item,
      'quantity': quantity,
      'supplier': supplier,
      'status': status,
      'remarks': remarks,
      'created_at': createdAt?.toIso8601String(),
      'received_date': receivedDate?.toIso8601String(), // [BARU] Tambahkan ke map
    };
  }

  factory AdditionalSR.fromMap(Map<String, dynamic> map) {
    return AdditionalSR(
      id: map['id'],
      panelNoPp: map['panel_no_pp'] ?? '',
      poNumber: map['po_number'] ?? '',
      item: map['item'] ?? '',
      quantity: map['quantity']?.toInt() ?? 0,
      supplier: map['supplier'], 
      status: map['status'] ?? 'open',
      remarks: map['remarks'] ?? '',
      createdAt: map['created_at'] != null ? DateTime.parse(map['created_at']) : null,
      receivedDate: map['received_date'] != null ? DateTime.parse(map['received_date']) : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory AdditionalSR.fromJson(String source) => AdditionalSR.fromMap(json.decode(source));
}
class AdditionalSRForExport {
  final String panelNoPp;
  final String? panelNoWbs;
  final String? panelNoPanel;
  final String poNumber;
  final String item;
  final int quantity;
  final String? supplier;
  final String status;
  final String remarks;

  factory AdditionalSRForExport.fromMap(Map<String, dynamic> map) {
    return AdditionalSRForExport(
      panelNoPp: map['panel_no_pp'] ?? '',
      panelNoWbs: _parseString(map['panel_no_wbs']), 
      panelNoPanel: _parseString(map['panel_no_panel']), 
      poNumber: _parseString(map['po_number']) ?? '', 
      item: _parseString(map['item']) ?? '', 
      quantity: map['quantity'] ?? 0,
      supplier: _parseString(map['supplier']),
      status: _parseString(map['status']) ?? '', 
      remarks: _parseString(map['remarks']) ?? '', 
    );
  }

  AdditionalSRForExport({
    required this.panelNoPp,
    this.panelNoWbs,
    this.panelNoPanel,
    required this.poNumber,
    required this.item,
    required this.quantity,
    this.supplier,
    required this.status,
    required this.remarks,
  });
}