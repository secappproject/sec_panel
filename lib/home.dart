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
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;

class HomeScreen extends StatefulWidget {
  final Company currentCompany;

  const HomeScreen({super.key, required this.currentCompany});

  @override
  HomeScreenState createState() => HomeScreenState();
}

enum ChartTimeView { daily, monthly, yearly }

class HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late final TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  List<PanelDisplayData> _allPanelsData = [];
  List<Company> _allK3Vendors = [];
  List<Company> _allK5Vendors = [];
  List<Company> _allWHSVendors = [];
  bool _isLoading = true;

  bool _isChartView = false;

  // State untuk Chart
  ChartTimeView _panelChartView = ChartTimeView.monthly;
  ChartTimeView _busbarChartView = ChartTimeView.monthly;
  bool _isPanelMonthly = true;
  bool _isBusbarMonthly = true;
  Map<String, dynamic> _panelChartData = {};
  Map<String, dynamic> _busbarChartData = {};

  // --- State untuk filter (tidak ada perubahan di sini) ---
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
  List<String> selectedPanelTypes = [];
  DateTimeRange? startDateRange;
  DateTimeRange? deliveryDateRange;
  DateTimeRange? closedDateRange;
  DateTimeRange? pccClosedDateRange;
  DateTimeRange? mccClosedDateRange;
  DateFilterType startDateStatus = DateFilterType.any;
  DateFilterType deliveryDateStatus = DateFilterType.any;
  DateFilterType closedDateStatus = DateFilterType.any;
  DateFilterType pccClosedDateStatus = DateFilterType.any;
  DateFilterType mccClosedDateStatus = DateFilterType.any;
  // --- Akhir State Filter ---

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
          _prepareChartData();
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

  void _prepareChartData() {
    final panelsToDisplay = filteredPanelsForDisplay;

    final allPanelVendorNames = _allK3Vendors.map((v) => v.name).toList();
    final allBusbarVendorNames = _allK5Vendors.map((v) => v.name).toList();

    if (panelsToDisplay.any((p) => p.panelVendorName.isEmpty)) {
      if (!allPanelVendorNames.contains("No Vendor")) {
        allPanelVendorNames.add("No Vendor");
      }
    }
    if (panelsToDisplay.any((p) => p.busbarVendorNames.isEmpty)) {
      if (!allBusbarVendorNames.contains("No Vendor")) {
        allBusbarVendorNames.add("No Vendor");
      }
    }

    _panelChartData = _calculateDeliveryByTime(
      panelsToDisplay,
      (data) => [
        data.panelVendorName.isNotEmpty ? data.panelVendorName : "No Vendor",
      ],
      view: _panelChartView,
      allPossibleVendors: allPanelVendorNames,
    );

    _busbarChartData = _calculateDeliveryByTime(
      panelsToDisplay,
      (data) {
        if (data.busbarVendorNames.isNotEmpty) {
          return data.busbarVendorNames
              .split(',')
              .map((e) => e.trim())
              .toList();
        }
        return ["No Vendor"];
      },
      view: _busbarChartView,
      allPossibleVendors: allBusbarVendorNames,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // --- Semua fungsi _open...BottomSheet dan logika filter tidak berubah ---
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
        selectedPanelTypes: selectedPanelTypes,
        startDateRange: startDateRange,
        deliveryDateRange: deliveryDateRange,
        closedDateRange: closedDateRange,
        pccClosedDateRange: pccClosedDateRange,
        mccClosedDateRange: mccClosedDateRange,
        startDateStatus: startDateStatus,
        deliveryDateStatus: deliveryDateStatus,
        closedDateStatus: closedDateStatus,
        pccClosedDateStatus: pccClosedDateStatus,
        mccClosedDateStatus: mccClosedDateStatus,
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
        onPanelTypesChanged: (value) =>
            setState(() => selectedPanelTypes = value),
        onStartDateRangeChanged: (value) =>
            setState(() => startDateRange = value),
        onDeliveryDateRangeChanged: (value) =>
            setState(() => deliveryDateRange = value),
        onClosedDateRangeChanged: (value) =>
            setState(() => closedDateRange = value),
        onPccClosedDateRangeChanged: (value) =>
            setState(() => pccClosedDateRange = value),
        onMccClosedDateRangeChanged: (value) =>
            setState(() => mccClosedDateRange = value),
        onStartDateStatusChanged: (value) =>
            setState(() => startDateStatus = value),
        onDeliveryDateStatusChanged: (value) =>
            setState(() => deliveryDateStatus = value),
        onClosedDateStatusChanged: (value) =>
            setState(() => closedDateStatus = value),
        onPccClosedDateStatusChanged: (value) =>
            setState(() => pccClosedDateStatus = value),
        onMccClosedDateStatusChanged: (value) =>
            setState(() => mccClosedDateStatus = value),
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
            pccClosedDateRange = null;
            mccClosedDateRange = null;
            startDateStatus = DateFilterType.any;
            deliveryDateStatus = DateFilterType.any;
            closedDateStatus = DateFilterType.any;
            pccClosedDateStatus = DateFilterType.any;
            mccClosedDateStatus = DateFilterType.any;
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
        onSave: (updatedPanel) => loadInitialData(),
        onDelete: () async {
          Navigator.of(context).pop();
          await DatabaseHelper.instance.deletePanel(dataToEdit.panel.noPp);
          loadInitialData();
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
        onSave: () => loadInitialData(),
      ),
    );
  }

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
      final bool matchSearch =
          allSearchTerms.isEmpty ||
          allSearchTerms.every((term) => isPanelMatch(term));

      final bool matchPanelType =
          selectedPanelTypes.isEmpty ||
          selectedPanelTypes.any(
            (type) => type == 'Belum Diatur'
                ? (panel.panelType == null || panel.panelType!.isEmpty)
                : panel.panelType == type,
          );

      final bool matchPanelVendor =
          selectedPanelVendors.isEmpty ||
          selectedPanelVendors.any((selectedId) {
            if (selectedId == 'No Vendor') {
              return panel.vendorId == null || panel.vendorId!.isEmpty;
            }
            return panel.vendorId == selectedId;
          });

      final bool matchBusbarVendor =
          selectedBusbarVendors.isEmpty ||
          selectedBusbarVendors.any((selectedId) {
            if (selectedId == 'No Vendor') return data.busbarVendorIds.isEmpty;
            return data.busbarVendorIds.contains(selectedId);
          });

      final bool matchComponentVendor =
          selectedComponentVendors.isEmpty ||
          selectedComponentVendors.any((selectedId) {
            if (selectedId == 'No Vendor') {
              return data.componentVendorIds.isEmpty;
            }
            return data.componentVendorIds.contains(selectedId);
          });

      final bool matchPaletVendor =
          selectedPaletVendors.isEmpty ||
          selectedPaletVendors.any((selectedId) {
            if (selectedId == 'No Vendor') return data.paletVendorIds.isEmpty;
            return data.paletVendorIds.contains(selectedId);
          });

      final bool matchCorepartVendor =
          selectedCorepartVendors.isEmpty ||
          selectedCorepartVendors.any((selectedId) {
            if (selectedId == 'No Vendor') {
              return data.corepartVendorIds.isEmpty;
            }
            return data.corepartVendorIds.contains(selectedId);
          });

      final bool matchPccStatus =
          selectedPccStatuses.isEmpty ||
          (panel.statusBusbarPcc != null &&
              selectedPccStatuses.contains(panel.statusBusbarPcc));

      final bool matchMccStatus =
          selectedMccStatuses.isEmpty ||
          (panel.statusBusbarMcc != null &&
              selectedMccStatuses.contains(panel.statusBusbarMcc));

      final bool matchComponent =
          selectedComponents.isEmpty ||
          selectedComponents.contains(panel.statusComponent);

      final bool matchPalet =
          selectedPalet.isEmpty || selectedPalet.contains(panel.statusPalet);

      final bool matchCorepart =
          selectedCorepart.isEmpty ||
          selectedCorepart.contains(panel.statusCorepart);

      bool checkDate(
        DateFilterType status,
        DateTimeRange? range,
        DateTime? date,
      ) {
        switch (status) {
          case DateFilterType.notSet:
            return date == null;
          case DateFilterType.set:
            return range == null ||
                (date != null &&
                    !date.isBefore(range.start) &&
                    !date.isAfter(range.end.add(const Duration(days: 1))));
          case DateFilterType.any:
            return true;
        }
      }

      final bool matchStartDate = checkDate(
        startDateStatus,
        startDateRange,
        panel.startDate,
      );
      final bool matchDeliveryDate = checkDate(
        deliveryDateStatus,
        deliveryDateRange,
        panel.targetDelivery,
      );
      final bool matchClosedDate = checkDate(
        closedDateStatus,
        closedDateRange,
        panel.closedDate,
      );
      final bool matchPccClosedDate = checkDate(
        pccClosedDateStatus,
        pccClosedDateRange,
        panel.closeDateBusbarPcc,
      );
      final bool matchMccClosedDate = checkDate(
        mccClosedDateStatus,
        mccClosedDateRange,
        panel.closeDateBusbarMcc,
      );

      final panelStatus = _getPanelFilterStatus(panel);
      final bool matchStatusAndArchive;
      if (panelStatus == PanelFilterStatus.closedArchived) {
        matchStatusAndArchive = includeArchived;
      } else {
        matchStatusAndArchive =
            selectedPanelStatuses.isEmpty ||
            selectedPanelStatuses.contains(panelStatus);
      }

      return matchSearch &&
          matchPanelType &&
          matchPanelVendor &&
          matchBusbarVendor &&
          matchComponentVendor &&
          matchPaletVendor &&
          matchCorepartVendor &&
          matchPccStatus &&
          matchMccStatus &&
          matchComponent &&
          matchPalet &&
          matchCorepart &&
          matchStartDate &&
          matchDeliveryDate &&
          matchClosedDate &&
          matchPccClosedDate &&
          matchMccClosedDate &&
          matchStatusAndArchive;
    }).toList();
  }

  List<PanelDisplayData> get filteredPanelsForDisplay {
    var tabFilteredPanels = _panelsAfterPrimaryFilters;
    final role = widget.currentCompany.role;

    switch (_tabController.index) {
      case 0:
        break;
      case 1:
        if (role == AppRole.k3) {
          tabFilteredPanels = tabFilteredPanels
              .where(
                (data) =>
                    data.panel.vendorId == null || data.panel.vendorId!.isEmpty,
              )
              .toList();
        } else if (role == AppRole.k5) {
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
                    data.panel.vendorId == null ||
                    data.panel.vendorId!.isEmpty ||
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
          bool isOpenVendor;
          if (role == AppRole.k3) {
            isOpenVendor =
                data.panel.vendorId == null || data.panel.vendorId!.isEmpty;
          } else if (role == AppRole.k5) {
            isOpenVendor = data.busbarVendorIds.isEmpty;
          } else if (role == AppRole.warehouse) {
            isOpenVendor = data.componentVendorIds.isEmpty;
          } else {
            isOpenVendor =
                data.panel.vendorId == null ||
                data.panel.vendorId!.isEmpty ||
                data.busbarVendorIds.isEmpty ||
                data.componentVendorIds.isEmpty ||
                data.paletVendorIds.isEmpty ||
                data.corepartVendorIds.isEmpty;
          }
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
    final baseFilteredList = _panelsAfterPrimaryFilters;
    final role = widget.currentCompany.role;

    final allCount = baseFilteredList.length;

    final openVendorCount = baseFilteredList.where((data) {
      if (role == AppRole.k3) {
        return data.panel.vendorId == null || data.panel.vendorId!.isEmpty;
      }
      if (role == AppRole.k5) {
        return data.busbarVendorIds.isEmpty;
      }
      if (role == AppRole.warehouse) {
        return data.componentVendorIds.isEmpty;
      }
      return data.panel.vendorId == null ||
          data.panel.vendorId!.isEmpty ||
          data.busbarVendorIds.isEmpty ||
          data.componentVendorIds.isEmpty ||
          data.paletVendorIds.isEmpty ||
          data.corepartVendorIds.isEmpty;
    }).length;

    final onGoingPanelCount = baseFilteredList.where((data) {
      final panel = data.panel;
      bool isReady = (panel.percentProgress ?? 0) >= 100 && !panel.isClosed;
      bool isOpen;
      if (role == AppRole.k3) {
        isOpen = data.panel.vendorId == null || data.panel.vendorId!.isEmpty;
      } else if (role == AppRole.k5) {
        isOpen = data.busbarVendorIds.isEmpty;
      } else if (role == AppRole.warehouse) {
        isOpen = data.componentVendorIds.isEmpty;
      } else {
        isOpen =
            data.panel.vendorId == null ||
            data.panel.vendorId!.isEmpty ||
            data.busbarVendorIds.isEmpty ||
            data.componentVendorIds.isEmpty ||
            data.paletVendorIds.isEmpty ||
            data.corepartVendorIds.isEmpty;
      }
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
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () {
                      setState(() {
                        _isChartView = !_isChartView;
                      });
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.grayLight),
                      ),
                      child: Icon(
                        _isChartView
                            ? Icons.list_alt_rounded
                            : Icons.bar_chart_rounded,
                        color: AppColors.gray,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
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
                        'assets/images/filter-gray.png',
                        width: 20,
                        height: 20,
                        color: AppColors.gray,
                      ),
                    ),
                  ),
                ],
              ),
              if (!_isChartView)
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
        Expanded(child: _isChartView ? _buildChartView() : _buildPanelView()),
      ],
    );
  }

  Widget _buildPanelView() {
    final panelsToDisplay = filteredPanelsForDisplay;

    if (panelsToDisplay.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 48.0),
          child: Text(
            "Tidak ada panel yang ditemukan",
            style: TextStyle(color: AppColors.gray, fontSize: 14),
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        const double gridBreakpoint = 740;

        if (constraints.maxWidth < gridBreakpoint) {
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
            itemCount: panelsToDisplay.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final data = panelsToDisplay[index];
              final panel = data.panel;
              return PanelProgressCard(
                currentUserRole: widget.currentCompany.role,
                targetDelivery: panel.targetDelivery,
                duration: _formatDuration(panel.startDate),
                progress: (panel.percentProgress ?? 0) / 100.0,
                startDate: panel.startDate,
                progressLabel: "${panel.percentProgress?.toInt() ?? 0}%",
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
                  } else if (role == AppRole.k5 || role == AppRole.warehouse) {
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
          final int crossAxisCount = (constraints.maxWidth / 500).floor().clamp(
            2,
            4,
          );

          return GridView.builder(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              mainAxisExtent: 440,
            ),
            itemCount: panelsToDisplay.length,
            itemBuilder: (context, index) {
              final data = panelsToDisplay[index];
              final panel = data.panel;
              return PanelProgressCard(
                currentUserRole: widget.currentCompany.role,
                targetDelivery: panel.targetDelivery,
                duration: _formatDuration(panel.startDate),
                progress: (panel.percentProgress ?? 0) / 100.0,
                startDate: panel.startDate,
                progressLabel: "${panel.percentProgress?.toInt() ?? 0}%",
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
                  } else if (role == AppRole.k5 || role == AppRole.warehouse) {
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
    );
  }

  Map<String, dynamic> _calculateDeliveryByTime(
    List<PanelDisplayData> panels,
    List<String> Function(PanelDisplayData) getVendors, {
    required ChartTimeView view,
    required List<String> allPossibleVendors,
  }) {
    final Map<String, Map<String, int>> counts = {};
    final now = DateTime.now();

    late DateTime timeLimit;
    late DateFormat keyFormat;
    late int limit;

    switch (view) {
      case ChartTimeView.daily:
        timeLimit = DateTime(now.year, now.month, now.day - 6);
        keyFormat = DateFormat('E, d MMM', 'id_ID'); // Format: Sen, 17 Sep
        limit = 7;
        break;
      case ChartTimeView.monthly:
        timeLimit = DateTime(now.year, now.month - 4, 1);
        keyFormat = DateFormat('MMMM yyyy', 'id_ID');
        limit = 5;
        break;
      case ChartTimeView.yearly:
        timeLimit = DateTime(now.year - 4, 1, 1);
        keyFormat = DateFormat('yyyy');
        limit = 5;
        break;
    }

    final relevantPanels = panels.where(
      (data) =>
          data.panel.closedDate != null &&
          data.panel.closedDate!.isAfter(
            timeLimit.subtract(const Duration(days: 1)),
          ) &&
          data.panel.closedDate!.isBefore(now.add(const Duration(days: 1))),
    );

    for (var data in relevantPanels) {
      final date = data.panel.closedDate!;
      final key = keyFormat.format(date);

      final vendorsFromPanel = getVendors(data);
      if (!counts.containsKey(key)) {
        counts[key] = {};
      }

      for (var vendor in vendorsFromPanel) {
        if (vendor.isNotEmpty && allPossibleVendors.contains(vendor)) {
          counts[key]![vendor] = (counts[key]![vendor] ?? 0) + 1;
        }
      }
    }

    final sortedKeys = counts.keys.toList()
      ..sort((a, b) {
        try {
          return keyFormat.parse(a).compareTo(keyFormat.parse(b));
        } catch (e) {
          return a.compareTo(b);
        }
      });

    final limitedKeys = sortedKeys.length > limit
        ? sortedKeys.sublist(sortedKeys.length - limit)
        : sortedKeys;
    final sortedMap = {for (var k in limitedKeys) k: counts[k]!};

    final sortedVendors = allPossibleVendors..sort();
    return {'data': sortedMap, 'vendors': sortedVendors};
  }

  Widget _buildChartView() {
    _prepareChartData();

    final panelsToDisplay = filteredPanelsForDisplay;

    if (panelsToDisplay.isEmpty && _allPanelsData.isNotEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 48.0),
          child: Text(
            "Tidak ada data untuk divisualisasikan\ndengan filter saat ini.",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.gray,
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          _buildGroupedBarChartCard(
            title: "Delivered Panel",
            chartData: _panelChartData,
            currentView: _panelChartView,
            onToggle: (newView) {
              setState(() {
                _panelChartView = newView;
              });
            },
          ),
          const SizedBox(height: 24),
          _buildGroupedBarChartCard(
            title: "Delivered Busbar",
            chartData: _busbarChartData,
            currentView: _busbarChartView,
            onToggle: (newView) {
              setState(() {
                _busbarChartView = newView;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildGroupedBarChartCard({
    required String title,
    required Map<String, dynamic> chartData,
    required ChartTimeView currentView,
    required ValueChanged<ChartTimeView> onToggle,
  }) {
    final Map<String, Map<String, int>> data =
        (chartData['data'] as Map<String, Map<String, int>>? ?? {});
    final List<String> vendors = (chartData['vendors'] as List<String>? ?? []);

    final List<Color> colorPalette = [
      AppColors.schneiderGreen, // Hijau
      const Color(0xFFFF5DD1), // Hijau
      const Color(0xFF0400FF), // Hijau
      const Color(0xFFFF9E50), // Hijau
      const Color(0xFFFF0000), // Hijau
    ];
    final Map<String, Color> vendorColors = {
      for (int i = 0; i < vendors.length; i++)
        vendors[i]: colorPalette[i % colorPalette.length],
    };

    double maxValue = 0;
    data.values.forEach((vendorMap) {
      vendorMap.values.forEach((count) {
        if (count > maxValue) {
          maxValue = count.toDouble();
        }
      });
    });
    if (maxValue == 0) maxValue = 50;

    // Widget untuk tombol-tombol filter (Daily, Monthly, Yearly)
    // Dibuat terpisah agar tidak duplikasi kode
    Widget buildToggleButtons() {
      Widget buildToggleButton(String text, ChartTimeView view) {
        final isSelected = currentView == view;
        return GestureDetector(
          onTap: () => onToggle(view),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
            decoration: BoxDecoration(
              color: isSelected ? Colors.white : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: isSelected
                  ? Border.all(color: AppColors.grayLight)
                  : null,
            ),
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: isSelected ? AppColors.black : AppColors.gray,
              ),
            ),
          ),
        );
      }

      return Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: AppColors.grayLight.withOpacity(0.5),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            buildToggleButton("Daily", ChartTimeView.daily),
            buildToggleButton("Monthly", ChartTimeView.monthly),
            buildToggleButton("Yearly", ChartTimeView.yearly),
          ],
        ),
      );
    }

    // Widget untuk judul
    Widget buildTitle() {
      return Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: AppColors.black,
        ),
      );
    }

    // Definisikan konstanta untuk kalkulasi lebar chart
    const double barWidth = 24.0;
    const double barsSpace = 6.0;
    const double groupsSpace = 32.0;

    final double widthPerGroup = vendors.isEmpty
        ? barWidth
        : (vendors.length * barWidth) + ((vendors.length - 1) * barsSpace);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.grayLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 400) {
                // TAMPILAN LAYAR KECIL (HP) -> Column
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    buildTitle(),
                    const SizedBox(height: 12),
                    buildToggleButtons(),
                  ],
                );
              } else {
                // TAMPILAN LAYAR LEBAR -> Row
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: buildTitle()),
                    buildToggleButtons(),
                  ],
                );
              }
            },
          ),
          const SizedBox(height: 16),
          if (vendors.isNotEmpty)
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: vendors.map((vendor) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: vendorColors[vendor],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(vendor, style: const TextStyle(fontSize: 12)),
                  ],
                );
              }).toList(),
            ),
          const SizedBox(height: 24),
          SizedBox(
            height: 250,
            child: data.isEmpty
                ? const Center(
                    child: Text(
                      "Tidak ada data delivery\nyang sesuai filter.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.gray,
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  )
                : LayoutBuilder(
                    builder: (context, constraints) {
                      final double calculatedWidth =
                          (data.keys.length * widthPerGroup) +
                          ((data.keys.length - 1) * groupsSpace);

                      final double availableWidth = constraints.maxWidth;
                      final double finalChartWidth = math.max(
                        availableWidth,
                        calculatedWidth,
                      );

                      return SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SizedBox(
                          width: finalChartWidth,
                          child: BarChart(
                            BarChartData(
                              alignment: calculatedWidth < availableWidth
                                  ? BarChartAlignment.spaceAround
                                  : BarChartAlignment.start,
                              groupsSpace: groupsSpace,
                              maxY: maxValue * 1.25,
                              barTouchData: BarTouchData(
                                handleBuiltInTouches: false,
                                touchTooltipData: BarTouchTooltipData(
                                  getTooltipColor: (_) => Colors.transparent,
                                  tooltipPadding: EdgeInsets.zero,
                                  tooltipMargin: 8,
                                  getTooltipItem:
                                      (group, groupIndex, rod, rodIndex) {
                                        if (rod.toY == 0) return null;
                                        return BarTooltipItem(
                                          rod.toY.round().toString(),
                                          const TextStyle(
                                            color: AppColors.black,
                                            fontWeight: FontWeight.w400,
                                            fontSize: 14,
                                          ),
                                        );
                                      },
                                ),
                              ),
                              titlesData: FlTitlesData(
                                show: true,
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget:
                                        (double value, TitleMeta meta) {
                                          final index = value.toInt();
                                          if (index >= data.keys.length) {
                                            return const SizedBox.shrink();
                                          }
                                          final key = data.keys.elementAt(
                                            index,
                                          );
                                          final title =
                                              currentView ==
                                                  ChartTimeView.monthly
                                              ? key.split(' ')[0]
                                              : currentView ==
                                                    ChartTimeView.daily
                                              ? key.replaceAll(', ', '\n')
                                              : key;
                                          return SideTitleWidget(
                                            axisSide: meta.axisSide,
                                            space: 8.0,
                                            child: Text(
                                              title,
                                              textAlign: TextAlign.center,
                                              style: const TextStyle(
                                                fontSize: 10,
                                                color: AppColors.gray,
                                              ),
                                            ),
                                          );
                                        },
                                    reservedSize: 38,
                                  ),
                                ),
                                leftTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                topTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                rightTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                              ),
                              borderData: FlBorderData(show: false),
                              gridData: const FlGridData(show: false),
                              barGroups: List.generate(data.keys.length, (
                                index,
                              ) {
                                final monthKey = data.keys.elementAt(index);
                                final vendorCounts = data[monthKey]!;
                                return BarChartGroupData(
                                  x: index,
                                  barsSpace: barsSpace,
                                  showingTooltipIndicators: List.generate(
                                    vendors.length,
                                    (i) => i,
                                  ),
                                  barRods: List.generate(vendors.length, (
                                    vendorIndex,
                                  ) {
                                    final vendorName = vendors[vendorIndex];
                                    final count =
                                        vendorCounts[vendorName]?.toDouble() ??
                                        0;
                                    final bool isZero = count == 0;
                                    final Color barColor =
                                        vendorColors[vendorName] ?? Colors.grey;

                                    // --- KODE BARU DENGAN LOGIKA HINT ---
                                    return BarChartRodData(
                                      // Jika nilainya 0, beri tinggi minimal agar terlihat. Jika tidak, gunakan nilai asli.
                                      toY: isZero ? 0.1 : count,

                                      // Jika nilainya 0, buat warna menjadi transparan. Jika tidak, gunakan warna solid.
                                      color: barColor.withOpacity(
                                        isZero ? 1.0 : 1.0,
                                      ),

                                      width: barWidth,
                                      borderRadius: isZero
                                          ? BorderRadius.circular(2)
                                          : BorderRadius.circular(6),
                                    );
                                  }),
                                );
                              }),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // --- Widget Skeleton (tidak ada perubahan) ---
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
