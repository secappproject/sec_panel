import 'package:flutter/material.dart';
import 'package:secpanel/components/panel/add/add_panel_bottom_sheet.dart';
import 'package:secpanel/models/company.dart';
import 'package:secpanel/models/paneldisplaydata.dart';
import 'package:secpanel/models/panels.dart';
import 'package:secpanel/models/approles.dart';
import 'package:secpanel/helpers/db_helper.dart';
import 'package:secpanel/theme/colors.dart';
import 'package:secpanel/components/panel/card/panel_progress_card.dart';
import 'package:secpanel/components/panel/edit/edit_panel_bottom_sheet.dart';
import 'package:secpanel/components/panel/edit/edit_status_bottom_sheet.dart';
import 'package:secpanel/components/panel/filtersearch/panel_filter_bottom_sheet.dart';
import 'package:secpanel/components/panel/filtersearch/search_field.dart';
import 'package:shimmer/shimmer.dart';

class HomeScreen extends StatefulWidget {
  final Company currentCompany;

  const HomeScreen({super.key, required this.currentCompany});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late final TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  List<PanelDisplayData> _allPanelsData = [];
  List<Company> _allK3Vendors = [];
  List<Company> _allK5Vendors = [];
  List<Company> _allWHSVendors = [];
  bool _isLoading = true;

  // --- State untuk filter ---
  List<String> searchChips = [];
  String activeSearchText = "";

  bool includeArchived = false;
  SortOption? selectedSort;
  List<PanelFilterStatus> selectedPanelStatuses = [];
  List<String> selectedPanelVendors = [];
  List<String> selectedBusbarVendors = [];
  List<String> selectedComponentVendors = [];
  List<String> selectedPaletVendors = [];
  List<String> selectedCorepartVendors = [];
  List<String> selectedPccStatuses = [];
  List<String> selectedMccStatuses = [];
  List<String> selectedComponents = [];
  List<String> selectedPalet = [];
  List<String> selectedCorepart = [];
  DateTimeRange? startDateRange;
  DateTimeRange? deliveryDateRange;
  DateTimeRange? closedDateRange;
  List<String> selectedPanelTypes = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(() => setState(() {}));
    loadInitialData();
  }

  Future<void> loadInitialData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final panelsDataFromDb = await DatabaseHelper.instance
          .getAllPanelsForDisplay(currentUser: widget.currentCompany);
      final k3Vendors = await DatabaseHelper.instance.getK3Vendors();
      final k5Vendors = await DatabaseHelper.instance.getK5Vendors();
      final whsVendors = await DatabaseHelper.instance.getWHSVendors();

      if (mounted) {
        setState(() {
          _allPanelsData = panelsDataFromDb;
          _allK3Vendors = k3Vendors;
          _allK5Vendors = k5Vendors;
          _allWHSVendors = whsVendors;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error memuat data: ${e.toString()}")),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _openFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => PanelFilterBottomSheet(
        selectedPccStatuses: selectedPccStatuses,
        selectedMccStatuses: selectedMccStatuses,
        selectedComponents: selectedComponents,
        selectedPalet: selectedPalet,
        selectedCorepart: selectedCorepart,
        includeArchived: includeArchived,
        selectedSort: selectedSort,
        selectedPanelStatuses: selectedPanelStatuses,
        allK3Vendors: _allK3Vendors,
        allK5Vendors: _allK5Vendors,
        allWHSVendors: _allWHSVendors,
        selectedPanelVendors: selectedPanelVendors,
        selectedBusbarVendors: selectedBusbarVendors,
        selectedComponentVendors: selectedComponentVendors,
        selectedPaletVendors: selectedPaletVendors,
        selectedCorepartVendors: selectedCorepartVendors,
        startDateRange: startDateRange,
        deliveryDateRange: deliveryDateRange,
        closedDateRange: closedDateRange,
        selectedPanelTypes: selectedPanelTypes,
        onPanelTypesChanged: (value) =>
            setState(() => selectedPanelTypes = value),
        onStartDateRangeChanged: (value) =>
            setState(() => startDateRange = value),
        onDeliveryDateRangeChanged: (value) =>
            setState(() => deliveryDateRange = value),
        onClosedDateRangeChanged: (value) =>
            setState(() => closedDateRange = value),
        onPccStatusesChanged: (value) =>
            setState(() => selectedPccStatuses = value),
        onMccStatusesChanged: (value) =>
            setState(() => selectedMccStatuses = value),
        onComponentsChanged: (value) =>
            setState(() => selectedComponents = value),
        onPaletChanged: (value) => setState(() => selectedPalet = value),
        onCorepartChanged: (value) => setState(() => selectedCorepart = value),
        onIncludeArchivedChanged: (value) =>
            setState(() => includeArchived = value),
        onSortChanged: (value) => setState(() => selectedSort = value),
        onPanelStatusesChanged: (value) =>
            setState(() => selectedPanelStatuses = value),
        onPanelVendorsChanged: (value) =>
            setState(() => selectedPanelVendors = value),
        onBusbarVendorsChanged: (value) =>
            setState(() => selectedBusbarVendors = value),
        onComponentVendorsChanged: (value) =>
            setState(() => selectedComponentVendors = value),
        onPaletVendorsChanged: (value) =>
            setState(() => selectedPaletVendors = value),
        onCorepartVendorsChanged: (value) =>
            setState(() => selectedCorepartVendors = value),
        onReset: () {
          setState(() {
            searchChips = [];
            activeSearchText = "";
            _searchController.clear();
            includeArchived = false;
            selectedSort = null;
            selectedPanelStatuses = [];
            selectedPanelVendors = [];
            selectedBusbarVendors = [];
            selectedComponentVendors = [];
            selectedPaletVendors = [];
            selectedCorepartVendors = [];
            selectedPccStatuses = [];
            selectedMccStatuses = [];
            selectedComponents = [];
            selectedPalet = [];
            selectedCorepart = [];
            selectedPanelTypes = [];
            startDateRange = null;
            deliveryDateRange = null;
            closedDateRange = null;
          });
        },
      ),
    );
  }

  void _openEditPanelBottomSheet(PanelDisplayData dataToEdit) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => EditPanelBottomSheet(
        panelData: dataToEdit,
        currentCompany: widget.currentCompany,
        k3Vendors: _allK3Vendors,
        onSave: (updatedPanel) => loadInitialData(), // Panggil refresh
        onDelete: () async {
          Navigator.of(context).pop();
          await DatabaseHelper.instance.deletePanel(dataToEdit.panel.noPp);
          loadInitialData(); // Panggil refresh
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Panel "${dataToEdit.panel.noPanel}" berhasil dihapus.',
                ),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
      ),
    );
  }

  void _openEditStatusBottomSheet(PanelDisplayData dataToEdit) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => EditStatusBottomSheet(
        duration: _formatDuration(dataToEdit.panel.startDate),
        startDate: dataToEdit.panel.startDate,
        progress: (dataToEdit.panel.percentProgress ?? 0) / 100.0,
        panelData: dataToEdit,
        panelVendorName: dataToEdit.panelVendorName,
        busbarVendorNames: dataToEdit.busbarVendorNames,
        currentCompany: widget.currentCompany,
        onSave: () => loadInitialData(), // Panggil refresh
      ),
    );
  }

  // ===========================================================================
  // LOGIKA UNTUK FILTERING DAN SORTING
  // ===========================================================================

  String _formatDuration(DateTime? startDate) {
    if (startDate == null) return "Belum Diatur";
    final now = DateTime.now();
    if (startDate.isAfter(now)) {
      final diff = startDate.difference(now);
      final days = diff.inDays;
      final hours = diff.inHours % 24;
      return "$days hari $hours jam";
    }
    final diff = now.difference(startDate);
    if (diff.inDays > 0) return "${diff.inDays} hari";
    if (diff.inHours > 0) return "${diff.inHours} jam";
    return "${diff.inMinutes} menit";
  }

  PanelFilterStatus _getPanelFilterStatus(Panel panel) {
    final progress = panel.percentProgress ?? 0;
    if (progress < 50) return PanelFilterStatus.progressRed;
    if (progress < 75) return PanelFilterStatus.progressOrange;
    if (progress < 100) return PanelFilterStatus.progressBlue;
    if (progress >= 100) {
      if (!panel.isClosed) return PanelFilterStatus.readyToDelivery;
      if (panel.closedDate != null &&
          DateTime.now().difference(panel.closedDate!).inHours > 48) {
        return PanelFilterStatus.closedArchived;
      }
      return PanelFilterStatus.closed;
    }
    return PanelFilterStatus.progressRed;
  }

  // home_screen.dart

  List<PanelDisplayData> get _panelsAfterPrimaryFilters {
    return _allPanelsData.where((data) {
      final panel = data.panel;

      bool isPanelMatch(String query) {
        if (query.isEmpty) return true;
        final q = query.toLowerCase();

        final displayPanelVendor = (data.panelVendorName ?? '').isEmpty
            ? 'no vendor'
            : data.panelVendorName!.toLowerCase();
        final displayBusbarVendors = (data.busbarVendorNames ?? '').isEmpty
            ? 'no vendor'
            : data.busbarVendorNames!.toLowerCase();
        final displayComponentVendors =
            (data.componentVendorNames ?? '').isEmpty
            ? 'no vendor'
            : data.componentVendorNames!.toLowerCase();
        final displayPaletVendors = (data.paletVendorNames ?? '').isEmpty
            ? 'no vendor'
            : data.paletVendorNames!.toLowerCase();
        final displayCorepartVendors = (data.corepartVendorNames ?? '').isEmpty
            ? 'no vendor'
            : data.corepartVendorNames!.toLowerCase();

        return (panel.noPanel ?? '').toLowerCase().contains(q) ||
            panel.noPp.toLowerCase().contains(q) ||
            (panel.noWbs ?? '').toLowerCase().contains(q) ||
            (panel.project ?? '').toLowerCase().contains(q) ||
            (panel.panelType ?? '').toLowerCase().contains(q) ||
            displayPanelVendor.contains(q) ||
            displayBusbarVendors.contains(q) ||
            displayComponentVendors.contains(q) ||
            displayPaletVendors.contains(q) ||
            displayCorepartVendors.contains(q) ||
            (panel.statusBusbarPcc ?? '').toLowerCase().contains(q) ||
            (panel.statusBusbarMcc ?? '').toLowerCase().contains(q) ||
            (panel.statusComponent ?? '').toLowerCase().contains(q) ||
            (panel.statusPalet ?? '').toLowerCase().contains(q) ||
            (panel.statusCorepart ?? '').toLowerCase().contains(q);
      }

      final allSearchTerms = [
        ...searchChips,
        activeSearchText.trim(),
      ].where((s) => s.isNotEmpty).toList();

      final bool matchSearch;
      if (allSearchTerms.isEmpty) {
        matchSearch = true;
      } else {
        matchSearch = allSearchTerms.any((term) => isPanelMatch(term));
      }

      final matchPanelType =
          selectedPanelTypes.isEmpty ||
          selectedPanelTypes.any(
            (type) => type == 'Belum Diatur'
                ? (panel.panelType == null || panel.panelType!.isEmpty)
                : panel.panelType == type,
          );

      final matchPanelVendor =
          selectedPanelVendors.isEmpty ||
          selectedPanelVendors.any((selectedId) {
            if (selectedId == 'No Vendor') {
              return panel.vendorId == null || panel.vendorId!.isEmpty;
            }
            return panel.vendorId == selectedId;
          });

      final matchBusbarVendor =
          selectedBusbarVendors.isEmpty ||
          selectedBusbarVendors.any((selectedId) {
            if (selectedId == 'No Vendor') {
              return data.busbarVendorIds.isEmpty;
            }
            return data.busbarVendorIds.contains(selectedId);
          });

      final matchComponentVendor =
          selectedComponentVendors.isEmpty ||
          selectedComponentVendors.any((selectedId) {
            if (selectedId == 'No Vendor') {
              return data.componentVendorIds.isEmpty;
            }
            return data.componentVendorIds.contains(selectedId);
          });

      final matchPaletVendor =
          selectedPaletVendors.isEmpty ||
          selectedPaletVendors.any((selectedId) {
            if (selectedId == 'No Vendor') {
              return data.paletVendorIds.isEmpty;
            }
            return data.paletVendorIds.contains(selectedId);
          });

      final matchCorepartVendor =
          selectedCorepartVendors.isEmpty ||
          selectedCorepartVendors.any((selectedId) {
            if (selectedId == 'No Vendor') {
              return data.corepartVendorIds.isEmpty;
            }
            return data.corepartVendorIds.contains(selectedId);
          });

      // ... sisa kode tidak berubah

      final matchPccStatus =
          selectedPccStatuses.isEmpty ||
          (panel.statusBusbarPcc != null &&
              selectedPccStatuses.contains(panel.statusBusbarPcc));
      final matchMccStatus =
          selectedMccStatuses.isEmpty ||
          (panel.statusBusbarMcc != null &&
              selectedMccStatuses.contains(panel.statusBusbarMcc));
      final matchComponent =
          selectedComponents.isEmpty ||
          selectedComponents.contains(panel.statusComponent);
      final matchPalet =
          selectedPalet.isEmpty || selectedPalet.contains(panel.statusPalet);
      final matchCorepart =
          selectedCorepart.isEmpty ||
          selectedCorepart.contains(panel.statusCorepart);

      final matchStartDate =
          startDateRange == null ||
          (panel.startDate != null &&
              !panel.startDate!.isBefore(startDateRange!.start) &&
              !panel.startDate!.isAfter(
                startDateRange!.end.add(const Duration(days: 1)),
              ));
      final matchDeliveryDate =
          deliveryDateRange == null ||
          (panel.targetDelivery != null &&
              !panel.targetDelivery!.isBefore(deliveryDateRange!.start) &&
              !panel.targetDelivery!.isAfter(
                deliveryDateRange!.end.add(const Duration(days: 1)),
              ));
      final matchClosedDate =
          closedDateRange == null ||
          (panel.closedDate != null &&
              !panel.closedDate!.isBefore(closedDateRange!.start) &&
              !panel.closedDate!.isAfter(
                closedDateRange!.end.add(const Duration(days: 1)),
              ));

      if (!matchSearch ||
          !matchPanelType ||
          !matchPanelVendor ||
          !matchBusbarVendor ||
          !matchComponentVendor ||
          !matchPaletVendor ||
          !matchCorepartVendor ||
          !matchPccStatus ||
          !matchMccStatus ||
          !matchComponent ||
          !matchPalet ||
          !matchCorepart ||
          !matchStartDate ||
          !matchDeliveryDate ||
          !matchClosedDate) {
        return false;
      }

      final panelStatus = _getPanelFilterStatus(panel);
      if (panelStatus == PanelFilterStatus.closedArchived) {
        return includeArchived;
      }
      return selectedPanelStatuses.isEmpty ||
          selectedPanelStatuses.contains(panelStatus);
    }).toList();
  }

  List<PanelDisplayData> get filteredPanelsForDisplay {
    var tabFilteredPanels = _panelsAfterPrimaryFilters;
    final role = widget.currentCompany.role;

    switch (_tabController.index) {
      case 0:
        break;
      case 1:
        if (role == AppRole.k5) {
          tabFilteredPanels = tabFilteredPanels
              .where((data) => data.busbarVendorIds.isEmpty)
              .toList();
        } else if (role == AppRole.warehouse) {
          tabFilteredPanels = tabFilteredPanels
              .where((data) => data.componentVendorIds.isEmpty)
              .toList();
        } else {
          tabFilteredPanels = tabFilteredPanels
              .where(
                (data) =>
                    data.busbarVendorIds.isEmpty ||
                    data.componentVendorIds.isEmpty ||
                    data.paletVendorIds.isEmpty ||
                    data.corepartVendorIds.isEmpty,
              )
              .toList();
        }
        break;
      case 2:
        tabFilteredPanels = tabFilteredPanels.where((data) {
          final panel = data.panel;
          bool isReadyToDelivery =
              (panel.percentProgress ?? 0) >= 100 && !panel.isClosed;
          bool isClosed = panel.isClosed;
          bool isOpenVendor = (role == AppRole.k5)
              ? data.busbarVendorIds.isEmpty
              : (role == AppRole.warehouse)
              ? data.componentVendorIds.isEmpty
              : (data.busbarVendorIds.isEmpty ||
                    data.componentVendorIds.isEmpty ||
                    data.paletVendorIds.isEmpty ||
                    data.corepartVendorIds.isEmpty);
          return !isOpenVendor && !isReadyToDelivery && !isClosed;
        }).toList();
        break;
      case 3:
        tabFilteredPanels = tabFilteredPanels
            .where(
              (data) =>
                  (data.panel.percentProgress ?? 0) >= 100 &&
                  !data.panel.isClosed,
            )
            .toList();
        break;
      case 4:
        tabFilteredPanels = tabFilteredPanels
            .where((data) => data.panel.isClosed)
            .toList();
        break;
    }

    tabFilteredPanels.sort((a, b) {
      final sort = selectedSort ?? SortOption.durationDesc;
      switch (sort) {
        case SortOption.percentageDesc:
          return (b.panel.percentProgress ?? 0).compareTo(
            a.panel.percentProgress ?? 0,
          );
        case SortOption.percentageAsc:
          return (a.panel.percentProgress ?? 0).compareTo(
            b.panel.percentProgress ?? 0,
          );
        case SortOption.durationAsc:
          return (a.panel.startDate ?? DateTime(2200)).compareTo(
            b.panel.startDate ?? DateTime(2200),
          );
        case SortOption.durationDesc:
          return (b.panel.startDate ?? DateTime(1900)).compareTo(
            a.panel.startDate ?? DateTime(1900),
          );
        case SortOption.panelNoAZ:
          return (a.panel.noPanel ?? "").toLowerCase().compareTo(
            (b.panel.noPanel ?? "").toLowerCase(),
          );
        case SortOption.panelNoZA:
          return (b.panel.noPanel ?? "").toLowerCase().compareTo(
            (a.panel.noPanel ?? "").toLowerCase(),
          );
        case SortOption.ppNoAZ:
          return (a.panel.noPp).compareTo(b.panel.noPp);
        case SortOption.ppNoZA:
          return (b.panel.noPp).compareTo(a.panel.noPp);
        case SortOption.wbsNoAZ:
          return (a.panel.noWbs ?? "").compareTo(b.panel.noWbs ?? "");
        case SortOption.wbsNoZA:
          return (b.panel.noWbs ?? "").compareTo(a.panel.noWbs ?? "");
        case SortOption.projectNoAZ:
          return (a.panel.project ?? "").toLowerCase().compareTo(
            (b.panel.project ?? "").toLowerCase(),
          );
        case SortOption.projectNoZA:
          return (b.panel.project ?? "").toLowerCase().compareTo(
            (a.panel.project ?? "").toLowerCase(),
          );
        default:
          return (b.panel.startDate ?? DateTime(1900)).compareTo(
            a.panel.startDate ?? DateTime(1900),
          );
      }
    });

    return tabFilteredPanels;
  }

  // ===========================================================================
  // BUILD METHOD UTAMA
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: loadInitialData,
        color: AppColors.schneiderGreen,
        child: SafeArea(
          child: _isLoading ? _buildSkeletonView() : _buildContentView(),
        ),
      ),
    );
  }

  Widget _buildContentView() {
    final panelsToDisplay = filteredPanelsForDisplay;
    final baseFilteredList = _panelsAfterPrimaryFilters;
    final role = widget.currentCompany.role;

    final allCount = baseFilteredList.length;
    final openVendorCount = baseFilteredList
        .where(
          (data) => (role == AppRole.k5)
              ? data.busbarVendorIds.isEmpty
              : (role == AppRole.warehouse)
              ? data.componentVendorIds.isEmpty
              : (data.busbarVendorIds.isEmpty ||
                    data.componentVendorIds.isEmpty ||
                    data.paletVendorIds.isEmpty ||
                    data.corepartVendorIds.isEmpty),
        )
        .length;
    final onGoingPanelCount = baseFilteredList.where((data) {
      final panel = data.panel;
      bool isReady = (panel.percentProgress ?? 0) >= 100 && !panel.isClosed;
      bool isOpen = (role == AppRole.k5)
          ? data.busbarVendorIds.isEmpty
          : (role == AppRole.warehouse)
          ? data.componentVendorIds.isEmpty
          : (data.busbarVendorIds.isEmpty ||
                data.componentVendorIds.isEmpty ||
                data.paletVendorIds.isEmpty ||
                data.corepartVendorIds.isEmpty);
      return !isOpen && !isReady && !panel.isClosed;
    }).length;
    final readyToDeliveryCount = baseFilteredList
        .where(
          (data) =>
              (data.panel.percentProgress ?? 0) >= 100 && !data.panel.isClosed,
        )
        .length;
    final closedPanelCount = baseFilteredList
        .where((data) => data.panel.isClosed)
        .length;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Alignment Panel Busbar & Komponen",
                style: TextStyle(
                  color: AppColors.black,
                  fontSize: 24,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: SearchField(
                      controller: _searchController,
                      chips: searchChips,
                      onChanged: (value) {
                        setState(() {
                          activeSearchText = value;
                        });
                      },
                      onChipDeleted: (chipToDelete) {
                        setState(() {
                          searchChips.remove(chipToDelete);
                        });
                      },
                      onSubmitted: (value) {
                        final text = value.trim();
                        if (text.isNotEmpty && !searchChips.contains(text)) {
                          setState(() {
                            searchChips.add(text);
                            activeSearchText = "";
                          });
                          _searchController.clear();
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  InkWell(
                    onTap: _openFilterBottomSheet,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.grayLight),
                      ),
                      child: Image.asset(
                        'assets/images/filter-green.png',
                        width: 20,
                        height: 20,
                        color: AppColors.schneiderGreen,
                      ),
                    ),
                  ),
                ],
              ),
              TabBar(
                controller: _tabController,
                isScrollable: true,
                labelColor: AppColors.black,
                unselectedLabelColor: AppColors.gray,
                indicatorColor: AppColors.schneiderGreen,
                indicatorWeight: 2,
                tabAlignment: TabAlignment.start,
                padding: EdgeInsets.zero,
                indicatorSize: TabBarIndicatorSize.label,
                overlayColor: WidgetStateProperty.all(Colors.transparent),
                dividerColor: Colors.transparent,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Lexend',
                  fontSize: 12,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.w400,
                  fontFamily: 'Lexend',
                  fontSize: 12,
                ),
                tabs: [
                  Tab(text: "All ($allCount)"),
                  Tab(text: "Open Vendor ($openVendorCount)"),
                  Tab(text: "Need to Track ($onGoingPanelCount)"),
                  Tab(text: "Ready to Delivery ($readyToDeliveryCount)"),
                  Tab(text: "Closed Panel ($closedPanelCount)"),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: panelsToDisplay.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 48.0),
                    child: Text(
                      "Tidak ada panel yang ditemukan",
                      style: TextStyle(color: AppColors.gray, fontSize: 14),
                    ),
                  ),
                )
              : LayoutBuilder(
                  builder: (context, constraints) {
                    // Tentukan breakpoint untuk beralih ke tampilan grid.
                    const double gridBreakpoint = 740;

                    if (constraints.maxWidth < gridBreakpoint) {
                      return ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                        itemCount: panelsToDisplay.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 16),
                        itemBuilder: (context, index) {
                          final data = panelsToDisplay[index];
                          final panel = data.panel;
                          // Widget card Anda (tidak perlu diubah)
                          return PanelProgressCard(
                            currentUserRole: widget.currentCompany.role,
                            targetDelivery: panel.targetDelivery,
                            duration: _formatDuration(panel.startDate),
                            progress: (panel.percentProgress ?? 0) / 100.0,
                            startDate: panel.startDate,
                            progressLabel:
                                "${panel.percentProgress?.toInt() ?? 0}%",
                            panelType: panel.panelType ?? "",
                            panelTitle: panel.noPanel ?? "",
                            panelRemarks: panel.remarks,
                            statusBusbarPcc: panel.statusBusbarPcc ?? "",
                            statusBusbarMcc: panel.statusBusbarMcc ?? "",
                            statusComponent: panel.statusComponent ?? "",
                            statusPalet: panel.statusPalet ?? "",
                            statusCorepart: panel.statusCorepart ?? "",
                            ppNumber: panel.noPp,
                            wbsNumber: panel.noWbs ?? "",
                            project: panel.project ?? "",
                            onEdit: () {
                              final role = widget.currentCompany.role;
                              if (role == AppRole.admin || role == AppRole.k3) {
                                _openEditPanelBottomSheet(data);
                              } else if (role == AppRole.k5 ||
                                  role == AppRole.warehouse) {
                                _openEditStatusBottomSheet(data);
                              }
                            },
                            panelVendorName: data.panelVendorName,
                            busbarVendorNames: data.busbarVendorNames,
                            componentVendorName: data.componentVendorNames,
                            paletVendorName: data.paletVendorNames,
                            corepartVendorName: data.corepartVendorNames,
                            isClosed: panel.isClosed,
                            closedDate: panel.closedDate,
                            busbarRemarks: data.busbarRemarks,
                          );
                        },
                      );
                    } else {
                      // === TAMPILAN GRID UNTUK LAYAR LEBAR (DESKTOP/TABLET) ===
                      // Hitung jumlah kolom secara dinamis, target lebar per card ~500px
                      final int crossAxisCount = (constraints.maxWidth / 500)
                          .floor()
                          .clamp(2, 4);

                      return GridView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          // Hapus childAspectRatio dan ganti dengan ini:
                          mainAxisExtent:
                              440, // Tentukan tinggi card yang pas, misal 380px
                        ),
                        itemCount: panelsToDisplay.length,
                        itemBuilder: (context, index) {
                          final data = panelsToDisplay[index];
                          final panel = data.panel;
                          // Widget card Anda (tidak perlu diubah)
                          return PanelProgressCard(
                            currentUserRole: widget.currentCompany.role,
                            targetDelivery: panel.targetDelivery,
                            duration: _formatDuration(panel.startDate),
                            progress: (panel.percentProgress ?? 0) / 100.0,
                            startDate: panel.startDate,
                            progressLabel:
                                "${panel.percentProgress?.toInt() ?? 0}%",
                            panelType: panel.panelType ?? "",
                            panelTitle: panel.noPanel ?? "",
                            panelRemarks: panel.remarks,
                            statusBusbarPcc: panel.statusBusbarPcc ?? "",
                            statusBusbarMcc: panel.statusBusbarMcc ?? "",
                            statusComponent: panel.statusComponent ?? "",
                            statusPalet: panel.statusPalet ?? "",
                            statusCorepart: panel.statusCorepart ?? "",
                            ppNumber: panel.noPp,
                            wbsNumber: panel.noWbs ?? "",
                            project: panel.project ?? "",
                            onEdit: () {
                              final role = widget.currentCompany.role;
                              if (role == AppRole.admin || role == AppRole.k3) {
                                _openEditPanelBottomSheet(data);
                              } else if (role == AppRole.k5 ||
                                  role == AppRole.warehouse) {
                                _openEditStatusBottomSheet(data);
                              }
                            },
                            panelVendorName: data.panelVendorName,
                            busbarVendorNames: data.busbarVendorNames,
                            componentVendorName: data.componentVendorNames,
                            paletVendorName: data.paletVendorNames,
                            corepartVendorName: data.corepartVendorNames,
                            isClosed: panel.isClosed,
                            closedDate: panel.closedDate,
                            busbarRemarks: data.busbarRemarks,
                          );
                        },
                      );
                    }
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildSkeletonView() {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20.0),
      child: Shimmer.fromColors(
        baseColor: Colors.grey[200]!,
        highlightColor: Colors.grey[100]!,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSkeletonBox(height: 28, width: 200),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildSkeletonBox(height: 48)),
                const SizedBox(width: 12),
                _buildSkeletonBox(width: 48, height: 48),
              ],
            ),
            const SizedBox(height: 8),
            _buildSkeletonBox(height: 48, width: double.infinity),
            const SizedBox(height: 12),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 5,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) => _buildSkeletonCard(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeletonCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.grayLight, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSkeletonBox(width: 100, height: 14),
              _buildSkeletonBox(width: 24, height: 24),
            ],
          ),
          const SizedBox(height: 8),
          _buildSkeletonBox(width: double.infinity, height: 8),
          const SizedBox(height: 12),
          _buildSkeletonBox(width: 150, height: 20),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildSkeletonBox(width: 80, height: 14),
              const SizedBox(width: 10),
              _buildSkeletonBox(width: 80, height: 14),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(),
          const SizedBox(height: 10),
          _buildSkeletonBox(width: 120, height: 12),
        ],
      ),
    );
  }

  Widget _buildSkeletonBox({double? width, double height = 16}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}
