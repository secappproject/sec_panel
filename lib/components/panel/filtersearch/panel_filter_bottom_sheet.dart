import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:secpanel/models/company.dart';
import 'package:secpanel/theme/colors.dart';

enum SortOption {
  durationDesc,
  durationAsc,
  percentageAsc,
  percentageDesc,
  panelNoAZ,
  panelNoZA,
  ppNoAZ,
  ppNoZA,
  wbsNoAZ,
  wbsNoZA,
  projectNoAZ,
  projectNoZA,
}

enum PanelFilterStatus {
  progressGrey,
  progressRed,
  progressOrange,
  progressBlue,
  readyToDelivery,
  closed,
  closedArchived,
}

enum DateFilterType { notSet, set, any }

enum IssueFilter { any, withIssues, withoutIssues }
enum SrFilter { any, withSr, withoutSr }

class PanelFilterBottomSheet extends StatefulWidget {
  final List<String> selectedStatuses;
  final List<String> selectedComponents;
  final List<String> selectedPalet;
  final List<String> selectedCorepart;
  final bool includeArchived;
  final SortOption? selectedSort;
  final List<PanelFilterStatus> selectedPanelStatuses;
  final List<Company> allK3Vendors;
  final List<Company> allK5Vendors;
  final List<Company> allWHSVendors;
  final List<String> selectedPanelVendors;
  final List<String> selectedBusbarVendors;
  final List<String> selectedComponentVendors;
  final List<String> selectedPaletVendors;
  final List<String> selectedCorepartVendors;
  final List<String> selectedPanelTypes;
  final IssueFilter selectedIssueStatus;
  final SrFilter selectedSrStatus;
  
  // [BARU] Properti untuk filter Position
  final List<String> selectedPositions;
  final Function(List<String>) onPositionsChanged;

  final Function(SrFilter) onSrStatusChanged;
  final DateTimeRange? startDateRange;
  final DateTimeRange? deliveryDateRange;
  final DateTimeRange? closedDateRange;
  final DateTimeRange? pccClosedDateRange;
  final DateTimeRange? mccClosedDateRange;
  final DateFilterType startDateStatus;
  final DateFilterType deliveryDateStatus;
  final DateFilterType closedDateStatus;
  final DateFilterType pccClosedDateStatus;
  final DateFilterType mccClosedDateStatus;
  final Function(List<String>) onStatusesChanged;
  final Function(List<String>) onComponentsChanged;
  final Function(List<String>) onPaletChanged;
  final Function(List<String>) onCorepartChanged;
  final Function(bool) onIncludeArchivedChanged;
  final Function(SortOption?) onSortChanged;
  final Function(List<PanelFilterStatus>) onPanelStatusesChanged;
  final Function(List<String>) onPanelVendorsChanged;
  final Function(List<String>) onBusbarVendorsChanged;
  final Function(List<String>) onComponentVendorsChanged;
  final Function(List<String>) onPaletVendorsChanged;
  final Function(List<String>) onCorepartVendorsChanged;
  final Function(List<String>) onPanelTypesChanged;
  final Function(IssueFilter) onIssueStatusChanged;
  final Function(DateTimeRange?) onStartDateRangeChanged;
  final Function(DateTimeRange?) onDeliveryDateRangeChanged;
  final Function(DateTimeRange?) onClosedDateRangeChanged;
  final Function(DateTimeRange?) onPccClosedDateRangeChanged;
  final Function(DateTimeRange?) onMccClosedDateRangeChanged;
  final Function(DateFilterType) onStartDateStatusChanged;
  final Function(DateFilterType) onDeliveryDateStatusChanged;
  final Function(DateFilterType) onClosedDateStatusChanged;
  final Function(DateFilterType) onPccClosedDateStatusChanged;
  final Function(DateFilterType) onMccClosedDateStatusChanged;
  final VoidCallback onReset;

  const PanelFilterBottomSheet({
    super.key,
    required this.selectedStatuses,
    required this.selectedComponents,
    required this.selectedPalet,
    required this.selectedCorepart,
    required this.includeArchived,
    required this.selectedSort,
    required this.selectedPanelStatuses,
    required this.allK3Vendors,
    required this.allK5Vendors,
    required this.allWHSVendors,
    required this.selectedPanelVendors,
    required this.selectedBusbarVendors,
    required this.selectedComponentVendors,
    required this.selectedPaletVendors,
    required this.selectedCorepartVendors,
    required this.onStatusesChanged,
    required this.onComponentsChanged,
    required this.onPaletChanged,
    required this.onCorepartChanged,
    required this.onIncludeArchivedChanged,
    required this.onSortChanged,
    required this.onPanelStatusesChanged,
    required this.onPanelVendorsChanged,
    required this.onBusbarVendorsChanged,
    required this.onComponentVendorsChanged,
    required this.onPaletVendorsChanged,
    required this.onCorepartVendorsChanged,
    required this.selectedPanelTypes,
    required this.onPanelTypesChanged,
    required this.selectedIssueStatus,
    required this.onIssueStatusChanged,
    required this.selectedSrStatus,
    required this.onSrStatusChanged,
    
    // [BARU] Tambahkan di constructor
    required this.selectedPositions,
    required this.onPositionsChanged,

    required this.startDateRange,
    required this.deliveryDateRange,
    required this.closedDateRange,
    required this.pccClosedDateRange,
    required this.mccClosedDateRange,
    required this.onStartDateRangeChanged,
    required this.onDeliveryDateRangeChanged,
    required this.onClosedDateRangeChanged,
    required this.onPccClosedDateRangeChanged,
    required this.onMccClosedDateRangeChanged,
    required this.startDateStatus,
    required this.deliveryDateStatus,
    required this.closedDateStatus,
    required this.pccClosedDateStatus,
    required this.mccClosedDateStatus,
    required this.onStartDateStatusChanged,
    required this.onDeliveryDateStatusChanged,
    required this.onClosedDateStatusChanged,
    required this.onPccClosedDateStatusChanged,
    required this.onMccClosedDateStatusChanged,
    required this.onReset,
  });

  @override
  State<PanelFilterBottomSheet> createState() => _PanelFilterBottomSheetState();
}

class _PanelFilterBottomSheetState extends State<PanelFilterBottomSheet> {
  late List<String> _selectedStatuses;
  late List<String> _selectedComponents;
  late List<String> _selectedPalet;
  late List<String> _selectedCorepart;
  late bool _includeArchived;
  late SortOption? _selectedSort;
  late List<PanelFilterStatus> _selectedPanelStatuses;
  late List<String> _selectedPanelVendors;
  late List<String> _selectedBusbarVendors;
  late List<String> _selectedComponentVendors;
  late List<String> _selectedPaletVendors;
  late List<String> _selectedCorepartVendors;
  late List<String> _selectedPanelTypes;
  late IssueFilter _selectedIssueStatus;
  late SrFilter _selectedSrStatus;

  // [BARU] State lokal untuk Position
  late List<String> _selectedPositions;

  late DateTimeRange? _startDateRange;
  late DateTimeRange? _deliveryDateRange;
  late DateTimeRange? _closedDateRange;
  late DateTimeRange? _busbarClosedDateRange;
  late DateFilterType _busbarClosedDateStatus;
  late DateFilterType _startDateStatus;
  late DateFilterType _deliveryDateStatus;
  late DateFilterType _closedDateStatus;

  // [BARU] Opsi untuk filter Position
  final List<String> positionOptions = [
    "Warehouse",
    "Subcontractor",
    "Production",
    "FAT",
    "Done",
  ];

  final List<String> busbarStatusOptions = [
    "Open",
    "Punching/Bending",
    "Plating/Epoxy",
    "Close",
    "100% Siap Kirim",
    "Red Block",
  ];
  final List<String> componentStatusOptions = ["Done", "On Progress", "Open"];
  final List<String> paletAndCorepartStatusOptions = ["Close", "Open"];

  @override
  void initState() {
    super.initState();
    _selectedStatuses = List.from(widget.selectedStatuses);
    _selectedComponents = List.from(widget.selectedComponents);
    _selectedPalet = List.from(widget.selectedPalet);
    _selectedCorepart = List.from(widget.selectedCorepart);
    _includeArchived = widget.includeArchived;
    _selectedSort = widget.selectedSort;
    _selectedPanelStatuses = List.from(widget.selectedPanelStatuses);
    _selectedPanelVendors = List.from(widget.selectedPanelVendors);
    _selectedBusbarVendors = List.from(widget.selectedBusbarVendors);
    _selectedComponentVendors = List.from(widget.selectedComponentVendors);
    _selectedPaletVendors = List.from(widget.selectedPaletVendors);
    _selectedCorepartVendors = List.from(widget.selectedCorepartVendors);
    _selectedPanelTypes = List.from(widget.selectedPanelTypes);
    _selectedIssueStatus = widget.selectedIssueStatus;
    _selectedSrStatus = widget.selectedSrStatus;

    // [BARU] Inisialisasi state Position
    _selectedPositions = List.from(widget.selectedPositions);

    _startDateRange = widget.startDateRange;
    _deliveryDateRange = widget.deliveryDateRange;
    _closedDateRange = widget.closedDateRange;
    _startDateStatus = widget.startDateStatus;
    _deliveryDateStatus = widget.deliveryDateStatus;
    _closedDateStatus = widget.closedDateStatus;
    _busbarClosedDateRange =
        widget.pccClosedDateRange ?? widget.mccClosedDateRange;
    if (widget.pccClosedDateRange != null &&
        widget.mccClosedDateRange != null) {
      if (widget.pccClosedDateRange!.end.isAfter(
        widget.mccClosedDateRange!.end,
      )) {
        _busbarClosedDateRange = widget.pccClosedDateRange;
      } else {
        _busbarClosedDateRange = widget.mccClosedDateRange;
      }
    }
    _busbarClosedDateStatus =
        widget.pccClosedDateStatus == DateFilterType.notSet ||
                widget.mccClosedDateStatus == DateFilterType.notSet
            ? DateFilterType.notSet
            : DateFilterType.any;
  }

  void _applyFilters() {
    widget.onStatusesChanged(_selectedStatuses);
    widget.onComponentsChanged(_selectedComponents);
    widget.onPaletChanged(_selectedPalet);
    widget.onCorepartChanged(_selectedCorepart);
    widget.onIncludeArchivedChanged(_includeArchived);
    widget.onSortChanged(_selectedSort);
    widget.onPanelStatusesChanged(_selectedPanelStatuses);
    widget.onPanelVendorsChanged(_selectedPanelVendors);
    widget.onBusbarVendorsChanged(_selectedBusbarVendors);
    widget.onComponentVendorsChanged(_selectedComponentVendors);
    widget.onPaletVendorsChanged(_selectedPaletVendors);
    widget.onCorepartVendorsChanged(_selectedCorepartVendors);
    widget.onPanelTypesChanged(_selectedPanelTypes);
    widget.onIssueStatusChanged(_selectedIssueStatus);
    widget.onSrStatusChanged(_selectedSrStatus);
    
    // [BARU] Panggil callback untuk Position
    widget.onPositionsChanged(_selectedPositions);

    widget.onStartDateRangeChanged(_startDateRange);
    widget.onDeliveryDateRangeChanged(_deliveryDateRange);
    widget.onClosedDateRangeChanged(_closedDateRange);
    widget.onPccClosedDateRangeChanged(_busbarClosedDateRange);
    widget.onMccClosedDateRangeChanged(_busbarClosedDateRange);
    widget.onPccClosedDateStatusChanged(_busbarClosedDateStatus);
    widget.onMccClosedDateStatusChanged(_busbarClosedDateStatus);
    widget.onStartDateStatusChanged(_startDateStatus);
    widget.onDeliveryDateStatusChanged(_deliveryDateStatus);
    widget.onClosedDateStatusChanged(_closedDateStatus);
    Navigator.pop(context);
  }

  void _resetFilters() {
    widget.onReset();
    Navigator.pop(context);
  }

  void _toggleSelection(List list, dynamic value) {
    setState(() {
      if (list.contains(value)) {
        list.remove(value);
      } else {
        list.add(value);
      }
    });
  }

  Widget _buildOptionButton({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    Widget? leading,
    bool enabled = true,
  }) {
    final Color textColor = enabled ? AppColors.black : AppColors.gray;
    final Color borderColor = selected
        ? AppColors.schneiderGreen
        : (enabled ? AppColors.grayLight : AppColors.gray.withOpacity(0.5));

    return Opacity(
      opacity: enabled ? 1.0 : 0.5,
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          margin: const EdgeInsets.only(right: 8, bottom: 12),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.schneiderGreen.withOpacity(0.08)
                : Colors.white,
            border: Border.all(color: borderColor),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (leading != null) ...[leading, const SizedBox(width: 8)],
              Text(
                label,
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.w400,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateField({
    required String title,
    required DateTimeRange? currentRange,
    required Function(DateTimeRange?) onRangeChanged,
    required DateFilterType currentStatus,
    required Function(DateFilterType) onStatusChanged,
  }) {
    final dateFormat = DateFormat('d MMM yyyy');

    Future<void> pickDateRange() async {
      final newRange = await showDateRangePicker(
        context: context,
        firstDate: DateTime(2020),
        lastDate: DateTime(2100),
        initialDateRange: currentRange,
        builder: (context, child) => Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.schneiderGreen,
              onPrimary: Colors.white,
              onSurface: AppColors.black,
              background: Colors.white,
            ),
            scaffoldBackgroundColor: Colors.white,
            textTheme: const TextTheme(
              bodyLarge: TextStyle(fontFamily: 'Lexend', color: AppColors.gray),
              titleMedium: TextStyle(
                fontFamily: 'Lexend',
                color: AppColors.gray,
              ),
              titleSmall: TextStyle(
                fontFamily: 'Lexend',
                color: AppColors.gray,
              ),
              bodyMedium: TextStyle(
                fontFamily: 'Lexend',
                color: AppColors.gray,
              ),
              labelSmall: TextStyle(
                fontFamily: 'Lexend',
                color: AppColors.gray,
              ),
            ),
            datePickerTheme: DatePickerThemeData(
              headerForegroundColor: AppColors.black,
              headerHelpStyle: const TextStyle(
                fontFamily: 'Lexend',
                color: AppColors.black,
                fontWeight: FontWeight.w500,
              ),
              dayStyle: const TextStyle(fontFamily: 'Lexend'),
              weekdayStyle: const TextStyle(
                fontFamily: 'Lexend',
                color: AppColors.gray,
              ),
              yearStyle: const TextStyle(fontFamily: 'Lexend'),
              rangePickerHeaderHelpStyle: const TextStyle(fontFamily: 'Lexend'),
              rangeSelectionBackgroundColor:
                  AppColors.schneiderGreen.withOpacity(0.1),
              todayBorder: const BorderSide(color: AppColors.schneiderGreen),
              todayForegroundColor: MaterialStateProperty.all(
                AppColors.schneiderGreen,
              ),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.schneiderGreen,
                textStyle: const TextStyle(fontFamily: 'Lexend'),
              ),
            ),
          ),
          child: child!,
        ),
      );
      if (newRange != null) {
        onRangeChanged(newRange);
        if (currentStatus != DateFilterType.set) {
          onStatusChanged(DateFilterType.set);
        }
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 12),
        Row(
          children: [
            Checkbox(
              value: currentStatus == DateFilterType.notSet,
              onChanged: (bool? value) {
                onStatusChanged(
                  value! ? DateFilterType.notSet : DateFilterType.any,
                );
              },
              activeColor: AppColors.schneiderGreen,
            ),
            const Text(
              "Hanya tampilkan yang belum diatur",
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 4),
        InkWell(
          onTap: currentStatus != DateFilterType.notSet ? pickDateRange : null,
          borderRadius: BorderRadius.circular(8),
          child: Opacity(
            opacity: currentStatus != DateFilterType.notSet ? 1.0 : 0.5,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.grayLight),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.calendar_today_outlined,
                    size: 20,
                    color: AppColors.gray,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      currentRange == null
                          ? 'Pilih Rentang Tanggal'
                          : '${dateFormat.format(currentRange.start)} - ${dateFormat.format(currentRange.end)}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w300,
                        color: currentRange != null
                            ? AppColors.black
                            : AppColors.gray,
                      ),
                    ),
                  ),
                  if (currentRange != null &&
                      currentStatus != DateFilterType.notSet)
                    InkWell(
                      onTap: () {
                        onRangeChanged(null);
                        onStatusChanged(DateFilterType.any);
                      },
                      child: const Icon(
                        Icons.clear,
                        size: 20,
                        color: AppColors.gray,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              height: 5,
              width: 40,
              decoration: BoxDecoration(
                color: AppColors.grayLight,
                borderRadius: BorderRadius.circular(100),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Image.asset(
                'assets/images/filter-green.png',
                width: 24,
                height: 24,
                color: AppColors.schneiderGreen,
              ),
              const SizedBox(width: 8),
              const Text(
                "Filter",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
              ),
              const Spacer(),
              TextButton(
                onPressed: _resetFilters,
                child: const Text(
                  'Reset Filter',
                  style: TextStyle(
                    color: AppColors.schneiderGreen,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.grayLight),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Image.asset(
                          'assets/images/alert-success.png',
                          width: 24,
                          height: 24,
                          color: AppColors.schneiderGreen,
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text("Tampilkan juga arsip (Closed > 2 hari)"),
                        ),
                        Switch.adaptive(
                          value: _includeArchived,
                          activeColor: AppColors.schneiderGreen,
                          onChanged: (val) {
                            setState(() {
                              _includeArchived = val;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildDateField(
                    title: "Range Target Delivery Panel",
                    currentRange: _deliveryDateRange,
                    onRangeChanged: (range) =>
                        setState(() => _deliveryDateRange = range),
                    currentStatus: _deliveryDateStatus,
                    onStatusChanged: (status) =>
                        setState(() => _deliveryDateStatus = status),
                  ),
                  const SizedBox(height: 24),
                  _buildDateField(
                    title: "Range Delivered (Close) Panel",
                    currentRange: _closedDateRange,
                    onRangeChanged: (range) =>
                        setState(() => _closedDateRange = range),
                    currentStatus: _closedDateStatus,
                    onStatusChanged: (status) =>
                        setState(() => _closedDateStatus = status),
                  ),
                  const SizedBox(height: 24),
                  _buildDateField(
                    title: "Range Delivered (Close) Busbar",
                    currentRange: _busbarClosedDateRange,
                    onRangeChanged: (range) =>
                        setState(() => _busbarClosedDateRange = range),
                    currentStatus: _busbarClosedDateStatus,
                    onStatusChanged: (status) =>
                        setState(() => _busbarClosedDateStatus = status),
                  ),
                  const SizedBox(height: 24),
                  
                  // [BARU] UI untuk filter Position
                  const Text(
                    "Position",
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    children: positionOptions
                        .map(
                          (position) => _buildOptionButton(
                            label: position,
                            selected: _selectedPositions.contains(position),
                            onTap: () =>
                                _toggleSelection(_selectedPositions, position),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 24),

                  const Text("Status Isu",
                      style: TextStyle(fontWeight: FontWeight.w500)),
                  const SizedBox(height: 12),
                  Wrap(
                    children: [
                      _buildOptionButton(
                        label: "Ada Isu",
                        selected: _selectedIssueStatus == IssueFilter.withIssues,
                        onTap: () => setState(() => _selectedIssueStatus =
                            _selectedIssueStatus == IssueFilter.withIssues
                                ? IssueFilter.any
                                : IssueFilter.withIssues),
                      ),
                      _buildOptionButton(
                        label: "Tidak Ada Isu",
                        selected:
                            _selectedIssueStatus == IssueFilter.withoutIssues,
                        onTap: () => setState(() => _selectedIssueStatus =
                            _selectedIssueStatus == IssueFilter.withoutIssues
                                ? IssueFilter.any
                                : IssueFilter.withoutIssues),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text("Status SR",
                      style: TextStyle(fontWeight: FontWeight.w500)),
                  const SizedBox(height: 12),
                  Wrap(
                    children: [
                      _buildOptionButton(
                        label: "Ada SR",
                        selected: _selectedSrStatus == SrFilter.withSr,
                        onTap: () => setState(() => _selectedSrStatus =
                            _selectedSrStatus == SrFilter.withSr
                                ? SrFilter.any
                                : SrFilter.withSr),
                      ),
                      _buildOptionButton(
                        label: "Tidak Ada SR",
                        selected: _selectedSrStatus == SrFilter.withoutSr,
                        onTap: () => setState(() => _selectedSrStatus =
                            _selectedSrStatus == SrFilter.withoutSr
                                ? SrFilter.any
                                : SrFilter.withoutSr),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    "Status Panel (% Progres)",
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    children: [
                      _buildOptionButton(
                        label: "0%",
                        leading: const CircleAvatar(
                          backgroundColor: AppColors.red,
                          radius: 7,
                        ),
                        selected: _selectedPanelStatuses
                            .contains(PanelFilterStatus.progressGrey),
                        onTap: () => _toggleSelection(
                          _selectedPanelStatuses,
                          PanelFilterStatus.progressGrey,
                        ),
                      ),
                      _buildOptionButton(
                        label: "1-49%",
                        leading: const CircleAvatar(
                          backgroundColor: AppColors.red,
                          radius: 7,
                        ),
                        selected: _selectedPanelStatuses
                            .contains(PanelFilterStatus.progressRed),
                        onTap: () => _toggleSelection(
                          _selectedPanelStatuses,
                          PanelFilterStatus.progressRed,
                        ),
                      ),
                      _buildOptionButton(
                        label: "50-75%",
                        leading: const CircleAvatar(
                          backgroundColor: AppColors.orange,
                          radius: 7,
                        ),
                        selected: _selectedPanelStatuses
                            .contains(PanelFilterStatus.progressOrange),
                        onTap: () => _toggleSelection(
                          _selectedPanelStatuses,
                          PanelFilterStatus.progressOrange,
                        ),
                      ),
                      _buildOptionButton(
                        label: "76-99%",
                        leading: const CircleAvatar(
                          backgroundColor: AppColors.blue,
                          radius: 7,
                        ),
                        selected: _selectedPanelStatuses
                            .contains(PanelFilterStatus.progressBlue),
                        onTap: () => _toggleSelection(
                          _selectedPanelStatuses,
                          PanelFilterStatus.progressBlue,
                        ),
                      ),
                      _buildOptionButton(
                        label: "100% (Ready)",
                        leading: const CircleAvatar(
                          backgroundColor: AppColors.blue,
                          radius: 7,
                        ),
                        selected: _selectedPanelStatuses
                            .contains(PanelFilterStatus.readyToDelivery),
                        onTap: () => _toggleSelection(
                          _selectedPanelStatuses,
                          PanelFilterStatus.readyToDelivery,
                        ),
                      ),
                      _buildOptionButton(
                        label: "100% (Closed)",
                        leading: const CircleAvatar(
                          backgroundColor: AppColors.schneiderGreen,
                          radius: 7,
                        ),
                        selected: _selectedPanelStatuses
                            .contains(PanelFilterStatus.closed),
                        onTap: () => _toggleSelection(
                          _selectedPanelStatuses,
                          PanelFilterStatus.closed,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    "Tipe Panel",
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    children: ["MCCF", "MCCW", "PCC", "Belum Diatur"]
                        .map(
                          (type) => _buildOptionButton(
                            label: type,
                            selected: _selectedPanelTypes.contains(type),
                            onTap: () =>
                                _toggleSelection(_selectedPanelTypes, type),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "Status Busbar",
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    children: busbarStatusOptions
                        .map(
                          (status) => _buildOptionButton(
                            label: status,
                            selected: _selectedStatuses.contains(status),
                            onTap: () =>
                                _toggleSelection(_selectedStatuses, status),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "Status Picking Component",
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    children: componentStatusOptions
                        .map(
                          (status) => _buildOptionButton(
                            label: status,
                            selected: _selectedComponents.contains(status),
                            onTap: () =>
                                _toggleSelection(_selectedComponents, status),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "Status Palet",
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    children: paletAndCorepartStatusOptions
                        .map(
                          (status) => _buildOptionButton(
                            label: status,
                            selected: _selectedPalet.contains(status),
                            onTap: () =>
                                _toggleSelection(_selectedPalet, status),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "Status Corepart",
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    children: paletAndCorepartStatusOptions
                        .map(
                          (status) => _buildOptionButton(
                            label: status,
                            selected: _selectedCorepart.contains(status),
                            onTap: () =>
                                _toggleSelection(_selectedCorepart, status),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "Vendor Panel (K3) / Palet / Corepart",
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    children: [
                      _buildOptionButton(
                        label: 'No Vendor',
                        selected: _selectedPanelVendors.contains('No Vendor'),
                        onTap: () => _toggleSelection(
                          _selectedPanelVendors,
                          'No Vendor',
                        ),
                      ),
                      ...widget.allK3Vendors.map(
                        (vendor) => _buildOptionButton(
                          label: vendor.name,
                          selected: _selectedPanelVendors.contains(vendor.id),
                          onTap: () => _toggleSelection(
                            _selectedPanelVendors,
                            vendor.id,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "Vendor Busbar (K5)",
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    children: [
                      _buildOptionButton(
                        label: 'No Vendor',
                        selected: _selectedBusbarVendors.contains('No Vendor'),
                        onTap: () => _toggleSelection(
                          _selectedBusbarVendors,
                          'No Vendor',
                        ),
                      ),
                      ...widget.allK5Vendors.map(
                        (vendor) => _buildOptionButton(
                          label: vendor.name,
                          selected: _selectedBusbarVendors.contains(vendor.id),
                          onTap: () => _toggleSelection(
                            _selectedBusbarVendors,
                            vendor.id,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "Urut Berdasarkan",
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    children: [
                      _buildOptionButton(
                        label: "Durasi Lama",
                        selected: _selectedSort == SortOption.durationDesc,
                        onTap: () => setState(
                          () => _selectedSort =
                              _selectedSort == SortOption.durationDesc
                                  ? null
                                  : SortOption.durationDesc,
                        ),
                      ),
                      _buildOptionButton(
                        label: "Durasi Cepat",
                        selected: _selectedSort == SortOption.durationAsc,
                        onTap: () => setState(
                          () => _selectedSort =
                              _selectedSort == SortOption.durationAsc
                                  ? null
                                  : SortOption.durationAsc,
                        ),
                      ),
                      _buildOptionButton(
                        label: "% Besar",
                        selected: _selectedSort == SortOption.percentageDesc,
                        onTap: () => setState(
                          () => _selectedSort =
                              _selectedSort == SortOption.percentageDesc
                                  ? null
                                  : SortOption.percentageDesc,
                        ),
                      ),
                      _buildOptionButton(
                        label: "% Kecil",
                        selected: _selectedSort == SortOption.percentageAsc,
                        onTap: () => setState(
                          () => _selectedSort =
                              _selectedSort == SortOption.percentageAsc
                                  ? null
                                  : SortOption.percentageAsc,
                        ),
                      ),
                      _buildOptionButton(
                        label: "No. Panel A-Z",
                        selected: _selectedSort == SortOption.panelNoAZ,
                        onTap: () => setState(
                          () => _selectedSort =
                              _selectedSort == SortOption.panelNoAZ
                                  ? null
                                  : SortOption.panelNoAZ,
                        ),
                      ),
                      _buildOptionButton(
                        label: "No. Panel Z-A",
                        selected: _selectedSort == SortOption.panelNoZA,
                        onTap: () => setState(
                          () => _selectedSort =
                              _selectedSort == SortOption.panelNoZA
                                  ? null
                                  : SortOption.panelNoZA,
                        ),
                      ),
                      _buildOptionButton(
                        label: "No. PP A-Z",
                        selected: _selectedSort == SortOption.ppNoAZ,
                        onTap: () => setState(
                          () => _selectedSort =
                              _selectedSort == SortOption.ppNoAZ
                                  ? null
                                  : SortOption.ppNoAZ,
                        ),
                      ),
                      _buildOptionButton(
                        label: "No. PP Z-A",
                        selected: _selectedSort == SortOption.ppNoZA,
                        onTap: () => setState(
                          () => _selectedSort =
                              _selectedSort == SortOption.ppNoZA
                                  ? null
                                  : SortOption.ppNoZA,
                        ),
                      ),
                      _buildOptionButton(
                        label: "No. WBS A-Z",
                        selected: _selectedSort == SortOption.wbsNoAZ,
                        onTap: () => setState(
                          () => _selectedSort =
                              _selectedSort == SortOption.wbsNoAZ
                                  ? null
                                  : SortOption.wbsNoAZ,
                        ),
                      ),
                      _buildOptionButton(
                        label: "No. WBS Z-A",
                        selected: _selectedSort == SortOption.wbsNoZA,
                        onTap: () => setState(
                          () => _selectedSort =
                              _selectedSort == SortOption.wbsNoZA
                                  ? null
                                  : SortOption.wbsNoZA,
                        ),
                      ),
                      _buildOptionButton(
                        label: "Project A-Z",
                        selected: _selectedSort == SortOption.projectNoAZ,
                        onTap: () => setState(
                          () => _selectedSort =
                              _selectedSort == SortOption.projectNoAZ
                                  ? null
                                  : SortOption.projectNoAZ,
                        ),
                      ),
                      _buildOptionButton(
                        label: "Project Z-A",
                        selected: _selectedSort == SortOption.projectNoZA,
                        onTap: () => setState(
                          () => _selectedSort =
                              _selectedSort == SortOption.projectNoZA
                                  ? null
                                  : SortOption.projectNoZA,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: AppColors.schneiderGreen),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  child: const Text(
                    "Batal",
                    style: TextStyle(
                      color: AppColors.schneiderGreen,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _applyFilters,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: AppColors.schneiderGreen,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  child: const Text(
                    "Terapkan",
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}