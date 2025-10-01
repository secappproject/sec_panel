import 'package:flutter/material.dart';
import 'package:secpanel/components/panel/add/add_panel_bottom_sheet.dart';
import 'package:secpanel/components/panel/transfer/transfer_panel_bottom_sheet.dart';
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

// ### Helper class untuk membuat TabBar menjadi sticky ###
class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);

  final TabBar _tabBar;

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor, // Warna background saat menempel
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
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
  late final TabController _chartTabController; // ### BARU: Controller untuk Chart Tab
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
  Map<String, dynamic> _panelWipChartData = {};
  Map<String, dynamic> _busbarWipChartData = {};
  Map<String, dynamic> _projectWipChartData = {};

  // --- State untuk filter dropdown di chart ---
  int _selectedYear = DateTime.now().year; // Untuk filter Daily & Monthly
  List<int> _selectedYears = [DateTime.now().year]; // BARU: Untuk filter Yearly (multi-select)
  int _selectedMonth = DateTime.now().month;
  int? _selectedWeek; // Bisa null, artinya "semua minggu"
  int? _selectedQuartile = (DateTime.now().month / 3).ceil();

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
  SrFilter selectedSrStatus = SrFilter.any;
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
    _chartTabController = TabController(length: 2, vsync: this); // ### BARU: Inisialisasi
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

  // Kalkulasi untuk Panel (Tidak Berubah)
  _panelChartData = _calculateDeliveryByTime(
    panelsToDisplay,
    (data) => [
      data.panelVendorName.isNotEmpty ? data.panelVendorName : "No Vendor",
    ],
    view: _panelChartView,
    allPossibleVendors: allPanelVendorNames,
    year: _selectedYear,
    years: _selectedYears,
    month: _selectedMonth,
    week: _selectedWeek,
    quartile: _selectedQuartile,
  );
  _panelWipChartData = _calculateWipByTime(
    panelsToDisplay,
    (data) => [
      data.panelVendorName.isNotEmpty ? data.panelVendorName : "No Vendor",
    ],
    view: _panelChartView,
    allPossibleVendors: allPanelVendorNames,
    year: _selectedYear,
    years: _selectedYears,
    month: _selectedMonth,
    week: _selectedWeek,
    quartile: _selectedQuartile,
  );

  // Kalkulasi untuk Busbar
  _busbarChartData = _calculateBusbarDeliveryByTime(
    panelsToDisplay,
    (data) {
      if (data.busbarVendorNames.isNotEmpty) {
        return data.busbarVendorNames.split(',').map((e) => e.trim()).toList();
      }
      return ["No Vendor"];
    },
    view: _busbarChartView,
    allPossibleVendors: allBusbarVendorNames,
    year: _selectedYear,
    years: _selectedYears,
    month: _selectedMonth,
    week: _selectedWeek,
    quartile: _selectedQuartile,
  );

  _busbarWipChartData = _calculateBusbarWipByTime(
    panelsToDisplay,
    (data) {
      if (data.busbarVendorNames.isNotEmpty) {
        return data.busbarVendorNames.split(',').map((e) => e.trim()).toList();
      }
      return ["No Vendor"];
    },
    view: _busbarChartView,
    allPossibleVendors: allBusbarVendorNames,
    year: _selectedYear,
    years: _selectedYears,
    month: _selectedMonth,
    week: _selectedWeek,
    quartile: _selectedQuartile,
  );


  // Kalkulasi untuk Project (Tidak Berubah)
  _projectChartData = _calculateDeliveryByProject(
      panelsToDisplay,
      view: _projectChartView,
      year: _selectedYear,
      years: _selectedYears,
      month: _selectedMonth,
      week: _selectedWeek,
      quartile: _selectedQuartile,
  );
  _projectWipChartData = _calculateWipByProject(
    panelsToDisplay,
    view: _projectChartView,
    year: _selectedYear,
    years: _selectedYears,
    month: _selectedMonth,
    week: _selectedWeek,
    quartile: _selectedQuartile,
  );
}
  @override
  void dispose() {
    _tabController.dispose();
    _chartTabController.dispose(); // ### BARU: Dispose controller
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
        selectedSrStatus: selectedSrStatus,
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
        onSrStatusChanged: (value) =>
            setState(() => selectedSrStatus = value),
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
            selectedSrStatus = SrFilter.any;
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

    void _openTransferPanelBottomSheet(PanelDisplayData panelData) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => TransferPanelBottomSheet(
          panelData: panelData,
          onSuccess: (updatedPanelData) {
            Navigator.of(context).pop();

            // === PERBAIKAN ADA DI BARIS-BARIS BERIKUT ===
            // 1. Gunakan `_allPanelsData` sebagai list yang benar
            final index = _allPanelsData.indexWhere((p) => p.panel.noPp == updatedPanelData.panel.noPp);
            
            if (index != -1) {
              setState(() {
                // 2. Perbarui item di dalam `_allPanelsData`
                _allPanelsData[index] = updatedPanelData;
              });
            } else {
              loadInitialData();
            }
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
      final bool matchSrStatus;
      switch (selectedSrStatus) {
        case SrFilter.withSr:
          matchSrStatus = data.additionalSrCount > 0;
          break;
        case SrFilter.withoutSr:
          matchSrStatus = data.additionalSrCount == 0;
          break;
        case SrFilter.any:
        default:
          matchSrStatus = true;
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
          matchSrStatus &&
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

  Widget _buildProductionSummaryCard() {
    // Helper widget for creating small tags (e.g., "1 di LV1")
    Widget buildTag(String text) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        decoration: ShapeDecoration(
          color: const Color(0xFFF5F5F5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 10,
            fontFamily: 'Lexend',
            fontWeight: FontWeight.w400,
          ),
        ),
      );
    }

    // Helper widget for creating a section row (e.g., "In Production")
    Widget buildSection(String title, String subtitle, List<Widget> tags) {
      return Container(
        decoration: const ShapeDecoration(
          shape: RoundedRectangleBorder(
            side: BorderSide(width: 1, color: Color(0xFFF5F5F5)),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Placeholder for icon
                  if (title == "In Production")...[
                  SizedBox(
                    width: 28,
                    height: 28,
                    child: Image.asset("assets/images/in.png"),
                  ),
                  ],
                  if (title == "Out Production")...[
                  SizedBox(
                    width: 28,
                    height: 28,
                    child: Image.asset("assets/images/out.png"),
                  ),
                  ],
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 14,
                          fontFamily: 'Lexend',
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: Color(0xFF5C5C5C),
                          fontSize: 12,
                          fontFamily: 'Lexend',
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: tags,
              )
            ],
          ),
        ),
      );
    }

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: ShapeDecoration(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          side: const BorderSide(
            width: 1,
            strokeAlign: BorderSide.strokeAlignOutside,
            color: Color(0xFFF5F5F5),
          ),
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: const ShapeDecoration(
              color: Colors.white,
              shape: RoundedRectangleBorder(
                side: BorderSide(width: 1, color: Color(0xFFF5F5F5)),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                ),
              ),
            ),
            child: const Text(
              'Production',
              style: TextStyle(
                color: Colors.black,
                fontSize: 16,
                fontFamily: 'Lexend',
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          // "In Production" Section
          buildSection(
            'In Production',
            '7 Panel in Total',
            [
              buildTag('1 di LV1'),
              buildTag('1 di LV2'),
              buildTag('1 di LV3'),
              buildTag('1 di LV4'),
              buildTag('1 di LV5'),
              buildTag('1 di LV6'),
              buildTag('1 di LV7'),
            ],
          ),
          // "Out Production" Section
          buildSection(
            'Out Production',
            '7 Panel in Total',
            [
              buildTag('1 di LV1'),
              buildTag('1 di LV2'),
              buildTag('1 di LV3'),
              buildTag('1 di LV4'),
              buildTag('1 di LV5'),
              buildTag('1 di LV6'),
              buildTag('1 di LV7'),
            ],
          ),
          // Buttons
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: Column(
              children: [
                InkWell(
                  onTap: () {},
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: double.infinity,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                    decoration: ShapeDecoration(
                      shape: RoundedRectangleBorder(
                        side: const BorderSide(width: 1, color: Color(0xFF008A15)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Center(
                      child: Text(
                        'Move Panel to Production',
                        style: TextStyle(
                          color: Color(0xFF008A15),
                          fontSize: 14,
                          fontFamily: 'Lexend',
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () {},
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: double.infinity,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                    decoration: ShapeDecoration(
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        side: const BorderSide(width: 1, color: Color(0xFFF5F5F5)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'See Detail',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 14,
                            fontFamily: 'Lexend',
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const SizedBox(width: 4),
                        // Placeholder for icon
                        Container(
                          width: 16,
                          height: 16,
                          clipBehavior: Clip.antiAlias,
                          decoration: const BoxDecoration(),
                          child:  Image.asset("assets/images/arrow-up-right.png",height: 16,)
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
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
    final closedPanelCount =
        baseFilteredList.where((data) => data.panel.isClosed).length;

    final tabBarWidget = TabBar(
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
    );

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
                  fontWeight: FontWeight.w500,
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
                      child: _isChartView
                          ? Image.asset(
                              'assets/images/panel.png',
                              height: 20,
                            )
                          : Image.asset(
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
            ],
          ),
        ),

        Expanded(
          child: _isChartView
              ? _buildChartView()
              : LayoutBuilder(
                  builder: (context, constraints) {
                    bool isDesktop = constraints.maxWidth > 950;

                    if (isDesktop) {
                      // Layout Desktop (2 Kolom)
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // SizedBox(
                            //   width: 320,
                            //   child: SingleChildScrollView(
                            //     child: _buildProductionSummaryCard(),
                            //   ),
                            // ),
                            // const SizedBox(width: 20),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  tabBarWidget,
                                  const SizedBox(height:12),
                                  Expanded(child: _buildPanelView()),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    } else {
                      // Layout Mobile (Scrollable dengan Sticky Header)
                      return CustomScrollView(
                        slivers: [
                          // Card di atas
                          // SliverToBoxAdapter(
                          //   child: Padding(
                          //     padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                          //     child: _buildProductionSummaryCard(),
                          //   ),
                          // ),
                          // TabBar yang menempel
                          SliverPersistentHeader(
                            delegate: _SliverAppBarDelegate(tabBarWidget),
                            pinned: true,
                          ),
                          // Daftar Panel
                          _buildPanelSliverList(),
                        ],
                      );
                    }
                  },
                ),
        ),
      ],
    );
  }

  // Method ini tidak lagi dipakai di mobile, hanya di desktop
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

    // Hanya mengembalikan GridView untuk desktop
    return LayoutBuilder(
      builder: (context, constraints) {
        final int crossAxisCount = (constraints.maxWidth / 500).floor().clamp(
              2,
              4,
            );

        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(0, 12, 0, 100),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            mainAxisExtent: 452,
          ),
          itemCount: panelsToDisplay.length,
          itemBuilder: (context, index) {
            final data = panelsToDisplay[index];
            final panel = data.panel;
            return PanelProgressCard(
              additionalSrCount: data.additionalSrCount ?? 0,
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
              onTransfer: (){
                _openTransferPanelBottomSheet(data);
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
    );
  }

  // Method ini membuat daftar panel sebagai Sliver untuk layout mobile
  Widget _buildPanelSliverList() {
    final panelsToDisplay = filteredPanelsForDisplay;

    if (panelsToDisplay.isEmpty) {
      return SliverFillRemaining( // Mengisi sisa ruang jika kosong
        hasScrollBody: false,
        child: const Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 48.0),
            child: Text(
              "Tidak ada panel yang ditemukan",
              style: TextStyle(color: AppColors.gray, fontSize: 14),
            ),
          ),
        ),
      );
    }

    // Memberi padding horizontal pada list
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
      sliver: SliverList.separated(
        itemCount: panelsToDisplay.length,
        separatorBuilder: (context, index) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final data = panelsToDisplay[index];
          final panel = data.panel;
          return PanelProgressCard(
            additionalSrCount: data.additionalSrCount ?? 0,
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
            onTransfer: () {
              _openTransferPanelBottomSheet(data);
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
      ),
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

Map<String, dynamic> _calculateBusbarDeliveryByTime(
  List<PanelDisplayData> panels,
  List<String> Function(PanelDisplayData) getVendors, {
  required ChartTimeView view,
  required List<String> allPossibleVendors,
  required int year,
  required List<int> years,
  required int month,
  int? week,
  int? quartile,
}) {
  final Map<String, Map<String, int>> counts = {};
  late DateTimeRange displayRange;
  late DateFormat keyFormat;

  // Setup rentang waktu (tidak ada perubahan)
  switch (view) {
    case ChartTimeView.daily:
      keyFormat = DateFormat('E, d', 'id_ID');
      if (week != null) {
        final firstDayOfMonth = DateTime(year, month, 1);
        final dayOfWeekOffset = (1 - firstDayOfMonth.weekday + 7) % 7;
        final firstMonday =
            firstDayOfMonth.subtract(Duration(days: dayOfWeekOffset));
        final startDate = firstMonday.add(Duration(days: (week - 1) * 7));
        displayRange = DateTimeRange(
            start: startDate, end: startDate.add(const Duration(days: 6)));
      } else {
        displayRange = DateTimeRange(
          start: DateTime(year, month, 1),
          end: DateTime(year, month + 1, 0),
        );
      }
      break;
    case ChartTimeView.monthly:
      if (quartile == null) {
        keyFormat = DateFormat('MMM', 'id_ID');
        displayRange = DateTimeRange(
          start: DateTime(year, 1, 1),
          end: DateTime(year, 12, 31),
        );
      } else {
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
      if (years.isEmpty) {
        displayRange =
            DateTimeRange(start: DateTime.now(), end: DateTime.now());
      } else {
        years.sort();
        displayRange = DateTimeRange(
            start: DateTime(years.first, 1, 1),
            end: DateTime(years.last, 12, 31));
      }
      break;
  }

  // Busbar dianggap "closed" HANYA JIKA statusnya 'Close'
  final relevantPanels = panels.where((data) {
      return (data.panel.statusBusbarPcc ?? '') == 'Close';
  });

  for (var data in relevantPanels) {
    // Gunakan startDate untuk menempatkan di timeline, karena closedDate diabaikan
    final dateForChart = data.panel.startDate ?? DateTime.now();

    // Cek apakah tanggal berada dalam rentang chart yang dipilih
    bool isInDateRange = false;
    if (view == ChartTimeView.yearly) {
      if (years.contains(dateForChart.year)) {
        isInDateRange = true;
      }
    } else {
      if (!dateForChart.isBefore(displayRange.start) && !dateForChart.isAfter(displayRange.end.add(const Duration(days: 1)))) {
        isInDateRange = true;
      }
    }

    if (!isInDateRange) continue;

    final key = keyFormat.format(dateForChart);
    final vendorsFromPanel = getVendors(data);
    counts.putIfAbsent(key, () => {});
    for (var vendor in vendorsFromPanel) {
      if (vendor.isNotEmpty && allPossibleVendors.contains(vendor)) {
        counts[key]![vendor] = (counts[key]![vendor] ?? 0) + 1;
      }
    }
  }

  // Sisa kode di bawah ini tidak berubah
  final allKeys = <String>{};
  if (view == ChartTimeView.daily && week == null) {
    for (int i = 0; i < displayRange.duration.inDays + 1; i++) {
      allKeys.add(keyFormat.format(displayRange.start.add(Duration(days: i))));
    }
  } else if (view == ChartTimeView.daily && week != null) {
    for (int i = 0; i < 7; i++) {
      allKeys.add(keyFormat.format(displayRange.start.add(Duration(days: i))));
    }
  } else if (view == ChartTimeView.monthly) {
    if (quartile == null) {
      for (int i = 1; i <= 12; i++) {
        allKeys.add(keyFormat.format(DateTime(year, i)));
      }
    } else {
      for (int i = 0; i < 3; i++) {
        allKeys
            .add(keyFormat.format(DateTime(year, (quartile - 1) * 3 + 1 + i)));
      }
    }
  } else {
    years.sort();
    for (final yearValue in years) {
      allKeys.add(yearValue.toString());
    }
  }

  for (final key in allKeys) {
    counts.putIfAbsent(key, () => {});
  }

  final sortedKeys = counts.keys.toList()
    ..sort((a, b) {
      try {
        if (view == ChartTimeView.monthly && quartile == null) {
          final dateA = DateFormat('MMM', 'id_ID').parse(a);
          final dateB = DateFormat('MMM', 'id_ID').parse(b);
          return dateA.month.compareTo(dateB.month);
        }
        if (view == ChartTimeView.yearly) {
          return a.compareTo(b);
        }
        return keyFormat.parse(a).compareTo(keyFormat.parse(b));
      } catch (e) {
        return a.compareTo(b);
      }
    });

  final finalKeys = sortedKeys;
  final sortedMap = {for (var k in finalKeys) k: counts[k]!};
  final sortedVendors = allPossibleVendors..sort();
  return {'data': sortedMap, 'vendors': sortedVendors};
}

Map<String, dynamic> _calculateBusbarWipByTime(
  List<PanelDisplayData> panels,
  List<String> Function(PanelDisplayData) getVendors, {
  required ChartTimeView view,
  required List<String> allPossibleVendors,
  required int year,
  required List<int> years,
  required int month,
  int? week,
  int? quartile,
}) {
  final Map<String, Map<String, int>> counts = {};
  late DateTimeRange displayRange;
  late DateFormat keyFormat;

  // Setup rentang waktu (tidak ada perubahan)
  switch (view) {
    case ChartTimeView.daily:
      keyFormat = DateFormat('E, d', 'id_ID');
      if (week != null) {
        final firstDayOfMonth = DateTime(year, month, 1);
        final dayOfWeekOffset = (1 - firstDayOfMonth.weekday + 7) % 7;
        final firstMonday =
            firstDayOfMonth.subtract(Duration(days: dayOfWeekOffset));
        final startDate = firstMonday.add(Duration(days: (week - 1) * 7));
        displayRange = DateTimeRange(
            start: startDate, end: startDate.add(const Duration(days: 6)));
      } else {
        displayRange = DateTimeRange(
          start: DateTime(year, month, 1),
          end: DateTime(year, month + 1, 0),
        );
      }
      break;
    case ChartTimeView.monthly:
      if (quartile == null) {
        keyFormat = DateFormat('MMM', 'id_ID');
        displayRange = DateTimeRange(
          start: DateTime(year, 1, 1),
          end: DateTime(year, 12, 31),
        );
      } else {
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
      if (years.isEmpty) {
        displayRange = DateTimeRange(start: DateTime.now(), end: DateTime.now());
      } else {
        years.sort();
        displayRange = DateTimeRange(
            start: DateTime(years.first, 1, 1),
            end: DateTime(years.last, 12, 31));
      }
      break;
  }

  // Busbar dianggap WIP jika statusnya BUKAN 'Close'
  final relevantPanels = panels.where((data) {
    final status = data.panel.statusBusbarPcc ?? '';
    return status != 'Close';
  });

  for (var data in relevantPanels) {
    // Gunakan startDate untuk menempatkan di timeline
    final dateForChart = data.panel.startDate ?? DateTime.now();

    bool isInDateRange = false;
    if (view == ChartTimeView.yearly) {
      if (years.contains(dateForChart.year)) {
        isInDateRange = true;
      }
    } else {
      if (!dateForChart.isBefore(displayRange.start) &&
          !dateForChart.isAfter(displayRange.end.add(const Duration(days: 1)))) {
        isInDateRange = true;
      }
    }

    if (!isInDateRange) continue;

    final key = keyFormat.format(dateForChart);
    final vendorsFromPanel = getVendors(data);
    counts.putIfAbsent(key, () => {});
    for (var vendor in vendorsFromPanel) {
      if (vendor.isNotEmpty && allPossibleVendors.contains(vendor)) {
        counts[key]![vendor] = (counts[key]![vendor] ?? 0) + 1;
      }
    }
  }

  // Sisa kode di bawah ini tidak berubah
  final allKeys = <String>{};
  if (view == ChartTimeView.daily && week == null) {
    for (int i = 0; i < displayRange.duration.inDays + 1; i++) {
      allKeys.add(keyFormat.format(displayRange.start.add(Duration(days: i))));
    }
  } else if (view == ChartTimeView.daily && week != null) {
    for (int i = 0; i < 7; i++) {
      allKeys.add(keyFormat.format(displayRange.start.add(Duration(days: i))));
    }
  } else if (view == ChartTimeView.monthly) {
    if (quartile == null) {
      for (int i = 1; i <= 12; i++) {
        allKeys.add(keyFormat.format(DateTime(year, i)));
      }
    } else {
      for (int i = 0; i < 3; i++) {
        allKeys.add(keyFormat.format(DateTime(year, (quartile - 1) * 3 + 1 + i)));
      }
    }
  } else {
    years.sort();
    for (final yearValue in years) {
      allKeys.add(yearValue.toString());
    }
  }

  for (final key in allKeys) {
    counts.putIfAbsent(key, () => {});
  }

  final sortedKeys = counts.keys.toList()
    ..sort((a, b) {
      try {
        if (view == ChartTimeView.monthly && quartile == null) {
          final dateA = DateFormat('MMM', 'id_ID').parse(a);
          final dateB = DateFormat('MMM', 'id_ID').parse(b);
          return dateA.month.compareTo(dateB.month);
        }
        return keyFormat.parse(a).compareTo(keyFormat.parse(b));
      } catch (e) {
        return a.compareTo(b);
      }
    });

  final finalKeys = sortedKeys;
  final sortedMap = {for (var k in finalKeys) k: counts[k]!};
  final sortedVendors = allPossibleVendors..sort();
  return {'data': sortedMap, 'vendors': sortedVendors};
}
Map<String, dynamic> _calculateWipByTime(
  List<PanelDisplayData> panels,
  List<String> Function(PanelDisplayData) getVendors, {
  required ChartTimeView view,
  required List<String> allPossibleVendors,
  required int year,
  required List<int> years,
  required int month,
  int? week,
  int? quartile,
}) {
  final Map<String, Map<String, int>> counts = {};
  late DateTimeRange displayRange;
  late DateFormat keyFormat;

  // Logika penentuan rentang waktu (displayRange) dan format (keyFormat)
  // tidak ada perubahan, jadi kita biarkan.
  switch (view) {
    case ChartTimeView.daily:
      keyFormat = DateFormat('E, d', 'id_ID');
      if (week != null) {
        final firstDayOfMonth = DateTime(year, month, 1);
        final dayOfWeekOffset = (1 - firstDayOfMonth.weekday + 7) % 7;
        final firstMonday =
            firstDayOfMonth.subtract(Duration(days: dayOfWeekOffset));
        final startDate = firstMonday.add(Duration(days: (week - 1) * 7));
        displayRange = DateTimeRange(
            start: startDate, end: startDate.add(const Duration(days: 6)));
      } else {
        displayRange = DateTimeRange(
          start: DateTime(year, month, 1),
          end: DateTime(year, month + 1, 0),
        );
      }
      break;
    case ChartTimeView.monthly:
      if (quartile == null) {
        keyFormat = DateFormat('MMM', 'id_ID');
        displayRange = DateTimeRange(
          start: DateTime(year, 1, 1),
          end: DateTime(year, 12, 31),
        );
      } else {
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
      if (years.isEmpty) {
        displayRange = DateTimeRange(start: DateTime.now(), end: DateTime.now());
      } else {
        years.sort();
        displayRange = DateTimeRange(
            start: DateTime(years.first, 1, 1),
            end: DateTime(years.last, 12, 31));
      }
      break;
  }

  // ### PERUBAHAN UTAMA DIMULAI DARI SINI ###

  // 1. (DIUBAH) Filter awal hanya untuk panel yang belum di-close.
  final relevantPanels = panels.where((data) => !data.panel.isClosed);

  for (var data in relevantPanels) {
    // 2. (BARU) Tentukan tanggal untuk chart.
    // Jika startDate ada, pakai itu. Jika tidak, pakai tanggal hari ini.
    final dateForChart = data.panel.startDate ?? DateTime.now();

    // 3. (BARU) Pindahkan filter waktu ke dalam loop.
    // Cek apakah tanggal panel (baik dari startDate atau hari ini) masuk
    // dalam rentang waktu yang dipilih di chart.
    bool isInDateRange = false;
    if (view == ChartTimeView.yearly) {
      if (years.contains(dateForChart.year)) {
        isInDateRange = true;
      }
    } else {
      // Logika untuk daily/monthly
      if (!dateForChart.isBefore(displayRange.start) &&
          !dateForChart.isAfter(displayRange.end.add(const Duration(days: 1)))) {
        isInDateRange = true;
      }
    }

    // Jika tanggalnya tidak masuk rentang, lewati panel ini dan lanjut ke berikutnya.
    if (!isInDateRange) continue;

    // ### AKHIR PERUBAHAN UTAMA ###

    final key = keyFormat.format(dateForChart);
    final vendorsFromPanel = getVendors(data);
    counts.putIfAbsent(key, () => {});
    for (var vendor in vendorsFromPanel) {
      if (vendor.isNotEmpty && allPossibleVendors.contains(vendor)) {
        counts[key]![vendor] = (counts[key]![vendor] ?? 0) + 1;
      }
    }
  }

  // Sisa kode di bawah ini tidak perlu diubah, biarkan saja.
  final allKeys = <String>{};
  if (view == ChartTimeView.daily && week == null) {
    for (int i = 0; i < displayRange.duration.inDays + 1; i++) {
      allKeys.add(keyFormat.format(displayRange.start.add(Duration(days: i))));
    }
  } else if (view == ChartTimeView.daily && week != null) {
    for (int i = 0; i < 7; i++) {
      allKeys.add(keyFormat.format(displayRange.start.add(Duration(days: i))));
    }
  } else if (view == ChartTimeView.monthly) {
    if (quartile == null) {
      for (int i = 1; i <= 12; i++) {
        allKeys.add(keyFormat.format(DateTime(year, i)));
      }
    } else {
      for (int i = 0; i < 3; i++) {
        allKeys.add(keyFormat.format(DateTime(year, (quartile - 1) * 3 + 1 + i)));
      }
    }
  } else {
    years.sort();
    for (final yearValue in years) {
      allKeys.add(yearValue.toString());
    }
  }

  for (final key in allKeys) {
    counts.putIfAbsent(key, () => {});
  }

  final sortedKeys = counts.keys.toList()
    ..sort((a, b) {
      try {
        if (view == ChartTimeView.monthly && quartile == null) {
          final dateA = DateFormat('MMM', 'id_ID').parse(a);
          final dateB = DateFormat('MMM', 'id_ID').parse(b);
          return dateA.month.compareTo(dateB.month);
        }
        return keyFormat.parse(a).compareTo(keyFormat.parse(b));
      } catch (e) {
        return a.compareTo(b);
      }
    });

  final finalKeys = sortedKeys;
  final sortedMap = {for (var k in finalKeys) k: counts[k]!};
  final sortedVendors = allPossibleVendors..sort();
  return {'data': sortedMap, 'vendors': sortedVendors};
}
  Map<String, dynamic> _calculateDeliveryByTime(
  List<PanelDisplayData> panels,
  List<String> Function(PanelDisplayData) getVendors, {
  required ChartTimeView view,
  required List<String> allPossibleVendors,
  required int year,
  required List<int> years,
  required int month,
  int? week,
  int? quartile,
}) {
  final Map<String, Map<String, int>> counts = {};
  late DateTimeRange displayRange;
  late DateFormat keyFormat;

  switch (view) {
    case ChartTimeView.daily:
      keyFormat = DateFormat('E, d', 'id_ID');
      if (week != null) {
        final firstDayOfMonth = DateTime(year, month, 1);
        final dayOfWeekOffset = (1 - firstDayOfMonth.weekday + 7) % 7;
        final firstMonday =
            firstDayOfMonth.subtract(Duration(days: dayOfWeekOffset));
        final startDate = firstMonday.add(Duration(days: (week - 1) * 7));
        displayRange = DateTimeRange(
            start: startDate, end: startDate.add(const Duration(days: 6)));
      } else {
        displayRange = DateTimeRange(
          start: DateTime(year, month, 1),
          end: DateTime(year, month + 1, 0),
        );
      }
      break;
    case ChartTimeView.monthly:
      if (quartile == null) {
        keyFormat = DateFormat('MMM', 'id_ID');
        displayRange = DateTimeRange(
          start: DateTime(year, 1, 1),
          end: DateTime(year, 12, 31),
        );
      } else {
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
      if (years.isEmpty) {
        displayRange =
            DateTimeRange(start: DateTime.now(), end: DateTime.now());
      } else {
        years.sort();
        displayRange = DateTimeRange(
            start: DateTime(years.first, 1, 1),
            end: DateTime(years.last, 12, 31));
      }
      break;
  }

  // ============== BAGIAN PENTING YANG DIPERBAIKI ==============
  final relevantPanels = panels.where((data) {
    if (data.panel.closedDate == null) return false;

    // Logika untuk Yearly View (Multi-select)
    if (view == ChartTimeView.yearly) {
      return years.contains(data.panel.closedDate!.year);
    }

    // Logika untuk Daily/Monthly View
    return !data.panel.closedDate!.isBefore(displayRange.start) &&
        !data.panel.closedDate!
            .isAfter(displayRange.end.add(const Duration(days: 1)));
  });
  // ==========================================================

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

  final allKeys = <String>{};
  if (view == ChartTimeView.daily && week == null) {
    for (int i = 0; i < displayRange.duration.inDays + 1; i++) {
      allKeys.add(keyFormat.format(displayRange.start.add(Duration(days: i))));
    }
  } else if (view == ChartTimeView.daily && week != null) {
    for (int i = 0; i < 7; i++) {
      allKeys.add(keyFormat.format(displayRange.start.add(Duration(days: i))));
    }
  } else if (view == ChartTimeView.monthly) {
    if (quartile == null) {
      for (int i = 1; i <= 12; i++) {
        allKeys.add(keyFormat.format(DateTime(year, i)));
      }
    } else {
      for (int i = 0; i < 3; i++) {
        allKeys
            .add(keyFormat.format(DateTime(year, (quartile - 1) * 3 + 1 + i)));
      }
    }
  } else {
    years.sort();
    for (final yearValue in years) {
      allKeys.add(yearValue.toString());
    }
  }

  for (final key in allKeys) {
    counts.putIfAbsent(key, () => {});
  }

  final sortedKeys = counts.keys.toList()
    ..sort((a, b) {
      try {
        if (view == ChartTimeView.monthly && quartile == null) {
          final dateA = DateFormat('MMM', 'id_ID').parse(a);
          final dateB = DateFormat('MMM', 'id_ID').parse(b);
          return dateA.month.compareTo(dateB.month);
        }
        // Perbaikan untuk sorting yearly
        if (view == ChartTimeView.yearly) {
          return a.compareTo(b);
        }
        return keyFormat.parse(a).compareTo(keyFormat.parse(b));
      } catch (e) {
        return a.compareTo(b);
      }
    });

  final finalKeys = sortedKeys;

  final sortedMap = {for (var k in finalKeys) k: counts[k]!};
  final sortedVendors = allPossibleVendors..sort();
  return {'data': sortedMap, 'vendors': sortedVendors};
}

Map<String, dynamic> _calculateWipByProject(
  List<PanelDisplayData> panels, {
  required ChartTimeView view,
  required int year,
  required List<int> years,
  required int month,
  int? week,
  int? quartile,
}) {
  final Map<String, Map<String, int>> counts = {};
  late DateTimeRange displayRange;
  late DateFormat keyFormat;

  // Logika penentuan rentang waktu (sama seperti fungsi lainnya)
  switch (view) {
    case ChartTimeView.daily:
      keyFormat = DateFormat('E, d', 'id_ID');
      if (week != null) {
        final firstDayOfMonth = DateTime(year, month, 1);
        final dayOfWeekOffset = (1 - firstDayOfMonth.weekday + 7) % 7;
        final firstMonday =
            firstDayOfMonth.subtract(Duration(days: dayOfWeekOffset));
        final startDate = firstMonday.add(Duration(days: (week - 1) * 7));
        displayRange = DateTimeRange(
            start: startDate, end: startDate.add(const Duration(days: 6)));
      } else {
        displayRange = DateTimeRange(
          start: DateTime(year, month, 1),
          end: DateTime(year, month + 1, 0),
        );
      }
      break;
    case ChartTimeView.monthly:
      if (quartile == null) {
        keyFormat = DateFormat('MMM', 'id_ID');
        displayRange = DateTimeRange(
          start: DateTime(year, 1, 1),
          end: DateTime(year, 12, 31),
        );
      } else {
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
      if (years.isEmpty) {
        displayRange =
            DateTimeRange(start: DateTime.now(), end: DateTime.now());
      } else {
        years.sort();
        displayRange = DateTimeRange(
            start: DateTime(years.first, 1, 1),
            end: DateTime(years.last, 12, 31));
      }
      break;
  }

  // Hanya filter panel yang belum closed
  final relevantPanels = panels.where((data) => !data.panel.isClosed);

  // Kumpulkan semua nama project yang mungkin ada dari panel yang relevan
  final allPossibleProjects = relevantPanels
      .map((p) => p.panel.project?.trim() ?? '')
      .map((name) => name.isEmpty ? "No Project" : name) // Ganti 'No Vendor' menjadi 'No Project'
      .toSet()
      .toList();


  for (var data in relevantPanels) {
    // Gunakan startDate jika ada, jika tidak, gunakan tanggal hari ini
    final dateForChart = data.panel.startDate ?? DateTime.now();

    // Cek apakah tanggal panel masuk dalam rentang waktu chart
    bool isInDateRange = false;
    if (view == ChartTimeView.yearly) {
      if (years.contains(dateForChart.year)) {
        isInDateRange = true;
      }
    } else {
      if (!dateForChart.isBefore(displayRange.start) &&
          !dateForChart
              .isAfter(displayRange.end.add(const Duration(days: 1)))) {
        isInDateRange = true;
      }
    }

    if (!isInDateRange) continue;

    final key = keyFormat.format(dateForChart);
    final projectName = data.panel.project?.trim();
    final finalProjectName =
        (projectName == null || projectName.isEmpty) ? "No Project" : projectName;

    counts.putIfAbsent(key, () => {});
    counts[key]![finalProjectName] = (counts[key]![finalProjectName] ?? 0) + 1;
  }

  // Sisa kode di bawah ini untuk memastikan semua label & urutan benar
  final allKeys = <String>{};
  if (view == ChartTimeView.daily && week == null) {
    for (int i = 0; i < displayRange.duration.inDays + 1; i++) {
      allKeys.add(keyFormat.format(displayRange.start.add(Duration(days: i))));
    }
  } else if (view == ChartTimeView.daily && week != null) {
    for (int i = 0; i < 7; i++) {
      allKeys.add(keyFormat.format(displayRange.start.add(Duration(days: i))));
    }
  } else if (view == ChartTimeView.monthly) {
    if (quartile == null) {
      for (int i = 1; i <= 12; i++) {
        allKeys.add(keyFormat.format(DateTime(year, i)));
      }
    } else {
      for (int i = 0; i < 3; i++) {
        allKeys
            .add(keyFormat.format(DateTime(year, (quartile - 1) * 3 + 1 + i)));
      }
    }
  } else {
    years.sort();
    for (final yearValue in years) {
      allKeys.add(yearValue.toString());
    }
  }

  for (final key in allKeys) {
    counts.putIfAbsent(key, () => {});
  }

  final sortedKeys = counts.keys.toList()
    ..sort((a, b) {
      try {
        if (view == ChartTimeView.monthly && quartile == null) {
          final dateA = DateFormat('MMM', 'id_ID').parse(a);
          final dateB = DateFormat('MMM', 'id_ID').parse(b);
          return dateA.month.compareTo(dateB.month);
        }
        if (view == ChartTimeView.yearly) {
          return a.compareTo(b);
        }
        return keyFormat.parse(a).compareTo(keyFormat.parse(b));
      } catch (e) {
        return a.compareTo(b);
      }
    });

  final finalKeys = sortedKeys;
  final sortedMap = {for (var k in finalKeys) k: counts[k]!};
  final sortedProjects = allPossibleProjects..sort();
  return {'data': sortedMap, 'projects': sortedProjects};
}

  Map<String, dynamic> _calculateDeliveryByProject(
    List<PanelDisplayData> panels, {
    required ChartTimeView view,
    // --- BARU: parameter filter ---
    required int year,
    required List<int> years, // Diubah
    required int month,
    int? week,
    int? quartile,
  }) {
    final Map<String, Map<String, int>> counts = {};
    late DateTimeRange displayRange;
    late DateFormat keyFormat;

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
        if (years.isEmpty) {
          displayRange = DateTimeRange(start: DateTime.now(), end: DateTime.now());
        } else {
          years.sort();
          displayRange = DateTimeRange(start: DateTime(years.first, 1, 1), end: DateTime(years.last, 12, 31));
        }
        break;
    }

    final relevantPanels = panels.where(
       (data) {
        if (data.panel.closedDate == null) return false;

        if (view == ChartTimeView.yearly) {
          return years.contains(data.panel.closedDate!.year);
        }

        // Logic untuk daily/monthly
        return !data.panel.closedDate!.isBefore(displayRange.start) &&
               !data.panel.closedDate!.isAfter(displayRange.end.add(const Duration(days: 1)));
      }
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
      years.sort();
      for (final yearValue in years) {
        allKeys.add(yearValue.toString());
      }
    }

    for (final key in allKeys) {
      counts.putIfAbsent(key, () => {});
    }

    final sortedKeys = counts.keys.toList()
      ..sort((a, b) {
        try {
          if (view == ChartTimeView.monthly && quartile == null) {
              final dateA = DateFormat('MMM', 'id_ID').parse(a);
              final dateB = DateFormat('MMM', 'id_ID').parse(b);
              return dateA.month.compareTo(dateB.month);
          }
          return keyFormat.parse(a).compareTo(keyFormat.parse(b));
        } catch (e) {
          return a.compareTo(b);
        }
      });

    final finalKeys = sortedKeys;

    final sortedMap = {for (var k in finalKeys) k: counts[k]!};
    final sortedProjects = allPossibleProjects..sort();
    return {'data': sortedMap, 'projects': sortedProjects};
  }

  // ### BARU: Widget untuk konten tab "By Vendor"
  Widget _buildVendorChartView() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isDesktop = constraints.maxWidth >= 800.0;

        if (isDesktop) {
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  // ### GANTI DI SINI ###
                  child: _GroupedBarChartCard(
                    title: "Delivered & On-Progress Panel",
                    itemType: "Panel",
                    closedChartData: _panelChartData,
                    wipChartData: _panelWipChartData,
                    currentView: _panelChartView,
                    onToggle: (newView) => setState(() => _panelChartView = newView),
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  // ### GANTI DI SINI ###
                  child: _GroupedBarChartCard(
                    title: "Delivered & On-Progress Busbar",
                    itemType: "Busbar",
                    closedChartData: _busbarChartData,
                    wipChartData: _busbarWipChartData,
                    currentView: _busbarChartView,
                    onToggle: (newView) => setState(() => _busbarChartView = newView),
                  ),
                ),
              ],
            ),
          );
        } else {
          // Layout Mobile
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _GroupedBarChartCard(
                  title: "Delivered & On-Progress Panel",
                  itemType: "Panel",
                  closedChartData: _panelChartData,
                  wipChartData: _panelWipChartData,
                  currentView: _panelChartView,
                  onToggle: (newView) => setState(() => _panelChartView = newView),
                ),
                const SizedBox(height: 24),
                // ### GANTI DI SINI ###
                _GroupedBarChartCard(
                  title: "Delivered & On-Progress Busbar",
                  itemType: "Busbar",
                  closedChartData: _busbarChartData,
                  wipChartData: _busbarWipChartData,
                  currentView: _busbarChartView,
                  onToggle: (newView) => setState(() => _busbarChartView = newView),
                ),
              ],
            ),
          );
        }
      },
    );
  }

  // ### BARU: Widget untuk konten tab "By Project"
  Widget _buildProjectChartView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
      child: _GroupedBarChartCard(
        title: "Delivered & On-Progress by Project",
        itemType: "by Project",
        closedChartData: _projectChartData,
        wipChartData: _projectWipChartData,
        currentView: _projectChartView,
        onToggle: (newView) => setState(() => _projectChartView = newView),
      )
    );
  }


  // ### DIUBAH: Widget ini sekarang menjadi kerangka untuk TabBar dan TabBarView
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

    // Menggunakan DefaultTabController dan Scaffold untuk membuat struktur Tab
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          toolbarHeight: 0, // Sembunyikan toolbar default
          automaticallyImplyLeading: false,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          elevation: 0,
          bottom: TabBar(
            controller: _chartTabController,
            labelColor: AppColors.black,
            unselectedLabelColor: AppColors.gray,
            indicatorColor: AppColors.schneiderGreen,
            indicatorWeight: 2,
            indicatorSize: TabBarIndicatorSize.label,
            overlayColor: WidgetStateProperty.all(Colors.transparent),
            dividerColor: Colors.transparent,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.w500,
              fontFamily: 'Lexend',
              fontSize: 12, // Sedikit diperbesar agar mudah dibaca
            ),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w400,
              fontFamily: 'Lexend',
              fontSize: 12,
            ),
            tabs: const [
              Tab(text: "By Vendor"),
              Tab(text: "By Project"),
            ],
          ),
        ),
        body: TabBarView(
          controller: _chartTabController,
          children: [
            // Konten untuk Tab "By Vendor"
            _buildVendorChartView(),
            // Konten untuk Tab "By Project"
            _buildProjectChartView(),
          ],
        ),
      ),
    );
  }

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
                            child: Text("All Month", style: dropdownStyle),
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
    else if (currentView == ChartTimeView.yearly) {
      // Tampilan Yearly sekarang menggunakan multi-select
      return _buildYearMultiSelect();
    }

    return const SizedBox.shrink();
  }

  void _showYearMultiSelectBottomSheet() {
    final availableYears =
        List.generate(10, (index) => DateTime.now().year - index);
    final List<int> tempSelectedYears = List.from(_selectedYears);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setSheetState) {
            final bool isAllSelected =
                Set.from(tempSelectedYears).containsAll(availableYears);

            return Container(
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: const BorderRadius.only(topRight: Radius.circular(12), topLeft: Radius.circular(12))),
              child: Padding(
                padding: EdgeInsets.only(
                  top: 16,
                  left: 16,
                  right: 16,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Select Years',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            setSheetState(() {
                              if (isAllSelected) {
                                tempSelectedYears.clear();
                              } else {
                                tempSelectedYears.clear();
                                tempSelectedYears.addAll(availableYears);
                              }
                            });
                          },
                          child: Text(isAllSelected ? 'Unselect All' : 'Select All', style: TextStyle(color: AppColors.schneiderGreen),),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    SizedBox(
                      height: (availableYears.length * 52.0).clamp(0, 300.0),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: availableYears.length,
                        itemBuilder: (context, index) {
                          final year = availableYears[index];
                          return CheckboxListTile(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              controlAffinity: ListTileControlAffinity.leading,
                              title: Text(year.toString(), style: const TextStyle(fontWeight: FontWeight.w300),),
                              value: tempSelectedYears.contains(year),
                              activeColor: AppColors.schneiderGreen,
                              checkColor: Colors.white,
                              onChanged: (bool? value) {
                                setSheetState(() {
                                  if (value == true) {
                                    tempSelectedYears.add(year);
                                  } else {
                                    tempSelectedYears.remove(year);
                                  }
                                });
                              },
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.schneiderGreen,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Apply', style: TextStyle(fontSize: 12),),
                      onPressed: () {
                        setState(() {
                          _selectedYears = tempSelectedYears;
                          if (_selectedYears.isEmpty) {
                            _selectedYears.add(DateTime.now().year);
                          }
                        });
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildYearMultiSelect() {
    final dropdownStyle = TextStyle(
      fontSize: 12,
      color: Colors.grey[700],
      fontWeight: FontWeight.w400,
    );

    _selectedYears.sort((a,b) => b.compareTo(a)); // Tampilkan dari tahun terbaru
    String displayText = _selectedYears.join(', ');
    if (displayText.isEmpty) {
      displayText = "Select Years";
    }

    return InkWell(
      onTap: _showYearMultiSelectBottomSheet, // DIUBAH ke bottom sheet
      borderRadius: BorderRadius.circular(6),
      child: Container(
        height: 30,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppColors.grayLight),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                displayText,
                style: dropdownStyle,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.keyboard_arrow_down, size: 16),
          ],
        ),
      ),
    );
  }
  Widget _buildBarChartItself({
    required Map<String, dynamic> chartData,
    required Map<String, Color> colorMap,
    required ChartTimeView currentView,
  }) {
    // Ekstrak data dan nama series
    final Map<String, Map<String, int>> data = (chartData['data'] as Map<String, Map<String, int>>? ?? {});
    final List<String> seriesNames = (chartData['vendors'] as List<String>? ?? chartData['projects'] as List<String>? ?? []);

    // Hitung nilai Y maksimum untuk skala chart
    double maxValue = 0;
    data.values.forEach((seriesMap) {
      double groupTotal = seriesMap.values.fold(0, (sum, item) => sum + item);
      if (groupTotal > maxValue) {
        maxValue = groupTotal;
      }
    });
    if (maxValue == 0) maxValue = 10;

    // Kalkulasi lebar dinamis untuk bar group
    const double barWidth = 24.0;
    const double barsSpace = 4.0;
    const double groupsSpace = 24.0;
    final double widthPerGroup = seriesNames.isEmpty ? barWidth : (seriesNames.length * barWidth) + ((seriesNames.length - 1) * barsSpace);

    return _ScrollableBarChart(
      key: ValueKey(chartData.hashCode),
      data: data,
      seriesNames: seriesNames,
      colorMap: colorMap,
      currentView: currentView,
      widthPerGroup: widthPerGroup,
      groupsSpace: groupsSpace,
      maxValue: maxValue,
      barWidth: barWidth,
      barsSpace: barsSpace,
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
// ### BARU: Widget Stateful untuk Kartu Chart dengan Scroller ###
class _GroupedBarChartCard extends StatefulWidget {
  final String title;
  final String itemType;
  final Map<String, dynamic> closedChartData;
  final Map<String, dynamic> wipChartData;
  final ChartTimeView currentView;
  final ValueChanged<ChartTimeView> onToggle;

  const _GroupedBarChartCard({
    required this.title,
    required this.itemType,
    required this.closedChartData,
    required this.wipChartData,
    required this.currentView,
    required this.onToggle,
  });

  @override
  _GroupedBarChartCardState createState() => _GroupedBarChartCardState();
}

class _GroupedBarChartCardState extends State<_GroupedBarChartCard> {
  late final ScrollController _scrollController;
  bool _showLeftArrow = false;
  bool _showRightArrow = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_scrollListener);
    // Cek posisi scroll setelah frame pertama selesai di-render
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkScrollPosition());
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }
  
  // Listener untuk mendeteksi perubahan posisi scroll
  void _scrollListener() {
    _checkScrollPosition();
  }
  
  // Fungsi untuk mengecek apakah tombol panah perlu ditampilkan
  void _checkScrollPosition() {
    if (!mounted || !_scrollController.hasClients) return;

    final bool canScrollLeft = _scrollController.position.pixels > 0;
    final bool canScrollRight = _scrollController.position.pixels < _scrollController.position.maxScrollExtent;

    // Hanya update state jika ada perubahan untuk menghindari rebuild yang tidak perlu
    if (canScrollLeft != _showLeftArrow || canScrollRight != _showRightArrow) {
      setState(() {
        _showLeftArrow = canScrollLeft;
        _showRightArrow = canScrollRight;
      });
    }
  }

  // Fungsi untuk scroll ke kiri
  void _scrollLeft() {
    _scrollController.animateTo(
      _scrollController.offset - 200, // Scroll sejauh 200px
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  // Fungsi untuk scroll ke kanan
  void _scrollRight() {
    _scrollController.animateTo(
      _scrollController.offset + 200, // Scroll sejauh 200px
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Logika untuk menggabungkan nama series (vendor/project) dari kedua dataset
    final List<String> closedSeries = (widget.closedChartData['vendors'] as List<String>? ?? widget.closedChartData['projects'] as List<String>? ?? []);
    final List<String> wipSeries = (widget.wipChartData['vendors'] as List<String>? ?? widget.wipChartData['projects'] as List<String>? ?? []);
    final List<String> seriesNames = {...closedSeries, ...wipSeries}.toList()..sort();

    // Palet warna
    final List<Color> colorPalette = [
      const Color(0xFF1D20E4), const Color(0xFFED1B3A), const Color(0xFFFEB019),
      const Color(0xFF09AF77), const Color(0xFF008FFB), const Color(0xFFFF5DD1),
      const Color(0xFF5D5FFF), const Color(0xFFC83CFF),
      const Color(0xFF00E396), const Color(0xFF775DD0), const Color(0xFFFEB019), const Color(0xFFE91E63),
    ];
    final Map<String, Color> seriesColors = {
      for (int i = 0; i < seriesNames.length; i++)
        seriesNames[i]: colorPalette[i % colorPalette.length],
    };

    // ### PERUBAHAN UTAMA: Widget Legenda dengan Scroller ###
    Widget legendWidget = seriesNames.isNotEmpty
      ? Stack(
          alignment: Alignment.center,
          children: [
            // Kontainer utama untuk list legenda yang bisa di-scroll
            SingleChildScrollView(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              // Tambahkan padding agar item tidak tertutup oleh tombol panah
              padding: const EdgeInsets.symmetric(horizontal: 30.0),
              child: Row( // Mengganti Wrap dengan Row
                children: seriesNames.map((name) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0), // Ganti spacing dari Wrap
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 12, height: 12,
                          decoration: BoxDecoration(color: seriesColors[name], borderRadius: BorderRadius.circular(4)),
                        ),
                        const SizedBox(width: 4),
                        Text(name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w300)),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            
            // Tombol Panah Kiri
            if (_showLeftArrow)
              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [Colors.white, Colors.white.withOpacity(0.0)],
                    )
                  ),
                  padding: const EdgeInsets.only(right: 10),
                  child: _buildArrowButton(Icons.arrow_back_ios_new, _scrollLeft),
                ),
              ),

            // Tombol Panah Kanan
            if (_showRightArrow)
              Align(
                alignment: Alignment.centerRight,
                child: Container(
                   decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerRight,
                      end: Alignment.centerLeft,
                      colors: [Colors.white, Colors.white.withOpacity(0.0)],
                    )
                  ),
                  padding: const EdgeInsets.only(left: 10),
                  child: _buildArrowButton(Icons.arrow_forward_ios, _scrollRight),
                ),
              ),
          ],
        )
      : const SizedBox.shrink();

    // Sisa dari build method (tidak ada perubahan signifikan)
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
              const double breakpoint = 850.0;
              if (constraints.maxWidth > breakpoint) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(widget.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: AppColors.black)),
                    ),
                    // Panggil method dari parent state (HomeScreenState)
                    (context.findAncestorStateOfType<HomeScreenState>())!._buildChartFilterDropdowns(currentView: widget.currentView),
                    const SizedBox(width: 8),
                    (context.findAncestorStateOfType<HomeScreenState>())!._buildToggleButtons(currentView: widget.currentView, onToggle: widget.onToggle),
                  ],
                );
              } else {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(widget.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: AppColors.black)),
                        ),
                        (context.findAncestorStateOfType<HomeScreenState>())!._buildToggleButtons(currentView: widget.currentView, onToggle: widget.onToggle),
                      ],
                    ),
                    const SizedBox(height: 12),
                    (context.findAncestorStateOfType<HomeScreenState>())!._buildChartFilterDropdowns(currentView: widget.currentView),
                  ],
                );
              }
            },
          ),
          const SizedBox(height: 16),
          legendWidget, // Widget legenda baru kita
          const SizedBox(height: 24),
          Text(
            "Jumlah ${widget.itemType == "by Project" ? "Panel" : widget.itemType} Closed",
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.black),
          ),
          const SizedBox(height: 8),
          // Panggil method dari parent state (HomeScreenState)
          (context.findAncestorStateOfType<HomeScreenState>())!._buildBarChartItself(
            chartData: widget.closedChartData,
            colorMap: seriesColors,
            currentView: widget.currentView,
          ),
          const SizedBox(height: 24),
          Text(
            "Jumlah ${widget.itemType == "by Project" ? "Panel" : widget.itemType} Work In Progress",
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.black),
          ),
          const SizedBox(height: 8),
          (context.findAncestorStateOfType<HomeScreenState>())!._buildBarChartItself(
            chartData: widget.wipChartData,
            colorMap: seriesColors,
            currentView: widget.currentView,
          ),
        ],
      ),
    );
  }

  // Helper untuk membuat tombol panah
  Widget _buildArrowButton(IconData icon, VoidCallback onPressed) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 2.0,
      shadowColor: Colors.black26,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: Container(
          width: 28,
          height: 28,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 14.0, color: Colors.grey[600]),
        ),
      ),
    );
  }
}

// ### GANTI SELURUH METHOD INI ###
Widget _buildBarChartItself({
  required Map<String, dynamic> chartData,
  required Map<String, Color> colorMap,
  required ChartTimeView currentView,
}) {
  // Ekstrak data dan nama series
  final Map<String, Map<String, int>> data = (chartData['data'] as Map<String, Map<String, int>>? ?? {});
  final List<String> seriesNames = (chartData['vendors'] as List<String>? ?? chartData['projects'] as List<String>? ?? []);

  // Hitung nilai Y maksimum untuk skala chart
  double maxValue = 0;
  data.values.forEach((seriesMap) {
    double groupTotal = seriesMap.values.fold(0, (sum, item) => sum + item);
    if (groupTotal > maxValue) {
      maxValue = groupTotal;
    }
  });
  if (maxValue == 0) maxValue = 10;

  // Kalkulasi lebar dinamis untuk bar group
  const double barWidth = 24.0;
  const double barsSpace = 4.0;
  const double groupsSpace = 24.0;
  final double widthPerGroup = seriesNames.isEmpty ? barWidth : (seriesNames.length * barWidth) + ((seriesNames.length - 1) * barsSpace);

  // ### BARU: Gunakan StatefulWidget untuk mengelola scroller ###
  return _ScrollableBarChart(
    key: ValueKey(chartData.hashCode), // Key penting agar state di-reset saat data berubah
    data: data,
    seriesNames: seriesNames,
    colorMap: colorMap,
    currentView: currentView,
    widthPerGroup: widthPerGroup,
    groupsSpace: groupsSpace,
    maxValue: maxValue,
    barWidth: barWidth,
    barsSpace: barsSpace,
  );
}

// ### BARU: Buat StatefulWidget terpisah untuk Chart yang bisa di-scroll ###
class _ScrollableBarChart extends StatefulWidget {
  final Map<String, Map<String, int>> data;
  final List<String> seriesNames;
  final Map<String, Color> colorMap;
  final ChartTimeView currentView;
  final double widthPerGroup;
  final double groupsSpace;
  final double maxValue;
  final double barWidth;
  final double barsSpace;

  const _ScrollableBarChart({
    super.key,
    required this.data,
    required this.seriesNames,
    required this.colorMap,
    required this.currentView,
    required this.widthPerGroup,
    required this.groupsSpace,
    required this.maxValue,
    required this.barWidth,
    required this.barsSpace,
  });

  @override
  _ScrollableBarChartState createState() => _ScrollableBarChartState();
}

class _ScrollableBarChartState extends State<_ScrollableBarChart> {
  late final ScrollController _scrollController;
  bool _showLeftArrow = false;
  bool _showRightArrow = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_scrollListener);
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkScrollPosition());
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    _checkScrollPosition();
  }

  void _checkScrollPosition() {
    if (!mounted || !_scrollController.hasClients) return;
    final position = _scrollController.position;
    final bool canScrollLeft = position.pixels > 0;
    // Cek dengan sedikit toleransi agar tidak hilang terlalu cepat
    final bool canScrollRight = position.pixels < (position.maxScrollExtent - 5);

    if (canScrollLeft != _showLeftArrow || canScrollRight != _showRightArrow) {
      setState(() {
        _showLeftArrow = canScrollLeft;
        _showRightArrow = canScrollRight;
      });
    }
  }

  void _scroll(double offset) {
    _scrollController.animateTo(
      _scrollController.offset + offset,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Widget _buildArrowButton(IconData icon, VoidCallback onPressed) {
    return Material(
      color: Colors.white.withOpacity(0.8),
      shape: const CircleBorder(),
      elevation: 2.0,
      shadowColor: Colors.black38,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: Container(
          width: 28,
          height: 28,
          decoration: const BoxDecoration(shape: BoxShape.circle),
          child: Icon(icon, size: 14.0, color: Colors.grey[700]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: widget.data.isEmpty || widget.data.values.every((map) => map.values.every((v) => v == 0))
          ? const Center(
              child: Text(
                "Tidak ada data untuk periode ini.",
                style: TextStyle(color: AppColors.gray, fontSize: 12),
              ),
            )
          : LayoutBuilder(
              builder: (context, constraints) {
                final double calculatedWidth = (widget.data.keys.length * widget.widthPerGroup) + ((widget.data.keys.length - 1) * widget.groupsSpace);
                final double availableWidth = constraints.maxWidth;
                final double finalChartWidth = math.max(availableWidth, calculatedWidth);
                
                // Cek ulang posisi setelah layout, karena bisa saja kontennya pas di layar
                WidgetsBinding.instance.addPostFrameCallback((_) => _checkScrollPosition());
                
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    SingleChildScrollView(
                      controller: _scrollController,
                      scrollDirection: Axis.horizontal,
                      child: SizedBox(
                        width: finalChartWidth,
                        child: BarChart(
                          BarChartData(
                            alignment: calculatedWidth < availableWidth ? BarChartAlignment.spaceAround : BarChartAlignment.start,
                            groupsSpace: widget.groupsSpace,
                            maxY: widget.maxValue * 1.25,
                            barTouchData: BarTouchData(
                              handleBuiltInTouches: true, // Biarkan sentuhan default aktif
                              touchTooltipData: BarTouchTooltipData(
                                getTooltipColor: (_) => AppColors.black.withOpacity(0.8),
                                tooltipPadding: const EdgeInsets.all(8),
                                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                  if (rod.toY.round() == 0) return null;
                                  String seriesName = widget.seriesNames[rodIndex];
                                  return BarTooltipItem(
                                    '$seriesName\n',
                                    const TextStyle(color: Colors.white, fontWeight: FontWeight.w300, fontSize: 12),
                                    children: <TextSpan>[
                                      TextSpan(
                                        text: rod.toY.round().toString(),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ),
                            titlesData: FlTitlesData(
                              show: true,
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (double value, TitleMeta meta) {
                                    final index = value.toInt();
                                    if (index >= widget.data.keys.length) return const SizedBox.shrink();
                                    final key = widget.data.keys.elementAt(index);
                                    final title = widget.currentView == ChartTimeView.monthly
                                        ? key.split(' ')[0]
                                        : widget.currentView == ChartTimeView.daily
                                            ? key.replaceAll(', ', '\n')
                                            : key;
                                    return SideTitleWidget(
                                      axisSide: meta.axisSide,
                                      space: 8.0,
                                      child: Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, color: AppColors.gray)),
                                    );
                                  },
                                  reservedSize: 38,
                                ),
                              ),
                              leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              topTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 26,
                                  getTitlesWidget: (double value, TitleMeta meta) {
                                    final index = value.toInt();
                                    if (index >= widget.data.keys.length) return const SizedBox.shrink();
                                    final groupKey = widget.data.keys.elementAt(index);
                                    final total = widget.data[groupKey]!.values.fold(0, (sum, item) => sum + item);
                                    if (total == 0) return const SizedBox.shrink();
                                    return SideTitleWidget(
                                      axisSide: meta.axisSide,
                                      space: 4.0,
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(total.toString(), style: const TextStyle(color: AppColors.gray, fontSize: 11, fontWeight: FontWeight.w500)),
                                          const SizedBox(height: 2),
                                          Container(height: 4, width: widget.widthPerGroup, color: AppColors.grayNeutral),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            ),
                            borderData: FlBorderData(show: false),
                            gridData: const FlGridData(show: false),
                            barGroups: List.generate(widget.data.keys.length, (index) {
                              final key = widget.data.keys.elementAt(index);
                              final seriesCounts = widget.data[key]!;
                              return BarChartGroupData(
                                x: index,
                                barsSpace: widget.barsSpace,
                                barRods: List.generate(widget.seriesNames.length, (seriesIndex) {
                                  final seriesName = widget.seriesNames[seriesIndex];
                                  final count = seriesCounts[seriesName]?.toDouble() ?? 0;
                                  return BarChartRodData(
                                    toY: count,
                                    color: widget.colorMap[seriesName] ?? Colors.grey,
                                    width: widget.barWidth,
                                    borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                                  );
                                }),
                              );
                            }),
                          ),
                        ),
                      ),
                    ),

                    // Tombol Panah Kiri
                    if (_showLeftArrow)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 4.0),
                          child: _buildArrowButton(Icons.arrow_back_ios_new, () => _scroll(-250)),
                        ),
                      ),
                    
                    // Tombol Panah Kanan
                    if (_showRightArrow)
                      Align(
                        alignment: Alignment.centerRight,
                        child: Padding(
                          padding: const EdgeInsets.only(right: 4.0),
                          child: _buildArrowButton(Icons.arrow_forward_ios, () => _scroll(250)),
                        ),
                      ),
                  ],
                );
              },
            ),
    );
  }
}