import 'package:file_picker/file_picker.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:secpanel/components/bulkdelete/bulk_delete_screen.dart';
import 'package:secpanel/components/export/export_bottom_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:secpanel/components/panel/add/add_panel_bottom_sheet.dart';
import 'package:secpanel/components/import/import_bottom_sheet.dart';
import 'package:secpanel/custom_bottom_navbar.dart';
import 'package:secpanel/helpers/db_helper.dart';
import 'package:secpanel/home.dart';
import 'package:secpanel/models/approles.dart';
import 'package:secpanel/models/company.dart';
import 'package:secpanel/models/paneldisplaydata.dart';
import 'package:secpanel/profile.dart';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:secpanel/theme/colors.dart';

// --- WIDGET SIDEBAR (Perbaikan Layout Saat Collapsed) ---
class AppSidebar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onPageSelected;
  final Company? currentUser;
  final VoidCallback onAddPanel;
  final bool canAddPanel;
  final bool isExpanded;

  const AppSidebar({
    super.key,
    required this.selectedIndex,
    required this.onPageSelected,
    required this.currentUser,
    required this.onAddPanel,
    required this.canAddPanel,
    required this.isExpanded,
    // onToggle sudah tidak ada lagi di sini, karena tombolnya pindah
  });

  @override
  Widget build(BuildContext context) {
    const sidebarColor = Color(0xFFFFFFFF);
    const textColor = AppColors.black;
    const iconColor = Color(0xFF6B7280);
    const hoverColor = Color(0xFFF3F4F6);
    final activeColor = AppColors.schneiderGreen;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: isExpanded ? 280 : 80,
      decoration: const BoxDecoration(
        color: sidebarColor,
        border: Border(right: BorderSide(color: Color(0xFFE5E7EB), width: 1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- PERUBAHAN DIMULAI DI SINI ---
            // Header dan SizedBox hanya ditampilkan saat sidebar 'expanded'
            if (isExpanded) ...[
              _buildHeader(textColor),
              const SizedBox(height: 16),
            ],
            // --- PERUBAHAN BERAKHIR DI SINI ---
            
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _buildNavTile("Panel", 'assets/images/panel-off.png', 0, selectedIndex == 0, hoverColor, iconColor, activeColor, textColor, activeColor),
                  _buildNavTile("Profil", 'assets/images/profile-off.png', 1, selectedIndex == 1, hoverColor, iconColor, activeColor, textColor, activeColor),
                  const Divider(color: hoverColor, height: 32),
                  if (canAddPanel) _buildActionTile("Tambah Panel", 'assets/images/plus.png', onAddPanel, hoverColor, activeColor, textColor),
                ],
              ),
            ),
            _buildUserProfile(currentUser, hoverColor, textColor, textColor),
          ],
        ),
      ),
    );
  }
  
  // --- PERUBAHAN KECIL: Menghapus tinggi tetap dari Container ---
  Widget _buildHeader(Color textColor) {
    final userName = currentUser?.name ?? 'Pengguna';
    return Container( // height: 72 dihapus dari sini
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      alignment: Alignment.centerLeft,
      child: Text.rich(
        TextSpan(
          text: 'Selamat Datang,\n',
          style: TextStyle(
            color: AppColors.gray,
            fontSize: 16,
            height: 1.4,
            fontWeight: FontWeight.w300,
          ),
          children: <TextSpan>[
            TextSpan(
              text: '$userName👋 ',
              style: const TextStyle(
                color: AppColors.black,
                fontSize: 20,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  // --- Widget helper lainnya tidak berubah ---
  Widget _buildNavTile(String title, String imagePath, int index, bool isSelected, Color hoverColor, Color iconColor, Color iconActiveColor, Color textColor, Color textActiveColor) {
    return Material(
      color: Colors.transparent,
      child: Tooltip(
        message: isExpanded ? '' : title,
        child: InkWell(
          onTap: () => onPageSelected(index),
          borderRadius: BorderRadius.circular(8),
          hoverColor: hoverColor,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? hoverColor : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: isExpanded ? MainAxisAlignment.start : MainAxisAlignment.center,
              children: [
                Image.asset(
                  imagePath,
                  width: 22,
                  height: 22,
                  color: isSelected ? iconActiveColor : iconColor,
                ),
                if (isExpanded) const SizedBox(width: 16),
                if (isExpanded)
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isSelected ? FontWeight.w400 : FontWeight.w300,
                        color: isSelected ? textActiveColor : textColor,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionTile(String title, String imagePath, VoidCallback onTap, Color hoverColor, Color iconColor, Color textColor) {
    return Material(
      color: Colors.transparent,
      child: Tooltip(
        message: isExpanded ? '' : title,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          hoverColor: hoverColor,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: isExpanded ? MainAxisAlignment.start : MainAxisAlignment.center,
              children: [
                Image.asset(
                  imagePath,
                  width: 22,
                  height: 22,
                  color: iconColor,
                ),
                if (isExpanded) const SizedBox(width: 16),
                if (isExpanded)
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(fontSize: 14, color: textColor, fontWeight: FontWeight.w300),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserProfile(Company? user, Color hoverColor, Color textColor, Color textActiveColor) {
    if (user == null) return const SizedBox.shrink();
    final double avatarRadius = isExpanded ? 20 : 18;
    final EdgeInsets padding = isExpanded ? const EdgeInsets.all(8.0) : const EdgeInsets.symmetric(vertical: 6.0, horizontal: 0);

    return Material(
      color: Colors.transparent,
      child: Tooltip(
        message: isExpanded ? '' : user.name,
        child: InkWell(
          onTap: () => onPageSelected(1),
          borderRadius: BorderRadius.circular(8),
          hoverColor: hoverColor,
          child: Padding(
            padding: padding,
            child: Row(
              mainAxisAlignment: isExpanded ? MainAxisAlignment.start : MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.schneiderGreen,
                  radius: avatarRadius,
                  child: Text(
                    user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w400),
                  ),
                ),
                if (isExpanded) const SizedBox(width: 12),
                if (isExpanded)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.name,
                          style: TextStyle(color: textActiveColor, fontWeight: FontWeight.w400),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          user.role.name,
                          style: TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.w300),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// --- CLASS UTAMA MainScreen ---
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  Company? _currentCompany;
  List<Company> _k3Vendors = [];
  List<Widget> _pages = [];
  bool _isLoading = true;
  bool _isSidebarExpanded = true;

  final GlobalKey<HomeScreenState> homeScreenKey = GlobalKey<HomeScreenState>();

  @override
  void initState() {
    super.initState();
    _loadCompanyDataAndInitializePages();
  }

  void _toggleSidebar() {
    setState(() {
      _isSidebarExpanded = !_isSidebarExpanded;
    });
  }

  // --- Semua fungsi logika lainnya tetap sama ---
  Future<void> _loadCompanyDataAndInitializePages() async {
    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    final companyId = prefs.getString('companyId');
    if (companyId == null) {
      if (mounted) Navigator.of(context).pushReplacementNamed('/login');
      return;
    }
    final company = await DatabaseHelper.instance.getCompanyById(companyId);
    if (company == null) {
      if (mounted) Navigator.of(context).pushReplacementNamed('/login');
      return;
    }
    final k3Vendors = await DatabaseHelper.instance.getK3Vendors();
    if (mounted) {
      setState(() {
        _currentCompany = company;
        _k3Vendors = k3Vendors;
        _pages = [
          HomeScreen(key: homeScreenKey, currentCompany: _currentCompany!),
          const ProfileScreen(),
        ];
        _isLoading = false;
      });
    }
  }

  void _showExportBottomSheet() async {
    final homeScreenState = homeScreenKey.currentState;
    if (homeScreenState == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Tidak bisa memuat data panel untuk preview."),
        ),
      );
      return;
    }
    final List<PanelDisplayData> filteredPanelsForPreview =
        homeScreenState.filteredPanelsForDisplay;
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return PreviewBottomSheet(
          currentUser: _currentCompany!,
          filteredPanels: filteredPanelsForPreview,
        );
      },
    );
    if (result != null && mounted) {
      await _processExport(result);
    }
  }

  Future<void> _processExport(Map<String, dynamic> exportData) async {
    final homeScreenState = homeScreenKey.currentState;
    if (homeScreenState == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Gagal memuat filter aktif.")),
        );
      }
      return;
    }
    final bool exportPanel = exportData['exportPanel'] as bool? ?? false;
    final bool exportUser = exportData['exportUser'] as bool? ?? false;
    final format = exportData['format'] as String;
    if (!exportPanel && !exportUser) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tidak ada data yang dipilih untuk di-extract.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Dialog(
          child: Padding(
            padding: EdgeInsets.all(20.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: AppColors.schneiderGreen),
                SizedBox(width: 20),
                Text("Meng-extract data..."),
              ],
            ),
          ),
        );
      },
    );
    String? successMessage;
    String? errorMessage;
    try {
      final timestamp = DateFormat('ddMMyy_HHmmss').format(DateTime.now());
      String extension;
      List<int>? fileBytes;
      final Company currentUser = _currentCompany!;
      final List<PanelDisplayData> panelsToExport =
          homeScreenState.filteredPanelsForDisplay;
      switch (format) {
        case 'Excel':
          extension = 'xlsx';
          final excel = await DatabaseHelper.instance.generateCustomExportExcel(
            includePanelData: exportPanel,
            includeUserData: exportUser,
            currentUser: currentUser,
            filteredPanels: panelsToExport,
            startDateRange: homeScreenState.startDateRange,
            deliveryDateRange: homeScreenState.deliveryDateRange,
            closedDateRange: homeScreenState.closedDateRange,
            selectedPanelTypes: homeScreenState.selectedPanelTypes,
            selectedPanelVendors: homeScreenState.selectedPanelVendors,
            selectedBusbarVendors: homeScreenState.selectedBusbarVendors,
            selectedComponentVendors: homeScreenState.selectedComponentVendors,
            selectedPaletVendors: homeScreenState.selectedPaletVendors,
            selectedCorepartVendors: homeScreenState.selectedCorepartVendors,
            selectedStatuses: homeScreenState.selectedStatuses,
            selectedComponents: homeScreenState.selectedComponents,
            selectedPalet: homeScreenState.selectedPalet,
            selectedCorepart: homeScreenState.selectedCorepart,
            selectedPanelStatuses: homeScreenState.selectedPanelStatuses,
            includeArchived: homeScreenState.includeArchived,
          );
          fileBytes = excel.encode();
          break;
        case 'JSON':
          extension = 'json';
          final jsonString = await DatabaseHelper.instance.generateCustomExportJson(
            includePanelData: exportPanel,
            includeUserData: exportUser,
            currentUser: currentUser,
            startDateRange: homeScreenState.startDateRange,
            deliveryDateRange: homeScreenState.deliveryDateRange,
            closedDateRange: homeScreenState.closedDateRange,
            selectedPanelTypes: homeScreenState.selectedPanelTypes,
            selectedPanelVendors: homeScreenState.selectedPanelVendors,
            selectedBusbarVendors: homeScreenState.selectedBusbarVendors,
            selectedComponentVendors: homeScreenState.selectedComponentVendors,
            selectedPaletVendors: homeScreenState.selectedPaletVendors,
            selectedCorepartVendors: homeScreenState.selectedCorepartVendors,
            selectedStatuses: homeScreenState.selectedStatuses,
            selectedComponents: homeScreenState.selectedComponents,
            selectedPalet: homeScreenState.selectedPalet,
            selectedCorepart: homeScreenState.selectedCorepart,
            selectedPanelStatuses: homeScreenState.selectedPanelStatuses,
            includeArchived: homeScreenState.includeArchived,
          );
          fileBytes = utf8.encode(jsonString);
          break;
        default:
          throw Exception("Format tidak dikenal");
      }
      final fileName = "ExportDataPanel_$timestamp.$extension";
      if (kIsWeb) {
        MimeType mimeType = MimeType.other;
        if (format == 'Excel') mimeType = MimeType.microsoftExcel;
        if (format == 'JSON') mimeType = MimeType.json;
        await FileSaver.instance.saveFile(
          name: fileName,
          bytes: Uint8List.fromList(fileBytes ?? []),
          ext: extension,
          mimeType: mimeType,
        );
        successMessage = "File $fileName berhasil diunduh dan tersimpan otomatis di folder Download.";
      } else {
        final selectedPath = await FilePicker.platform.getDirectoryPath();
        if (selectedPath != null) {
          final path = "$selectedPath/$fileName";
          final file = File(path);
          await file.writeAsBytes(fileBytes ?? []);
          successMessage = "File berhasil disimpan di: $path";
          if (Platform.isIOS || Platform.isAndroid) {
            await Share.shareXFiles([XFile(path)], text: 'File Extract Data');
          }
        } else {
          errorMessage = "Extract dibatalkan: Tidak ada folder yang dipilih.";
        }
      }
    } catch (e) {
      errorMessage = "Extract gagal: ${e.toString()}";
    } finally {
      if (mounted) Navigator.of(context).pop();
    }
    if (mounted) {
      if (successMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(successMessage),
            duration: const Duration(seconds: 4),
            backgroundColor: AppColors.schneiderGreen,
          ),
        );
      }
      if (errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _refreshHomeScreen() {
    homeScreenKey.currentState?.loadInitialData();
  }

  void _onItemTapped(int index) => setState(() => _selectedIndex = index);

  void _openAddPanelSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => AddPanelBottomSheet(
        currentCompany: _currentCompany!,
        k3Vendors: _k3Vendors,
        onPanelAdded: (newPanel) => _refreshHomeScreen(),
      ),
    );
  }

  void _showImportBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => ImportBottomSheet(
        onImportSuccess: () {
          _refreshHomeScreen();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Data berhasil diperbarui!'),
              backgroundColor: AppColors.schneiderGreen,
            ),
          );
        },
      ),
    );
  }

void _showBulkDeleteBottomSheet() {
  final homeScreenState = homeScreenKey.currentState;
  if (homeScreenState == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Tidak bisa memuat data panel untuk Bulk Delete."),
      ),
    );
    return;
  }
  
  // Perubahan: Ambil data panel yang sudah terfilter dari HomeScreenState
  final List<PanelDisplayData> filteredPanelsForDelete = homeScreenState.filteredPanelsForDisplay; 

  showModalBottomSheet<BulkDeleteResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    // Perubahan: Teruskan data panel yang sudah terfilter ke BulkDeleteBottomSheet
    builder: (context) => BulkDeleteBottomSheet(panelsToDisplay: filteredPanelsForDelete), 
  ).then((result) {
      if (result != null && mounted) {
        if (result.message.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.message),
              backgroundColor: result.success ? AppColors.schneiderGreen : Colors.red,
            ),
          );
        }
        if (result.dataHasChanged) _refreshHomeScreen();
      }
    });
  }

  Widget _buildMassDataFab() {
    final bool canImportData = _currentCompany?.role == AppRole.admin || _currentCompany?.role == AppRole.k3;
    final bool canExportData = true;
    final bool canBulkDelete = _currentCompany?.role == AppRole.admin;

    return PopupMenuButton<String>(
      offset: const Offset(0, -140),
      color: AppColors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: AppColors.grayLight, width: 2),
      ),
      itemBuilder: (BuildContext context) {
        List<PopupMenuEntry<String>> items = [];
        if (canImportData) {
          items.add(
            PopupMenuItem<String>(
              value: 'import',
              height: 36,
              child: Row(children: [
                Image.asset('assets/images/import-green.png', width: 24, height: 24, color: AppColors.schneiderGreen),
                const SizedBox(width: 12),
                const Text('Upload', style: TextStyle(color: AppColors.black, fontSize: 12, fontWeight: FontWeight.w400)),
              ]),
            ),
          );
        }
        if (canExportData) {
          items.add(
            PopupMenuItem<String>(
              value: 'export',
              height: 36,
              child: Row(children: [
                Image.asset('assets/images/export-green.png', width: 24, height: 24, color: AppColors.schneiderGreen),
                const SizedBox(width: 12),
                const Text('Extract', style: TextStyle(color: AppColors.black, fontSize: 12, fontWeight: FontWeight.w400)),
              ]),
            ),
          );
        }
        if (canBulkDelete) {
          items.add(
            PopupMenuItem<String>(
              value: 'bulk_delete',
              height: 36,
              child: Row(children: [
                const Icon(Icons.delete_sweep_outlined, color: AppColors.red, size: 24),
                const SizedBox(width: 12),
                const Text('Bulk Delete', style: TextStyle(color: AppColors.black, fontSize: 12, fontWeight: FontWeight.w400)),
              ]),
            ),
          );
        }
        return items;
      },
      onSelected: (String result) {
        switch (result) {
          case 'import': _showImportBottomSheet(); break;
          case 'export': _showExportBottomSheet(); break;
          case 'bulk_delete': _showBulkDeleteBottomSheet(); break;
        }
      },
      child: FloatingActionButton.extended(
        heroTag: 'dataMenuFab',
        onPressed: null,
        backgroundColor: AppColors.white,
        elevation: 2.0,
        shape: const StadiumBorder(side: BorderSide(color: AppColors.grayLight, width: 1.5)),
        icon: Image.asset('assets/images/import-export-green.png', width: 24, height: 24, color: AppColors.schneiderGreen),
        label: const Text('Mass Data', style: TextStyle(color: AppColors.black, fontSize: 12, fontWeight: FontWeight.w400)),
      ),
    );
  }

  // --- WIDGET BARU: Header untuk area konten utama ---
  Widget _buildContentHeader() {
    // Tentukan judul berdasarkan halaman yang aktif
    final String currentPage = _selectedIndex == 0 ? "Panel" : "Profil";

    return Container(
      color: AppColors.white, // Pastikan ada latar belakang
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Tombol Toggle Sidebar
          IconButton(
            icon: Image.asset(
              // Memilih gambar berdasarkan state _isSidebarExpanded
              _isSidebarExpanded ? 'assets/images/menu-open.png' : 'assets/images/menu-close.png',
              width: 24,  // Atur lebar ikon
              height: 24, 
            ),
            onPressed: _toggleSidebar,
            tooltip: _isSidebarExpanded ? 'Tutup sidebar' : 'Buka sidebar',
          ),
          const SizedBox(width: 16),
          // Breadcrumb
          Text(
            "Halaman Utama",
            style: TextStyle(
              fontSize: 12,
              color: AppColors.gray,
              fontWeight: FontWeight.w300,
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right, color: AppColors.gray, size: 12),
          const SizedBox(width: 8),
          Text(
            currentPage,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: AppColors.black,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.schneiderGreen),
        ),
      );
    }

    final bool canAddPanel = _currentCompany?.role == AppRole.admin || _currentCompany?.role == AppRole.k3;
    
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isDesktop = constraints.maxWidth > 840;

        if (isDesktop) {
          // TAMPILAN DESKTOP DENGAN HEADER KONTEN
          return Scaffold(
            backgroundColor: AppColors.white,
            body: Row(
              children: [
                AppSidebar(
                  selectedIndex: _selectedIndex,
                  onPageSelected: _onItemTapped,
                  currentUser: _currentCompany,
                  onAddPanel: _openAddPanelSheet,
                  canAddPanel: canAddPanel,
                  isExpanded: _isSidebarExpanded,
                  // onToggle dihapus dari sini
                ),
                Expanded(
                  child: Scaffold(
                    backgroundColor: AppColors.white,
                    body: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header baru ditambahkan di sini
                        _buildContentHeader(),
                        const Divider(height: 1, color: Color(0xFFE5E7EB)),
                        // Konten halaman utama
                        Expanded(
                          child: IndexedStack(
                            index: _selectedIndex,
                            children: _pages,
                          ),
                        ),
                      ],
                    ),
                    floatingActionButton: _buildMassDataFab(),
                  ),
                ),
              ],
            ),
          );
        } else {
          // TAMPILAN MOBILE (TIDAK BERUBAH)
          return Scaffold(
            backgroundColor: AppColors.white,
            body: Stack(
              children: [
                IndexedStack(index: _selectedIndex, children: _pages),
                Positioned(
                  bottom: 20,
                  right: 16,
                  child: _buildMassDataFab(),
                ),
              ],
            ),
            floatingActionButton: canAddPanel
                ? FloatingActionButton(
                    heroTag: 'addPanelFabMobile',
                    onPressed: _openAddPanelSheet,
                    backgroundColor: AppColors.schneiderGreen,
                    foregroundColor: AppColors.white,
                    shape: const CircleBorder(),
                    elevation: 0.0,
                    child: const Icon(Icons.add),
                  )
                : null,
            floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
            bottomNavigationBar: Container(
              height: 70,
              decoration: BoxDecoration(
                color: AppColors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    spreadRadius: 1,
                    blurRadius: 10,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: BottomAppBar(
                color: Colors.transparent,
                elevation: 0,
                shape: const CircularNotchedRectangle(),
                notchMargin: 8.0,
                child: CustomBottomNavBar(
                  selectedIndex: _selectedIndex,
                  onItemTapped: _onItemTapped,
                ),
              ),
            ),
          );
        }
      },
    );
  }
}