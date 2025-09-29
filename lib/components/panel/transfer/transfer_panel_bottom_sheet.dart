import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:secpanel/helpers/db_helper.dart';
import 'package:secpanel/models/paneldisplaydata.dart';
import 'package:secpanel/models/productionslot.dart';
import 'package:secpanel/theme/colors.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Enum untuk mengelola alur multi-langkah di dalam bottom sheet
enum _TransferFlowStep {
  displayStatus,
  selectSlot,
  confirmToProduction,
  confirmToFat,
}

class TransferPanelBottomSheet extends StatefulWidget {
  final PanelDisplayData panelData;
  final Function(PanelDisplayData) onSuccess;

  const TransferPanelBottomSheet({
    super.key,
    required this.panelData,
    required this.onSuccess,
  });

  @override
  State<TransferPanelBottomSheet> createState() =>
      _TransferPanelBottomSheetState();
}

class _TransferPanelBottomSheetState extends State<TransferPanelBottomSheet> {
  late PanelDisplayData _currentPanelData;
  bool _isLoading = false;
  _TransferFlowStep _currentStep = _TransferFlowStep.displayStatus;

  List<ProductionSlot> _productionSlots = [];
  String? _selectedSlot;

  bool get _isVendorBranchDone {
    final panel = _currentPanelData.panel;
    return (panel.statusBusbarPcc ?? '') == 'Close' &&
        (panel.statusBusbarMcc ?? '') == 'Close' &&
        (panel.statusPalet ?? '') == 'Close' &&
        (panel.statusCorepart ?? '') == 'Close' &&
        panel.isClosed;
  }

  bool get _isWarehouseBranchDone =>
      (_currentPanelData.panel.statusComponent ?? '') == 'Done';

  @override
  void initState() {
    super.initState();
    _currentPanelData = widget.panelData;
    if (_currentPanelData.panel.statusPenyelesaian == 'Production') {
      _selectedSlot = _currentPanelData.panel.productionSlot;
    }
  }

  Future<void> _fetchProductionSlots() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final slots = await DatabaseHelper.instance.getProductionSlots();
      if (mounted) {
        setState(() => _productionSlots = slots);
      }
    } catch (e) {
      _showErrorSnackbar('Gagal memuat data slot: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleTransferAction(String action) async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    final prefs = await SharedPreferences.getInstance();
    final actorUsername = prefs.getString('username') ?? 'unknown_user';
    try {
      final updatedPanelData =
          await DatabaseHelper.instance.transferPanelAction(
        panelNoPp: _currentPanelData.panel.noPp,
        action: action,
        slot: _selectedSlot,
        actor: actorUsername, 
      );
      widget.onSuccess(updatedPanelData);

      if (mounted) {
        setState(() {
          _currentPanelData = updatedPanelData;
          _currentStep = _TransferFlowStep.displayStatus;
        });
      }
    } catch (e) {
      _showErrorSnackbar(e.toString());
      if (mounted) {
        setState(() {
          _currentStep = _TransferFlowStep.displayStatus;
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showErrorSnackbar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: _isLoading
              ? const Padding(
                  padding: EdgeInsets.all(48.0),
                  child: Center(
                      child: CircularProgressIndicator(
                          color: AppColors.schneiderGreen)),
                )
              : AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  transitionBuilder: (child, animation) {
                    return FadeTransition(opacity: animation, child: child);
                  },
                  child: _buildCurrentView(),
                ),
        ),
      ),
    );
  }

  Widget _buildCurrentView() {
    switch (_currentStep) {
      case _TransferFlowStep.selectSlot:
        return _buildSlotSelectionView();
      case _TransferFlowStep.confirmToProduction:
        return _buildConfirmProductionView();
      case _TransferFlowStep.confirmToFat:
        return _buildConfirmFatView();
      case _TransferFlowStep.displayStatus:
      default:
        return _buildStatusDisplayView();
    }
  }
  Widget _buildSlotSelectionView() {
    const int totalSlots = 28;
    final int occupiedCount = _productionSlots.where((s) => s.isOccupied).length;
    final int remainingCount = totalSlots - occupiedCount;
    final int displayCount = (_selectedSlot == null) ? remainingCount : remainingCount - 1;

        Widget buildSlotItem(ProductionSlot slot) {
      final isSelected = _selectedSlot == slot.positionCode;
      final isOccupiedByOther = slot.isOccupied &&
          _currentPanelData.panel.productionSlot != slot.positionCode;

      Color backgroundColor;
      Color textColor;
      Border? border;

      // === PERUBAHAN DI SINI ===
      if (isOccupiedByOther) {
        // Style baru untuk "Unavailable"
        backgroundColor = Colors.white; // Latar belakang putih
        textColor = Colors.grey.shade400; // Teks abu-abu (disabled)
        border = Border.all(color: Colors.grey.shade300); // Border abu-abu tipis
      } else if (isSelected) {
        // Style untuk "Selected"
        backgroundColor = const Color(0xFFE0F1E3);
        textColor = const Color(0xFF008A15);
        border = Border.all(color: const Color(0xFF008A15));
      } else {
        // Style untuk "Available"
        backgroundColor = const Color(0xFFF5F5F5);
        textColor = Colors.black;
        border = null;
      }
      // ==========================

      return GestureDetector(
        onTap: isOccupiedByOther
            ? null
            : () {
                setState(() {
                  if (_selectedSlot == slot.positionCode) {
                    _selectedSlot = null; 
                  } else {
                    _selectedSlot = slot.positionCode;
                  }
                });
              },
        child: Container(
          width: 35,
          height: 35,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(12),
            border: border,
          ),
          child: Center(
            child: Text(
              slot.positionCode,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontFamily: 'Lexend',
                fontSize: 12,
                color: textColor,
              ),
            ),
          ),
        ),
      );
    }

    Widget buildSlotColumn(String prefix) {
      final columnSlots = _productionSlots
          .where((s) => s.positionCode.startsWith(prefix))
          .toList()
        ..sort((a, b) => a.positionCode.compareTo(b.positionCode));

      return Column(
        mainAxisSize: MainAxisSize.min,
        children: columnSlots
            .map((slot) => Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: buildSlotItem(slot),
                ))
            .toList(),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
      child: Column(
        key: const ValueKey('selectSlot'),
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader('Transfer to Production',
              isSubPage: true,
              onBack: () =>
                  setState(() => _currentStep = _TransferFlowStep.displayStatus)),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                'Select Position',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Lexend'),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$displayCount/28 Slot Tersisa',
                  style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      fontFamily: 'Lexend'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildLegend(),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                buildSlotColumn('D'),
                buildSlotColumn('C'),
                buildSlotColumn('B'),
                buildSlotColumn('A'),
                // === PERUBAHAN 2: Garis pemisah dibuat lebih halus warnanya ===
                Container(
                  width: 8,
                  height: 341,
                  color: AppColors.grayLight, // Warna lebih halus (0xFFEEEEEE)
                ),
                // === PERUBAHAN 1: Widget Office diposisikan di tengah ===
                SizedBox(
                  height: 341,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset('assets/images/office.png',
                            width: 24,),
                        const SizedBox(height: 8),
                        const Text(
                          'Office',
                          style: TextStyle(
                              color: Color(0xFF5C5C5C),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Lexend'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          _buildFooterButtons(
            secondaryText: 'Kembali',
            secondaryAction: () =>
                setState(() => _currentStep = _TransferFlowStep.displayStatus),
            primaryText: 'Lanjutkan',
            primaryAction: _selectedSlot == null
                ? null
                : () => setState(() =>
                    _currentStep = _TransferFlowStep.confirmToProduction),
          ),
        ],
      ),
    );
  }

 Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        // === PERUBAHAN DI SINI: Legenda untuk "Unavailable" disesuaikan ===
        _buildLegendItem(Colors.white, 'Unavailable', borderColor: Colors.grey.shade300),
        const SizedBox(width: 32),
        _buildLegendItem(Colors.white, 'Selected', borderColor: const Color(0xFF008A15)),
        const SizedBox(width: 32),
        _buildLegendItem(const Color(0xFFF5F5F5), 'Available'),
      ],
    );
  }

  Widget _buildLegendItem(Color color, String label, {Color? borderColor}) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: borderColor ?? Colors.transparent, width: 1.5),
          ),
        ),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 12, fontFamily: 'Lexend')),
      ],
    );
  }

  Widget _buildFooterButtons({
    required String primaryText,
    required VoidCallback? primaryAction,
    required String secondaryText,
    required VoidCallback? secondaryAction,
  }) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: secondaryAction,
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF008A15),
              side: const BorderSide(color: Color(0xFF008A15), width: 1.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: Text(secondaryText, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12)),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: primaryAction,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF008A15),
              foregroundColor: Colors.white,
              disabledBackgroundColor: AppColors.grayLight,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: Text(primaryText, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12)),
          ),
        ),
      ],
    );
  }
  Widget _buildStatusDisplayView() {
    final status = _currentPanelData.panel.statusPenyelesaian ?? 'VendorWarehouse';
    String title = 'Transfer Position';
    String statusText = '';
    Widget actionButton;
    VoidCallback? rollbackAction;

    // === PERBAIKAN 2: Logika untuk menampilkan label default "Vendor" ===
    final String vendorLabelSource = [
      _currentPanelData.panelVendorName,
      _currentPanelData.busbarVendorNames,
    ].where((e) => e.isNotEmpty).join(' & ');
    // Variabel ini akan digunakan untuk ditampilkan di UI
    final String displayVendorLabel = vendorLabelSource.isNotEmpty ? vendorLabelSource : 'Vendor';
    // ====================================================================

    final String warehouseLabel = _currentPanelData.componentVendorNames.isNotEmpty
        ? _currentPanelData.componentVendorNames
        : 'Warehouse';

    switch (status) {
      case 'Production':
        statusText = 'Masih Dikerjakan Production';
        actionButton = _buildActionButton(
          'Transfer to FAT',
          isOutline: true,
          assetIconPath: 'assets/images/fat.png',
          onPressed: () {
            _fetchProductionSlots().then((_) {
              if (mounted) setState(() => _currentStep = _TransferFlowStep.confirmToFat);
            });
          },
        );
        rollbackAction = () => _handleTransferAction('rollback');
        break;

      case 'FAT':
        statusText = 'Factory Acceptance Test';
        actionButton = _buildActionButton(
          'All Done',
          isOutline: true,
          assetIconPath: 'assets/images/done.png',
          onPressed: () => _handleTransferAction('to_done'),
        );
        rollbackAction = () => _handleTransferAction('rollback');
        break;

      case 'Done':
        statusText = 'All Done';
        actionButton = _buildActionButton(
          'Tutup',
          isOutline: false,
          onPressed: () => Navigator.of(context).pop(),
        );
        rollbackAction = () => _handleTransferAction('rollback');
        break;

      case 'VendorWarehouse':
      default:
        List<String> locations = [];
        if (!_isVendorBranchDone) locations.add(displayVendorLabel); // Gunakan displayVendorLabel
        if (!_isWarehouseBranchDone) locations.add(warehouseLabel);
        statusText = locations.isEmpty
            ? 'Siap untuk Produksi'
            : 'Masih Dikerjakan ${locations.join(' & ')}';

        actionButton = _buildActionButton(
          'Transfer to Production',
          isOutline: true,
          assetIconPath: 'assets/images/production.png',
          onPressed: () {
            setState(() => _currentStep = _TransferFlowStep.selectSlot);
            _fetchProductionSlots();
          },
        );
        break;
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
      child: Column(
        key: ValueKey(status),
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHandle(),
          _buildHeader(title),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.grayLight),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Row(
                    children: [
                      const Text('Status: ', style: TextStyle(color: AppColors.gray, fontWeight: FontWeight.w300, fontSize: 12)),
                      Expanded(
                        child: Text(statusText, style: const TextStyle(fontWeight: FontWeight.w400, fontSize: 12), overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                ),
                const Divider(color: AppColors.grayLight, height: 1),
                const SizedBox(height: 12),
                _buildStatusTimeline(
                  currentStage: status,
                  // === PERBAIKAN 2 (Lanjutan): Gunakan variabel yang benar di sini ===
                  vendorLabel: displayVendorLabel,
                  // =================================================================
                  warehouseLabel: warehouseLabel,
                  isVendorDone: _isVendorBranchDone,
                  isWarehouseDone: _isWarehouseBranchDone,
                ),
                if (status == 'Production' && _currentPanelData.panel.productionSlot != null) ...[
                  const Divider(height: 32, color: AppColors.grayLight,),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Position:', style: TextStyle(color: AppColors.gray, fontWeight: FontWeight.w300, fontSize: 12)),
                      Container(
                        alignment: Alignment.center,
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppColors.grayLight,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(_currentPanelData.panel.productionSlot!, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w400)),
                      )
                    ],
                  )
                ]
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildActionButtons(
            primaryButton: actionButton,
            secondaryAction: rollbackAction,
          ),
        ],
      ),
    );
  }

// Helper baru untuk menampilkan status item di halaman konfirmasi
  Widget _buildConfirmationStatusItem(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppColors.gray,
            fontWeight: FontWeight.w300,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Close',
              style: TextStyle(
                color: AppColors.black,
                fontWeight: FontWeight.w400,
                fontSize: 12,
              ),
            ),
            const SizedBox(width: 4),
            // Menggunakan icon yang sama dengan di panel card
            Image.asset('assets/images/done-green.png', height: 14),
          ],
        ),
      ],
    );
  }

Widget _buildConfirmProductionView() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
      child: Column(
        key: const ValueKey('confirmProduction'),
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHandle(),
          _buildHeader('Transfer to Production'),
          const SizedBox(height: 16),
          const Text(
            'Transfer ke production akan mengubah semua status menjadi close, panel 100%, dan delivery date terhitung saat ini',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.gray, fontSize: 12),
          ),
          const SizedBox(height: 24),
          
          // Card container baru yang meniru gaya PanelProgressCard
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: AppColors.grayLight),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Label persentase
                const Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      '100%',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: AppColors.black,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Progress bar yang sudah di-styling
                Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: FractionallySizedBox(
                    widthFactor: 1.0, // Selalu 100%
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.schneiderGreen, // Selalu hijau
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Baris untuk menampilkan status item
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildConfirmationStatusItem('Busbar'),
                    _buildConfirmationStatusItem('Component'),
                    _buildConfirmationStatusItem('Palet'),
                    _buildConfirmationStatusItem('Corepart'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildActionButtons(
            primaryButton: _buildActionButton('Ya, Transfer',
                onPressed: () => _handleTransferAction('to_production')),
            secondaryText: 'Kembali',
            secondaryAction: () =>
                setState(() => _currentStep = _TransferFlowStep.selectSlot),
          )
        ],
      ),
    );
  }
  
  // Helper baru untuk visualisasi di halaman konfirmasi FAT
  Widget _buildSlotStateColumn({
    required String slotName,
    required String countText,
    required Widget subtitle,
    required bool isOrigin,
  }) {
    // Widget untuk kotak nama slot (A2, C7, dll)
    Widget slotBox;
    if (isOrigin) {
      // Style untuk slot "sebelum" (terisi)
      slotBox = Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.schneiderGreen.withOpacity(0.1),
          border: Border.all(color: AppColors.schneiderGreen),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          slotName,
          style: const TextStyle(
            color: AppColors.schneiderGreen,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            fontFamily: 'Lexend',
          ),
        ),
      );
    } else {
      // Style untuk slot "sesudah" (kosong dengan border putus-putus)
      slotBox = DashedBorderContainer(
        color: AppColors.gray,
        strokeWidth: 1.5,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Text(
            slotName,
            style: const TextStyle(
              color: AppColors.gray,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              fontFamily: 'Lexend',
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        slotBox,
        const SizedBox(height: 12),
        // Widget untuk kotak jumlah slot (8/28, 9/28, dll)
        Container(
          width: 60,
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Text(
                countText,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Lexend',
                ),
              ),
              subtitle,
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildConfirmFatView() {
    const int totalSlots = 28;
    // Hitung jumlah slot yang terisi secara permanen oleh panel lain
    final int occupiedByOthers = _productionSlots
        .where((s) => s.isOccupied && s.panelNoPp != _currentPanelData.panel.noPp)
        .length;
    
    // Jumlah slot yang tersedia sebelum panel ini ditransfer
    final int availableBefore = totalSlots - occupiedByOthers - 1;
    // Jumlah slot yang tersedia setelah panel ini ditransfer
    final int availableAfter = availableBefore + 1;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
      child: Column(
        key: const ValueKey('confirmFat'),
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHandle(),
          _buildHeader('Transfer to FAT'),
          const SizedBox(height: 24),
          const Text(
            'Transfer ke FAT akan mengeluarkan panel dari slot produksi',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.gray, fontSize: 12, fontFamily: 'Lexend'),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Visualisasi "Sebelum"
              _buildSlotStateColumn(
                slotName: _currentPanelData.panel.productionSlot ?? 'N/A',
                countText: '$availableBefore/28',
                subtitle: const Text(
                  'Slot',
                  style: TextStyle(color: AppColors.gray, fontSize: 8, fontFamily: 'Lexend'),
                ),
                isOrigin: true,
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.0),
                child: Icon(Icons.arrow_forward, color: AppColors.gray),
              ),
              // Visualisasi "Sesudah"
              _buildSlotStateColumn(
                slotName: _currentPanelData.panel.productionSlot ?? 'N/A',
                countText: '$availableAfter/28',
                subtitle: Text.rich(
                  TextSpan(children: [
                    const TextSpan(text: 'Slot', style: TextStyle(color: AppColors.gray, fontSize: 8)),
                    TextSpan(text: ' (+1)', style: TextStyle(color: AppColors.schneiderGreen.withOpacity(0.8), fontSize: 8)),
                  ]),
                ),
                isOrigin: false,
              ),
            ],
          ),
          const SizedBox(height: 32),
          _buildFooterButtons(
            secondaryText: 'Kembali',
            secondaryAction: () =>
                setState(() => _currentStep = _TransferFlowStep.displayStatus),
            primaryText: 'Ya, Transfer',
            primaryAction: () => _handleTransferAction('to_fat'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildHeader(String title, {bool isSubPage = false, VoidCallback? onBack}) {
    return Row(
      children: [
        if (isSubPage) IconButton(icon: const Icon(Icons.arrow_back), onPressed: onBack)
        else const SizedBox(width: 48), // Placeholder
        Expanded(
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w500),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }

  Widget _buildHandle() {
    return Center(
      child: Container(
        width: 74,
        height: 4,
        margin: const EdgeInsets.only(bottom: 24),
        decoration: BoxDecoration(
          color: const Color(0xFFDBDBDB),
          borderRadius: BorderRadius.circular(99),
        ),
      ),
    );
  }

Widget _buildActionButtons({required Widget primaryButton, String? secondaryText, VoidCallback? secondaryAction}) {
    Widget secondaryButton;

    // === PERBAIKAN LOGIKA DI SINI ===
    // Cukup periksa apakah ada 'secondaryAction'. Jika ada, tentukan jenis tombolnya.
    if (secondaryAction != null) {
      // Tentukan teksnya. Jika tidak diberi tahu, anggap saja "Rollback".
      final String text = secondaryText ?? 'Rollback';

      if(text == 'Kembali') {
        // Jika teksnya 'Kembali', buat tombol outline hijau.
        secondaryButton = Expanded(child: _buildActionButton(text, onPressed: secondaryAction, isOutline: true));
      } else { 
        // Untuk kasus lain (termasuk "Rollback"), buat tombol teks merah.
        secondaryButton = TextButton(
            onPressed: secondaryAction,
            child: Text(text, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w500, fontSize: 12)),
          );
      }
    } else {
      // Jika tidak ada aksi sekunder, jangan tampilkan tombol apa pun.
      secondaryButton = const Spacer();
    }
    // ===============================
    
    return Row(
      children: [
        secondaryButton,
        // Atur jarak antar tombol dengan lebih baik
        if (secondaryAction != null && secondaryText != 'Kembali') const Spacer(),
        if (secondaryAction != null && secondaryText == 'Kembali') const SizedBox(width: 16),
        // Tombol primer sekarang mengambil sisa ruang yang fleksibel
        Flexible(flex: 2, child: primaryButton),
      ],
    );
  }
  
Widget _buildActionButton(String text, {VoidCallback? onPressed, String? assetIconPath, bool isOutline = false}) {
    final textColor = isOutline ? AppColors.schneiderGreen : Colors.white;
    final backgroundColor = isOutline ? Colors.white : AppColors.schneiderGreen;
    final borderColor = isOutline ? AppColors.schneiderGreen : Colors.transparent;

    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        foregroundColor: textColor,
        backgroundColor: backgroundColor,
        disabledBackgroundColor: AppColors.grayLight,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
          side: BorderSide(color: borderColor, width: 1.5), // Sedikit pertebal border
        ),
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(
            child: Text(
              text,
              textAlign: TextAlign.center, // Penting jika teks wrap
              style: TextStyle(color: textColor, fontWeight: FontWeight.w500, fontSize: 12),
            ),
          ),
          if (assetIconPath != null) ...[
            const SizedBox(width: 8),
            Image.asset(assetIconPath, width: 16, height: 16, color: textColor),
          ]
        ],
      ),
    );
  }

  Widget _buildStatusTimeline({
    required String currentStage,
    required String vendorLabel,
    required String warehouseLabel,
    required bool isVendorDone,
    required bool isWarehouseDone,
  }) {
    final stages = ['VendorWarehouse', 'Production', 'FAT', 'Done'];
    final stageIndex = stages.indexOf(currentStage);

    final bool vendorCheck = stageIndex > 0 || isVendorDone;
    final bool warehouseCheck = stageIndex > 0 || isWarehouseDone;
    
    final bool productionDone = stageIndex >= 2;
    final bool fatDone = stageIndex >= 3;
    final bool isProductionActive = stageIndex == 1;
    final bool isFatActive = stageIndex == 2;

    return Column(
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            return Column(
              children: [
                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTimelineNode(
                        vendorLabel,
                        Image.asset('assets/images/vendor.png', color: vendorCheck ? AppColors.schneiderGreen : AppColors.blue, width: 24),
                        isComplete: vendorCheck,
                        isActive: !vendorCheck,
                      ),
                      const SizedBox(width: 40),
                      _buildTimelineNode(
                        warehouseLabel,
                        Image.asset('assets/images/warehouse.png', color: warehouseCheck ? AppColors.schneiderGreen : AppColors.blue, width: 24),
                        isComplete: warehouseCheck,
                        isActive: !warehouseCheck,
                      ),
                    ],
                  ),
                ),
                _buildTimelineConnector(isComplete: stageIndex >= 1, branchWidth: constraints.maxWidth),
              ],
            );
          },
        ),
        _buildTimelineNode(
          'Production',
          Image.asset('assets/images/production.png', color: stageIndex >= 1 ? (isProductionActive ? AppColors.blue : AppColors.schneiderGreen) : AppColors.gray, width: 24),
          isComplete: productionDone,
          isActive: isProductionActive,
        ),
        _buildTimelineConnector(isComplete: stageIndex >= 2),
        _buildTimelineNode(
          'FAT',
          Image.asset('assets/images/fat.png', color: stageIndex >= 2 ? (isFatActive ? AppColors.blue : AppColors.schneiderGreen) : AppColors.gray, width: 24),
          isComplete: fatDone,
          isActive: isFatActive,
        ),
      ],
    );
  }

Widget _buildTimelineNode(String label, Widget icon, {required bool isComplete, bool isActive = false}) {
    final Color color = isActive ? AppColors.blue : (isComplete ? AppColors.schneiderGreen : AppColors.gray);

    // === PERBAIKAN 1: Beri lebar yang konsisten agar tidak mencong ===
    return SizedBox(
      width: 65, // Memberi lebar minimum agar rata
      child: Column(
        children: [
          icon,
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w300, color: color),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          if (isActive) Image.asset('assets/images/progress_load.png', width: 14)
          else if (isComplete) Icon(Icons.check_circle, size: 14, color: color)
          else const SizedBox(height: 14), // Placeholder agar tinggi sama
        ],
      ),
    );
  }

  Widget _buildTimelineConnector({required bool isComplete, double? branchWidth}) {
    final color = isComplete ? AppColors.schneiderGreen : AppColors.grayLight;
    if (branchWidth != null) {
      return SizedBox(
        height: 20,
        child: CustomPaint(
          painter: _BranchConnectorPainter(color: color, branchWidth: branchWidth),
          child: Container(),
        ),
      );
    }
    return SizedBox(
      height: 20,
      child: Center(
        child: Container(width: 2, height: double.infinity, color: color),
      ),
    );
  }

  Widget _buildStatusDetail(String label, bool isClosed) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.gray)),
        const SizedBox(height: 4),
        Row(
          children: [
            Text(
              'Close',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isClosed ? AppColors.schneiderGreen : Colors.grey),
            ),
            const SizedBox(width: 4),
            Icon(Icons.check_circle, color: isClosed ? AppColors.schneiderGreen : Colors.grey, size: 16)
          ],
        )
      ],
    );
  }

  Widget _buildSlotInfo(String slot, String description, {bool isOrigin = true}) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isOrigin ? AppColors.schneiderGreen.withOpacity(0.2) : const Color(0xFFFEFEFE),
            border: Border.all(color: isOrigin ? AppColors.schneiderGreen : AppColors.gray),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(slot, style: TextStyle(fontWeight: FontWeight.bold, color: isOrigin ? AppColors.schneiderGreen : AppColors.gray)),
        ),
        const SizedBox(height: 4),
        Text(
          description,
          style: TextStyle(fontSize: 10, color: AppColors.gray, fontWeight: isOrigin ? FontWeight.normal : FontWeight.bold),
        ),
      ],
    );
  }
}

class _BranchConnectorPainter extends CustomPainter {
  final Color color;
  final double branchWidth;
  _BranchConnectorPainter({required this.color, required this.branchWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color..strokeWidth = 2..style = PaintingStyle.stroke;
    final path = Path();
    const double horizontalLineLength = 90;
    final double startX = (branchWidth / 2) - (horizontalLineLength / 2);
    final double endX = (branchWidth / 2) + (horizontalLineLength / 2);
    path.moveTo(startX, 0);
    path.lineTo(endX, 0);
    final double verticalLineX = branchWidth / 2;
    path.moveTo(verticalLineX, 0);
    path.lineTo(verticalLineX, size.height);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _BranchConnectorPainter oldDelegate) => color != oldDelegate.color || branchWidth != oldDelegate.branchWidth;
}
// Helper widget untuk membuat border putus-putus
class DashedBorderContainer extends StatelessWidget {
  final Widget child;
  final Color color;
  final double strokeWidth;
  final double dashWidth;
  final double dashGap;
  final double borderRadius;

  const DashedBorderContainer({
    super.key,
    required this.child,
    this.color = Colors.grey,
    this.strokeWidth = 1.0,
    this.dashWidth = 4.0,
    this.dashGap = 4.0,
    this.borderRadius = 12.0,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedBorderPainter(
        color: color,
        strokeWidth: strokeWidth,
        dashWidth: dashWidth,
        dashGap: dashGap,
        radius: Radius.circular(borderRadius),
      ),
      child: child,
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double dashWidth;
  final double dashGap;
  final Radius radius;

  _DashedBorderPainter({
    required this.color,
    required this.strokeWidth,
    required this.dashWidth,
    required this.dashGap,
    required this.radius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    Path path = Path();
    path.addRRect(RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, size.width, size.height), radius));

    Path dashPath = Path();
    double distance = 0.0;
    for (PathMetric metric in path.computeMetrics()) {
      while (distance < metric.length) {
        dashPath.addPath(
          metric.extractPath(distance, distance + dashWidth),
          Offset.zero,
        );
        distance += dashWidth + dashGap;
      }
    }
    canvas.drawPath(dashPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}