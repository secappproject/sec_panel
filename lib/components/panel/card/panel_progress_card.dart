// lib/components/panel/card/panel_progress_card.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:secpanel/components/issue/panel_issue_screen.dart';
// AlertBox tidak lagi digunakan di sini, bisa dihapus jika tidak ada referensi lain
// import 'package:secpanel/components/alert_box.dart';
import 'package:secpanel/components/panel/card/remarks_bottom_sheet.dart';
import 'package:secpanel/models/approles.dart';
import 'package:secpanel/models/busbarremark.dart';
import 'package:secpanel/theme/colors.dart';

class AlertInfo {
  final String title;
  final String description;
  final String imagePath;
  final Color backgroundColor;
  final Color borderColor;
  final Color textColor;

  AlertInfo({
    required this.title,
    required this.description,
    required this.imagePath,
    required this.backgroundColor,
    required this.borderColor,
    required this.textColor,
  });
}

class PanelProgressCard extends StatelessWidget {
  final AppRole currentUserRole;
  final String duration;
  final DateTime? targetDelivery;
  final double progress;
  final DateTime? startDate;
  final String progressLabel;
  final String panelTitle;
  final int issueCount;
  final String panelType;
  final String statusBusbar;
  final String statusComponent;
  final String statusPalet;
  final String statusCorepart;
  final String ppNumber;
  final String wbsNumber;
  final String project;
  final VoidCallback onEdit;
  final String panelVendorName;
  final String busbarVendorNames;
  final String componentVendorName;
  final String paletVendorName;
  final String corepartVendorName;
  final bool isClosed;
  final DateTime? closedDate;
  final String? panelRemarks;
  final List<BusbarRemark> busbarRemarks;

  const PanelProgressCard({
    super.key,
    required this.currentUserRole,
    required this.duration,
    required this.targetDelivery,
    required this.progress,
    required this.startDate,
    required this.progressLabel,
    required this.panelType,
    required this.issueCount,
    required this.panelTitle,
    required this.statusBusbar,
    required this.statusComponent,
    required this.statusPalet,
    required this.statusCorepart,
    required this.ppNumber,
    required this.wbsNumber,
    required this.project,
    required this.onEdit,
    required this.panelVendorName,
    required this.busbarVendorNames,
    required this.componentVendorName,
    required this.paletVendorName,
    required this.corepartVendorName,
    required this.isClosed,
    this.closedDate,
    this.panelRemarks,
    required this.busbarRemarks,
  });

  void _showRemarksBottomSheet(
    BuildContext context, {
    required String title,
    required Map<String, String?> remarksMap,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => RemarksBottomSheet(title: title, remarksMap: remarksMap),
    );
  }

  AlertInfo? _getAlertInfo() {
    // Jika targetDelivery tidak diatur atau tidak valid
    if (targetDelivery == null) {
      return AlertInfo(
        title: "Belum Diatur",
        description: "Target pengiriman belum diatur",
        imagePath: 'assets/images/alert-warning.png',
        backgroundColor: AppColors.orange.withOpacity(0.1),
        borderColor: AppColors.orange,
        textColor: AppColors.orange,
      );
    }
    final now = DateTime.now();
    final nowDateOnly = DateTime(now.year, now.month, now.day);
    final targetDateOnly = DateTime(
      targetDelivery!.year,
      targetDelivery!.month,
      targetDelivery!.day,
    );
    final differenceInDays = targetDateOnly.difference(nowDateOnly).inDays;
    final formattedDate = DateFormat(
      'd MMM yyyy',
      'id_ID',
    ).format(targetDelivery!);
    // Deskripsi singkat untuk chip
    String shortDesc = "";
    if (differenceInDays < 0) {
      shortDesc = "Telat ${differenceInDays.abs()} hari ($formattedDate)";
    } else if (differenceInDays == 0) {
      shortDesc = "Perlu dikirim hari ini ($formattedDate)";
    } else {
      shortDesc = "Akan dikirim dalam $differenceInDays hari ($formattedDate)";
    }

    if (differenceInDays < 0) {
      return AlertInfo(
        title: "Telat",
        description: shortDesc,
        imagePath: 'assets/images/alert-danger.png',
        backgroundColor: AppColors.red.withOpacity(0.05),
        borderColor: AppColors.red,
        textColor: AppColors.red,
      );
    }
    if (differenceInDays >= 0) {
      return AlertInfo(
        title: "Perlu Dikejar",
        description: shortDesc,
        imagePath: 'assets/images/alert-progress.png',
        backgroundColor: AppColors.blue.withOpacity(0.1),
        borderColor: AppColors.blue,
        textColor: AppColors.blue,
      );
    }
    if (differenceInDays >= 0) {
      return AlertInfo(
        title: "Perlu Dikejar",
        description: shortDesc,
        imagePath: 'assets/images/alert-progress.png',
        backgroundColor: AppColors.blue.withOpacity(0.1),
        borderColor: AppColors.blue,
        textColor: AppColors.blue,
      );
    }
  }

  Color _getProgressColor() {
    if (isClosed) return AppColors.schneiderGreen;
    if (progress < 0.5) return AppColors.red;
    if (progress < 0.75) return AppColors.orange;
    return AppColors.blue;
  }

  String _getProgressImage() {
    if (isClosed) return 'assets/images/progress-bolt-green.png';
    if (progress < 0.5) return 'assets/images/progress-bolt-red.png';
    if (progress < 0.75) return 'assets/images/progress-bolt-orange.png';
    return 'assets/images/progress-bolt-blue.png';
  }

  // String _getBusbarStatusImage(String status) {
  //   final lower = status.toLowerCase();
  //   if (lower.contains('on progress')) return 'assets/images/new-yellow.png';
  //   if (lower.contains('close')) return 'assets/images/done-green.png';
  //   if (lower.contains('siap 100%')) return 'assets/images/done-blue.png';
  //   if (lower.contains('red block')) return 'assets/images/on-block-red.png';
  //   return 'assets/images/no-status-gray.png';
  // }

  String _getBusbarStatusImage(String status) {
    final lower = status.toLowerCase();
    if (lower.contains('open')) return 'assets/images/no-status-gray.png';
    if (lower.contains('done') || lower.contains('close')) {
      return 'assets/images/done-green.png';
    }
    if (lower.contains('on progress') ||
        lower.contains('punching/bending') ||
        lower.contains('plating/epoxy')) {
      return 'assets/images/on-progress-blue.png';
    }
    if (lower.contains('100% siap kirim')) return 'assets/images/done-blue.png';
    if (lower.contains('red block')) return 'assets/images/on-block-red.png';
    return 'assets/images/no-status-gray.png';
  }

  String _getComponentStatusImage(String status) {
    final lower = status.toLowerCase();
    if (lower.contains('open')) return 'assets/images/no-status-gray.png';
    if (lower.contains('done')) {
      return 'assets/images/done-green.png';
    }
    if (lower.contains('on progress')) {
      return 'assets/images/on-progress-blue.png';
    }
    return 'assets/images/no-status-gray.png';
  }

  String _getPaletStatusImage(String status) =>
      status.toLowerCase().contains('close')
      ? 'assets/images/done-green.png'
      : 'assets/images/no-status-gray.png';
  String _getCorepartStatusImage(String status) =>
      status.toLowerCase().contains('close')
      ? 'assets/images/done-green.png'
      : 'assets/images/no-status-gray.png';

  Widget _buildStatusChip() {
    AlertInfo? alert;

    if (isClosed) {
      alert = AlertInfo(
        title: "Closed",
        description:
            "Closed ${DateFormat('d MMM yyyy', 'id_ID').format(closedDate ?? DateTime.now())} (Target: ${targetDelivery != null ? DateFormat('d MMM yyyy', 'id_ID').format(targetDelivery!) : 'belum diatur'})",
        imagePath: 'assets/images/alert-success.png',
        backgroundColor: AppColors.schneiderGreen.withOpacity(0.05),
        borderColor: AppColors.schneiderGreen,
        textColor: AppColors.schneiderGreen,
      );
    } else {
      alert = _getAlertInfo();
    }

    if (alert == null) {
      return const SizedBox.shrink(); // Tidak menampilkan apa-apa jika tidak ada alert
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8, right: 8, left: 8),
      child: Container(
        width: double.infinity,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: alert.backgroundColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: alert.borderColor, width: 0.8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(alert.imagePath, height: 14),
            const SizedBox(width: 6),
            Text(
              alert.description,
              style: TextStyle(
                color: alert.textColor,
                fontSize: 11,
                fontWeight: FontWeight.w300,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isTemporary = ppNumber.startsWith('TEMP_PP_');
    final bool hasBusbarRemarks = busbarRemarks.isNotEmpty;
    final bool hasPanelRemarks =
        panelRemarks != null && panelRemarks!.trim().isNotEmpty;

    // final String pccDisplayStatus = statusBusbarPcc.isEmpty
    //     ? 'On Progress'
    //     : statusBusbarPcc;
    // final String mccDisplayStatus = statusBusbarMcc.isEmpty
    //     ? 'On Progress'
    //     : statusBusbarMcc;
    final String displayStatus = statusBusbar.isEmpty
        ? 'On Progress'
        : statusBusbar;
    final String componentDisplayStatus = statusComponent.isEmpty
        ? 'Open'
        : statusComponent;
    final String paletDisplayStatus = statusPalet.isEmpty
        ? 'Open'
        : statusPalet;
    final String corepartDisplayStatus = statusCorepart.isEmpty
        ? 'Open'
        : statusCorepart;

    final bool isFuture =
        startDate != null && startDate!.isAfter(DateTime.now());

    final String durationLabel = isFuture ? "Mulai Dalam" : "Durasi Proses";
    final String displayDuration = startDate == null
        ? "Belum Diatur"
        : duration;
    final String displayPanelType = panelType.isEmpty
        ? "Belum Diatur"
        : panelType;
    final String displayPanelTitle = panelTitle.isEmpty
        ? "Belum Diatur"
        : panelTitle;
    final String displayPpNumber = isTemporary ? "Belum Diatur" : ppNumber;
    final String displayWbsNumber = wbsNumber.isEmpty
        ? "Belum Diatur"
        : wbsNumber;
    final String displayProject = project.isEmpty ? "Belum Diatur" : project;

    return Padding(
      padding: const EdgeInsets.only(top: 8, left: 8, right: 8),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.all(Radius.circular(8)),
          border: Border.all(width: 1, color: AppColors.grayLight),
          // boxShadow: [
          //   BoxShadow(
          //     color: Colors.grey.withOpacity(0.08),
          //     spreadRadius: 1,
          //     blurRadius: 0.5,
          //     offset: const Offset(0, 2),
          //   ),
          // ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusChip(),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(width: 2, color: AppColors.grayLight),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Image.asset(_getProgressImage(), height: 28),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.only(right: 8),
                        decoration: const BoxDecoration(
                          border: Border(
                            right: BorderSide(
                              color: AppColors.grayNeutral,
                              width: 1,
                            ),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              durationLabel,
                              style: const TextStyle(
                                color: AppColors.gray,
                                fontWeight: FontWeight.w300,
                                fontSize: 11,
                              ),
                            ),
                            Text(
                              displayDuration,
                              style: const TextStyle(
                                color: AppColors.black,
                                fontWeight: FontWeight.w400,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        children: [
                          Container(
                            height: 11,
                            width: MediaQuery.of(context).size.width * 0.10,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: progress.clamp(0.0, 1.0),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: _getProgressColor(),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            progressLabel,
                            style: const TextStyle(
                              color: AppColors.black,
                              fontWeight: FontWeight.w500,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      // const SizedBox(height: 4),
                      // _buildStatusChip(),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      border: Border.all(width: 1, color: AppColors.grayLight),
                      borderRadius: const BorderRadius.all(Radius.circular(12)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Text(
                              "Panel",
                              style: TextStyle(
                                color: AppColors.gray,
                                fontWeight: FontWeight.w300,
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.grayLight,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                panelVendorName.isEmpty
                                    ? 'No Vendor'
                                    : panelVendorName,
                                style: const TextStyle(
                                  color: AppColors.black,
                                  fontWeight: FontWeight.w400,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            if (hasPanelRemarks) ...[
                              const SizedBox(width: 4),
                              InkWell(
                                onTap: () => _showRemarksBottomSheet(
                                  context,
                                  title: 'Panel Remarks',
                                  remarksMap: {
                                    panelVendorName.isNotEmpty
                                            ? panelVendorName
                                            : 'Panel':
                                        panelRemarks,
                                  },
                                ),
                                borderRadius: BorderRadius.circular(16),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: AppColors.grayLight,
                                      width: 1,
                                    ),
                                  ),
                                  child: Image.asset(
                                    'assets/images/remarks.png',
                                    height: 16,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        // InkWell(
                        //   onTap: () {
                        //     // The actual navigation logic
                        //     Navigator.push(
                        //       context,
                        //       MaterialPageRoute(
                        //         builder: (context) => PanelIssuesScreen(
                        //           panelNoPp: ppNumber,
                        //           panelNoWBS: wbsNumber,
                        //           panelNoPanel: panelTitle,
                        //           panelVendor: panelVendorName,
                        //           busbarVendor: busbarVendorNames,
                        //         ),
                        //       ),
                        //     );
                        //   },
                        //   borderRadius: BorderRadius.circular(16),
                        //   child: Container(
                        //     padding: const EdgeInsets.only(
                        //       top: 4,
                        //       bottom: 4,
                        //       left: 8,
                        //       right: 8,
                        //     ),
                        //     decoration: BoxDecoration(
                        //       borderRadius: BorderRadius.circular(16),
                        //       border: Border.all(
                        //         color: AppColors.grayLight,
                        //         width: 1,
                        //       ),
                        //     ),
                        //     child: Text(
                        //       "Issues",
                        //       style: TextStyle(fontSize: 12),
                        //     ),
                        //   ),
                        // ),
                        Row(
                          children: [
                            const Text(
                              "Busbar",
                              style: TextStyle(
                                color: AppColors.gray,
                                fontWeight: FontWeight.w300,
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Container(
                              constraints: BoxConstraints(
                                maxWidth:
                                    MediaQuery.of(context).size.width * 0.3,
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.grayLight,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                busbarVendorNames.isEmpty
                                    ? 'No Vendor'
                                    : busbarVendorNames,
                                style: const TextStyle(
                                  color: AppColors.black,
                                  fontWeight: FontWeight.w400,
                                  fontSize: 12,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (hasBusbarRemarks) ...[
                              const SizedBox(width: 4),
                              InkWell(
                                onTap: () => _showRemarksBottomSheet(
                                  context,
                                  title: 'Busbar Remarks',
                                  remarksMap: {
                                    for (var e in busbarRemarks)
                                      e.vendorName: e.remark,
                                  },
                                ),
                                borderRadius: BorderRadius.circular(16),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: AppColors.grayLight,
                                      width: 1,
                                    ),
                                  ),
                                  child: Image.asset(
                                    'assets/images/remarks.png',
                                    height: 16,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // ▼▼▼ [PERBAIKAN] Judul dan chip status digabung dalam satu Row ▼▼▼
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          displayPanelTitle,
                          style: const TextStyle(
                            color: AppColors.black,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // _buildStatusChip(),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatusColumn(
                          "Busbar",
                          displayStatus,
                          _getBusbarStatusImage(statusBusbar),
                        ),
                      ),
                      Expanded(
                        child: _buildStatusColumn(
                          "Component",
                          componentDisplayStatus,
                          _getComponentStatusImage(statusComponent),
                        ),
                      ),
                      SizedBox(
                        width: 64,
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: _buildEditButton(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatusColumn(
                          "Palet",
                          paletDisplayStatus,
                          _getPaletStatusImage(statusPalet),
                        ),
                      ),
                      Expanded(
                        child: _buildStatusColumn(
                          "Corepart",
                          corepartDisplayStatus,
                          _getCorepartStatusImage(statusCorepart),
                        ),
                      ),
                      SizedBox(
                        width: 64,
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: _buildIssueButton(context),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(width: 1, color: AppColors.grayLight),
                ),
              ),
              child: Column(
                children: [
                  _buildInfoRow("Tipe Panel", displayPanelType),
                  const SizedBox(height: 8),
                  _buildInfoRow("No. PP", displayPpNumber),
                  const SizedBox(height: 8),
                  _buildInfoRow("No. WBS", displayWbsNumber),
                  const SizedBox(height: 8),
                  _buildInfoRow("Project", displayProject),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusColumn(String title, String status, String imagePath) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppColors.gray,
            fontWeight: FontWeight.w300,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Text(
              status,
              style: const TextStyle(
                color: AppColors.black,
                fontWeight: FontWeight.w400,
                fontSize: 12,
              ),
            ),
            const SizedBox(width: 4),
            Image.asset(imagePath, height: 12),
          ],
        ),
      ],
    );
  }

  Widget _buildEditButton() {
    if (currentUserRole == AppRole.viewer) return const SizedBox.shrink();
    return InkWell(
      onTap: onEdit,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.grayLight, width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Image.asset('assets/images/edit-green.png', height: 20),
            SizedBox(width: 4,),
            // Text("Edit", style: TextStyle(color: AppColors.black, fontSize: 10),)
          ],
        ),
      ),
    );
  }
  Widget _buildIssueButton(BuildContext context) {
    if (currentUserRole == AppRole.viewer) return const SizedBox.shrink();
    return InkWell(
      onTap: () => {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PanelIssuesScreen(
              issueCount: issueCount,
              panelNoPp: ppNumber,
              panelNoWBS: wbsNumber,
              panelNoPanel: panelTitle,
              panelVendor: panelVendorName,
              busbarVendor: busbarVendorNames,
            ),
          ),
        )},
      borderRadius: BorderRadius.circular(8),
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.grayLight, width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (issueCount == 0)...[
            Image.asset('assets/images/issue-no.png', height: 20),
            ],
            if (issueCount != 0) ...[
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Image.asset(
                    'assets/images/issue-no.png',
                    height: 20,
                  ),
                  Positioned(
                    right: -3, // posisi ke kanan
                    top: -6,   // posisi ke atas
                    child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 15,
                        minHeight: 15,
                      ),
                      child: Text(
                        issueCount.toString(),
                        style:  TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            SizedBox(width: 4,),
            // Text("Issue", style: TextStyle(color: AppColors.black, fontSize: 10),)
          ],
        ),
      ),
    );
  }
  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.gray,
            fontWeight: FontWeight.w300,
            fontSize: 11,
          ),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(
              color: AppColors.gray,
              fontWeight: FontWeight.w400,
              fontSize: 12,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
