// lib/models/additionalsr.dart

import 'dart:convert';

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
      panelNoPp: map['PanelNoPp'] ?? '',
      panelNoWbs: map['PanelNoWbs']?['String'],
      panelNoPanel: map['PanelNoPanel']?['String'],
      poNumber: map['PoNumber'] ?? '',
      item: map['Item'] ?? '',
      quantity: map['Quantity'] ?? 0,
      supplier: map['Supplier']?['String'],
      status: map['Status'] ?? '',
      remarks: map['Remarks'] ?? '',
    );
  }

  // Constructor lama Anda
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