

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
  final String g3VendorNames; 

  PanelDisplayData({
    required this.panel,
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
    required this.issueCount,
    required this.additionalSrCount,
    this.productionDate,
    this.fatDate,
    this.allDoneDate,
    required this.g3VendorNames, 
  });

  factory PanelDisplayData.fromJson(Map<String, dynamic> json) {
    
    List<String> _parseStringList(dynamic jsonList) {
      if (jsonList is List) {
        return jsonList.map((e) => e.toString()).toList();
      }
      return [];
    }

    
    List<BusbarRemark> _parseBusbarRemarks(dynamic remarksJson) {
      if (remarksJson == null) {
        return [];
      }
      try {
        
        if (remarksJson is String) {
          final List<dynamic> decodedList = jsonDecode(remarksJson);
          return decodedList
              .map((item) => BusbarRemark.fromJson(item))
              .toList();
        }
        
        else if (remarksJson is List) {
          return remarksJson
              .map((item) => BusbarRemark.fromJson(item))
              .toList();
        }
        return [];
      } catch (e) {
        print('Error parsing busbar remarks: $e');
        return [];
      }
    }

    return PanelDisplayData(
      panel: Panel.fromMap(json['panel']),
      panelVendorName: json['panel_vendor_name'] ?? '',
      busbarVendorNames: json['busbar_vendor_names'] ?? '',
      busbarVendorIds: _parseStringList(json['busbar_vendor_ids']),
      busbarRemarks: _parseBusbarRemarks(json['busbar_remarks']),
      componentVendorNames: json['component_vendor_names'] ?? '',
      componentVendorIds: _parseStringList(json['component_vendor_ids']),
      paletVendorNames: json['palet_vendor_names'] ?? '',
      paletVendorIds: _parseStringList(json['palet_vendor_ids']),
      corepartVendorNames: json['corepart_vendor_names'] ?? '',
      corepartVendorIds: _parseStringList(json['corepart_vendor_ids']),
      issueCount: json['issue_count'] ?? 0,
      additionalSrCount: json['additional_sr_count'] ?? 0,
      productionDate: json['production_date'] != null
          ? DateTime.parse(json['production_date'])
          : null,
      fatDate: json['fat_date'] != null
          ? DateTime.parse(json['fat_date'])
          : null,
      allDoneDate: json['all_done_date'] != null
          ? DateTime.parse(json['all_done_date'])
          : null,
      g3VendorNames: json['g3_vendor_names'] ?? '', 
    );
  }
}