//import 'dart:convert' show jsonDecode;
//import 'package:intl/intl.dart';
import 'package:secpanel/models/panels.dart';

class BusbarRemark {
  final String? remark;
  final String? vendorId;
  final String? vendorName;

  BusbarRemark({this.remark, this.vendorId, this.vendorName});

  factory BusbarRemark.fromJson(Map<String, dynamic> json) {
    String? vName = json['vendor_name']?.toString();
    String? vId = json['vendor_id']?.toString();
    return BusbarRemark(
      remark: json['remark']?.toString(),
      vendorId: vId,
      // Ambil vendor_name, jika kosong gunakan vendor_id sebagai cadangan
      vendorName: vName ?? vId,
    );
  }

  Map<String, dynamic> toJson() => {
    'remark': remark,
    'vendor_id': vendorId,
    'vendor_name': vendorName,
  };
}

class Wiring {
  final String id;
  final String status;
  final int progress;
  final DateTime? closedAt;
  final String noWbs;
  final DateTime? targetDeliveryWiring;
  final String supplier;

  Wiring({
    required this.id,
    required this.status,
    required this.progress,
    this.closedAt,
    required this.noWbs,
    this.targetDeliveryWiring,
    this.supplier = '',
  });

  factory Wiring.fromJson(Map<String, dynamic> json) {
    return Wiring(
      id: json['id']?.toString() ?? '',
      status: json['status'] ?? 'Open',
      progress: json['progress'] is int
          ? json['progress']
          : int.tryParse(json['progress']?.toString() ?? '0') ?? 0,
      closedAt: json['closed_at'] != null && json['closed_at'] != ""
          ? DateTime.tryParse(json['closed_at'])
          : null,
      noWbs: json['no_wbs']?.toString() ?? '',
      targetDeliveryWiring:
          json['target_delivery_wiring'] != null &&
              json['target_delivery_wiring'] != ""
          ? DateTime.tryParse(json['target_delivery_wiring'].toString())
          : null,
      supplier: json['supplier']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'status': status,
    'progress': progress,
    'closed_at': closedAt?.toIso8601String(),
    'supplier': supplier,
    'target_delivery_wiring': targetDeliveryWiring == null
        ? null
        : "${targetDeliveryWiring!.year.toString().padLeft(4, '0')}-"
              "${targetDeliveryWiring!.month.toString().padLeft(2, '0')}-"
              "${targetDeliveryWiring!.day.toString().padLeft(2, '0')}",
  };
}

class PanelDisplayData {
  final Panel panel;
  final String panelType;
  final String? productType;
  final String panelVendorName;
  final String busbarVendorNames;
  final List<String> busbarVendorIds;
  final List<BusbarRemark> busbarRemarks;
  final String componentVendorNames;
  final List<String> componentVendorIds;
  final String paletVendorNames;
  final List<String> paletVendorIds;
  final String corepartVendorNames;
  final List<String> corepartVendorIds;
  final String wiringVendorNames;
  final List<String> wiringVendorIds;

  final DateTime? targetDelivery;
  DateTime? actualDeliveryWiring;
  DateTime? targetDeliveryWiring;
  String wiringStatus;
  int wiringProgress;

  final List<Wiring> wirings;

  final int issueCount;
  final int additionalSrCount;
  final DateTime? productionDate;
  final DateTime? fatDate;
  final DateTime? allDoneDate;
  final String g3VendorNames;

  PanelDisplayData({
    required this.panel,
    required this.panelType,
    this.productType,
    required this.panelVendorName,
    required this.busbarVendorNames,
    required this.busbarVendorIds,
    required this.busbarRemarks,
    required this.componentVendorNames,
    required this.componentVendorIds,
    required this.paletVendorNames,
    required this.paletVendorIds,
    required this.corepartVendorNames,
    required this.corepartVendorIds,
    required this.wiringVendorNames,
    required this.wiringVendorIds,
    this.wiringStatus = "Open",
    this.wiringProgress = 0,
    this.wirings = const [],
    required this.issueCount,
    required this.additionalSrCount,
    this.productionDate,
    this.fatDate,
    this.allDoneDate,
    required this.g3VendorNames,
    this.targetDelivery,
    this.actualDeliveryWiring,
    this.targetDeliveryWiring,
  });

  factory PanelDisplayData.fromJson(Map<String, dynamic> json) {
    List<Wiring> wiringList = [];

    if (json['wirings'] is List) {
      wiringList = (json['wirings'] as List)
          .map((w) => Wiring.fromJson(w))
          .toList();
    }

    int progress = 0;
    String status = 'Open';

    if (wiringList.isNotEmpty) {
      progress = wiringList
          .map((w) => w.progress)
          .reduce((a, b) => a > b ? a : b);

      status = wiringList.any((w) => w.status == 'Closed') ? 'Closed' : 'Open';
    }

    return PanelDisplayData(
      panel: Panel.fromMap(json['panel']),
      panelType: json['panel_type'] ?? json['panel']?['panel_type'] ?? '',
      productType: json['product_type'],
      panelVendorName: json['panel_vendor_name'] ?? '',
      busbarVendorNames: json['busbar_vendor_names'] ?? '',
      busbarVendorIds:
          (json['busbar_vendor_ids'] as List?)?.cast<String>() ?? [],
      busbarRemarks: [],
      componentVendorNames: json['component_vendor_names'] ?? '',
      componentVendorIds:
          (json['component_vendor_ids'] as List?)?.cast<String>() ?? [],
      paletVendorNames: json['palet_vendor_names'] ?? '',
      paletVendorIds: (json['palet_vendor_ids'] as List?)?.cast<String>() ?? [],
      corepartVendorNames: json['corepart_vendor_names'] ?? '',
      corepartVendorIds:
          (json['corepart_vendor_ids'] as List?)?.cast<String>() ?? [],
      wiringVendorNames: json['wiring_vendor_names'] ?? '',
      wiringVendorIds:
          (json['wiring_vendor_ids'] as List?)?.cast<String>() ?? [],
      wiringStatus: json['wiring_status'] ?? 'Open',
      wiringProgress: json['wiring_progress'] ?? 0,
      wirings: wiringList,
      issueCount: json['issue_count'] ?? 0,
      additionalSrCount: json['additional_sr_count'] ?? 0,
      productionDate: json['production_date'] != null
          ? DateTime.parse(json['production_date']).toLocal()
          : null,
      targetDelivery: json['panel']?['target_delivery'] != null
          ? DateTime.parse(json['panel']['target_delivery']).toLocal()
          : null,

      targetDeliveryWiring: json['target_delivery_wiring'] != null
          ? DateTime.parse(json['target_delivery_wiring']).toLocal()
          : json['wiring_target_delivery'] != null
          ? DateTime.parse(json['wiring_target_delivery']).toLocal()
          : null,

      fatDate: json['fat_date'] != null
          ? DateTime.parse(json['fat_date']).toLocal()
          : null,
      allDoneDate: json['all_done_date'] != null
          ? DateTime.parse(json['all_done_date']).toLocal()
          : null,
      g3VendorNames: json['g3_vendor_names'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'panel_vendor_name': panelVendorName,
    'busbar_vendor_names': busbarVendorNames,
    'busbar_vendor_ids': busbarVendorIds,
    'busbar_remarks': busbarRemarks.map((e) => e.toJson()).toList(),
    'component_vendor_names': componentVendorNames,
    'component_vendor_ids': componentVendorIds,
    'palet_vendor_names': paletVendorNames,
    'palet_vendor_ids': paletVendorIds,
    'corepart_vendor_names': corepartVendorNames,
    'corepart_vendor_ids': corepartVendorIds,
    'wiring_vendor_names': wiringVendorNames,
    'wiring_vendor_ids': wiringVendorIds,
    'wiring_status': wiringStatus,
    'wiring_progress': wiringProgress,
    'wirings': wirings.map((w) => w.toJson()).toList(),
    'issue_count': issueCount,
    'additional_sr_count': additionalSrCount,
    'production_date': productionDate?.toIso8601String(),
    'target_delivery': targetDelivery?.toIso8601String(),
    'target_delivery_wiring': targetDeliveryWiring?.toIso8601String(),
    'fat_date': fatDate?.toIso8601String(),
    'all_done_date': allDoneDate?.toIso8601String(),
    'closed_date': allDoneDate?.toIso8601String(),
    'g3_vendor_names': g3VendorNames,
  };
}
