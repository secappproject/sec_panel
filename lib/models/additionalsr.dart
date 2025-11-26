import 'dart:convert';






String? _parseString(dynamic jsonValue) {
  if (jsonValue == null) {
    return null;
  }
  
  
  if (jsonValue is Map<String, dynamic>) {
    if (jsonValue['Valid'] == true) {
      return jsonValue['String']?.toString();
    }
    return null; 
  }
  
  
  if (jsonValue is String) {
    return jsonValue.isEmpty ? null : jsonValue;
  }
  
  return jsonValue.toString();
}


DateTime? _parseDateTime(dynamic jsonValue) {
  if (jsonValue == null) {
    return null;
  }
  
  
  if (jsonValue is String && jsonValue.isNotEmpty) {
    try {
      return DateTime.parse(jsonValue);
    } catch (e) {
      return null; 
    }
  }
  
  
  if (jsonValue is Map<String, dynamic>) {
    
    if (jsonValue['Valid'] == true && jsonValue['Time'] != null) {
      try {
        return DateTime.parse(jsonValue['Time'].toString());
      } catch (e) {
        return null;
      }
    }
    return null;
  }
  
  return null;
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
  final DateTime? receivedDate; 
  final DateTime? closeDate; 

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
    this.receivedDate, 
    this.closeDate, 
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
      'received_date': receivedDate?.toIso8601String(), 
      'close_date': closeDate?.toIso8601String(), 
    };
  }

  factory AdditionalSR.fromMap(Map<String, dynamic> map) {
    return AdditionalSR(
      id: map['id'],
      
      panelNoPp: map['panel_no_pp']?.toString().trim() ?? '',
      
      poNumber: _parseString(map['po_number']) ?? '',
      item: _parseString(map['item']) ?? '',
      quantity: map['quantity']?.toInt() ?? 0,
      supplier: _parseString(map['supplier']), 
      status: _parseString(map['status']) ?? 'open',
      remarks: _parseString(map['remarks']) ?? '',
      
      createdAt: _parseDateTime(map['created_at']),
      receivedDate: _parseDateTime(map['received_date']),
      closeDate: _parseDateTime(map['close_date']),
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
  final DateTime? receivedDate; 
  final DateTime? closeDate; 

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
    this.receivedDate, 
    this.closeDate, 
  });

  factory AdditionalSRForExport.fromMap(Map<String, dynamic> map) {
    return AdditionalSRForExport(
      panelNoPp: (map['panel_no_pp'] as String? ?? '').trim(),
      panelNoWbs: _parseString(map['panel_no_wbs']), 
      panelNoPanel: _parseString(map['panel_no_panel']), 
      poNumber: _parseString(map['po_number']) ?? '', 
      item: _parseString(map['item']) ?? '', 
      quantity: map['quantity'] ?? 0,
      supplier: _parseString(map['supplier']),
      status: _parseString(map['status']) ?? '', 
      remarks: _parseString(map['remarks']) ?? '', 
      receivedDate: _parseDateTime(map['received_date']), 
      closeDate: _parseDateTime(map['close_date']),
    );
  }
}