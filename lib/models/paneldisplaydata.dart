// lib/models/paneldisplaydata.dart

import 'package:secpanel/models/busbarremark.dart';
import 'package:secpanel/models/panels.dart';

class PanelDisplayData {
  final Panel panel;
  final String panelVendorName;
  final String? panelRemarks; 
  final String busbarVendorNames;
  final List<String> busbarVendorIds;
  final List<BusbarRemark> busbarRemarks;
  final String componentVendorNames;
  final List<String> componentVendorIds;
  final String paletVendorNames;
  final List<String> paletVendorIds;
  final String corepartVendorNames;
  final List<String> corepartVendorIds;
  final int issueCount;
  final int additionalSrCount;
  final DateTime? productionDate;
  final DateTime? fatDate;
  final DateTime? allDoneDate;

  PanelDisplayData({
    required this.panel,
    required this.panelVendorName,
    required this.panelRemarks,
    required this.busbarVendorNames,
    required this.busbarVendorIds,
    required this.busbarRemarks,
    required this.componentVendorNames,
    required this.componentVendorIds,
    required this.paletVendorNames,
    required this.paletVendorIds,
    required this.corepartVendorNames,
    required this.corepartVendorIds,
    required this.issueCount,
    required this.additionalSrCount,
    this.productionDate,
    this.fatDate,
    this.allDoneDate,
  });

  factory PanelDisplayData.fromJson(Map<String, dynamic> json) {
    List<String> parseIdList(dynamic rawValue) {
      if (rawValue is List) {
        return rawValue.map((e) => e.toString()).toList();
      }
      if (rawValue is String && rawValue.isNotEmpty) {
        return rawValue.split(',').where((id) => id.isNotEmpty).toList();
      }
      return [];
    }

    List<BusbarRemark> remarks = [];
    final dynamic rawRemarks = json['busbar_remarks'];
    if (rawRemarks is List) {
      remarks = rawRemarks
          .map((r) => BusbarRemark.fromJson(r as Map<String, dynamic>))
          .toList();
    }

    final panelData = json['panel'] as Map<String, dynamic>? ?? {};
    final Panel createdPanel = Panel.fromMap(panelData);
    DateTime? parseDate(String? dateStr) {
      if (dateStr == null) return null;
      return DateTime.tryParse(dateStr)?.toLocal();
    }
    return PanelDisplayData(
      panel: createdPanel,
      panelVendorName: json['panel_vendor_name'] as String? ?? '',
      panelRemarks: createdPanel.remarks,
      busbarVendorNames: json['busbar_vendor_names'] as String? ?? '',
      busbarVendorIds: parseIdList(json['busbar_vendor_ids']),
      busbarRemarks: remarks,
      componentVendorNames: json['component_vendor_names'] as String? ?? '',
      componentVendorIds: parseIdList(json['component_vendor_ids']),
      paletVendorNames: json['palet_vendor_names'] as String? ?? '',
      paletVendorIds: parseIdList(json['palet_vendor_ids']),
      corepartVendorNames: json['corepart_vendor_names'] as String? ?? '',
      corepartVendorIds: parseIdList(json['corepart_vendor_ids']),
      issueCount: json['issue_count'] as int? ?? 0,
      additionalSrCount: json['additional_sr_count'] as int? ?? 0,
      productionDate: parseDate(json['production_date'] as String?),
      fatDate: parseDate(json['fat_date'] as String?),
      allDoneDate: parseDate(json['all_done_date'] as String?),
    );
  }
}
