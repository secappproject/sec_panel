import 'dart:convert';
import 'package:secpanel/models/paneldisplaydata.dart';
import 'package:secpanel/models/company.dart';

class ExportHelper {
  /// ================= BUILD MAIN PAYLOAD =================
  static Map<String, dynamic> buildExportPayload({
    required Company currentUser,
    required List<PanelDisplayData> panels,
    required bool exportPanel,
    required bool exportUser,
    required bool exportIssue,
    required bool exportSr,
    required bool exportWiring,
  }) {
    final Map<String, dynamic> payload = {};

    if (exportPanel) {
      payload['panels'] = panels.map(buildPanelExportRow).toList();
    }

    if (exportUser) {
      payload['user'] = buildUserExportRow(currentUser);
    }

    if (exportIssue) {
      payload['issues'] = panels.expand(buildIssueExportRows).toList();
    }

    if (exportSr) {
      payload['additional_sr'] = panels
          .expand(buildAdditionalSrExportRows)
          .toList();
    }

    if (exportWiring) {
      payload['wirings'] = panels.expand(buildWiringExportRows).toList();
    }

    return payload;
  }

  /// ================= WIRING EXPORT =================
  static List<Map<String, dynamic>> buildWiringExportRows(
    PanelDisplayData panel,
  ) {
    if (panel.wirings == null || panel.wirings!.isEmpty) {
      return [];
    }

    return panel.wirings!.map((wiring) {
      return {
        "panel_no_pp": panel.panel.noPp,
        "wiring_status": wiring.status,
        "wiring_timestamp": wiring.closedAt?.toIso8601String(),
      };
    }).toList();
  }

  /// ================= PANEL EXPORT =================
  static Map<String, dynamic> buildPanelExportRow(PanelDisplayData panel) {
    return {
      // PANEL
      "panel_no_pp": panel.panel.noPp,
      "no_panel": panel.panel.noPanel ?? "",
      "panel_vendor": panel.panelVendorName,
      "panel_type": panel.panelType,
      "target_delivery": panel.targetDelivery?.toIso8601String(),

      // BUSBAR
      "busbar_vendor": panel.busbarVendorNames,
      "busbar_vendor_ids": panel.busbarVendorIds.join(", "),
      "busbar_remarks": panel.busbarRemarks.map((e) => e.remark).join(" | "),

      // COMPONENT
      "component_vendor": panel.componentVendorNames,
      "component_vendor_ids": panel.componentVendorIds.join(", "),

      // PALET
      "palet_vendor": panel.paletVendorNames,
      "palet_vendor_ids": panel.paletVendorIds.join(", "),

      // COREPART
      "corepart_vendor": panel.corepartVendorNames,
      "corepart_vendor_ids": panel.corepartVendorIds.join(", "),

      // WIRING SUMMARY
      "wiring_vendor": panel.wiringVendorNames,
      "wiring_vendor_ids": panel.wiringVendorIds.join(", "),
      "wiring_timestamps": panel.wirings
          .map((w) => w.closedAt?.toIso8601String() ?? "")
          .where((e) => e.isNotEmpty)
          .join(" | "),

      // STATUS
      "issue_count": panel.issueCount,
      "additional_sr_count": panel.additionalSrCount,

      // DATE
      "production_date": panel.productionDate?.toIso8601String(),
      "fat_date": panel.fatDate?.toIso8601String(),
      "all_done_date": panel.allDoneDate?.toIso8601String(),

      // G3
      "g3_vendor": panel.g3VendorNames,
    };
  }

  /// ================= USER EXPORT =================
  static Map<String, dynamic> buildUserExportRow(Company user) {
    return {"user_id": user.id, "company_name": user.name};
  }

  /// ================= ISSUE EXPORT =================
  static List<Map<String, dynamic>> buildIssueExportRows(
    PanelDisplayData panel,
  ) {
    if (panel.issueCount == 0) return [];

    return List.generate(panel.issueCount, (index) {
      return {
        "panel_no_pp": panel.panel.noPp,
        "issue_index": index + 1,
        "issue_type": "Issue",
        "issue_status": "Open",
      };
    });
  }

  /// ================= ADDITIONAL SR EXPORT =================
  static List<Map<String, dynamic>> buildAdditionalSrExportRows(
    PanelDisplayData panel,
  ) {
    if (panel.additionalSrCount == 0) return [];

    return List.generate(panel.additionalSrCount, (index) {
      return {
        "panel_no_pp": panel.panel.noPp,
        "sr_index": index + 1,
        "sr_type": "Additional SR",
        "sr_status": "Open",
      };
    });
  }

  /// ================= JSON EXPORT =================
  static String exportToJson({
    required Company currentUser,
    required List<PanelDisplayData> panels,
    required bool exportPanel,
    required bool exportUser,
    required bool exportIssue,
    required bool exportSr,
    required bool exportWiring,
  }) {
    final payload = buildExportPayload(
      currentUser: currentUser,
      panels: panels,
      exportPanel: exportPanel,
      exportUser: exportUser,
      exportIssue: exportIssue,
      exportSr: exportSr,
      exportWiring: exportWiring,
    );

    return const JsonEncoder.withIndent('  ').convert(payload);
  }

  /// ================= EXCEL EXPORT =================
  static List<Map<String, dynamic>> exportToExcelRows({
    required Company currentUser,
    required List<PanelDisplayData> panels,
    required bool exportPanel,
    required bool exportUser,
    required bool exportIssue,
    required bool exportSr,
    required bool exportWiring,
  }) {
    final List<Map<String, dynamic>> rows = [];

    if (exportPanel) {
      rows.addAll(panels.map(buildPanelExportRow));
    }

    if (exportUser) {
      rows.add(buildUserExportRow(currentUser));
    }

    if (exportIssue) {
      rows.addAll(panels.expand(buildIssueExportRows));
    }

    if (exportSr) {
      rows.addAll(panels.expand(buildAdditionalSrExportRows));
    }

    if (exportWiring) {
      rows.addAll(panels.expand(buildWiringExportRows));
    }

    return rows;
  }
}
