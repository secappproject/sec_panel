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
  List<IssueWithPhotos> _allIssues = [];
  List<IssueWithPhotos> _unsolvedIssues = [];
  List<IssueWithPhotos> _solvedIssues = [];
  bool _isLoading = true;
  String? _errorMessage;

  String _appBarTitle = ' ';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadIssues();
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
        setState(() {
          _allIssues = issues;
          _unsolvedIssues = issues
              .where((i) => i.status == 'unsolved')
              .toList();
          _solvedIssues = issues.where((i) => i.status == 'solved').toList();
          _isLoading = false;
        });
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
                if (mounted) {
                  setState(() {
                    _appBarTitle = newTitle;
                  });
                }
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
                      const Divider(
                        height: 1,
                        thickness: 1,
                        color: AppColors.grayLight,
                      ),
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
                      Tab(text: 'All (${_allIssues.length})'),
                      Tab(text: 'Unsolved (${_unsolvedIssues.length})'),
                      Tab(text: 'Solved (${_solvedIssues.length})'),
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
                    _buildIssueList(_allIssues),
                    _buildIssueList(_unsolvedIssues),
                    _buildIssueList(_solvedIssues),
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
            const Center(
              child: Text(
                'Tidak ada isu di kategori ini.',
                style: TextStyle(
                  color: AppColors.gray,
                  fontWeight: FontWeight.w400,
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
          child: Container(
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
      builder: (context) {
        return AddIssueBottomSheet(
          panelNoPp: widget.panelNoPp,
          onIssueAdded: widget.onIssueAdded,
        );
      },
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
