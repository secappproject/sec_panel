// lib/models/additionalsr.dart

import 'dart:convert';

class AdditionalSR {
  final int? id;
  final String panelNoPp;
  final String poNumber;
  final String item;
  final int quantity;
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
      status: map['status'] ?? 'open',
      remarks: map['remarks'] ?? '',
      createdAt: map['created_at'] != null ? DateTime.parse(map['created_at']) : null,
      // [BARU] Parsing dari map
      receivedDate: map['received_date'] != null ? DateTime.parse(map['received_date']) : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory AdditionalSR.fromJson(String source) => AdditionalSR.fromMap(json.decode(source));
}