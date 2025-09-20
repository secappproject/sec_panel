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

// --- CLASS HELPER UNTUK DATA TABEL ---
class _ProjectWbsSummary {
  final String project;
  final String wbs;
  final int count;

  _ProjectWbsSummary({
    required this.project,
    required this.wbs,
    required this.count,
  });
}

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
  ChartTimeView _projectChartView = ChartTimeView.monthly;
  bool _isPanelMonthly = true;
  bool _isBusbarMonthly = true;
  Map<String, dynamic> _panelChartData = {};
  Map<String, dynamic> _busbarChartData = {};
  Map<String, dynamic> _projectChartData = {};

  // --- BARU: State untuk filter dropdown di chart ---
  int _selectedYear = DateTime.now().year;
  int _selectedMonth = DateTime.now().month;
  int? _selectedWeek; // Bisa null, artinya "semua minggu"
  int? _selectedQuartile = (DateTime.now().month / 3).ceil(); // Diubah menjadi nullable

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
  List<String> selectedStatuses = [];
  List<String> selectedComponents = [];
  List<String> selectedPalet = [];
  List<String> selectedCorepart = [];
  List<String> selectedPanelTypes = [];
  IssueFilter selectedIssueStatus = IssueFilter.any;
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

    // --- BARU: Mengirim state filter ke fungsi kalkulasi ---
    _panelChartData = _calculateDeliveryByTime(
      panelsToDisplay,
      (data) => [
        data.panelVendorName.isNotEmpty ? data.panelVendorName : "No Vendor",
      ],
      view: _panelChartView,
      allPossibleVendors: allPanelVendorNames,
      year: _selectedYear,
      month: _selectedMonth,
      week: _selectedWeek,
      quartile: _selectedQuartile,
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
      year: _selectedYear,
      month: _selectedMonth,
      week: _selectedWeek,
      quartile: _selectedQuartile,
    );

    _projectChartData = _calculateDeliveryByProject(
      panelsToDisplay,
      view: _projectChartView,
      year: _selectedYear,
      month: _selectedMonth,
      week: _selectedWeek,
      quartile: _selectedQuartile,
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
        selectedIssueStatus: selectedIssueStatus,
        selectedStatuses: selectedStatuses,
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
        onStatusesChanged: (value) =>
            setState(() => selectedStatuses = value),
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
        onIssueStatusChanged: (value) =>
            setState(() => selectedIssueStatus = value),
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
            selectedStatuses = [];
            selectedComponents = [];
            selectedPalet = [];
            selectedIssueStatus = IssueFilter.any;
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
    if (progress == 0) return PanelFilterStatus.progressGrey;
    if (progress > 0 && progress < 50) return PanelFilterStatus.progressRed;
    if (progress >= 50 && progress < 75) return PanelFilterStatus.progressOrange;
    if (progress < 100) return PanelFilterStatus.progressBlue;
    if (progress >= 100) {
      if (!panel.isClosed) return PanelFilterStatus.readyToDelivery;
      if (panel.closedDate != null &&
          DateTime.now().difference(panel.closedDate!).inHours > 48) {
        return PanelFilterStatus.closedArchived;
      }
      return PanelFilterStatus.closed;
    }
    return PanelFilterStatus.progressGrey;
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

      final bool matchStatus =
          selectedStatuses.isEmpty ||
          (panel.statusBusbarPcc != null &&
              selectedStatuses.contains(panel.statusBusbarPcc));

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
      final bool matchIssueStatus;
      switch (selectedIssueStatus) {
        case IssueFilter.withIssues:
          matchIssueStatus = data.issueCount > 0;
          break;
        case IssueFilter.withoutIssues:
          matchIssueStatus = data.issueCount == 0;
          break;
        case IssueFilter.any:
        default:
          matchIssueStatus = true;
          break;
      }

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
          matchIssueStatus &&
          matchPanelVendor &&
          matchBusbarVendor &&
          matchComponentVendor &&
          matchPaletVendor &&
          matchCorepartVendor &&
          matchStatus &&
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
                      child:
                          _isChartView? Image.asset(
                            'assets/images/panel.png',
                            height: 20,
                          ):Image.asset(
                            'assets/images/graph.png',
                            height: 20,
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
                issueCount: data.issueCount ?? 0,
                currentUserRole: widget.currentCompany.role,
                targetDelivery: panel.targetDelivery,
                duration: _formatDuration(panel.startDate),
                progress: (panel.percentProgress ?? 0) / 100.0,
                startDate: panel.startDate,
                progressLabel: "${panel.percentProgress?.toInt() ?? 0}%",
                panelType: panel.panelType ?? "",
                panelTitle: panel.noPanel ?? "",
                panelRemarks: panel.remarks,
                statusBusbar: panel.statusBusbarPcc ?? "",
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
                issueCount: data.issueCount ?? 0,
                currentUserRole: widget.currentCompany.role,
                targetDelivery: panel.targetDelivery,
                duration: _formatDuration(panel.startDate),
                progress: (panel.percentProgress ?? 0) / 100.0,
                startDate: panel.startDate,
                progressLabel: "${panel.percentProgress?.toInt() ?? 0}%",
                panelType: panel.panelType ?? "",
                panelTitle: panel.noPanel ?? "",
                panelRemarks: panel.remarks,
                statusBusbar: panel.statusBusbarPcc ?? "",
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

  // --- BARU: Helper untuk menghitung jumlah minggu dalam sebulan ---
  int _getWeeksInMonth(int year, int month) {
    final firstDay = DateTime(year, month, 1);
    final lastDay = DateTime(year, month + 1, 0);
    // Hitung hari dari Senin pertama hingga hari terakhir
    final days = lastDay.day + (firstDay.weekday - 1);
    return (days / 7).ceil();
  }

  Map<String, dynamic> _calculateDeliveryByTime(
    List<PanelDisplayData> panels,
    List<String> Function(PanelDisplayData) getVendors, {
    required ChartTimeView view,
    required List<String> allPossibleVendors,
    // --- BARU: parameter filter ---
    required int year,
    required int month,
    int? week,
    int? quartile,
  }) {
    final Map<String, Map<String, int>> counts = {};
    late DateTimeRange displayRange;
    late DateFormat keyFormat;
    late int limit;
    final now = DateTime.now();

    switch (view) {
      case ChartTimeView.daily:
        keyFormat = DateFormat('E, d', 'id_ID'); // Format: Sen, 17
        if (week != null) {
          // Tampilkan 7 hari dalam minggu yang dipilih
          final firstDayOfMonth = DateTime(year, month, 1);
          final dayOfWeekOffset = (1 - firstDayOfMonth.weekday + 7) % 7;
          final firstMonday = firstDayOfMonth.subtract(Duration(days: dayOfWeekOffset));
          final startDate = firstMonday.add(Duration(days: (week - 1) * 7));
          displayRange = DateTimeRange(start: startDate, end: startDate.add(const Duration(days: 6)));
        } else {
          // Tampilkan seluruh bulan
          displayRange = DateTimeRange(
            start: DateTime(year, month, 1),
            end: DateTime(year, month + 1, 0),
          );
        }
        break;
      case ChartTimeView.monthly:
        if (quartile == null) { // KONDISI BARU: Jika "Semua Bulan" dipilih
            keyFormat = DateFormat('MMM', 'id_ID'); // Format: Jan, Feb, Mar
            displayRange = DateTimeRange(
              start: DateTime(year, 1, 1),
              end: DateTime(year, 12, 31),
            );
        } else { // LOGIKA LAMA: Jika Kuartal dipilih
            keyFormat = DateFormat('MMM yyyy', 'id_ID');
            final startMonth = (quartile - 1) * 3 + 1;
            displayRange = DateTimeRange(
              start: DateTime(year, startMonth, 1),
              end: DateTime(year, startMonth + 3, 0),
            );
        }
        break;
      case ChartTimeView.yearly:
        keyFormat = DateFormat('yyyy');
        displayRange = DateTimeRange(
          start: DateTime(now.year - 4, 1, 1),
          end: DateTime(now.year, 12, 31),
        );
        limit = 5;
        break;
    }

    final relevantPanels = panels.where(
      (data) =>
          data.panel.closedDate != null &&
          !data.panel.closedDate!.isBefore(displayRange.start) &&
          !data.panel.closedDate!.isAfter(displayRange.end.add(const Duration(days: 1))),
    );

    for (var data in relevantPanels) {
      final date = data.panel.closedDate!;
      final key = keyFormat.format(date);
      final vendorsFromPanel = getVendors(data);
      counts.putIfAbsent(key, () => {});
      for (var vendor in vendorsFromPanel) {
        if (vendor.isNotEmpty && allPossibleVendors.contains(vendor)) {
          counts[key]![vendor] = (counts[key]![vendor] ?? 0) + 1;
        }
      }
    }

    // --- BARU: Pastikan semua label ada di chart ---
    final allKeys = <String>{};
    if (view == ChartTimeView.daily && week == null) { // Tampilkan semua tanggal di bulan
      for (int i = 0; i < displayRange.duration.inDays + 1; i++) {
        allKeys.add(keyFormat.format(displayRange.start.add(Duration(days: i))));
      }
    } else if (view == ChartTimeView.daily && week != null) { // Tampilkan 7 hari di minggu
        for (int i = 0; i < 7; i++) {
        allKeys.add(keyFormat.format(displayRange.start.add(Duration(days: i))));
      }
    } else if (view == ChartTimeView.monthly) { // Logika baru untuk label bulan/kuartal
      if (quartile == null) { // Jika "Semua Bulan", buat label untuk 12 bulan
          for (int i = 1; i <= 12; i++) {
            allKeys.add(keyFormat.format(DateTime(year, i)));
          }
      } else { // Jika Kuartal, buat label untuk 3 bulan
          for (int i = 0; i < 3; i++) {
            allKeys.add(keyFormat.format(DateTime(year, (quartile - 1) * 3 + 1 + i)));
          }
      }
    } else { // Yearly
      for (int i = 0; i < limit; i++) {
        allKeys.add(keyFormat.format(DateTime(now.year - (limit - 1) + i)));
      }
    }

    for (final key in allKeys) {
      counts.putIfAbsent(key, () => {});
    }

    final sortedKeys = counts.keys.toList()
      ..sort((a, b) {
        try {
          return keyFormat.parse(a).compareTo(keyFormat.parse(b));
        } catch (e) {
          return a.compareTo(b);
        }
      });

    final finalKeys = (view == ChartTimeView.yearly && sortedKeys.length > limit)
        ? sortedKeys.sublist(sortedKeys.length - limit)
        : sortedKeys;

    final sortedMap = {for (var k in finalKeys) k: counts[k]!};
    final sortedVendors = allPossibleVendors..sort();
    return {'data': sortedMap, 'vendors': sortedVendors};
  }

  Map<String, dynamic> _calculateDeliveryByProject(
    List<PanelDisplayData> panels, {
    required ChartTimeView view,
    // --- BARU: parameter filter ---
    required int year,
    required int month,
    int? week,
    int? quartile,
  }) {
    final Map<String, Map<String, int>> counts = {};
    late DateTimeRange displayRange;
    late DateFormat keyFormat;
    late int limit;
    final now = DateTime.now();

    // --- BARU: Logika penentuan rentang waktu disamakan dengan _calculateDeliveryByTime ---
    switch (view) {
      case ChartTimeView.daily:
        keyFormat = DateFormat('E, d', 'id_ID');
        if (week != null) {
          final firstDayOfMonth = DateTime(year, month, 1);
          final dayOfWeekOffset = (1 - firstDayOfMonth.weekday + 7) % 7;
          final firstMonday = firstDayOfMonth.subtract(Duration(days: dayOfWeekOffset));
          final startDate = firstMonday.add(Duration(days: (week - 1) * 7));
          displayRange = DateTimeRange(start: startDate, end: startDate.add(const Duration(days: 6)));
        } else {
          displayRange = DateTimeRange(
            start: DateTime(year, month, 1),
            end: DateTime(year, month + 1, 0),
          );
        }
        break;
      case ChartTimeView.monthly:
        if (quartile == null) { // KONDISI BARU: Jika "Semua Bulan" dipilih
            keyFormat = DateFormat('MMM', 'id_ID');
            displayRange = DateTimeRange(
              start: DateTime(year, 1, 1),
              end: DateTime(year, 12, 31),
            );
        } else { // LOGIKA LAMA: Jika Kuartal dipilih
            keyFormat = DateFormat('MMM yyyy', 'id_ID');
            final startMonth = (quartile - 1) * 3 + 1;
            displayRange = DateTimeRange(
              start: DateTime(year, startMonth, 1),
              end: DateTime(year, startMonth + 3, 0),
            );
        }
        break;
      case ChartTimeView.yearly:
        keyFormat = DateFormat('yyyy');
        displayRange = DateTimeRange(
          start: DateTime(now.year - 4, 1, 1),
          end: DateTime(now.year, 12, 31),
        );
        limit = 5;
        break;
    }

    final relevantPanels = panels.where(
      (data) =>
          data.panel.closedDate != null &&
          !data.panel.closedDate!.isBefore(displayRange.start) &&
          !data.panel.closedDate!.isAfter(displayRange.end.add(const Duration(days: 1))),
    );

    final allPossibleProjects = relevantPanels
        .where(
          (p) => p.panel.project != null && p.panel.project!.trim().isNotEmpty,
        )
        .map((p) => p.panel.project!.trim())
        .toSet()
        .toList();

    if (relevantPanels.any(
      (p) => p.panel.project == null || p.panel.project!.trim().isEmpty,
    )) {
      if (!allPossibleProjects.contains("No Project")) {
        allPossibleProjects.add("No Project");
      }
    }

    for (var data in relevantPanels) {
      final date = data.panel.closedDate!;
      final key = keyFormat.format(date);
      final projectName = data.panel.project?.trim();
      final finalProjectName = (projectName == null || projectName.isEmpty)
          ? "No Project"
          : projectName;

      counts.putIfAbsent(key, () => {});
      counts[key]![finalProjectName] = (counts[key]![finalProjectName] ?? 0) + 1;
    }

    // --- BARU: Pastikan semua label ada di chart ---
    final allKeys = <String>{};
    if (view == ChartTimeView.daily && week == null) { // Tampilkan semua tanggal di bulan
      for (int i = 0; i < displayRange.duration.inDays + 1; i++) {
        allKeys.add(keyFormat.format(displayRange.start.add(Duration(days: i))));
      }
    } else if (view == ChartTimeView.daily && week != null) { // Tampilkan 7 hari di minggu
        for (int i = 0; i < 7; i++) {
        allKeys.add(keyFormat.format(displayRange.start.add(Duration(days: i))));
      }
    } else if (view == ChartTimeView.monthly) { // Logika baru untuk label bulan/kuartal
        if (quartile == null) { // Jika "Semua Bulan", buat label untuk 12 bulan
            for (int i = 1; i <= 12; i++) {
                allKeys.add(keyFormat.format(DateTime(year, i)));
            }
        } else { // Jika Kuartal, buat label untuk 3 bulan
            for (int i = 0; i < 3; i++) {
                allKeys.add(keyFormat.format(DateTime(year, (quartile - 1) * 3 + 1 + i)));
            }
        }
    } else { // Yearly
      for (int i = 0; i < limit; i++) {
        allKeys.add(keyFormat.format(DateTime(now.year - (limit - 1) + i)));
      }
    }

    for (final key in allKeys) {
      counts.putIfAbsent(key, () => {});
    }

    final sortedKeys = counts.keys.toList()
      ..sort((a, b) {
        try {
          return keyFormat.parse(a).compareTo(keyFormat.parse(b));
        } catch (e) {
          return a.compareTo(b);
        }
      });

    final finalKeys = (view == ChartTimeView.yearly && sortedKeys.length > limit)
        ? sortedKeys.sublist(sortedKeys.length - limit)
        : sortedKeys;

    final sortedMap = {for (var k in finalKeys) k: counts[k]!};
    final sortedProjects = allPossibleProjects..sort();
    return {'data': sortedMap, 'projects': sortedProjects};
  }


  Widget _buildChartView() {
    _prepareChartData();

    final panelsToDisplay = filteredPanelsForDisplay;

    // --- FIX 1: Filter data untuk tabel sesuai dengan filter waktu chart ---
    final now = DateTime.now();
    late DateTime timeLimit;

    switch (_projectChartView) {
      case ChartTimeView.daily:
        timeLimit = DateTime(now.year, now.month, now.day - 6);
        break;
      case ChartTimeView.monthly:
        timeLimit = DateTime(now.year, now.month - 4, 1);
        break;
      case ChartTimeView.yearly:
        timeLimit = DateTime(now.year - 4, 1, 1);
        break;
    }

    final relevantDeliveredPanels = panelsToDisplay.where(
      (data) =>
          data.panel.isClosed &&
          data.panel.closedDate != null &&
          data.panel.closedDate!.isAfter(
            timeLimit.subtract(const Duration(days: 1)),
          ) &&
          data.panel.closedDate!.isBefore(now.add(const Duration(days: 1))),
    );
    // --- AKHIR DARI FIX 1 ---

    final Map<String, int> summaryCount = {};

    // Gunakan data yang sudah difilter waktu
    for (final data in relevantDeliveredPanels) {
      final project = data.panel.project?.trim();
      final finalProject = (project == null || project.isEmpty)
          ? "No Project"
          : project;
      final wbs = data.panel.noWbs?.trim();
      final finalWbs = (wbs == null || wbs.isEmpty) ? "No WBS" : wbs;
      final key = "$finalProject|$finalWbs";
      summaryCount[key] = (summaryCount[key] ?? 0) + 1;
    }

    final summaryList = summaryCount.entries.map((entry) {
      final parts = entry.key.split('|');
      return _ProjectWbsSummary(
        project: parts[0],
        wbs: parts[1],
        count: entry.value,
      );
    }).toList();

    summaryList.sort((a, b) {
      int projectComp = a.project.toLowerCase().compareTo(
            b.project.toLowerCase(),
          );
      if (projectComp != 0) return projectComp;
      return a.wbs.toLowerCase().compareTo(b.wbs.toLowerCase());
    });

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

    return LayoutBuilder(
      builder: (context, constraints) {
        const double breakpoint = 800.0;
        final bool isDesktop = constraints.maxWidth >= breakpoint;

        if (isDesktop) {
          // Layout untuk Desktop/Layar Lebar
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildGroupedBarChartCard(
                        title: "Delivered (Closed) Panel",
                        chartData: _panelChartData,
                        currentView: _panelChartView,
                        onToggle: (newView) {
                          setState(() {
                            _panelChartView = newView;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: _buildGroupedBarChartCard(
                        title: "Delivered (Closed) Busbar",
                        chartData: _busbarChartData,
                        currentView: _busbarChartView,
                        onToggle: (newView) {
                          setState(() {
                            _busbarChartView = newView;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildProjectSummaryCard(
                  chartData: _projectChartData,
                  summaryData: summaryList,
                  currentView: _projectChartView,
                  onToggle: (newView) {
                    setState(() {
                      _projectChartView = newView;
                    });
                  },
                ),
              ],
            ),
          );
        } else {
          // Layout untuk Mobile/Layar Kecil
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildGroupedBarChartCard(
                  title: "Delivered (Closed) Panel",
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
                  title: "Delivered (Closed) Busbar",
                  chartData: _busbarChartData,
                  currentView: _busbarChartView,
                  onToggle: (newView) {
                    setState(() {
                      _busbarChartView = newView;
                    });
                  },
                ),
                const SizedBox(height: 24),
                _buildProjectSummaryCard(
                  chartData: _projectChartData,
                  summaryData: summaryList,
                  currentView: _projectChartView,
                  onToggle: (newView) {
                    setState(() {
                      _projectChartView = newView;
                    });
                  },
                ),
              ],
            ),
          );
        }
      },
    );
  }

  // --- WIDGET HELPER BARU: HANYA UNTUK TOMBOL TOGGLE ---
  Widget _buildToggleButtons({
    required ChartTimeView currentView,
    required ValueChanged<ChartTimeView> onToggle,
  }) {
    Widget buildToggleButton(String text, ChartTimeView view) {
      final isSelected = currentView == view;
      return GestureDetector(
        onTap: () => onToggle(view),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: isSelected ? Border.all(color: AppColors.grayLight) : null,
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

  // --- BARU: Widget untuk dropdown filter di chart ---
  Widget _buildChartFilterDropdowns({
    required ChartTimeView currentView,
  }) {
    // Dropdown Item Style
    final dropdownStyle = TextStyle(
      fontSize: 12,
      color: Colors.grey[700],
      fontWeight: FontWeight.w400,
    );

    // Dropdown Years
    final yearItems = List.generate(
      5,
      (index) => DropdownMenuItem<int>(
        value: DateTime.now().year - index,
        child: Text('${DateTime.now().year - index}', style: dropdownStyle),
      ),
    );

    // Dropdown Months
    final monthItems = List.generate(
      12,
      (index) => DropdownMenuItem<int>(
        value: index + 1,
        child: Text(
          DateFormat('MMMM', 'id_ID').format(DateTime(0, index + 1)),
          style: dropdownStyle,
        ),
      ),
    );

    // Dropdown Weeks
    final weekCount = _getWeeksInMonth(_selectedYear, _selectedMonth);
    final weekItems = [
      DropdownMenuItem<int?>(
        value: null,
        child: Text("All Week", style: dropdownStyle),
      ),
      ...List.generate(
        weekCount,
        (index) => DropdownMenuItem<int?>(
          value: index + 1,
          child: Text("Week ${index + 1}", style: dropdownStyle),
        ),
      )
    ];

    Widget buildDropdown<T>({
      required T value,
      required List<DropdownMenuItem<T>> items,
      required ValueChanged<T?> onChanged,
      required String hint,
    }) {
      return Container(
        height: 30,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppColors.grayLight),
        ),
        child: DropdownButton<T>(
          value: value,
          items: items,
          onChanged: onChanged,
          underline: const SizedBox(),
          isExpanded: false,
          icon: const Icon(Icons.keyboard_arrow_down, size: 16),
          hint: Text(hint, style: dropdownStyle),

          // --- PENYESUAIAN DESAIN DROPDOWN ---
          dropdownColor: Colors.white,
          borderRadius: BorderRadius.circular(6),
          elevation: 2,
          // ---------------------------------
        ),
      );
    }

    if (currentView == ChartTimeView.daily) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Tahun
          buildDropdown<int>(
            value: _selectedYear,
            items: yearItems,
            hint: 'Tahun',
            onChanged: (val) {
              if (val != null) setState(() => _selectedYear = val);
            },
          ),
          const SizedBox(width: 8),
          // Bulan
          buildDropdown<int>(
            value: _selectedMonth,
            items: monthItems,
            hint: 'Bulan',
            onChanged: (val) {
              if (val != null) {
                setState(() {
                  _selectedMonth = val;
                  _selectedWeek = null; // Reset minggu jika bulan berubah
                });
              }
            },
          ),
            const SizedBox(width: 8),
          // Minggu
          buildDropdown<int?>(
            value: _selectedWeek,
            items: weekItems,
            hint: 'Minggu',
            onChanged: (val) {
              setState(() => _selectedWeek = val);
            },
          ),
        ],
      );
    } else if (currentView == ChartTimeView.monthly) {
        return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
                // Tahun (tidak berubah)
                buildDropdown<int>(
                    value: _selectedYear,
                    items: yearItems,
                    hint: 'Tahun',
                    onChanged: (val) {
                        if (val != null) setState(() => _selectedYear = val);
                    },
                ),
                const SizedBox(width: 8),

                // Kuartal (dengan opsi "Semua Bulan")
                buildDropdown<int?>( // Tipe datanya diubah ke int?
                    value: _selectedQuartile,
                    items: [
                        // Item baru untuk "Semua Bulan"
                        DropdownMenuItem<int?>(
                            value: null, // 'null' merepresentasikan "Semua Bulan"
                            child: Text("All Week", style: dropdownStyle),
                        ),
                        // Item untuk Kuartal 1-4
                        ...List.generate(
                            4,
                            (index) => DropdownMenuItem<int?>(
                                value: index + 1,
                                child: Text("Q${index + 1}", style: dropdownStyle),
                            ),
                        )
                    ],
                    hint: 'Periode',
                    onChanged: (val) {
                        setState(() => _selectedQuartile = val);
                    },
                ),
            ],
        );
    }

    return const SizedBox.shrink(); // Tampilan yearly tidak punya dropdown
  }


  // --- WIDGET HELPER BARU: HANYA UNTUK KONTEN CHART PROJECT ---
  Widget _buildProjectBarChartItself({
    required Map<String, dynamic> chartData,
  }) {
    final Map<String, Map<String, int>> data =
        (chartData['data'] as Map<String, Map<String, int>>? ?? {});
    final List<String> projects =
        (chartData['projects'] as List<String>? ?? []);

    final List<Color> colorPalette = [
      const Color(0xFF1D20E4),
      const Color(0xFFED1B3A),
      const Color(0xFFFEB019),
      const Color(0xFF09AF77),
      const Color(0xFF008FFB),
      const Color(0xFFFF5DD1),
      const Color(0xFF5D5FFF),
      const Color(0xFFC83CFF),
    ];
    final Map<String, Color> projectColors = {
      for (int i = 0; i < projects.length; i++)
        projects[i]: colorPalette[i % colorPalette.length],
    };

    double maxValue = 0;
    data.values.forEach((projectMap) {
      double groupTotal = 0;
      projectMap.values.forEach((count) {
        groupTotal += count;
      });
      if (groupTotal > maxValue) {
        maxValue = groupTotal;
      }
    });
    if (maxValue == 0) maxValue = 50;

    const double barWidth = 24.0;
    const double barsSpace = 4.0;
    const double groupsSpace = 24.0;
    final double widthPerGroup = projects.isEmpty
        ? barWidth
        : (projects.length * barWidth) + ((projects.length - 1) * barsSpace);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (projects.isNotEmpty)
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: projects.map((project) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: projectColors[project],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      project,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w300,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
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
                                    final key = data.keys.elementAt(index);
                                    final title =
                                        _projectChartView ==
                                                ChartTimeView.monthly
                                            ? key.split(' ')[0]
                                            : _projectChartView ==
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
                              // === PERUBAHAN DIMULAI DI SINI ===
                              topTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 26, // Beri ruang lebih untuk garis
                                  getTitlesWidget: (double value, TitleMeta meta) {
                                    final index = value.toInt();
                                    if (index >= data.keys.length) {
                                      return const SizedBox.shrink();
                                    }
                                    final groupKey = data.keys.elementAt(index);
                                    final projectCounts = data[groupKey]!;

                                    // Hitung total untuk grup ini
                                    final total = projectCounts.values.fold(0, (sum, item) => sum + item);

                                    // Jangan tampilkan total jika nilainya 0
                                    if (total == 0) {
                                      return const SizedBox.shrink();
                                    }

                                    return SideTitleWidget(
                                      axisSide: meta.axisSide,
                                      space: 4.0, // Jarak di atas bar
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            total.toString(),
                                            style: const TextStyle(
                                              color: AppColors.gray,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Container(
                                            height: 4,
                                            width: widthPerGroup, // ### FIX DI SINI ###
                                            color: AppColors.grayNeutral,
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                              // === PERUBAHAN BERAKHIR DI SINI ===
                              rightTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                            ),
                            borderData: FlBorderData(show: false),
                            gridData: const FlGridData(show: false),
                            barGroups: List.generate(data.keys.length, (index) {
                              final monthKey = data.keys.elementAt(index);
                              final projectCounts = data[monthKey]!;
                              return BarChartGroupData(
                                x: index,
                                barsSpace: barsSpace,
                                showingTooltipIndicators: List.generate(
                                  projects.length,
                                  (i) => i,
                                ),
                                barRods: List.generate(projects.length, (
                                  projectIndex,
                                ) {
                                  final projectName = projects[projectIndex];
                                  final count =
                                      projectCounts[projectName]?.toDouble() ??
                                          0;
                                  final bool isZero = count == 0;
                                  final Color barColor =
                                      projectColors[projectName] ?? Colors.grey;

                                  return BarChartRodData(
                                    toY: isZero ? 0.1 : count,
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
    );
  }

  // --- WIDGET GABUNGAN YANG DI-REFACTOR ---
  Widget _buildProjectSummaryCard({
    required Map<String, dynamic> chartData,
    required List<_ProjectWbsSummary> summaryData,
    required ChartTimeView currentView,
    required ValueChanged<ChartTimeView> onToggle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.grayLight),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          const double breakpoint = 850.0;
          if (constraints.maxWidth > breakpoint) {
            // Layout untuk Layar Lebar (NON-HP)
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Kolom Kiri: Judul dan Chart
                Expanded(
                  flex: 5,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Delivered (Closed) Panel by Project",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          color: AppColors.black,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildProjectBarChartItself(chartData: chartData),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                // Kolom Kanan: Tabs dan Tabel
                Expanded(
                  flex: 4,
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          _buildChartFilterDropdowns(currentView: currentView),
                          const SizedBox(width: 8),
                          _buildToggleButtons(
                            currentView: currentView,
                            onToggle: onToggle,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildDeliveredSummaryTable(summaryData),
                    ],
                  ),
                ),
              ],
            );
          } else {
            // Layout untuk Layar Kecil (HP)
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Expanded(
                      child: Text(
                        "Delivered Panel by Project",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          color: AppColors.black,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildToggleButtons(
                      currentView: currentView,
                      onToggle: onToggle,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: _buildChartFilterDropdowns(currentView: currentView),
                ),
                const SizedBox(height: 16),
                _buildProjectBarChartItself(chartData: chartData),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),
                _buildDeliveredSummaryTable(summaryData),
              ],
            );
          }
        },
      ),
    );
  }

  // --- FIX 2: Widget tabel diganti untuk mendukung merge cells ---
  Widget _buildDeliveredSummaryTable(List<_ProjectWbsSummary> summaryData) {
    if (summaryData.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 20),
          child: Text(
            "Tidak ada data rincian.",
            style: TextStyle(color: AppColors.gray),
          ),
        ),
      );
    }

    // Kelompokkan data berdasarkan nama project
    final Map<String, List<String>> groupedData = {};
    for (var summary in summaryData) {
      if (!groupedData.containsKey(summary.project)) {
        groupedData[summary.project] = [];
      }
      groupedData[summary.project]!.add(summary.wbs);
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header Tabel
        Container(
          decoration: BoxDecoration(
            color: AppColors.grayLight.withOpacity(0.3),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(8),
              topRight: Radius.circular(8),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: const Row(
            children: [
              Expanded(
                flex: 1,
                child: Text(
                  'Project',
                  style: TextStyle(
                    fontWeight: FontWeight.w400,
                    color: AppColors.black,
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: Text(
                  'WBS',
                  style: TextStyle(fontWeight: FontWeight.w400),
                ),
              ),
            ],
          ),
        ),
        // Body Tabel
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.grayLight.withOpacity(0.5)),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(8),
              bottomRight: Radius.circular(8),
            ),
          ),
          child: Column(
            children: groupedData.entries.map((entry) {
              final project = entry.key;
              final wbsList = entry.value;

              return IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Kolom Project (Merged)
                    Expanded(
                      flex: 1,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border(
                            right: BorderSide(
                              color: AppColors.grayLight.withOpacity(0.5),
                            ),
                          ),
                        ),
                        child: Align(
                          alignment: Alignment.topLeft,
                          child: Text(
                            project,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.gray,
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Kolom WBS (List)
                    Expanded(
                      flex: 1,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: wbsList.asMap().entries.map((wbsEntry) {
                          final index = wbsEntry.key;
                          final wbs = wbsEntry.value;
                          return Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              border: index != wbsList.length - 1
                                  ? Border(
                                      bottom: BorderSide(
                                        color: AppColors.grayLight.withOpacity(
                                          0.5,
                                        ),
                                      ),
                                    )
                                  : null,
                            ),
                            child: Text(
                              wbs,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.gray,
                                fontWeight: FontWeight.w300,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // --- WIDGET INI TELAH DIUBAH UNTUK RESPONSIVE LAYOUT ---
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
      const Color(0xFF1D20E4),
      const Color(0xFFED1B3A),
      const Color(0xFFFEB019),
      const Color(0xFF09AF77),
      const Color(0xFF008FFB),
      const Color(0xFFFF5DD1),
      const Color(0xFF5D5FFF),
      const Color(0xFFC83CFF),
    ];
    final Map<String, Color> vendorColors = {
      for (int i = 0; i < vendors.length; i++)
        vendors[i]: colorPalette[i % colorPalette.length],
    };

    double maxValue = 0;
    data.values.forEach((vendorMap) {
      double groupTotal = 0;
      vendorMap.values.forEach((count) {
        groupTotal += count;
      });
      if (groupTotal > maxValue) {
        maxValue = groupTotal;
      }
    });
    if (maxValue == 0) maxValue = 50;

    Widget legendWidget = vendors.isNotEmpty
        ? Wrap(
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
                  Text(
                    vendor,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                ],
              );
            }).toList(),
          )
        : const SizedBox.shrink();

    Widget chartItself = SizedBox(
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
                const double barWidth = 24.0;
                const double barsSpace = 6.0;
                const double groupsSpace = 32.0;

                final double widthPerGroup = vendors.isEmpty
                    ? barWidth
                    : (vendors.length * barWidth) +
                        ((vendors.length - 1) * barsSpace);
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
                                    currentView == ChartTimeView.monthly
                                        ? key.split(' ')[0]
                                        : currentView == ChartTimeView.daily
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
                          // === PERUBAHAN DIMULAI DI SINI ===
                          topTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 26, // Beri ruang lebih untuk garis
                              getTitlesWidget: (double value, TitleMeta meta) {
                                final index = value.toInt();
                                if (index >= data.keys.length) {
                                  return const SizedBox.shrink();
                                }
                                final groupKey = data.keys.elementAt(index);
                                final vendorCounts = data[groupKey]!;

                                // Hitung total untuk grup ini
                                final total = vendorCounts.values.fold(0, (sum, item) => sum + item);

                                // Jangan tampilkan total jika nilainya 0
                                if (total == 0) {
                                  return const SizedBox.shrink();
                                }

                                return SideTitleWidget(
                                  axisSide: meta.axisSide,
                                  space: 4.0, // Jarak di atas bar
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        total.toString(),
                                        style: const TextStyle(
                                          color: AppColors.gray,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Container(
                                        height: 4,
                                        width: widthPerGroup, // ### FIX DI SINI ###
                                        color: AppColors.grayNeutral,
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                          // === PERUBAHAN BERAKHIR DI SINI ===
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
                                  vendorCounts[vendorName]?.toDouble() ?? 0;
                              final bool isZero = count == 0;
                              final Color barColor =
                                  vendorColors[vendorName] ?? Colors.grey;

                              return BarChartRodData(
                                toY: isZero ? 0.1 : count,
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
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.grayLight),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          const double breakpoint = 850.0;
          if (constraints.maxWidth > breakpoint) {
            // DESKTOP LAYOUT
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 5,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          color: AppColors.black,
                        ),
                      ),
                      const SizedBox(height: 24),
                      chartItself,
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  flex: 4,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          _buildChartFilterDropdowns(currentView: currentView),
                          const SizedBox(width: 8),
                          _buildToggleButtons(
                              currentView: currentView, onToggle: onToggle),
                        ],
                      ),
                      const SizedBox(height: 16),
                      legendWidget,
                    ],
                  ),
                ),
              ],
            );
          } else {
            // MOBILE LAYOUT
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          color: AppColors.black,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildToggleButtons(
                        currentView: currentView, onToggle: onToggle),
                  ],
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft, // Disamakan dengan Project
                  child: _buildChartFilterDropdowns(currentView: currentView),
                ),
                const SizedBox(height: 16),
                legendWidget,
                const SizedBox(height: 24),
                chartItself,
              ],
            );
          }
        },
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
  BarTooltipItem? _getTooltipWithComparison(
    BarChartGroupData group,
    int groupIndex,
    BarChartRodData rod,
    int rodIndex,
    Map<String, Map<String, int>> chartData,
    List<String> seriesNames, // Ini bisa berupa 'vendors' atau 'projects'
  ) {
    // Jangan tampilkan tooltip untuk bar yang nilainya nol
    if (rod.toY.round() == 0) return null;

    final currentValue = rod.toY.round();
    String tooltipText = '$currentValue';

    // Lakukan perbandingan hanya jika ini bukan grup data pertama (indeks > 0)
    if (groupIndex > 0) {
      // Ambil key dari grup data sebelumnya (misal: "Sep 2025")
      final previousGroupKey = chartData.keys.elementAt(groupIndex - 1);
      final previousGroupData = chartData[previousGroupKey];

      // Ambil nama dari seri data saat ini (misal: "ABACUS" atau nama project)
      final seriesName = seriesNames[rodIndex];

      // Ambil nilai dari seri yang sama pada periode sebelumnya, default ke 0 jika tidak ada
      final previousValue = previousGroupData?[seriesName] ?? 0;

      final diff = currentValue - previousValue;

      // Format teks perubahan berdasarkan nilai perbedaan (diff)
      if (diff > 0) {
        tooltipText += ' (+${diff})'; // Hasil: 20 (+2)
      } else if (diff < 0) {
        tooltipText += ' (${diff})'; // Hasil: 18 (-2)
      }
      // Jika tidak ada perubahan (diff == 0), kita tidak menambahkan apa-apa
    }

    return BarTooltipItem(
      tooltipText,
      const TextStyle(
        color: AppColors.black,
        fontWeight: FontWeight.w500, // Sedikit tebalkan agar mudah dibaca
        fontSize: 12, // Sedikit kecilkan agar muat
      ),
    );
  }
}