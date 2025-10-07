import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:secpanel/helpers/db_helper.dart';
import 'package:secpanel/models/approles.dart';
import 'package:secpanel/models/company.dart';
import 'package:secpanel/models/paneldisplaydata.dart';
import 'package:secpanel/models/panels.dart';
import 'package:secpanel/models/productionslot.dart';
import 'package:secpanel/theme/colors.dart';
import 'package:shared_preferences/shared_preferences.dart';

// [MODIFIKASI] Menambahkan step baru untuk alur pemilihan
enum _TransferFlowStep {
  displayStatus,
  selectProductionOrSubcontractor, // <-- LANGKAH BARU
  selectSlot,
  selectSubcontractorVendor, // <-- LANGKAH BARU
  confirmToProduction,
  confirmToFat,
  confirmToDone,
}

class TransferPanelBottomSheet extends StatefulWidget {
  final PanelDisplayData panelData;
  final Company currentCompany;
  final Function(PanelDisplayData) onSuccess;

  const TransferPanelBottomSheet({
    super.key,
    required this.panelData,
    required this.onSuccess,
    required this.currentCompany,
  });

  @override
  State<TransferPanelBottomSheet> createState() =>
      _TransferPanelBottomSheetState();
}

class _TransferPanelBottomSheetState extends State<TransferPanelBottomSheet> {
  late PanelDisplayData _currentPanelData;
  bool _isLoading = false;
  _TransferFlowStep _currentStep = _TransferFlowStep.displayStatus;
  bool get _isViewer => widget.currentCompany.role == AppRole.viewer;

  List<ProductionSlot> _productionSlots = [];
  String? _selectedSlot;

  // [MODIFIKASI] State baru untuk pemilihan subkontraktor
  List<Company> _subcontractorVendors = [];
  String? _selectedSubcontractorVendorId;

  late DateTime _selectedStartDate;
  late DateTime _selectedProductionDate;
  late DateTime _selectedFatDate;
  late DateTime _selectedAllDoneDate;

  bool get _isVendorBranchDone {
    final panel = _currentPanelData.panel;
    return (panel.statusPalet ?? '') == 'Close' &&
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

    _selectedStartDate = _currentPanelData.panel.startDate ?? DateTime.now();
    _selectedProductionDate =
        _currentPanelData.productionDate ?? DateTime.now();
    _selectedFatDate = _currentPanelData.fatDate ?? DateTime.now();
    _selectedAllDoneDate = _currentPanelData.allDoneDate ?? DateTime.now();
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
  
  // [MODIFIKASI] Fungsi baru untuk mengambil data vendor K3 & K5
  Future<void> _fetchSubcontractorVendors() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        DatabaseHelper.instance.getK3Vendors(),
        DatabaseHelper.instance.getK5Vendors(),
      ]);
      final allVendors = [...results[0], ...results[1]];
      allVendors.sort((a, b) => a.name.compareTo(b.name));

      if (mounted) {
        setState(() => _subcontractorVendors = allVendors);
      }
    } catch (e) {
      _showErrorSnackbar('Gagal memuat data vendor: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleTransferAction(
    String action, {
    DateTime? productionDate,
    DateTime? fatDate,
    DateTime? allDoneDate,
    String? subcontractorVendorId, // <-- [MODIFIKASI] Parameter baru
  }) async {
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
        productionDate: productionDate,
        fatDate: fatDate,
        allDoneDate: allDoneDate,
        vendorId: subcontractorVendorId, // <-- [MODIFIKASI] Kirim vendorId ke helper
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
  
  Future<void> _handleDateUpdate({
      DateTime? newStartDate,
      DateTime? newProductionDate,
      DateTime? newFatDate,
      DateTime? newAllDoneDate,
  }) async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    final prefs = await SharedPreferences.getInstance();
    final actorUsername = prefs.getString('username') ?? 'unknown_user';

    try {
        final updatedPanelData =
            await DatabaseHelper.instance.transferPanelAction(
        panelNoPp: _currentPanelData.panel.noPp,
        action: 'update_dates',
        actor: actorUsername,
        startDate: newStartDate,
        productionDate: newProductionDate,
        fatDate: newFatDate,
        allDoneDate: newAllDoneDate,
        );
        
        widget.onSuccess(updatedPanelData);

        if (mounted) {
        setState(() {
            _currentPanelData = updatedPanelData;
            if (newStartDate != null) _selectedStartDate = newStartDate;
            if (newProductionDate != null) _selectedProductionDate = newProductionDate;
            if (newFatDate != null) _selectedFatDate = newFatDate;
            if (newAllDoneDate != null) _selectedAllDoneDate = newAllDoneDate;
        });
        }
    } catch (e) {
        _showErrorSnackbar('Gagal memperbarui tanggal: ${e.toString()}');
    } finally {
        if (mounted) setState(() => _isLoading = false);
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
      case _TransferFlowStep.selectProductionOrSubcontractor:
        return _buildSelectProductionOrSubcontractorView();
      case _TransferFlowStep.selectSubcontractorVendor:
        return _buildSelectSubcontractorVendorView();
      case _TransferFlowStep.selectSlot:
        return _buildSlotSelectionView();
      case _TransferFlowStep.confirmToProduction:
        return _buildConfirmProductionView();
      case _TransferFlowStep.confirmToFat:
        return _buildConfirmFatView();
      case _TransferFlowStep.confirmToDone:
        return _buildConfirmDoneView();
      case _TransferFlowStep.displayStatus:
      default:
        return _buildStatusDisplayView();
    }
  }

  Widget _buildSelectProductionOrSubcontractorView() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
      child: Column(
        key: const ValueKey('selectProdOrSub'),
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader('Transfer To',
              isSubPage: true,
              onBack: () => setState(
                  () => _currentStep = _TransferFlowStep.displayStatus)),
          const SizedBox(height: 24),
           Text(
            'Pilih tujuan transfer panel selanjutnya.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.gray, fontSize: 14, fontWeight: FontWeight.w300),
          ),
          const SizedBox(height: 24),
          _buildChoiceCard(
            title: 'Internal Production',
            subtitle: 'Alokasikan panel ke slot produksi internal.',
            icon: Icons.precision_manufacturing_outlined,
            onTap: () {
              setState(() => _currentStep = _TransferFlowStep.selectSlot);
              _fetchProductionSlots();
            },
          ),
          const SizedBox(height: 16),
          _buildChoiceCard(
            title: 'Subcontractor',
            subtitle: 'Serahkan pengerjaan panel ke vendor eksternal.',
            icon: Icons.store_mall_directory_outlined,
            onTap: () {
              setState(() =>
                  _currentStep = _TransferFlowStep.selectSubcontractorVendor);
              _fetchSubcontractorVendors();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildChoiceCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.grayLight, width: 1.5),
        ),
        child: Row(
          children: [
            Icon(icon, size: 32, color: AppColors.schneiderGreen),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w400),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: AppColors.gray, fontWeight: FontWeight.w300),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios,
                size: 16, color: AppColors.gray),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectSubcontractorVendorView() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
      child: Column(
        key: const ValueKey('selectSubcontractor'),
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader('Select Subcontractor',
              isSubPage: true,
              onBack: () => setState(() => _currentStep =
                  _TransferFlowStep.selectProductionOrSubcontractor)),
          const SizedBox(height: 24),
          const Text('Pilih Vendor',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          const SizedBox(height: 16),
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Wrap(
                  spacing: 8,
                  runSpacing: 12,
                  children: _subcontractorVendors.map((vendor) {
                    final isSelected = _selectedSubcontractorVendorId == vendor.id;
                    return _buildVendorOptionButton(
                      company: vendor,
                      selected: isSelected,
                      onTap: () {
                        setState(() {
                          _selectedSubcontractorVendorId = isSelected ? null : vendor.id;
                        });
                      },
                    );
                  }).toList(),
                ),
          const SizedBox(height: 32),
          _buildFooterButtons(
            secondaryText: 'Kembali',
            secondaryAction: () => setState(() =>
                _currentStep = _TransferFlowStep.selectProductionOrSubcontractor),
            primaryText: 'Konfirmasi Transfer',
            primaryAction: _selectedSubcontractorVendorId == null
                ? null
                : () => _handleTransferAction(
                      'to_subcontractor',
                      subcontractorVendorId: _selectedSubcontractorVendorId,
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildVendorOptionButton({
    required Company company,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final Color borderColor = selected
        ? AppColors.schneiderGreen
        : AppColors.grayLight;
    final Color color = selected
        ? AppColors.schneiderGreen.withOpacity(0.08)
        : Colors.white;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color,
          border: Border.all(color: borderColor),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              company.name,
              style: const TextStyle(
                fontWeight: FontWeight.w400,
                fontSize: 12,
                color: AppColors.black,
              ),
            ),
            const SizedBox(width: 8),
            Chip(
              label: Text(
                company.role.name.toUpperCase(),
                style: const TextStyle(fontSize: 10, color: AppColors.gray),
              ),
              backgroundColor: AppColors.grayLight,
              padding: EdgeInsets.zero,
              labelPadding: const EdgeInsets.symmetric(horizontal: 6),
              visualDensity: VisualDensity.compact,
              side: BorderSide.none,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlotSelectionView() {
    final Map<int, List<ProductionSlot>> slotsByRow = {};
    for (var slot in _productionSlots) {
      final nameParts = slot.positionCode.split(' ');
      if (nameParts.length < 2) continue;
      final detailParts = nameParts[1].split('-');
      if (detailParts.isEmpty) continue;
      final rowNum = int.tryParse(detailParts[0]);
      if (rowNum != null) {
        (slotsByRow[rowNum] ??= []).add(slot);
      }
    }

    Widget buildCellRowItem(int rowNum, List<ProductionSlot> slotsInRow) {
      const int baselineCapacity = 8;
      final occupiedSlots = slotsInRow.where((s) => s.isOccupied).toList();
      final int occupiedCount = occupiedSlots.length;
      final int availableInBaseline = baselineCapacity - occupiedCount;
      final bool isOverBaseline = occupiedCount >= baselineCapacity;
      final bool isSelected =
          _selectedSlot != null && _selectedSlot!.startsWith('Cell $rowNum');
      final occupiedPanelNames = occupiedSlots
          .map((s) => s.panelNoPanel ?? s.panelNoPp ?? 'Unknown')
          .join(', ');

      return GestureDetector(
        onTap: () {
          setState(() {
            if (isSelected) {
              _selectedSlot = null;
            } else {
              _selectedSlot = slotsInRow.first.positionCode;
            }
          });
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.schneiderGreen.withOpacity(0.1)
                : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppColors.schneiderGreen : AppColors.grayLight,
              width: 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Production Cell $rowNum',
                      style: TextStyle(
                        fontWeight: FontWeight.w400,
                        fontSize: 14,
                        color: isSelected
                            ? AppColors.schneiderGreen
                            : AppColors.black,
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      if (isOverBaseline)
                        Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color.fromARGB(255, 255, 246, 246),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Over Capacity',
                            style: TextStyle(
                              color: AppColors.red,
                              fontWeight: FontWeight.w500,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      Text(
                        '$availableInBaseline/$baselineCapacity Available',
                        style: TextStyle(
                          fontWeight: FontWeight.w300,
                          fontSize: 12,
                          color: isSelected
                              ? AppColors.schneiderGreen
                              : AppColors.gray,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (occupiedSlots.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Panel in Production: $occupiedPanelNames',
                  style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.gray,
                      fontWeight: FontWeight.w300),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ]
            ],
          ),
        ),
      );
    }

    final sortedKeys = slotsByRow.keys.toList()..sort();
    final int totalOccupiedCount =
        _productionSlots.where((s) => s.isOccupied).length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
      child: Column(
        key: const ValueKey('selectCellFinal'),
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader('Transfer to Production',
              isSubPage: true,
              onBack: () =>
                  setState(() => _currentStep = _TransferFlowStep.selectProductionOrSubcontractor)),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                'Select Production Cell',
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
                  '$totalOccupiedCount Panel in Production',
                  style: const TextStyle(
                      fontWeight: FontWeight.w400,
                      fontSize: 12,
                      fontFamily: 'Lexend'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  children: sortedKeys
                      .map((rowNum) =>
                          buildCellRowItem(rowNum, slotsByRow[rowNum]!))
                      .toList(),
                ),
              ),
              const SizedBox(width: 16),
              Row(
                children: [
                  Container(
                    width: 6,
                    height: 400,
                    color: AppColors.grayLight,
                  ),
                  const SizedBox(width: 24),
                  Column(
                    children: [
                      Image.asset(
                        'assets/images/office.png',
                        width: 24,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Office',
                        style: TextStyle(
                            color: Color(0xFF5C5C5C),
                            fontSize: 12,
                            fontWeight: FontWeight.w300,
                            fontFamily: 'Lexend'),
                      ),
                    ],
                  ),
                ],
              )
            ],
          ),
          const SizedBox(height: 16),
          if (!_isViewer)
            _buildFooterButtons(
              secondaryText: 'Kembali',
              secondaryAction: () =>
                  setState(() => _currentStep = _TransferFlowStep.selectProductionOrSubcontractor),
              primaryText: 'Lanjutkan',
              primaryAction: _selectedSlot == null
                  ? null
                  : () => setState(
                      () => _currentStep = _TransferFlowStep.confirmToProduction),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusDisplayView() {
    final status =
        _currentPanelData.panel.statusPenyelesaian ?? 'VendorWarehouse';
    String title = 'Transfer Position';
    String statusText = '';
    Widget actionButton;
    VoidCallback? rollbackAction;

    final String vendorLabelSource = [_currentPanelData.panelVendorName]
        .where((e) => e.isNotEmpty)
        .join(' & ');
    final String displayVendorLabel =
        vendorLabelSource.isNotEmpty ? vendorLabelSource : 'Vendor';

    final String warehouseLabel =
        _currentPanelData.componentVendorNames.isNotEmpty
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
              if (mounted) {
                setState(() => _currentStep = _TransferFlowStep.confirmToFat);
              }
            });
          },
        );
        rollbackAction = () => _handleTransferAction('rollback');
        break;

      case 'Subcontractor':
        statusText = 'Dikerjakan oleh Subkontraktor ${_currentPanelData.panelVendorName ?? 'N/A'}';
        actionButton = _buildActionButton(
          'Transfer to FAT',
          isOutline: true,
          assetIconPath: 'assets/images/fat.png',
          onPressed: () {
            setState(() => _currentStep = _TransferFlowStep.confirmToFat);
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
          onPressed: () =>
              setState(() => _currentStep = _TransferFlowStep.confirmToDone),
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
        if (!_isVendorBranchDone) locations.add(displayVendorLabel);
        if (!_isWarehouseBranchDone) locations.add(warehouseLabel);
        statusText = locations.isEmpty
            ? 'Siap untuk Produksi / Subkontraktor'
            : 'Masih Dikerjakan ${locations.join(' & ')}';

        actionButton = _buildActionButton(
          'Transfer to Production / Subcon',
          isOutline: true,
          assetIconPath: 'assets/images/production.png',
          onPressed: () {
            setState(() => _currentStep = _TransferFlowStep.selectProductionOrSubcontractor);
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
                      const Text('Status: ',
                          style: TextStyle(
                              color: AppColors.gray,
                              fontWeight: FontWeight.w300,
                              fontSize: 12)),
                      Expanded(
                        child: Text(statusText,
                            style: const TextStyle(
                                fontWeight: FontWeight.w400, fontSize: 12),
                            overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                ),
                const Divider(color: AppColors.grayLight, height: 1),
                const SizedBox(height: 12),
                _buildStatusTimeline(
                  currentStage: status,
                  vendorLabel: displayVendorLabel,
                  warehouseLabel: warehouseLabel,
                  isVendorDone: _isVendorBranchDone,
                  isWarehouseDone: _isWarehouseBranchDone,
                  panelCreatedDate: _currentPanelData.panel.startDate,
                  productionDate: _currentPanelData.productionDate,
                  fatDate: _currentPanelData.fatDate,
                  allDoneDate: _currentPanelData.allDoneDate,
                ),
                if ((status == 'Production' || status == 'Subcontractor') &&
                    _currentPanelData.panel.productionSlot != null) ...[
                  const Divider(
                    height: 32,
                    color: AppColors.grayLight,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Position:',
                          style: TextStyle(
                              color: AppColors.gray,
                              fontWeight: FontWeight.w300,
                              fontSize: 12)),
                      Container(
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppColors.grayLight,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          RegExp(r'Cell\s+\d+')
                                  .firstMatch(
                                      _currentPanelData.panel.productionSlot!)
                                  ?.group(0) ??
                              _currentPanelData.panel.productionSlot!,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      )
                    ],
                  )
                ]
              ],
            ),
          ),
          const SizedBox(height: 24),
          if (!_isViewer)
            _buildActionButtons(
              primaryButton: actionButton,
              secondaryAction: rollbackAction,
            ),
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
    DateTime? panelCreatedDate,
    DateTime? productionDate,
    DateTime? fatDate,
    DateTime? allDoneDate,
  }) {
    // [MODIFIKASI] Tambahkan 'Subcontractor' sebagai alias dari 'Production' untuk timeline
    final stages = ['VendorWarehouse', 'Production', 'FAT', 'Done'];
    final normalizedStage = currentStage == 'Subcontractor' ? 'Production' : currentStage;
    final stageIndex = stages.indexOf(normalizedStage);

    final bool vendorCheck = stageIndex > 0 || isVendorDone;
    final bool warehouseCheck = stageIndex > 0 || isWarehouseDone;
    final bool productionDone = stageIndex >= 2;
    final bool fatDone = stageIndex >= 3;
    final bool isProductionActive = stageIndex == 1;
    final bool isFatActive = stageIndex == 2;
    
    Future<void> pickAndUpdateDate({
      required DateTime initialDate,
      DateTime? newStartDate,
      DateTime? newProductionDate,
      DateTime? newFatDate,
      DateTime? newAllDoneDate,
    }) async {
        if (_isViewer) return;
        final newDate = await showDatePicker(
            context: context,
            initialDate: initialDate,
            firstDate: DateTime(2020),
            lastDate: DateTime(2100),
        );
        if (newDate != null) {
            await _handleDateUpdate(
              newStartDate: newStartDate != null ? newDate : null,
              newProductionDate: newProductionDate != null ? newDate : null,
              newFatDate: newFatDate != null ? newDate : null,
              newAllDoneDate: newAllDoneDate != null ? newDate : null,
            );
        }
    }

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
                        Image.asset('assets/images/vendor.png',
                            color: vendorCheck
                                ? AppColors.schneiderGreen
                                : AppColors.blue,
                            width: 24),
                        isComplete: vendorCheck,
                        isActive: !vendorCheck,
                        date: panelCreatedDate,
                        onDateTap: () => pickAndUpdateDate(
                          initialDate: _selectedStartDate,
                          newStartDate: _selectedStartDate
                        ),
                        isEditable: !_isViewer,
                      ),
                      const SizedBox(width: 40),
                      _buildTimelineNode(
                        warehouseLabel,
                        Image.asset('assets/images/warehouse.png',
                            color: warehouseCheck
                                ? AppColors.schneiderGreen
                                : AppColors.blue,
                            width: 24),
                        isComplete: warehouseCheck,
                        isActive: !warehouseCheck,
                        date: panelCreatedDate,
                        onDateTap: () => pickAndUpdateDate(
                          initialDate: _selectedStartDate,
                          newStartDate: _selectedStartDate
                        ),
                        isEditable: !_isViewer,
                      ),
                    ],
                  ),
                ),
                _buildTimelineConnector(
                    isComplete: stageIndex >= 1,
                    branchWidth: constraints.maxWidth),
              ],
            );
          },
        ),
        _buildTimelineNode(
          'Prod / Subcon', // [MODIFIKASI] Ubah label
          Image.asset('assets/images/production.png',
              color: stageIndex >= 1
                  ? (isProductionActive
                      ? AppColors.blue
                      : AppColors.schneiderGreen)
                  : AppColors.gray,
              width: 24),
          isComplete: productionDone,
          isActive: isProductionActive,
          date: productionDate,
          datePrefix: 'Start',
          onDateTap: productionDate == null ? null : () => pickAndUpdateDate(
            initialDate: _selectedProductionDate,
            newProductionDate: _selectedProductionDate,
          ),
          isEditable: !_isViewer && productionDate != null,
        ),
        _buildTimelineConnector(isComplete: stageIndex >= 2),
        _buildTimelineNode(
          'FAT',
          Image.asset('assets/images/fat.png',
              color: stageIndex >= 2
                  ? (isFatActive ? AppColors.blue : AppColors.schneiderGreen)
                  : AppColors.gray,
              width: 24),
          isComplete: fatDone,
          isActive: isFatActive,
          date: fatDate,
          datePrefix: 'Start',
           onDateTap: fatDate == null ? null : () => pickAndUpdateDate(
            initialDate: _selectedFatDate,
            newFatDate: _selectedFatDate,
          ),
          isEditable: !_isViewer && fatDate != null,
        ),
        _buildTimelineConnector(isComplete: stageIndex >= 3),
        _buildTimelineNode(
          'All Done',
          Image.asset('assets/images/done.png',
              color: stageIndex >= 3
                  ? AppColors.schneiderGreen
                  : (isFatActive)
                      ? AppColors.blue
                      : AppColors.gray,
              width: 24),
          isComplete: fatDone,
          isActive: isFatActive,
          date: allDoneDate,
          datePrefix: 'Done',
          onDateTap: allDoneDate == null ? null : () => pickAndUpdateDate(
            initialDate: _selectedAllDoneDate,
            newAllDoneDate: _selectedAllDoneDate,
          ),
          isEditable: !_isViewer && allDoneDate != null,
        ),
      ],
    );
  }
  
  Widget _buildTimelineNode(
    String label,
    Widget icon, {
    required bool isComplete,
    bool isActive = false,
    DateTime? date,
    String datePrefix = 'Start',
    VoidCallback? onDateTap,
    bool isEditable = false,
  }) {
    final Color color = isActive
        ? AppColors.blue
        : (isComplete ? AppColors.schneiderGreen : AppColors.gray);
    final String dateText =
        date != null ? DateFormat('d MMM yyyy').format(date) : '';

    return SizedBox(
      width: 85,
      child: Column(
        children: [
          icon,
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 10, fontWeight: FontWeight.w300, color: color),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (dateText.isNotEmpty)
            GestureDetector(
              onTap: onDateTap,
              child: Container(
                color: Colors.transparent, 
                padding: const EdgeInsets.only(top: 2.0, left: 4, right: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        "$datePrefix $dateText",
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w300,
                          color: AppColors.black,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    if (isEditable && onDateTap != null) ...[
                      const SizedBox(width: 2),
                      const Icon(Icons.edit, size: 10, color: AppColors.gray)
                    ]
                  ],
                ),
              ),
            ),
          const SizedBox(height: 4),
          if (isActive)
            Image.asset('assets/images/progress_load.png', width: 14)
          else if (isComplete)
            Icon(Icons.check_circle, size: 14, color: color)
          else
            const SizedBox(height: 14),
        ],
      ),
    );
  }
  
  Widget _buildEditableDateRow({
    required String label,
    required DateTime date,
    required ValueChanged<DateTime> onDateSelected,
  }) {
    return InkWell(
      onTap: () async {
        final newDate = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: DateTime(2020),
          lastDate: DateTime(2100),
          helpText: 'Pilih Tanggal',
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: const ColorScheme.light(
                  primary: AppColors.schneiderGreen,
                  onPrimary: Colors.white,
                  onSurface: AppColors.black,
                ),
                textButtonTheme: TextButtonThemeData(
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.schneiderGreen,
                  ),
                ),
              ),
              child: child!,
            );
          },
        );
        if (newDate != null) {
          onDateSelected(newDate);
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: const TextStyle(color: AppColors.gray, fontSize: 12)),
            Row(
              children: [
                Text(
                  DateFormat('d MMM yyyy').format(date),
                  style: const TextStyle(
                      fontWeight: FontWeight.w500, fontSize: 14),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.edit_calendar_outlined,
                    color: AppColors.schneiderGreen, size: 20),
              ],
            ),
          ],
        ),
      ),
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
          _buildEditableDateRow(
            label: 'Tanggal Mulai Produksi:',
            date: _selectedProductionDate,
            onDateSelected: (newDate) {
              setState(() => _selectedProductionDate = newDate);
            },
          ),
          const SizedBox(height: 16),
          const Text(
            'Transfer ke production akan mengubah semua status menjadi close, panel 100%, dan delivery date terhitung saat ini',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.gray, fontSize: 12),
          ),
          const SizedBox(height: 24),
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
                Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: FractionallySizedBox(
                    widthFactor: 1.0,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.schneiderGreen,
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
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
                onPressed: () => _handleTransferAction(
                      'to_production',
                      productionDate: _selectedProductionDate,
                    )),
            secondaryText: 'Kembali',
            secondaryAction: () =>
                setState(() => _currentStep = _TransferFlowStep.selectSlot),
          )
        ],
      ),
    );
  }

  Widget _buildConfirmFatView() {
    final String currentSlotName =
        _currentPanelData.panel.productionSlot ?? 'N/A';
    int? rowNum;
    final nameParts = currentSlotName.split(' ');
    if (nameParts.length > 1) {
      final detailParts = nameParts[1].split('-');
      if (detailParts.isNotEmpty) {
        rowNum = int.tryParse(detailParts[0]);
      }
    }

    int availableBefore = 0;
    int availableAfter = 0;
    int capacity = 8;
    String cellDisplayName = "Cell ?";

    if (rowNum != null) {
      cellDisplayName = "Cell $rowNum";
      final slotsInThisRow = _productionSlots
          .where((s) => s.positionCode.startsWith('Cell $rowNum-'))
          .toList();
      capacity = 8;
      if (capacity > 0) {
        final occupiedBefore = slotsInThisRow.where((s) => s.isOccupied).length;
        availableBefore = capacity - occupiedBefore;
        availableAfter = availableBefore + 1;
      }
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
      child: Column(
        key: const ValueKey('confirmFat'),
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHandle(),
          _buildHeader('Transfer to FAT'),
          const SizedBox(height: 16),
          _buildEditableDateRow(
            label: 'Tanggal Mulai FAT:',
            date: _selectedFatDate,
            onDateSelected: (newDate) {
              setState(() => _selectedFatDate = newDate);
            },
          ),
          const SizedBox(height: 16),
          const Text(
            'Transfer ke FAT akan mengeluarkan panel dari slot produksi',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: AppColors.gray,
                fontSize: 12,
                fontFamily: 'Lexend',
                fontWeight: FontWeight.w300),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildSlotStateColumn(
                slotName: cellDisplayName,
                countText: '$availableBefore/$capacity',
                subtitle: const Text(
                  'Slot Available',
                  style: TextStyle(
                      color: AppColors.gray,
                      fontSize: 8,
                      fontFamily: 'Lexend',
                      fontWeight: FontWeight.w300),
                ),
                isOrigin: true,
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.0),
                child: Icon(Icons.arrow_forward, color: AppColors.gray),
              ),
              _buildSlotStateColumn(
                slotName: cellDisplayName,
                countText: '$availableAfter/$capacity',
                subtitle: Text.rich(
                  TextSpan(children: [
                    const TextSpan(
                        text: 'Slot Available',
                        style: TextStyle(
                            color: AppColors.gray,
                            fontSize: 8,
                            fontFamily: 'Lexend',
                            fontWeight: FontWeight.w300)),
                    TextSpan(
                        text: ' (+1)',
                        style: TextStyle(
                            color: AppColors.schneiderGreen.withOpacity(0.8),
                            fontWeight: FontWeight.w300,
                            fontSize: 8)),
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
            primaryAction: () => _handleTransferAction(
              'to_fat',
              fatDate: _selectedFatDate,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmDoneView() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
      child: Column(
        key: const ValueKey('confirmDone'),
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHandle(),
          _buildHeader('Selesaikan Panel'),
          const SizedBox(height: 24),
          const Text(
            'Panel akan ditandai sebagai "All Done". Harap konfirmasi tanggal penyelesaian.',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: AppColors.gray,
                fontSize: 12,
                fontFamily: 'Lexend',
                fontWeight: FontWeight.w300),
          ),
          const SizedBox(height: 24),
          _buildEditableDateRow(
            label: 'Tanggal Selesai:',
            date: _selectedAllDoneDate,
            onDateSelected: (newDate) {
              setState(() => _selectedAllDoneDate = newDate);
            },
          ),
          const SizedBox(height: 32),
          _buildFooterButtons(
            secondaryText: 'Kembali',
            secondaryAction: () =>
                setState(() => _currentStep = _TransferFlowStep.displayStatus),
            primaryText: 'Ya, Selesaikan',
            primaryAction: () => _handleTransferAction(
              'to_done',
              allDoneDate: _selectedAllDoneDate,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(String title,
      {bool isSubPage = false, VoidCallback? onBack}) {
    return Row(
      children: [
        if (isSubPage)
          IconButton(icon: const Icon(Icons.arrow_back), onPressed: onBack)
        else
          const SizedBox(width: 48), // Placeholder
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
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6)),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: Text(secondaryText,
                style: const TextStyle(
                    fontWeight: FontWeight.w500, fontSize: 12)),
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
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6)),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: Text(primaryText,
                style: const TextStyle(
                    fontWeight: FontWeight.w500, fontSize: 12)),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(
      {required Widget primaryButton,
      String? secondaryText,
      VoidCallback? secondaryAction}) {
    Widget secondaryButton;

    if (secondaryAction != null) {
      final String text = secondaryText ?? 'Rollback';
      if (text == 'Kembali') {
        secondaryButton = Expanded(
            child: _buildActionButton(text,
                onPressed: secondaryAction, isOutline: true));
      } else {
        secondaryButton = TextButton(
          onPressed: secondaryAction,
          child: Text(text,
              style: const TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.w500,
                  fontSize: 12)),
        );
      }
    } else {
      secondaryButton = const Spacer();
    }

    return Row(
      children: [
        secondaryButton,
        if (secondaryAction != null && secondaryText != 'Kembali')
          const Spacer(),
        if (secondaryAction != null && secondaryText == 'Kembali')
          const SizedBox(width: 16),
        Flexible(flex: 2, child: primaryButton),
      ],
    );
  }

  Widget _buildActionButton(String text,
      {VoidCallback? onPressed,
      String? assetIconPath,
      bool isOutline = false}) {
    final textColor = isOutline ? AppColors.schneiderGreen : Colors.white;
    final backgroundColor =
        isOutline ? Colors.white : AppColors.schneiderGreen;
    final borderColor =
        isOutline ? AppColors.schneiderGreen : Colors.transparent;

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
          side: BorderSide(color: borderColor, width: 1.5),
        ),
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: textColor, fontWeight: FontWeight.w500, fontSize: 12),
            ),
          ),
          if (assetIconPath != null) ...[
            const SizedBox(width: 8),
            Image.asset(assetIconPath,
                width: 16, height: 16, color: textColor),
          ]
        ],
      ),
    );
  }

  Widget _buildTimelineConnector(
      {required bool isComplete, double? branchWidth}) {
    final color = isComplete ? AppColors.schneiderGreen : AppColors.grayLight;
    if (branchWidth != null) {
      return SizedBox(
        height: 20,
        child: CustomPaint(
          painter:
              _BranchConnectorPainter(color: color, branchWidth: branchWidth),
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
            Image.asset('assets/images/done-green.png', height: 14),
          ],
        ),
      ],
    );
  }

  Widget _buildSlotStateColumn({
    required String slotName,
    required String countText,
    required Widget subtitle,
    required bool isOrigin,
  }) {
    Widget slotBox;
    if (isOrigin) {
      slotBox = Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
            fontWeight: FontWeight.w400,
            fontFamily: 'Lexend',
          ),
        ),
      );
    } else {
      slotBox = DashedBorderContainer(
        color: AppColors.gray,
        strokeWidth: 1,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
        Container(
          width: 80,
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(8),
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
}

class _BranchConnectorPainter extends CustomPainter {
  final Color color;
  final double branchWidth;
  _BranchConnectorPainter({required this.color, required this.branchWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
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
  bool shouldRepaint(covariant _BranchConnectorPainter oldDelegate) =>
      color != oldDelegate.color || branchWidth != oldDelegate.branchWidth;
}

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
    path.addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height), radius));

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