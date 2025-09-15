import 'package:flutter/material.dart';
import 'package:secpanel/components/issue/add_issue_bottom_sheet.dart';
import 'package:secpanel/components/issue/issue_card.dart';
import 'package:secpanel/components/issue/issue_card_skeleton.dart';
import 'package:secpanel/helpers/db_helper.dart';
import 'package:secpanel/theme/colors.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/issue.dart';

final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

class PanelIssuesScreen extends StatefulWidget {
  final String panelNoPp;
  final String panelVendor;
  final String panelNoPanel;
  final String panelNoWBS;
  final String busbarVendor;

  const PanelIssuesScreen({
    super.key,
    required this.panelNoPp,
    required this.panelVendor,
    required this.busbarVendor,
    required this.panelNoPanel,
    required this.panelNoWBS,
  });

  static void showSnackBar(String message, {bool isError = false}) {
    scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : AppColors.schneiderGreen,
      ),
    );
  }

  @override
  State<PanelIssuesScreen> createState() => _PanelIssuesScreenState();
}

class _PanelIssuesScreenState extends State<PanelIssuesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // State untuk menyimpan semua issue asli
  List<IssueWithPhotos> _allIssues = [];

  // State untuk menyimpan daftar issue yang sudah difilter
  List<IssueWithPhotos> _filteredAllIssues = [];
  List<IssueWithPhotos> _filteredUnsolvedIssues = [];
  List<IssueWithPhotos> _filteredSolvedIssues = [];

  // State untuk filter root cause
  List<String> _allRootCauses = [];
  List<String> _selectedRootCauses = []; // Diubah untuk multi-select
  Map<String, int> _rootCauseCounts =
      {}; // Untuk menyimpan jumlah issue per root cause

  bool _isLoading = true;
  String? _errorMessage;
  String _appBarTitle = ' ';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadInitialData();
  }

  void _processIssueData(
    List<IssueWithPhotos> issues, {
    List<Map<String, dynamic>>? rootCauseMaps,
  }) {
    // Hitung jumlah issue untuk setiap root cause
    final counts = <String, int>{};
    for (var issue in issues) {
      // -- PERBAIKAN DI SINI --
      // Menambahkan .trim() untuk menghapus spasi di awal/akhir judul
      final trimmedTitle = issue.title.trim();
      counts.update(trimmedTitle, (value) => value + 1, ifAbsent: () => 1);
    }

    setState(() {
      _allIssues = issues;
      _rootCauseCounts = counts;
      // Hanya update daftar root cause jika data baru tersedia (saat load awal)
      if (rootCauseMaps != null) {
        _allRootCauses = rootCauseMaps
            .map((map) => map['title'] as String)
            .toList();
      }
      _isLoading = false;
      _applyFilter(); // Terapkan filter
    });
  }

  Future<void> _loadInitialData() async {
    if (mounted) setState(() => _isLoading = true);
    try {
      final issuesFuture = DatabaseHelper.instance.getIssuesByPanel(
        widget.panelNoPp,
      );
      final rootCausesFuture = DatabaseHelper.instance.getIssueTitles();

      final results = await Future.wait([issuesFuture, rootCausesFuture]);
      final issues = results[0] as List<IssueWithPhotos>;
      final rootCauseMaps = results[1] as List<Map<String, dynamic>>;

      if (mounted) {
        _processIssueData(issues, rootCauseMaps: rootCauseMaps);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "Gagal memuat data: ${e.toString()}";
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadIssues({bool showLoading = true}) async {
    if (showLoading && mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }
    try {
      final issues = await DatabaseHelper.instance.getIssuesByPanel(
        widget.panelNoPp,
      );
      if (mounted) {
        _processIssueData(issues); // Proses ulang data issue
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "Gagal memuat isu: ${e.toString()}";
          _isLoading = false;
        });
      }
    }
  }

  void _applyFilter() {
    // Jika _selectedRootCauses kosong, berarti "Semua" dipilih.
    final filtered = _selectedRootCauses.isEmpty
        ? _allIssues
        : _allIssues
              .where((issue) => _selectedRootCauses.contains(issue.title))
              .toList();

    setState(() {
      _filteredAllIssues = filtered;
      _filteredUnsolvedIssues = filtered
          .where((i) => i.status == 'unsolved')
          .toList();
      _filteredSolvedIssues = filtered
          .where((i) => i.status == 'solved')
          .toList();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
      key: scaffoldMessengerKey,
      child: Scaffold(
        backgroundColor: AppColors.white,
        appBar: _buildAppBar(),
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            final newTitle = innerBoxIsScrolled ? widget.panelNoPp : ' ';
            if (newTitle != _appBarTitle) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) setState(() => _appBarTitle = newTitle);
              });
            }
            return [
              SliverToBoxAdapter(
                child: Container(
                  color: AppColors.white,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildPanelHeader(),
                      _buildRootCauseFilter(),
                      const Divider(
                        height: 1,
                        thickness: 1,
                        color: AppColors.grayLight,
                      ),
                      SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
              SliverPersistentHeader(
                delegate: _SliverAppBarDelegate(
                  TabBar(
                    controller: _tabController,
                    labelColor: AppColors.black,
                    unselectedLabelColor: AppColors.gray,
                    labelStyle: const TextStyle(
                      fontWeight: FontWeight.w400,
                      fontSize: 12,
                      fontFamily: 'Lexend',
                    ),
                    unselectedLabelStyle: const TextStyle(
                      fontWeight: FontWeight.w400,
                      fontSize: 12,
                      fontFamily: 'Lexend',
                    ),
                    indicatorColor: AppColors.schneiderGreen,
                    indicatorWeight: 3,
                    indicatorSize: TabBarIndicatorSize.label,
                    dividerColor: Colors.transparent,
                    tabs: [
                      Tab(text: 'All (${_filteredAllIssues.length})'),
                      Tab(text: 'Unsolved (${_filteredUnsolvedIssues.length})'),
                      Tab(text: 'Solved (${_filteredSolvedIssues.length})'),
                    ],
                  ),
                ),
                pinned: true,
              ),
            ];
          },
          body: _isLoading
              ? _buildLoadingSkeleton()
              : _errorMessage != null
              ? Center(child: Text(_errorMessage!))
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildIssueList(_filteredAllIssues),
                    _buildIssueList(_filteredUnsolvedIssues),
                    _buildIssueList(_filteredSolvedIssues),
                  ],
                ),
        ),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      shadowColor: AppColors.grayLight,
      centerTitle: true,
      title: Text(
        _appBarTitle,
        style: const TextStyle(
          color: AppColors.black,
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: AppColors.gray),
        onPressed: () => Navigator.of(context).pop(),
      ),
    );
  }

  // WIDGET BARU: Kustom chip dengan desain yang diinginkan
  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    int? count,
  }) {
    final Color textColor = isSelected
        ? AppColors.schneiderGreen
        : AppColors.black;
    final Color borderColor = isSelected
        ? AppColors.schneiderGreen
        : AppColors.grayLight;
    final Color backgroundColor = isSelected
        ? AppColors.schneiderGreen.withOpacity(0.08)
        : Colors.white;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          color: backgroundColor,
          border: Border.all(color: borderColor),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w400,
                fontSize: 12,
              ),
            ),
            if (count != null) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.schneiderGreen
                      : AppColors.gray.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  count.toString(),
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppColors.black,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // WIDGET BARU: Untuk menampilkan filter chips
  Widget _buildRootCauseFilter() {
    if (_isLoading || _allRootCauses.isEmpty) {
      return const SizedBox.shrink();
    }

    // Handler untuk tap events pada chips
    void _onChipTap(String? cause) {
      setState(() {
        if (cause == null) {
          // Chip "Semua" ditekan
          _selectedRootCauses.clear();
        } else {
          // Chip root cause spesifik ditekan
          if (_selectedRootCauses.contains(cause)) {
            _selectedRootCauses.remove(cause);
          } else {
            _selectedRootCauses.add(cause);
          }
        }
        _applyFilter();
      });
    }

    return Container(
      height: 52,
      color: AppColors.white,
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        scrollDirection: Axis.horizontal,
        children: [
          // _buildFilterChip(
          //   label: 'Semua',
          //   isSelected: _selectedRootCauses.isEmpty,
          //   onTap: () => _onChipTap(null),
          //   count: _allIssues.length,
          // ),
          ..._allRootCauses.map((cause) {
            return _buildFilterChip(
              label: cause,
              isSelected: _selectedRootCauses.contains(cause),
              onTap: () => _onChipTap(cause),
              count: _rootCauseCounts[cause] ?? 0,
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildLoadingSkeleton() {
    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: 3,
      itemBuilder: (context, index) => const IssueCardSkeleton(),
    );
  }

  Widget _buildPanelHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "${(widget.panelNoPp != "" || widget.panelNoPp.contains("TEMP_")) ? "" : "${widget.panelNoPp} "}${widget.panelNoPanel != "" ? widget.panelNoPanel : ""} ${widget.panelNoWBS != "" ? widget.panelNoWBS : ""}",
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w500,
              color: AppColors.black,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildInfoChip(
                "Panel",
                widget.panelVendor != '' ? widget.panelVendor : 'No Vendor',
              ),
              const SizedBox(width: 12),
              _buildInfoChip(
                "Busbar",
                widget.busbarVendor != '' ? widget.busbarVendor : 'No Vendor',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(String label, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.gray,
            fontSize: 11,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.gray.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            value,
            style: const TextStyle(
              color: AppColors.black,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildIssueList(List<IssueWithPhotos> issues) {
    if (issues.isEmpty) {
      bool isFilterActive = _selectedRootCauses.isNotEmpty;
      return RefreshIndicator(
        onRefresh: () => _loadIssues(),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            AddIssuePostBox(
              onIssueAdded: () => _loadIssues(showLoading: false),
              panelNoPp: widget.panelNoPp,
            ),
            const SizedBox(height: 100),
            Center(
              child: Text(
                isFilterActive
                    ? 'Tidak ada isu dengan root cause yang dipilih.'
                    : 'Tidak ada isu di kategori ini.',
                style: const TextStyle(
                  color: AppColors.gray,
                  fontWeight: FontWeight.w300,
                ),
              ),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () => _loadIssues(),
      child: Container(
        color: AppColors.grayLight.withOpacity(0.5),
        child: Center(
          child: SizedBox(
            width: 500,
            child: ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: issues.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return AddIssuePostBox(
                    onIssueAdded: () => _loadIssues(showLoading: false),
                    panelNoPp: widget.panelNoPp,
                  );
                }
                return IssueCard(
                  issue: issues[index - 1],
                  onUpdate: () => _loadIssues(showLoading: false),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);
  final TabBar _tabBar;
  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;
  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(bottom: BorderSide(width: 1, color: Colors.transparent)),
      ),
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) => false;
}

class AddIssuePostBox extends StatefulWidget {
  final VoidCallback onIssueAdded;
  final String panelNoPp;
  const AddIssuePostBox({
    super.key,
    required this.onIssueAdded,
    required this.panelNoPp,
  });

  @override
  State<AddIssuePostBox> createState() => _AddIssuePostBoxState();
}

class _AddIssuePostBoxState extends State<AddIssuePostBox> {
  String _initials = 'US';
  Color _avatarColor = AppColors.gray;

  @override
  void initState() {
    super.initState();
    _loadUserInitials();
  }

  Future<void> _loadUserInitials() async {
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString('loggedInUsername');
    if (username != null && username.isNotEmpty) {
      final initials = username.length >= 2
          ? username.substring(0, 2).toUpperCase()
          : username.toUpperCase();
      final hash =
          initials.codeUnitAt(0) +
          (initials.length > 1 ? initials.codeUnitAt(1) : 0);
      final color = Colors.primaries[hash % Colors.primaries.length];
      if (mounted) {
        setState(() {
          _initials = initials;
          _avatarColor = color;
        });
      }
    }
  }

  void _showAddIssueSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => AddIssueBottomSheet(
        panelNoPp: widget.panelNoPp,
        onIssueAdded: widget.onIssueAdded,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.grayLight),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: _avatarColor,
                radius: 20,
                child: Text(
                  _initials,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () => _showAddIssueSheet(context),
                  child: Container(
                    height: 40,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: AppColors.grayLight.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Ada isu apa sekarang?',
                        style: TextStyle(
                          color: AppColors.gray,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                onPressed: () => _showAddIssueSheet(context),
                icon: const Icon(Icons.add, color: AppColors.gray),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
