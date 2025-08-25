import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
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
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:secpanel/theme/colors.dart';

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

  // Kunci untuk mengakses State dari HomeScreen
  final GlobalKey<HomeScreenState> homeScreenKey = GlobalKey<HomeScreenState>();

  @override
  void initState() {
    super.initState();
    _loadCompanyDataAndInitializePages();
  }

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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Gagal memuat filter aktif.")),
      );
      return;
    }

    final bool exportPanel = exportData['exportPanel'] as bool? ?? false;
    final bool exportUser = exportData['exportUser'] as bool? ?? false;
    final format = exportData['format'] as String;

    if (!exportPanel && !exportUser) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tidak ada data yang dipilih untuk di-extract.'),
            backgroundColor: Colors.orange,
          ),
        );
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
          );
          fileBytes = excel.encode();
          break;
        case 'JSON':
          extension = 'json';
          final jsonString = await DatabaseHelper.instance
              .generateCustomExportJson(
                includePanelData: exportPanel,
                includeUserData: exportUser,
                currentUser: currentUser,
                startDateRange: homeScreenState.startDateRange,
                deliveryDateRange: homeScreenState.deliveryDateRange,
                closedDateRange: homeScreenState.closedDateRange,
                selectedPanelTypes: homeScreenState.selectedPanelTypes,
                selectedPanelVendors: homeScreenState.selectedPanelVendors,
                selectedBusbarVendors: homeScreenState.selectedBusbarVendors,
                selectedComponentVendors:
                    homeScreenState.selectedComponentVendors,
                selectedPaletVendors: homeScreenState.selectedPaletVendors,
                selectedCorepartVendors:
                    homeScreenState.selectedCorepartVendors,
                selectedPccStatuses: homeScreenState.selectedPccStatuses,
                selectedMccStatuses: homeScreenState.selectedMccStatuses,
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
      String? selectedPath;
      if (kIsWeb) {
        // --- Logika untuk WEB ---
        final xFile = XFile.fromData(
          Uint8List.fromList(fileBytes ?? []),
          mimeType: format == 'Excel'
              ? 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
              : 'application/json',
          name: fileName,
        );
        await Share.shareXFiles([xFile], text: 'File Extract Data');
        successMessage = "File $fileName siap untuk di-download.";
      } else {
        // --- Logika untuk MOBILE & DESKTOP ---
        // 1. Minta izin terlebih dahulu
        var status = await Permission.storage.status;
        if (!status.isGranted) {
          status = await Permission.storage.request();
        }

        if (status.isGranted) {
          // 2. Jika izin diberikan, buka pemilih direktori
          final selectedPath = await FilePicker.platform.getDirectoryPath();

          if (selectedPath != null) {
            final path = "$selectedPath/$fileName";
            final file = File(path);
            await file.writeAsBytes(fileBytes ?? []);
            successMessage = "File berhasil disimpan di: $path";

            // Opsi untuk langsung membuka/share file setelah disimpan
            if (Platform.isIOS || Platform.isAndroid) {
              await Share.shareXFiles([XFile(path)], text: 'File Extract Data');
            }
          } else {
            errorMessage = "Extract dibatalkan: Tidak ada folder yang dipilih.";
          }
        } else {
          errorMessage = "Extract gagal: Izin akses penyimpanan ditolak.";
        }
      }
    } catch (e) {
      errorMessage = "Extract gagal: ${e.toString()}";
    } finally {
      if (mounted) Navigator.of(context).pop(); // Menutup dialog loading
    }

    if (mounted) {
      if (successMessage != null)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(successMessage),
            duration: const Duration(seconds: 4),
            backgroundColor: AppColors.schneiderGreen,
          ),
        );
      if (errorMessage != null)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
        );
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
    showModalBottomSheet<BulkDeleteResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => const BulkDeleteBottomSheet(),
    ).then((result) {
      if (result != null && mounted) {
        if (result.message.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.message),
              backgroundColor: result.success
                  ? AppColors.schneiderGreen
                  : Colors.red,
            ),
          );
        }
        if (result.dataHasChanged) _refreshHomeScreen();
      }
    });
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

    final bool canAddPanel =
        _currentCompany?.role == AppRole.admin ||
        _currentCompany?.role == AppRole.k3;
    final bool canImportData =
        _currentCompany?.role == AppRole.admin ||
        _currentCompany?.role == AppRole.k3;
    final bool canExportData = true;
    final bool canBulkDelete = _currentCompany?.role == AppRole.admin;

    return Scaffold(
      backgroundColor: AppColors.white,
      body: Stack(
        children: [
          IndexedStack(index: _selectedIndex, children: _pages),
          Positioned(
            bottom: 20,
            right: 16,
            child: PopupMenuButton<String>(
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
                      child: Row(
                        children: [
                          Image.asset(
                            'assets/images/import-green.png',
                            width: 24,
                            height: 24,
                            color: AppColors.schneiderGreen,
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Upload',
                            style: TextStyle(
                              color: AppColors.black,
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                if (canExportData) {
                  items.add(
                    PopupMenuItem<String>(
                      value: 'export',
                      height: 36,
                      child: Row(
                        children: [
                          Image.asset(
                            'assets/images/export-green.png',
                            width: 24,
                            height: 24,
                            color: AppColors.schneiderGreen,
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Extract',
                            style: TextStyle(
                              color: AppColors.black,
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                if (canBulkDelete)
                  items.add(
                    PopupMenuItem<String>(
                      value: 'bulk_delete',
                      height: 36,
                      child: Row(
                        children: [
                          const Icon(
                            Icons.delete_sweep_outlined,
                            color: AppColors.red,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Bulk Delete',
                            style: TextStyle(
                              color: AppColors.black,
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                return items;
              },
              onSelected: (String result) {
                switch (result) {
                  case 'import':
                    _showImportBottomSheet();
                    break;
                  case 'export':
                    _showExportBottomSheet();
                    break;
                  case 'bulk_delete':
                    _showBulkDeleteBottomSheet();
                    break;
                }
              },
              child: SizedBox(
                height: 52,
                child: FloatingActionButton.extended(
                  heroTag: 'dataMenuFab',
                  onPressed: null,
                  backgroundColor: AppColors.white,
                  elevation: 0.0,
                  shape: const StadiumBorder(
                    side: BorderSide(color: AppColors.grayLight, width: 2),
                  ),
                  icon: Image.asset(
                    'assets/images/import-export-green.png',
                    width: 24,
                    height: 24,
                    color: AppColors.schneiderGreen,
                  ),
                  label: const Text(
                    'Mass Data',
                    style: TextStyle(
                      color: AppColors.black,
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: canAddPanel
          ? FloatingActionButton(
              heroTag: 'addPanelFab',
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
}
