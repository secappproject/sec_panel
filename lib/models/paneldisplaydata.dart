// lib/models/paneldisplaydata.dart

import 'dart:convert';
import 'package:secpanel/models/busbarremark.dart';
import 'package:secpanel/models/panels.dart';

class PanelDisplayData {
  final Panel panel;
  final String panelVendorName;
  final String busbarVendorNames;
  final List<String> busbarVendorIds;
  final List<BusbarRemark> busbarRemarks;
  final String componentVendorNames;
  final String? panelRemarks;

  final List<String> componentVendorIds;
  final String paletVendorNames;
  final List<String> paletVendorIds;
  final String corepartVendorNames;
  final List<String> corepartVendorIds;

  PanelDisplayData({
    required this.panel,
    required this.panelVendorName,
    required this.busbarVendorNames,
    required this.busbarVendorIds,
    required this.busbarRemarks,
    required this.componentVendorNames,
    required this.panelRemarks,
    required this.componentVendorIds,
    required this.paletVendorNames,
    required this.paletVendorIds,
    required this.corepartVendorNames,
    required this.corepartVendorIds,
  });
  factory PanelDisplayData.fromJson(Map<String, dynamic> json) {
    // This helper function now correctly handles a List<dynamic> from JSON.
    List<String> _parseIdList(dynamic rawValue) {
      if (rawValue is List) {
        return rawValue.map((e) => e.toString()).toList();
      }
      // Kept for robustness in case the API ever sends a string
      if (rawValue is String && rawValue.isNotEmpty) {
        return rawValue.split(',').where((id) => id.isNotEmpty).toList();
      }
      return [];
    }

    List<BusbarRemark> remarks = [];
    final dynamic rawRemarks = json['busbar_remarks'];

    if (rawRemarks != null) {
      // This logic is already correct and handles a JSON array for remarks.
      if (rawRemarks is String && rawRemarks.isNotEmpty) {
        try {
          final List<dynamic> decodedRemarks = jsonDecode(rawRemarks);
          remarks = decodedRemarks
              .map((r) => BusbarRemark.fromJson(r))
              .toList();
        } catch (e) {
          print("Gagal parse busbar_remarks (string): $e");
        }
      } else if (rawRemarks is List) {
        remarks = rawRemarks
            .map((r) => BusbarRemark.fromJson(r as Map<String, dynamic>))
            .toList();
      }
    }

    final panelData = json['panel'] as Map<String, dynamic>? ?? {};

    return PanelDisplayData(
      panel: Panel.fromMap(panelData),
      panelVendorName: json['panel_vendor_name'] as String? ?? '',
      panelRemarks: panelData['remarks'] as String?,
      busbarVendorNames: json['busbar_vendor_names'] as String? ?? '',
      // Use the new helper function without the failing 'as String?' cast.
      busbarVendorIds: _parseIdList(json['busbar_vendor_ids']),
      busbarRemarks: remarks,
      componentVendorNames: json['component_vendor_names'] as String? ?? '',
      componentVendorIds: _parseIdList(json['component_vendor_ids']),
      paletVendorNames: json['palet_vendor_names'] as String? ?? '',
      paletVendorIds: _parseIdList(json['palet_vendor_ids']),
      corepartVendorNames: json['corepart_vendor_names'] as String? ?? '',
      corepartVendorIds: _parseIdList(json['corepart_vendor_ids']),
    );
  }
}
