import 'package:flutter/material.dart';
import 'package:secpanel/components/issue/add_issue_bottom_sheet.dart';
import 'package:secpanel/components/issue/issue_card.dart';
import 'package:secpanel/components/issue/issue_card_skeleton.dart';
import 'package:secpanel/components/issue/issue_chat/ask_ai.dart';
import 'package:secpanel/helpers/db_helper.dart';
import 'package:secpanel/theme/colors.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';

import '../../models/issue.dart';

final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

class PanelIssuesScreen extends StatefulWidget {
  final String panelNoPp;
  final String panelVendor;
  final String panelNoPanel;
  final String panelNoWBS;
  final String busbarVendor;
  final int issueCount;

  const PanelIssuesScreen({
    super.key,
    required this.panelNoPp,
    required this.panelVendor,
    required this.busbarVendor,
    required this.panelNoPanel,
    required this.panelNoWBS,
    required this.issueCount
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

// --- ▼▼▼ [PERUBAHAN 1] Menggunakan Record untuk menyimpan 2 count ▼▼▼ ---
typedef RootCauseCount = ({int unsolved, int solved});

class _PanelIssuesScreenState extends State<PanelIssuesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List<IssueWithPhotos> _allIssues = [];
  List<IssueWithPhotos> _filteredAllIssues = [];
  List<IssueWithPhotos> _filteredUnsolvedIssues = [];
  List<IssueWithPhotos> _filteredSolvedIssues = [];

  List<String> _allRootCauses = [];
  List<String> _selectedRootCauses = [];

  // --- ▼▼▼ [PERUBAHAN 2] State variable diubah untuk menyimpan 2 count ▼▼▼ ---
  Map<String, RootCauseCount> _rootCauseCounts = {};
  int _totalUnsolvedCount = 0;
  int _totalSolvedCount = 0;

  bool _isLoading = true;
  String? _errorMessage;
  String _appBarTitle = ' ';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: 1, // 0 = All, 1 = Unsolved, 2 = Solved
    );
    _loadInitialData();
  }


  void _showAiChatSheet() async {
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString('loggedInUsername');

    if (username != null && mounted) {
      final currentUser = User(id: username, name: username);
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => AskAiScreen(
            panelNoPp: widget.panelNoPp ,
            panelTitle: (() {
              final title = "${widget.panelNoPanel} ${widget.panelNoWBS}".trim();
              if (title.isEmpty || title.startsWith("TEMP")) {
                return "Belum Diatur";
              }
              return title;
            })(),
            currentUser: currentUser,
            onUpdate: () => _loadIssues(showLoading: false),
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Gagal mengidentifikasi user.")),
      );
    }
  }

  // --- ▼▼▼ [PERUBAHAN 3] Logika kalkulasi count diubah total ▼▼▼ ---
  void _processIssueData(
    List<IssueWithPhotos> issues, {
    List<Map<String, dynamic>>? rootCauseMaps,
  }) {
    final counts = <String, ({int unsolved, int solved})>{};
    int totalUnsolved = 0;
    int totalSolved = 0;

    for (var issue in issues) {
      final trimmedTitle = issue.title.trim();
      // Inisialisasi jika belum ada
      counts.putIfAbsent(trimmedTitle, () => (unsolved: 0, solved: 0));

      var current = counts[trimmedTitle]!;
      if (issue.status == 'solved') {
        counts[trimmedTitle] = (
          unsolved: current.unsolved,
          solved: current.solved + 1,
        );
        totalSolved++;
      } else {
        counts[trimmedTitle] = (
          unsolved: current.unsolved + 1,
          solved: current.solved,
        );
        totalUnsolved++;
      }
    }

    setState(() {
      _allIssues = issues;
      _rootCauseCounts = counts;
      _totalUnsolvedCount = totalUnsolved;
      _totalSolvedCount = totalSolved;

      if (rootCauseMaps != null) {
        _allRootCauses = rootCauseMaps
            .map((map) => map['title'] as String)
            .toList();
      }
      _isLoading = false;
      _applyFilter();
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
      setState(() => _isLoading = true);
    }
    try {
      final issues = await DatabaseHelper.instance.getIssuesByPanel(
        widget.panelNoPp,
      );
      if (mounted) {
        // Hanya memproses ulang issue, tidak perlu load ulang root cause
        _processIssueData(issues);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = "Gagal memuat isu: ${e.toString()}");
      }
    } finally {
      if (showLoading && mounted) setState(() => _isLoading = false);
    }
  }

  void _applyFilter() {
    final filtered = _selectedRootCauses.isEmpty
        ? _allIssues
        : _allIssues
              .where(
                (issue) => _selectedRootCauses.contains(issue.title.trim()),
              )
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
            final newTitle = (() {
            final title = innerBoxIsScrolled ? widget.panelNoPp : 'Belum Diatur';
            if (title.trim().isEmpty || title.startsWith("TEMP")) {
              return '';
            }
            return title;
          })();
            if (newTitle != _appBarTitle) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) setState(() => _appBarTitle = newTitle);
              });
            }
            return [
              if (widget.issueCount != 0)...[
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
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              )],
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

  Widget _buildRootCauseFilter() {
    if (_isLoading) return _buildRootCauseFilterSkeleton();
    if (_allIssues.isEmpty) return const SizedBox(height: 52);

    void _onChipTap(String? cause) {
      setState(() {
        if (cause == null) {
          _selectedRootCauses.clear();
        } else {
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
          _buildFilterChip(
            label: 'Semua',
            isSelected: _selectedRootCauses.isEmpty,
            onTap: () => _onChipTap(null),
            unsolvedCount: _totalUnsolvedCount,
            solvedCount: _totalSolvedCount,
          ),
          ..._allRootCauses.map((cause) {
            final counts = _rootCauseCounts[cause] ?? (unsolved: 0, solved: 0);
            if (counts.unsolved == 0 &&
                counts.solved == 0 &&
                !_selectedRootCauses.contains(cause)) {
              return const SizedBox.shrink();
            }
            return _buildFilterChip(
              label: cause,
              isSelected: _selectedRootCauses.contains(cause),
              onTap: () => _onChipTap(cause),
              unsolvedCount: counts.unsolved,
              solvedCount: counts.solved,
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildRootCauseFilterSkeleton() {
    Widget placeholderChip({double width = 80}) {
      return Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Container(width: width, height: 14, color: Colors.white),
            const SizedBox(width: 8),
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(11),
              ),
            ),
          ],
        ),
      );
    }

    return Shimmer.fromColors(
      baseColor: Colors.grey[200]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: ListView(
          scrollDirection: Axis.horizontal,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            placeholderChip(width: 50),
            placeholderChip(width: 70),
            placeholderChip(width: 90),
            placeholderChip(width: 60),
          ],
        ),
      ),
    );
  }

  // --- ▼▼▼ [PERUBAHAN 5] Widget _buildFilterChip diubah untuk menampilkan 2 count ▼▼▼ ---
  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    int? unsolvedCount,
    int? solvedCount,
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

    final hasUnsolved = unsolvedCount != null && unsolvedCount > 0;
    final hasSolved = solvedCount != null && solvedCount > 0;

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
            if (hasUnsolved || hasSolved) ...[
              const SizedBox(width: 8),
              if (hasUnsolved)
                _buildCountPill(unsolvedCount, Colors.red.shade700),
              if (hasUnsolved && hasSolved) const SizedBox(width: 4),
              if (hasSolved)
                _buildCountPill(solvedCount, AppColors.schneiderGreen),
            ],
          ],
        ),
      ),
    );
  }

  // --- ▼▼▼ [PERUBAHAN 6] Widget helper baru untuk membuat pill count ▼▼▼ ---
  Widget _buildCountPill(int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6.5, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        count.toString(),
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
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
    final title = "${widget.panelNoPanel} ${widget.panelNoWBS}".trim();
    final noPanel = widget.panelNoPanel;
    final noWBS = widget.panelNoWBS;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ((noPanel == "" && noWBS == "") || title.startsWith("TEMP")) ? "Belum Diatur" : title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w400,
                    color: AppColors.black,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildInfoChip(
                      "Panel",
                      widget.panelVendor.isNotEmpty
                          ? widget.panelVendor
                          : 'No Vendor',
                    ),
                    const SizedBox(width: 12),
                    _buildInfoChip(
                      "Busbar",
                      widget.busbarVendor.isNotEmpty
                          ? widget.busbarVendor
                          : 'No Vendor',
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          GestureDetector(
            onTap: _showAiChatSheet,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset("assets/images/askai.png", height: 32),
                const SizedBox(height: 2),
                Text(
                  "Tanya AI",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: AppColors.schneiderGreen,
                  ),
                ),
              ],
            ),
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
    if (issues.isEmpty && _allIssues.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => _loadIssues(),
        child: ListView(
          children: [
            AddIssuePostBox(
              onIssueAdded: () => _loadIssues(showLoading: false),
              panelNoPp: widget.panelNoPp,
            ),
            const SizedBox(height: 100),
            const Center(
              child: Text(
                'Belum ada isu untuk panel ini.',
                style: TextStyle(
                  color: AppColors.gray,
                  fontWeight: FontWeight.w300,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (issues.isEmpty && _selectedRootCauses.isNotEmpty) {
      return RefreshIndicator(
        onRefresh: () => _loadIssues(),
        child: ListView(
          children: [
            AddIssuePostBox(
              onIssueAdded: () => _loadIssues(showLoading: false),
              panelNoPp: widget.panelNoPp,
            ),
            const SizedBox(height: 100),
            const Center(
              child: Text(
                'Tidak ada isu dengan root cause yang dipilih.',
                style: TextStyle(
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
                  panelNoPp: widget.panelNoPp,
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

// ... (Sisa kode: _SliverAppBarDelegate dan AddIssuePostBox tidak berubah) ...
// (Salin sisa kode dari file asli Anda ke sini)
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
