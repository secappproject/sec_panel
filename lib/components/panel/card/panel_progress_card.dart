// lib/components/panel/card/panel_progress_card.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:secpanel/components/additionalsr/additionalsr_bottom_sheet.dart';
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
  final String? statusPenyelesaian;
  final String? productionSlot;
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
  final VoidCallback onTransfer;
  final String panelVendorName;
  final String busbarVendorNames;
  final String componentVendorName;
  final String paletVendorName;
  final String corepartVendorName;
  final bool isClosed;
  final DateTime? closedDate;
  final String? panelRemarks;
  final List<BusbarRemark> busbarRemarks;
  final int additionalSrCount;

  const PanelProgressCard({
    super.key,
    required this.currentUserRole,
    this.statusPenyelesaian,
    this.productionSlot,
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
    required this.onTransfer,
    required this.panelVendorName,
    required this.busbarVendorNames,
    required this.componentVendorName,
    required this.paletVendorName,
    required this.corepartVendorName,
    required this.isClosed,
    this.closedDate,
    this.panelRemarks,
    required this.busbarRemarks,
    required this.additionalSrCount, 
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
    if (lower.contains('done') || lower.contains('close')) {
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
  Widget _buildPanelPosition() {
    // Tentukan status default jika null atau kosong
    final status = statusPenyelesaian ?? 'VendorWarehouse';
    String positionText;
    String iconPath;

    switch (status) {
      case 'Production':
        // Jika di produksi, tampilkan juga nomor slotnya
        positionText = 'Production (${productionSlot ?? 'N/A'})';
        iconPath = 'assets/images/production.png';
        break;
      case 'FAT':
        positionText = 'FAT';
        iconPath = 'assets/images/fat.png';
        break;
      case 'Done':
        positionText = 'Done';
        iconPath = 'assets/images/done.png';
        break;
      case 'VendorWarehouse':
      default:
        // Gabungkan nama vendor dan warehouse
        List<String> locations = [];
        if (panelVendorName.isNotEmpty) locations.add(panelVendorName);
        if (componentVendorName.isNotEmpty) locations.add(componentVendorName);

        positionText = locations.isEmpty ? 'Vendor/WHS' : locations.join(' & ');
        iconPath = 'assets/images/vendor.png';
        break;
    }

    return Row(
      children: [
        Image.asset(iconPath, height: 12, color: AppColors.gray),
        const SizedBox(width: 4),
        Text(
          positionText,
          style: const TextStyle(
            color: AppColors.gray,
            fontWeight: FontWeight.w300,
            fontSize: 11,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
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
        ? 'Progress'
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
                          SizedBox(height: 8,),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                           const Text(
                            "Posisi:",
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w300, color: AppColors.gray),
                          ),
                          SizedBox(width: 8,),
                          Align(
                            alignment: Alignment.centerRight,
                            child: _buildPanelPosition(),
                          ),
                        ],
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
                          (displayStatus == "100% Siap Kirim")
                          ? "Ready" : 
                          (displayStatus == "On Progress")
                          ? "Progress" : 
                          displayStatus,
                          _getBusbarStatusImage(statusBusbar),
                        ),
                      ),
                      SizedBox(width: 4,),
                      Expanded(
                        child: _buildStatusColumn(
                          "Comp.",
                          componentDisplayStatus == "On Progress" ? "Progress" : componentDisplayStatus,
                          _getComponentStatusImage(statusComponent),
                        ),
                      ),
                      // SizedBox(
                      //   width: 64,
                      //   child: Align(
                      //     alignment: Alignment.centerRight,
                      //     child: _buildEditButton(),
                      //   ),
                      // ),
                      SizedBox(width: 4,),
                      Expanded(
                        child: _buildStatusColumn(
                          "Palet",
                          paletDisplayStatus,
                          _getPaletStatusImage(statusPalet),
                        ),
                      ),
                      SizedBox(width: 4,),
                      Container(
                        width: 60,
                        child: _buildStatusColumn(
                          "Corepart",
                          corepartDisplayStatus,
                          _getCorepartStatusImage(statusCorepart),
                        ),
                      ),
                    ],
                  ),
                  // Row(
                  //   children: [
                  //     Expanded(
                  //       child: _buildStatusColumn(
                  //         "Palet",
                  //         paletDisplayStatus,
                  //         _getPaletStatusImage(statusPalet),
                  //       ),
                  //     ),
                  //     Expanded(
                  //       child: _buildStatusColumn(
                  //         "Corepart",
                  //         corepartDisplayStatus,
                  //         _getCorepartStatusImage(statusCorepart),
                  //       ),
                  //     ),
                  //     // SizedBox(
                  //     //   width: 64,
                  //     //   child: Align(
                  //     //     alignment: Alignment.centerRight,
                  //     //     child: _buildIssueButton(context),
                  //     //   ),
                  //     // ),
                  //   ],
                  // ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.only(top: 12, right: 12, left: 12, bottom: 12),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(width: 1, color: AppColors.grayLight),
                  top: BorderSide(width: 1, color: AppColors.grayLight),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: EdgeInsets.all(2),
                    decoration: BoxDecoration(border: BoxBorder.all(width: 1, color: AppColors.grayLight), borderRadius: BorderRadius.all(Radius.circular(12))),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildAdditionalSRButton(context),
                        SizedBox(width: 8,),
                        _buildIssueButton(context),
                        SizedBox(width: 8,),
                        _buildCycleButton(),
                        SizedBox(width: 8,),
                        _buildEditButton(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Wrap your widgets in a Column for vertical arrangement
            Container(
              padding: EdgeInsets.all(12),
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(width: 1, color: AppColors.grayLight),
                ),
              ),
              child: Column(
                children: [
                  // 1. A Row for the Vendor and Busbar info
                  Container(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Vendor",
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w300, color: AppColors.gray),
                        ),
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
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.grayLight,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                panelVendorName.isEmpty ? 'No Vendor' : panelVendorName,
                                style: const TextStyle(
                                  color: AppColors.black,
                                  fontWeight: FontWeight.w400,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                            SizedBox(width: 12),
                            const Text(
                              "Busbar",
                              style: TextStyle(
                                color: AppColors.gray,
                                fontWeight: FontWeight.w300,
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(width: 4),
                            // Use Flexible to prevent long text from causing an overflow
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.grayLight,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                busbarVendorNames.isEmpty ? 'No Vendor' : busbarVendorNames,
                                style: const TextStyle(
                                  color: AppColors.black,
                                  fontWeight: FontWeight.w400,
                                  fontSize: 11,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  // Add some space between the row above and the column below
                  const SizedBox(height: 12),
              
                  // 2. A Column for the rest of the panel details
                  Column(
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
                ],
              ),
            )
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
          overflow: TextOverflow.ellipsis,
          maxLines: 2,
          style: const TextStyle(
            color: AppColors.gray,
            fontWeight: FontWeight.w300,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Flexible(
              child: Text(
                status,
                style: const TextStyle(
                  color: AppColors.black,
                  fontWeight: FontWeight.w400,
                  fontSize: 12,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 4),
            Image.asset(imagePath, height: 12),
          ],
        ),
      ],
    );
  }

  Widget _buildCycleButton() {
    if (currentUserRole == AppRole.viewer) return const SizedBox.shrink();
    return InkWell(
      onTap: onTransfer,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Image.asset('assets/images/cycle.png', height: 20,),
            SizedBox(width: 8,),
            Text("Transfer", style: TextStyle(fontSize: 11, color: AppColors.black, fontWeight: FontWeight.w300,overflow: TextOverflow.ellipsis),),
          ],
        ),
      ),
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Image.asset('assets/images/edit-green.png', height: 20, color: AppColors.gray,),
            SizedBox(width: 8,),
            Text("Edit", style: TextStyle(fontSize: 11, color: AppColors.black, fontWeight: FontWeight.w300,overflow: TextOverflow.ellipsis),),
          ],
        ),
      ),
    );
  }
Widget _buildAdditionalSRButton(BuildContext context) {
  if (currentUserRole == AppRole.viewer) return const SizedBox.shrink();
  return InkWell(
    onTap: () {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => AdditionalSrBottomSheet(
          panelNoPp: ppNumber,
          poNumber: panelTitle,
          panelTitle: panelTitle,
        ),
      );
    },
    borderRadius: BorderRadius.circular(8),
    child: Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          if (additionalSrCount == 0) ...[
            Image.asset('assets/images/package.png', height: 20, color: AppColors.gray),
          ],
          if (additionalSrCount != 0) ...[
            Stack(
              clipBehavior: Clip.none,
              children: [
                Image.asset(
                  'assets/images/package.png',
                  height: 20,
                  color: AppColors.gray
                ),
                Positioned(
                  right: -3, // posisi ke kanan (seperti issue)
                  top: -6,   // posisi ke atas (seperti issue)
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
                      additionalSrCount.toString(),
                      style: const TextStyle(
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
          SizedBox(width: 8,),
          Text("SR", style: TextStyle(fontSize: 11, color: AppColors.black, fontWeight: FontWeight.w300,overflow: TextOverflow.ellipsis),),
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (issueCount == 0)...[
            Image.asset('assets/images/issue-no.png', height: 20,
                    color: AppColors.gray,),
            ],
            if (issueCount != 0) ...[
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Image.asset(
                    'assets/images/issue-no.png',
                    height: 20,
                    color: AppColors.gray,
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
            SizedBox(width: 8,),
            Text("Issue", style: TextStyle(fontSize: 11, color: AppColors.black, fontWeight: FontWeight.w300,overflow: TextOverflow.ellipsis),),
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
              fontWeight: FontWeight.w300,
              fontSize: 12,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
