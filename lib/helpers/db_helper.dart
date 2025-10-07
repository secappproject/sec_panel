import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:excel/excel.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:secpanel/components/panel/filtersearch/panel_filter_bottom_sheet.dart';
import 'package:secpanel/models/additionalsr.dart';
import 'package:secpanel/models/approles.dart';
import 'package:secpanel/models/busbar.dart';
import 'package:secpanel/models/busbarremark.dart';
import 'package:secpanel/models/company.dart';
import 'package:secpanel/models/companyaccount.dart';
import 'package:secpanel/models/component.dart';
import 'package:secpanel/models/corepart.dart';
import 'package:secpanel/models/issue.dart';
import 'package:secpanel/models/palet.dart';
import 'package:secpanel/models/paneldisplaydata.dart';
import 'package:secpanel/models/panels.dart';
import 'package:secpanel/models/productionslot.dart';

class TemplateFile {
  final List<int> bytes;
  final String extension;
  TemplateFile({required this.bytes, required this.extension});
}

class DatabaseHelper {
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  String get _baseUrl {
    if (kReleaseMode) {
      return "https://secpanel-server.onrender.com";
    } else {
      if (Platform.isAndroid) {
      return "https://secpanel-server.onrender.com";
      } else {
      return "https://secpanel-server.onrender.com";
      }
    }
  }

  // String get _baseUrl {
  //   if (kReleaseMode) {
  //     return "http://localhost:8080";
  //   } else {
  //     if (Platform.isAndroid) {
  //     return "http://localhost:8080";
  //     } else {
  //     return "http://localhost:8080";
  //     }
  //   }
  // }
  static final _headers = {'Content-Type': 'application/json; charset=UTF-8'};

  Future<dynamic> _apiRequest(
    String method,
    String endpoint, {
    dynamic body,
  }) async {
    final uri = Uri.parse('$_baseUrl$endpoint');
    http.Response response;
    try {
      switch (method.toUpperCase()) {
        case 'GET':
          response = await http.get(uri);
          break;
        case 'POST':
          response = await http.post(
            uri,
            headers: _headers,
            body: jsonEncode(body),
          );
          break;
        case 'PUT':
          response = await http.put(
            uri,
            headers: _headers,
            body: jsonEncode(body),
          );
          break;
        case 'DELETE':
          response = await http.delete(
            uri,
            headers: _headers,
            body: body != null ? jsonEncode(body) : null,
          );
          break;
        default:
          throw Exception('Metode HTTP tidak didukung: $method');
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (response.body.isEmpty) return null;
        return jsonDecode(utf8.decode(response.bodyBytes));
      } else {
        String errorMessage;
        try {
          final errorBody = jsonDecode(utf8.decode(response.bodyBytes));
          errorMessage =
              errorBody['error'] ??
              'Terjadi kesalahan tidak dikenal dari server.';
        } catch (e) {
          errorMessage = utf8.decode(response.bodyBytes);
          if (errorMessage.isEmpty) {
            errorMessage =
                'Terjadi kesalahan tanpa pesan (Code: ${response.statusCode})';
          }
        }
        throw Exception(errorMessage);
      }
  } on SocketException catch (e) {
    print('DEBUG: SocketException caught: ${e.message}');
    print('DEBUG: SocketException address: ${e.address}');
    print('DEBUG: SocketException port: ${e.port}');
    throw Exception(
      'Tidak dapat terhubung ke server. Periksa koneksi internet Anda. (Detail: ${e.message})',
    );
  } on TimeoutException catch (e) {
    print('DEBUG: TimeoutException: ${e.message}');
    throw Exception('Request timeout: ${e.message}');
  } on FormatException catch (e) {
    print('DEBUG: FormatException: ${e.message}');
    throw Exception('Format error: ${e.message}');
  } catch (e, stackTrace) {
    print('DEBUG: Unexpected error type: ${e.runtimeType}');
    print('DEBUG: Unexpected error: $e');
    print('DEBUG: Stack trace: $stackTrace');
    
    // Re-throw with more context
    if (e.toString().contains('Database error')) {
      print('DEBUG: Re-throwing existing Database error');
      rethrow;
    }
    
    throw Exception('Request error: $e');
  }
  }

  // =========================================================================
  // FUNGSI-FUNGSI API
  // =========================================================================

  Future<List<PanelDisplayData>> getAllPanelsForDisplay({
    Company? currentUser,
    DateTimeRange? startDateRange,
    DateTimeRange? deliveryDateRange,
    DateTimeRange? closedDateRange,
    bool rawIds = false,
  }) async {
    Map<String, String> queryParams = {};
    if (currentUser != null) {
      queryParams = {
        'role': currentUser.role.name,
        'company_id': currentUser.id,
      };
    }
    if (startDateRange != null) {
      queryParams['start_date_start'] = startDateRange.start
          .toUtc()
          .toIso8601String();
      queryParams['start_date_end'] = startDateRange.end
          .toUtc()
          .toIso8601String();
    }
    if (deliveryDateRange != null) {
      queryParams['delivery_date_start'] = deliveryDateRange.start
          .toUtc()
          .toIso8601String();
      queryParams['delivery_date_end'] = deliveryDateRange.end
          .toUtc()
          .toIso8601String();
    }
    if (closedDateRange != null) {
      queryParams['closed_date_start'] = closedDateRange.start
          .toUtc()
          .toIso8601String();
      queryParams['closed_date_end'] = closedDateRange.end
          .toUtc()
          .toIso8601String();
    }
    if (rawIds) {
      queryParams['raw_ids'] = 'true';
    }
    final uri = Uri.parse(
      '$_baseUrl/panels',
    ).replace(queryParameters: queryParams);
    final endpoint = uri.toString().substring(_baseUrl.length);

    final List<dynamic>? data = await _apiRequest('GET', endpoint);
    if (data == null) return [];

    // Ini adalah titik di mana JSON diubah menjadi objek Dart
    // Pastikan PanelDisplayData.fromJson sudah benar
    return data.map((json) => PanelDisplayData.fromJson(json)).toList();
  }

  // Placeholder functions, not used with API backend
  static dynamic? _database;
  Future<dynamic> get database async => _database ??= await _initDatabase();
  Future<dynamic> _initDatabase() async => Future.value(null);

  // =========================================================================
  // FUNGSI-FUNGSI API
  // =========================================================================

  Future<Company?> login(String username, String password) async {
    final data = await _apiRequest(
      'POST',
      '/login',
      body: {'username': username, 'password': password},
    );
    return data != null ? Company.fromMap(data) : null;
  }

Future<Company?> getCompanyByUsername(String username) async {
  final data = await _apiRequest('GET', '/company-by-username/$username');
  if (data == null) return null;
  
  // Handle jika backend mengembalikan array
  if (data is List && data.isNotEmpty) {
    return Company.fromMap(data[0] as Map<String, dynamic>);
  }
  
  // Handle jika backend mengembalikan object langsung
  if (data is Map<String, dynamic>) {
    return Company.fromMap(data);
  }
  
  throw Exception('Unexpected response format: ${data.runtimeType}');
}

  Future<List<String>> searchUsernames(String query) async {
    // Hindari panggilan API jika input kosong
    if (query.isEmpty) {
      return [];
    }
    try {
      // Panggil endpoint baru dengan query yang di-encode
      final encodedQuery = Uri.encodeComponent(query);
      final data = await _apiRequest('GET', '/accounts/search?q=$encodedQuery');

      if (data != null && data is List) {
        // Konversi hasil (List<dynamic>) menjadi List<String>
        return List<String>.from(data);
      }
      return [];
    } catch (e) {
      // Jika terjadi error (misal: tidak ada koneksi), kembalikan list kosong
      print('Error searching usernames: $e');
      return [];
    }
  }

  Future<bool> updatePassword(String username, String newPassword) async {
    await _apiRequest(
      'PUT',
      '/user/$username/password',
      body: {'password': newPassword},
    );
    return true;
  }

  Future<void> insertCompany(Company company) async {
    await _apiRequest('POST', '/company', body: company.toMap());
  }

  Future<void> insertCompanyWithAccount(
    Company company,
    CompanyAccount account,
  ) async {
    await _apiRequest(
      'POST',
      '/company-with-account',
      body: {'company': company.toMap(), 'account': account.toMap()},
    );
  }

  Future<void> updateCompanyAndAccount(
    Company company, {
    String? newPassword,
  }) async {
    final username = company.id;
    await _apiRequest(
      'PUT',
      '/company-with-account/$username',
      body: {'company': company.toMap(), 'new_password': newPassword},
    );
  }

  Future<int> deleteCompanyAccount(String username) async {
    await _apiRequest('DELETE', '/account/$username');
    return 1;
  }

  Future<Company?> getCompanyById(String id) async {
    final data = await _apiRequest('GET', '/company/$id');
    return data != null ? Company.fromMap(data) : null;
  }

  Future<List<Company>> getAllCompanies() async {
    final dynamic data = await _apiRequest('GET', '/companies');

    // [PERBAIKAN] Cek jika data null, kembalikan list kosong
    if (data == null || data is! List) {
      return [];
    }

    return (data as List).map((e) => Company.fromMap(e)).toList();
  }

  Future<List<CompanyAccount>> getAllCompanyAccounts() async {
    final dynamic data = await _apiRequest('GET', '/accounts');

    // [PERBAIKAN] Cek jika data null, kembalikan list kosong
    if (data == null || data is! List) {
      return [];
    }

    return (data as List).map((e) => CompanyAccount.fromMap(e)).toList();
  }

  Future<List<Map<String, dynamic>>> getAllUserAccountsForDisplay() async {
    final List<dynamic>? data = await _apiRequest('GET', '/users/display');
    if (data == null) return [];
    return List<Map<String, dynamic>>.from(data);
  }

  // package:secpanel/helpers/db_helper.dart

  Future<List<Map<String, dynamic>>> getColleagueAccountsForDisplay(
    String companyName,
    String currentUsername,
  ) async {
    final endpoint =
        '/users/colleagues/display?company_name=$companyName&current_username=$currentUsername';

    // PERBAIKAN 1: Izinkan `data` bisa bernilai null dengan tanda tanya (?).
    final List<dynamic>? data = await _apiRequest('GET', endpoint);

    // PERBAIKAN 2: Jika data ternyata null (tidak ada kolega),
    // kembalikan list kosong `[]` yang aman dan tidak membuat crash.
    if (data == null) {
      return [];
    }

    // Jika tidak null, lanjutkan proses seperti biasa.
    return List<Map<String, dynamic>>.from(data);
  }

  Future<List<Map<String, String>>> getUniqueCompanyDataForForm() async {
    final List<dynamic> data = await _apiRequest('GET', '/companies/form-data');
    return data.map((e) => Map<String, String>.from(e)).toList();
  }

  Future<Company?> getCompanyByName(String name) async {
    final encodedName = Uri.encodeComponent(name);
    final data = await _apiRequest('GET', '/company-by-name/$encodedName');
    return data != null ? Company.fromMap(data) : null;
  }

  Future<void> updateCompany(Company company) async {
    await _apiRequest(
      'PUT',
      '/company/${company.id}',
      body: {'name': company.name, 'role': company.role.name},
    );
  }

  Future<List<Company>> getK3Vendors() => _getCompaniesByRole(AppRole.k3);
  Future<List<Company>> getK5Vendors() => _getCompaniesByRole(AppRole.k5);
  Future<List<Company>> getWHSVendors() =>
      _getCompaniesByRole(AppRole.warehouse);

  Future<List<Company>> _getCompaniesByRole(AppRole role) async {
    final List<dynamic> data = await _apiRequest(
      'GET',
      '/vendors?role=${role.name}',
    );
    return data.map((map) => Company.fromMap(map)).toList();
  }

  // Change the isNoPpTaken function to parse the boolean from the API response
  Future<bool> isNoPpTaken(String noPp) async {
    try {
      // This API call will now always succeed with a 200 OK if the server is reached.
      // The response body will be like `{"exists": true}` or `{"exists": false}`.
      final data = await _apiRequest('GET', '/panel/exists/no-pp/$noPp');

      // [FIX] Check the value of the 'exists' key in the returned map.
      if (data is Map<String, dynamic> && data.containsKey('exists')) {
        return data['exists'] as bool? ?? false;
      }

      // Fallback: If the response format is unexpected, assume the PP is not taken
      // to avoid blocking the user.
      return false;
    } catch (e) {
      // If a real network error occurs, it will be caught here.
      // For safety, we can assume it's not taken, but also log the error.
      debugPrint("Error checking No. PP existence: $e");
      // Depending on desired behavior, you might want to rethrow the error
      // or return true to prevent accidental duplicates on network failure.
      // Returning `false` is generally safer for user experience.
      return false;
    }
  }

  Future<int> insertPanel(Panel panel) async {
    await _apiRequest('POST', '/panels', body: panel.toMapForApi());
    return 1;
  }

  Future<Panel> changePanelNoPp(String oldNoPp, Panel updatedPanel) async {
    final responseData = await _apiRequest(
      'PUT',
      '/panels/$oldNoPp/change-pp',
      body: updatedPanel.toMapForApi(),
    );
    // Backend sekarang mengembalikan data panel yang sudah diupdate,
    // kita parsing dan kembalikan sebagai objek Panel.
    return Panel.fromMap(responseData);
  }

  Future<void> deletePanel(String noPp) async {
    await _apiRequest('DELETE', '/panels/$noPp');
  }

  Future<void> deletePanels(List<String> noPps) async {
    try {
      await _apiRequest(
        'DELETE',
        '/panels/bulk-delete',
        body: {'no_pps': noPps},
      );
    } catch (e) {
      print('Error deleting multiple panels: $e');
      // [PERBAIKAN KEDUA] Gunakan 'rethrow' untuk meneruskan error asli dari server.
      // Ini akan memberikan pesan error yang lebih spesifik di UI,
      // bukan "Gagal menghapus panel secara massal".
      rethrow;
    }
  }

  Future<List<Panel>> getAllPanels() async {
    final dynamic data = await _apiRequest('GET', '/panels/all');

    // [PERBAIKAN] Cek jika data null, kembalikan list kosong
    if (data == null || data is! List) {
      return [];
    }

    return (data as List).map((map) => Panel.fromMap(map)).toList();
  }

  Future<Panel?> getPanelByNoPp(String noPp) async {
    final data = await _apiRequest('GET', '/panel/$noPp');
    return data != null ? Panel.fromMap(data) : null;
  }

  Future<int> upsertBusbar(Busbar busbar) async {
    await _apiRequest('POST', '/busbar', body: busbar.toMap());
    return 1;
  }

  Future<void> deleteBusbar(String panelNoPp, String vendorId) async {
    await _apiRequest(
      'DELETE',
      '/busbar',
      body: {'panel_no_pp': panelNoPp, 'vendor': vendorId},
    );
  }

  Future<void> deletePalet(String panelNoPp, String vendorId) async {
    await _apiRequest(
      'DELETE',
      '/palet', // Pastikan endpoint ini ada di backend Go
      body: {'panel_no_pp': panelNoPp, 'vendor': vendorId},
    );
  }

  Future<void> deleteCorepart(String panelNoPp, String vendorId) async {
    await _apiRequest(
      'DELETE',
      '/corepart', // Pastikan endpoint ini ada di backend Go
      body: {'panel_no_pp': panelNoPp, 'vendor': vendorId},
    );
  }

  Future<int> upsertComponent(Component component) async {
    await _apiRequest('POST', '/component', body: component.toMap());
    return 1;
  }

  Future<int> upsertPalet(Palet palet) async {
    await _apiRequest('POST', '/palet', body: palet.toMap());
    return 1;
  }

  Future<int> upsertCorepart(Corepart corepart) async {
    await _apiRequest('POST', '/corepart', body: corepart.toMap());
    return 1;
  }

  Future<List<Component>> getAllComponents() async {
    final dynamic data = await _apiRequest('GET', '/components');
    if (data == null || data is! List) return [];
    return (data as List).map((map) => Component.fromMap(map)).toList();
  }

  Future<List<Palet>> getAllPalet() async {
    final dynamic data = await _apiRequest('GET', '/palets');
    if (data == null || data is! List) return [];
    return (data as List).map((map) => Palet.fromMap(map)).toList();
  }

  Future<List<Corepart>> getAllCorepart() async {
    final dynamic data = await _apiRequest('GET', '/coreparts');
    if (data == null || data is! List) return [];
    return (data as List).map((map) => Corepart.fromMap(map)).toList();
  }

  Future<List<Busbar>> getAllBusbars() async {
    final dynamic data = await _apiRequest('GET', '/busbars');
    if (data == null || data is! List) return [];
    return (data as List).map((map) => Busbar.fromMap(map)).toList();
  }

  Future<void> upsertPanelRemark({
    required String panelNoPp,
    required String newRemark,
  }) async {
    await _apiRequest(
      'POST',
      '/panel/remark-vendor',
      body: {'panel_no_pp': panelNoPp, 'remarks': newRemark},
    );
  }

  Future<void> upsertBusbarRemarkandVendor({
    required String panelNoPp,
    required String vendorId,
    required String newRemark,
  }) async {
    await _apiRequest(
      'POST',
      '/busbar/remark-vendor',
      body: {
        'panel_no_pp': panelNoPp,
        'vendor': vendorId,
        'remarks': newRemark,
      },
    );
  }

  Future<void> upsertStatusAOK5({
    required String panelNoPp,
    required String vendorId,
    required String aoBusbarPcc,
    required String aoBusbarMcc,
    required String statusBusbarPcc,
    required String statusBusbarMcc,
  }) async {
    await _apiRequest(
      'POST',
      '/panel/status-ao-k5',
      body: {
        'panel_no_pp': panelNoPp,
        'vendor': vendorId,
        'ao_busbar_pcc': aoBusbarPcc,
        'ao_busbar_mcc': aoBusbarMcc,
        'status_busbar_pcc': statusBusbarPcc,
        'status_busbar_mcc': statusBusbarMcc,
      },
    );
  }

  Future<void> upsertStatusWHS({
    required String panelNoPp,
    required String vendorId,
    required String statusComponent,
  }) async {
    await _apiRequest(
      'POST',
      '/panel/status-whs',
      body: {
        'panel_no_pp': panelNoPp,
        'vendor': vendorId,
        'status_component': statusComponent,
      },
    );
  }

  Future<List<Map<String, dynamic>>> getPanelKeys() async {
    final dynamic data = await _apiRequest('GET', '/panels/keys');
    if (data == null || data is! List) {
      return [];
    }
    return List<Map<String, dynamic>>.from(data);
  }

  // ▼▼▼ FUNGSI 1: getFilteredDataForExport ▼▼▼
  // Helper serbaguna yang meneruskan SEMUA filter yang ada di UI ke backend.
  Future<Map<String, List<dynamic>>> getFilteredDataForExport({
    required Company currentUser,
    // Semua state filter dari HomeScreen/PanelFilterBottomSheet
    DateTimeRange? startDateRange,
    DateTimeRange? deliveryDateRange,
    DateTimeRange? closedDateRange,
    List<String>? selectedPanelTypes,
    List<String>? selectedPanelVendors,
    List<String>? selectedBusbarVendors,
    List<String>? selectedComponentVendors,
    List<String>? selectedPaletVendors,
    List<String>? selectedCorepartVendors,
    List<String>? selectedStatuses,
    List<String>? selectedMccStatuses,
    List<String>? selectedComponents,
    List<String>? selectedPalet,
    List<String>? selectedCorepart,
    List<PanelFilterStatus>? selectedPanelStatuses,
    bool? includeArchived,
  }) async {
    Map<String, String> queryParams = {
      'role': currentUser.role.name,
      'company_id': currentUser.id,
    };

    // Helper untuk mengubah list menjadi string dipisahkan koma
    void addListToParams(String key, List<String>? list) {
      if (list != null && list.isNotEmpty) {
        queryParams[key] = list.join(',');
      }
    }

    // Helper untuk mengubah enum menjadi string
    void addEnumListToParams(String key, List<dynamic>? list) {
      if (list != null && list.isNotEmpty) {
        queryParams[key] = list.map((e) => e.name).join(',');
      }
    }

    // Tambahkan semua filter yang aktif ke dalam parameter
    if (startDateRange != null) {
      queryParams['start_date_start'] = startDateRange.start
          .toUtc()
          .toIso8601String();
      queryParams['start_date_end'] = startDateRange.end
          .toUtc()
          .toIso8601String();
    }
    if (deliveryDateRange != null) {
      queryParams['delivery_date_start'] = deliveryDateRange.start
          .toUtc()
          .toIso8601String();
      queryParams['delivery_date_end'] = deliveryDateRange.end
          .toUtc()
          .toIso8601String();
    }
    if (closedDateRange != null) {
      queryParams['closed_date_start'] = closedDateRange.start
          .toUtc()
          .toIso8601String();
      queryParams['closed_date_end'] = closedDateRange.end
          .toUtc()
          .toIso8601String();
    }
    if (includeArchived != null) {
      queryParams['include_archived'] = includeArchived.toString();
    }

    addListToParams('panel_types', selectedPanelTypes);
    addListToParams('panel_vendors', selectedPanelVendors);
    addListToParams('busbar_vendors', selectedBusbarVendors);
    addListToParams('component_vendors', selectedComponentVendors);
    addListToParams('palet_vendors', selectedPaletVendors);
    addListToParams('corepart_vendors', selectedCorepartVendors);
    addListToParams('pcc_statuses', selectedStatuses);
    addListToParams('component_statuses', selectedComponents);
    addListToParams('palet_statuses', selectedPalet);
    addListToParams('corepart_statuses', selectedCorepart);
    addEnumListToParams('panel_statuses', selectedPanelStatuses);

    final uri = Uri.parse(
      '$_baseUrl/export/filtered-data',
    ).replace(queryParameters: queryParams);
    final endpoint = uri.toString().substring(_baseUrl.length);
    final dynamic responseData = await _apiRequest('GET', endpoint);

    if (responseData == null || responseData is! Map<String, dynamic>) {
      return {
        'companies': [],
        'companyAccounts': [],
        'panels': [],
        'busbars': [],
        'components': [],
        'palet': [],
        'corepart': [],
      };
    }
    // ... (sisa fungsi parsing tidak berubah)
    final Map<String, dynamic> data = responseData;
    return {
      'companies': ((data['companies'] as List<dynamic>?) ?? [])
          .map((c) => Company.fromMap(c as Map<String, dynamic>))
          .toList(),
      'companyAccounts': ((data['companyAccounts'] as List<dynamic>?) ?? [])
          .map((c) => CompanyAccount.fromMap(c as Map<String, dynamic>))
          .toList(),
      'panels': ((data['panels'] as List<dynamic>?) ?? [])
          .map((p) => Panel.fromMap(p as Map<String, dynamic>))
          .toList(),
      'busbars': ((data['busbars'] as List<dynamic>?) ?? [])
          .map((b) => Busbar.fromMap(b as Map<String, dynamic>))
          .toList(),
      'components': ((data['components'] as List<dynamic>?) ?? [])
          .map((c) => Component.fromMap(c as Map<String, dynamic>))
          .toList(),
      'palet': ((data['palet'] as List<dynamic>?) ?? [])
          .map((p) => Palet.fromMap(p as Map<String, dynamic>))
          .toList(),
      'corepart': ((data['corepart'] as List<dynamic>?) ?? [])
          .map((c) => Corepart.fromMap(c as Map<String, dynamic>))
          .toList(),
    };
  }

  String _formatBusbarRemarks(List<BusbarRemark> remarks) {
    if (remarks.isEmpty) {
      return '';
    }
    try {
      return remarks
          .map((remark) {
            final vendorName = remark.vendorName;
            final remarkText = remark.remark;
            return '$vendorName: "$remarkText"';
          })
          .join('; '); // Pisahkan setiap remark dengan titik koma
    } catch (e) {
      return 'Error formatting remarks';
    }
  }

  Future<Excel> generateCustomExportExcel({
    required bool includePanelData,
    required bool includeUserData,
    required Company currentUser,
    required List<PanelDisplayData> filteredPanels, // Data dari UI
    // ▼▼▼ TAMBAHKAN SEMUA PARAMETER FILTER INI ▼▼▼
    DateTimeRange? startDateRange,
    DateTimeRange? deliveryDateRange,
    DateTimeRange? closedDateRange,
    List<String>? selectedPanelTypes,
    List<String>? selectedPanelVendors,
    List<String>? selectedBusbarVendors,
    List<String>? selectedComponentVendors,
    List<String>? selectedPaletVendors,
    List<String>? selectedCorepartVendors,
    List<String>? selectedStatuses,
    List<String>? selectedComponents,
    List<String>? selectedPalet,
    List<String>? selectedCorepart,
    List<PanelFilterStatus>? selectedPanelStatuses,
    bool? includeArchived,
  }) async {
    final excel = Excel.createExcel();
    excel.delete('Sheet1');
    final allCompanies = await getAllCompanies();
    final companyMap = {for (var c in allCompanies) c.id: c};
    String? formatDate(DateTime? date) =>
        date != null ? DateFormat('dd-MMM-yyyy').format(date) : null;

  
    if (includePanelData) {
      final panelSheet = excel['Panel'];
      final panelHeaders = [
        'PP Panel',
        'Panel No',
        'WBS',
        'PROJECT',
        'Panel Type',
        'Start Time of Work',
        'Panel Remarks',
        'Busbar Remarks',
        'Plan Start',
        'Actual Delivery ke SEC',
        'Panel',
        'Busbar',
        'Progres Panel',
        'Status Corepart',
        'Status Palet',
        'Status Busbar',
        'Close Date Busbar',
        'AO Busbar',
        'Current Position',
        'Production/Subcon. Date',
        'FAT Date',
        'All Done Date',
      ];
      panelSheet.appendRow(panelHeaders.map((h) => TextCellValue(h)).toList());

      // Bagian ini sudah benar, tidak perlu diubah.
      for (final panelData in filteredPanels) {
        final panel = panelData.panel;
        final latestAoBusbar =
            (panel.aoBusbarPcc != null &&
                (panel.aoBusbarMcc == null ||
                    panel.aoBusbarPcc!.isAfter(panel.aoBusbarMcc!)))
            ? panel.aoBusbarPcc
            : panel.aoBusbarMcc;

        final latestCloseDateBusbar =
            (panel.closeDateBusbarPcc != null &&
                (panel.closeDateBusbarMcc == null ||
                    panel.closeDateBusbarPcc!.isAfter(
                      panel.closeDateBusbarMcc!,
                    )))
            ? panel.closeDateBusbarPcc
            : panel.closeDateBusbarMcc;

        final status = panel.statusPenyelesaian ?? 'Warehouse';
        String? positionText;

        switch (status) {
          case 'Production':
            // Jika di produksi, tampilkan juga nomor slotnya
            positionText = 'Production (${RegExp(r'Cell\s+\d+')
                                        .firstMatch(panel.productionSlot!)
                                        ?.group(0) ?? panel.productionSlot! ?? 'N/A'})';
            break;
          case 'FAT':
            positionText = 'FAT';
            break;
          case 'Done':
            positionText = 'Done';
            break;
          case 'VendorWarehouse':
          default:
            // Gabungkan nama vendor dan warehouse
            // List<String> locations = [];
            // if (panelVendorName.isNotEmpty) locations.add(panelVendorName);
            // if (componentVendorName.isNotEmpty) locations.add(componentVendorName);

            // positionText = locations.isEmpty ? 'Vendor/WHS' : locations.join(' & ');

            positionText = 'Warehouse';
            break;
        }
        panelSheet.appendRow([
          TextCellValue(
            panel.noPp.startsWith('TEMP_') ? 'Belum Diatur' : panel.noPp,
          ),
          TextCellValue(panel.noPanel ?? ''),
          TextCellValue(panel.noWbs ?? ''),
          TextCellValue(panel.project ?? ''),
          TextCellValue(panel.panelType ?? ''),
          TextCellValue(formatDate(panel.startDate) ?? ''),
          TextCellValue(panel.remarks ?? ''),
          TextCellValue(_formatBusbarRemarks(panelData.busbarRemarks)),
          TextCellValue(formatDate(panel.targetDelivery) ?? ''),
          TextCellValue(formatDate(panel.closedDate) ?? ''),
          TextCellValue(panelData.panelVendorName),
          TextCellValue(panelData.busbarVendorNames),
          TextCellValue(panel.percentProgress?.toStringAsFixed(0) ?? '0'),
          TextCellValue(panel.statusCorepart ?? ''),
          TextCellValue(panel.statusPalet ?? ''),
          TextCellValue(panel.statusBusbarPcc ?? ''),
          TextCellValue(formatDate(latestAoBusbar) ?? ''),
          TextCellValue(formatDate(latestCloseDateBusbar) ?? ''),
          TextCellValue(positionText),
          TextCellValue(formatDate(panelData.productionDate) ?? ''),
          TextCellValue(formatDate(panelData.fatDate) ?? ''),
          TextCellValue(formatDate(panelData.allDoneDate) ?? ''),
        ]);
      }
    }

    if (includeUserData) {
      final data = await getFilteredDataForExport(
        currentUser: currentUser,
        startDateRange: startDateRange,
        deliveryDateRange: deliveryDateRange,
        closedDateRange: closedDateRange,
        selectedPanelTypes: selectedPanelTypes,
        selectedPanelVendors: selectedPanelVendors,
        selectedBusbarVendors: selectedBusbarVendors,
        selectedComponentVendors: selectedComponentVendors,
        selectedPaletVendors: selectedPaletVendors,
        selectedCorepartVendors: selectedCorepartVendors,
        selectedStatuses: selectedStatuses,
        selectedComponents: selectedComponents,
        selectedPalet: selectedPalet,
        selectedCorepart: selectedCorepart,
        selectedPanelStatuses: selectedPanelStatuses,
        includeArchived: includeArchived,
      );
      // ▲▲▲ AKHIR PERBAIKAN ▲▲▲

      final companyAccounts =
          (data['companyAccounts'] as List<dynamic>?)?.cast<CompanyAccount>() ??
          [];
      final userSheet = excel['User'];
      final userHeaders = ['Username', 'Password', 'Company', 'Company Role'];
      userSheet.appendRow(userHeaders.map((h) => TextCellValue(h)).toList());
      for (final account in companyAccounts) {
        final company = companyMap[account.companyId];
        userSheet.appendRow([
          TextCellValue(account.username),
          TextCellValue(account.password),
          TextCellValue(company?.name ?? account.companyId),
          TextCellValue(company?.role.name ?? ''),
        ]);
      }
    }
    return excel;
  }

  Future<String> generateCustomExportJson({
    required bool includePanelData,
    required bool includeUserData,
    required Company currentUser,
    // Semua state filter dari HomeScreen/PanelFilterBottomSheet
    DateTimeRange? startDateRange,
    DateTimeRange? deliveryDateRange,
    DateTimeRange? closedDateRange,
    List<String>? selectedPanelTypes,
    List<String>? selectedPanelVendors,
    List<String>? selectedBusbarVendors,
    List<String>? selectedComponentVendors,
    List<String>? selectedPaletVendors,
    List<String>? selectedCorepartVendors,
    List<String>? selectedStatuses,
    List<String>? selectedComponents,
    List<String>? selectedPalet,
    List<String>? selectedCorepart,
    List<PanelFilterStatus>? selectedPanelStatuses,
    bool? includeArchived,
  }) async {
    Map<String, String> queryParams = {
      'panels': includePanelData.toString(),
      'users': includeUserData.toString(),
      'role': currentUser.role.name,
      'company_id': currentUser.id,
    };

    // Logika pembangunan parameter sama persis dengan getFilteredDataForExport
    void addListToParams(String key, List<String>? list) {
      if (list != null && list.isNotEmpty) queryParams[key] = list.join(',');
    }

    void addEnumListToParams(String key, List<dynamic>? list) {
      if (list != null && list.isNotEmpty)
        queryParams[key] = list.map((e) => e.name).join(',');
    }

    if (startDateRange != null) {
      queryParams['start_date_start'] = startDateRange.start
          .toUtc()
          .toIso8601String();
      queryParams['start_date_end'] = startDateRange.end
          .toUtc()
          .toIso8601String();
    }
    // ... (Tambahkan semua if dan addListToParams lainnya seperti di fungsi pertama) ...
    if (deliveryDateRange != null) {
      queryParams['delivery_date_start'] = deliveryDateRange.start
          .toUtc()
          .toIso8601String();
      queryParams['delivery_date_end'] = deliveryDateRange.end
          .toUtc()
          .toIso8601String();
    }
    if (closedDateRange != null) {
      queryParams['closed_date_start'] = closedDateRange.start
          .toUtc()
          .toIso8601String();
      queryParams['closed_date_end'] = closedDateRange.end
          .toUtc()
          .toIso8601String();
    }
    if (includeArchived != null) {
      queryParams['include_archived'] = includeArchived.toString();
    }
    addListToParams('panel_types', selectedPanelTypes);
    addListToParams('panel_vendors', selectedPanelVendors);
    addListToParams('busbar_vendors', selectedBusbarVendors);
    addListToParams('component_vendors', selectedComponentVendors);
    addListToParams('palet_vendors', selectedPaletVendors);
    addListToParams('corepart_vendors', selectedCorepartVendors);
    addListToParams('pcc_statuses', selectedStatuses);
    addListToParams('component_statuses', selectedComponents);
    addListToParams('palet_statuses', selectedPalet);
    addListToParams('corepart_statuses', selectedCorepart);
    addEnumListToParams('panel_statuses', selectedPanelStatuses);

    final uri = Uri.parse(
      '$_baseUrl/export/custom',
    ).replace(queryParameters: queryParams);
    final endpoint = uri.toString().substring(_baseUrl.length);
    final data = await _apiRequest('GET', endpoint);
    return const JsonEncoder.withIndent('  ').convert(data);
  }

  // ▼▼▼ FUNGSI 4: generateFilteredDatabaseJson ▼▼▼
  // Fungsi ini juga meneruskan SEMUA filter yang ada di UI ke backend.
  Future<String> generateFilteredDatabaseJson({
    required Map<String, bool> tablesToInclude,
    required Company currentUser,
    // Semua state filter dari HomeScreen/PanelFilterBottomSheet
    DateTimeRange? startDateRange,
    DateTimeRange? deliveryDateRange,
    DateTimeRange? closedDateRange,
    List<String>? selectedPanelTypes,
    List<String>? selectedPanelVendors,
    List<String>? selectedBusbarVendors,
    List<String>? selectedComponentVendors,
    List<String>? selectedPaletVendors,
    List<String>? selectedCorepartVendors,
    List<String>? selectedStatuses,
    List<String>? selectedComponents,
    List<String>? selectedPalet,
    List<String>? selectedCorepart,
    List<PanelFilterStatus>? selectedPanelStatuses,
    bool? includeArchived,
  }) async {
    final tables = tablesToInclude.entries
        .where((e) => e.value)
        .map((e) => e.key)
        .join(',');
    Map<String, String> queryParams = {
      'tables': tables,
      'role': currentUser.role.name,
      'company_id': currentUser.id,
    };

    // Gunakan lagi logika penambahan parameter yang sama
    void addListToParams(String key, List<String>? list) {
      if (list != null && list.isNotEmpty) queryParams[key] = list.join(',');
    }

    void addEnumListToParams(String key, List<dynamic>? list) {
      if (list != null && list.isNotEmpty)
        queryParams[key] = list.map((e) => e.name).join(',');
    }

    if (startDateRange != null) {
      queryParams['start_date_start'] = startDateRange.start
          .toUtc()
          .toIso8601String();
      queryParams['start_date_end'] = startDateRange.end
          .toUtc()
          .toIso8601String();
    }
    // ... (Tambahkan semua if dan addListToParams lainnya seperti di fungsi pertama) ...
    if (deliveryDateRange != null) {
      queryParams['delivery_date_start'] = deliveryDateRange.start
          .toUtc()
          .toIso8601String();
      queryParams['delivery_date_end'] = deliveryDateRange.end
          .toUtc()
          .toIso8601String();
    }
    if (closedDateRange != null) {
      queryParams['closed_date_start'] = closedDateRange.start
          .toUtc()
          .toIso8601String();
      queryParams['closed_date_end'] = closedDateRange.end
          .toUtc()
          .toIso8601String();
    }
    if (includeArchived != null) {
      queryParams['include_archived'] = includeArchived.toString();
    }
    addListToParams('panel_types', selectedPanelTypes);
    addListToParams('panel_vendors', selectedPanelVendors);
    addListToParams('busbar_vendors', selectedBusbarVendors);
    addListToParams('component_vendors', selectedComponentVendors);
    addListToParams('palet_vendors', selectedPaletVendors);
    addListToParams('corepart_vendors', selectedCorepartVendors);
    addListToParams('pcc_statuses', selectedStatuses);
    addListToParams('component_statuses', selectedComponents);
    addListToParams('palet_statuses', selectedPalet);
    addListToParams('corepart_statuses', selectedCorepart);
    addEnumListToParams('panel_statuses', selectedPanelStatuses);

    final uri = Uri.parse(
      '$_baseUrl/export/database',
    ).replace(queryParameters: queryParams);
    final endpoint = uri.toString().substring(_baseUrl.length);
    final data = await _apiRequest('GET', endpoint);
    return const JsonEncoder.withIndent('  ').convert(data);
  }

  Future<void> importData(
    Map<String, List<Map<String, dynamic>>> data,
    Function(double progress, String message) onProgress,
  ) async {
    onProgress(0.1, "Mengirim data ke server...");
    await _apiRequest('POST', '/import/database', body: data);
    onProgress(1.0, "Impor selesai diproses oleh server.");
  }

  Future<TemplateFile> generateImportTemplate({
    required String dataType,
    required String format,
  }) async {
    final endpoint = '/import/template?dataType=$dataType&format=$format';
    final Map<String, dynamic> data = await _apiRequest('GET', endpoint);
    final bytes = base64Decode(data['bytes']);
    final extension = data['extension'];
    return TemplateFile(bytes: bytes, extension: extension);
  }

  Future<bool> isPanelNumberUnique(
    String noPanel, {
    String? currentNoPp,
  }) async {
    String endpoint = '/panel/exists/no-panel/$noPanel';
    if (currentNoPp != null) {
      endpoint += '?current_no_pp=$currentNoPp';
    }
    final data = await _apiRequest('GET', endpoint);
    return data == null;
  }

  Future<bool> isUsernameTaken(String username) async {
    try {
      // Panggil API. _apiRequest akan melempar error jika status code bukan 2xx.
      final data = await _apiRequest('GET', '/account/exists/$username');

      // Backend Go akan mengembalikan JSON seperti: `{"exists": true}`.
      // Kita harus periksa isi dari Map tersebut.
      if (data is Map<String, dynamic> && data.containsKey('exists')) {
        // Kembalikan nilai boolean dari kunci 'exists'.
        // `?? false` untuk keamanan, jika nilainya null, anggap tidak ada.
        return data['exists'] as bool? ?? false;
      }

      // Jika respons tidak sesuai format yang diharapkan, anggap saja tidak terpakai
      // agar tidak memblokir user. Ini adalah fallback yang aman.
      return false;
    } catch (e) {
      // Jika ada error koneksi atau sejenisnya, anggap username tidak terpakai
      // agar fungsionalitas tidak terblokir total.
      // Anda bisa menambahkan log di sini jika perlu.
      debugPrint("Error checking username: $e");
      return false;
    }
  }

  Future<String> importFromCustomTemplate({
    required Map<String, List<Map<String, dynamic>>> data,
    required Function(double progress, String message) onProgress,
    required String? loggedInUsername,
  }) async {
    try {
      onProgress(0.1, "Mengirim data template ke server...");
      final Map<String, dynamic> result = await _apiRequest(
        'POST',
        '/import/custom',
        body: {'data': data, 'loggedInUsername': loggedInUsername},
      );
      onProgress(1.0, result['message'] ?? "Impor selesai.");
      return result['message'] ?? "Impor berhasil diselesaikan! 🎉";
    } catch (e) {
      onProgress(1.0, "Impor gagal.");
      rethrow;
    }
  }

  Future<List<IssueWithPhotos>> getIssuesByPanel(String panelNoPp) async {
    final List<dynamic>? data = await _apiRequest(
      'GET',
      '/panels/$panelNoPp/issues',
    );
    if (data == null) return [];
    // Kembalikan sebagai List<IssueWithPhotos>
    return data.map((json) => IssueWithPhotos.fromJson(json)).toList();
  }

  /// Mengambil detail satu isu beserta foto-fotonya.
  Future<IssueWithPhotos> getIssueById(int issueId) async {
    final data = await _apiRequest('GET', '/issues/$issueId');
    if (data == null) {
      throw Exception('Issue with ID $issueId not found.');
    }
    return IssueWithPhotos.fromJson(data);
  }

  /// Membuat isu baru untuk sebuah panel.
  Future<void> createIssueForPanel(
    String panelNoPp,
    Map<String, dynamic> issueData,
  ) async {
    await _apiRequest('POST', '/panels/$panelNoPp/issues', body: issueData);
  }

  /// Memperbarui data sebuah isu.
  Future<void> updateIssue(int issueId, Map<String, dynamic> issueData) async {
    await _apiRequest('PUT', '/issues/$issueId', body: issueData);
  }

  /// Menghapus sebuah isu.
  Future<void> deleteIssue(int issueId) async {
    await _apiRequest('DELETE', '/issues/$issueId');
  }

  /// Mengambil semua tipe isu yang tersedia untuk ditampilkan sebagai pilihan.
  Future<List<Map<String, dynamic>>> getIssueTitles() async {
    final List<dynamic>? data = await _apiRequest('GET', '/issue-titles');
    if (data == null) return [];
    return List<Map<String, dynamic>>.from(data);
  }

  /// Membuat tipe isu baru.
  Future<void> createIssueTitle(String title) async {
    await _apiRequest('POST', '/issue-titles', body: {'title': title});
  }

  /// Memperbarui nama tipe isu yang sudah ada.
  Future<void> updateIssueTitle(int id, String newTitle) async {
    await _apiRequest('PUT', '/issue-titles/$id', body: {'title': newTitle});
  }

  /// Menghapus tipe isu.
  Future<void> deleteIssueTitle(int id) async {
    await _apiRequest('DELETE', '/issue-titles/$id');
  }

  /// Menambah foto ke sebuah isu.
  Future<void> addPhotoToIssue(int issueId, String base64Photo) async {
    await _apiRequest(
      'POST',
      '/issues/$issueId/photos',
      body: {'photo': base64Photo},
    );
  }

  /// Menghapus foto dari sebuah isu.
  Future<void> deletePhoto(int photoId) async {
    await _apiRequest('DELETE', '/photos/$photoId');
  }

  Future<List<IssueComment>> getComments(int issueId) async {
    final List<dynamic>? data = await _apiRequest(
      'GET',
      '/issues/$issueId/comments',
    );
    if (data == null) return [];
    return data.map((json) => IssueComment.fromJson(json)).toList();
  }

  Future<String> createComment({
    required int issueId,
    required String text,
    required String senderId,
    String? replyToCommentId,
    String? replyToUserId,
    required List<File> images,
  }) async {
    List<String> base64Images = [];
    for (var imageFile in images) {
      final bytes = await imageFile.readAsBytes();
      final base64String = 'data:image/jpeg;base64,${base64Encode(bytes)}';
      base64Images.add(base64String);
    }

    final body = {
      'text': text,
      'sender_id': senderId,
      'reply_to_comment_id': replyToCommentId,
      'reply_to_user_id': replyToUserId,
      'images': base64Images,
    };

    // Panggil _apiRequest dan dapatkan hasilnya
    final responseData = await _apiRequest(
      'POST',
      '/issues/$issueId/comments',
      body: body,
    );

    // Kembalikan ID dari response
    if (responseData != null && responseData['id'] != null) {
      return responseData['id'];
    } else {
      throw Exception('Failed to get comment ID from server');
    }
  }

  Future<void> updateComment({
    required String commentId,
    required String text,
    required List<String> existingImageUrls, // URL yang sudah ada
    required List<File> newImages, // File gambar baru
  }) async {
    List<String> finalImages = List.from(existingImageUrls);

    for (var imageFile in newImages) {
      final bytes = await imageFile.readAsBytes();
      final base64String = 'data:image/jpeg;base64,${base64Encode(bytes)}';
      finalImages.add(base64String);
    }

    final body = {'text': text, 'images': finalImages};
    await _apiRequest('PUT', '/comments/$commentId', body: body);
  }

  Future<void> deleteComment(String commentId) async {
    await _apiRequest('DELETE', '/comments/$commentId');
  }

  Future<void> askGemini({
    required int issueId,
    required String question,
    required String senderId,
    required String replyToCommentId, // <-- TAMBAHKAN INI
  }) async {
    final body = {
      'question': question,
      'sender_id': senderId,
      'reply_to_comment_id': replyToCommentId, // <-- TAMBAHKAN INI
    };
    await _apiRequest('POST', '/issues/$issueId/ask-gemini', body: body);
  }

  Future<Map<String, dynamic>> askAiAboutPanel({
    required String panelNoPp,
    required String question,
    required String senderId,
    String? imageB64,
  }) async {
    final responseData = await _apiRequest(
      'POST',
      '/panels/$panelNoPp/ask-gemini',
      body: {
        'question': question,
        'sender_id': senderId,
        'image_b64': imageB64,
      },
    );

    if (responseData is Map<String, dynamic>) {
      return responseData;
    } else {
      throw Exception('Format respon dari AI tidak valid.');
    }
  }

  Future<List<String>> getEmailRecommendations({required String panelNoPp}) async {
    if (panelNoPp.isEmpty) {
      return [];
    }

    final endpoint = '/issues/email-recommendations?panel_no_pp=${Uri.encodeComponent(panelNoPp)}';

    final List<dynamic>? data = await _apiRequest('GET', endpoint);

    if (data == null) return [];
    return List<String>.from(data);
  }  

  Future<List<AdditionalSR>> getAdditionalSRs(String panelNoPp) async {
    final List<dynamic>? data = await _apiRequest('GET', '/panel/$panelNoPp/additional-sr');
    if (data == null) {
      return [];
    }
    return data.map((item) => AdditionalSR.fromMap(item)).toList();
  }

  Future<AdditionalSR> createAdditionalSR(String panelNoPp, AdditionalSR sr) async {
    final data = await _apiRequest(
      'POST',
      '/panel/$panelNoPp/additional-sr',
      body: sr.toMap(), // Gunakan toMap, karena _apiRequest sudah melakukan jsonEncode
    );
    if (data != null) {
      return AdditionalSR.fromMap(data);
    } else {
      throw Exception('Failed to create Additional SR: No data received from server');
    }
  }

  Future<void> updateAdditionalSR(int srId, AdditionalSR sr) async {
    await _apiRequest(
      'PUT',
      '/additional-sr/$srId',
      body: sr.toMap(), // Gunakan toMap
    );
  }

  Future<void> deleteAdditionalSR(int srId) async {
    await _apiRequest('DELETE', '/additional-sr/$srId');
  }

  Future<List<String>> getSuppliers() async {
    final List<dynamic>? data = await _apiRequest('GET', '/suppliers');
    if (data == null) {
      return [];
    }
    // Konversi dari List<dynamic> ke List<String>
    return List<String>.from(data);
  }
  
  /// Mengambil semua slot produksi beserta statusnya.
  Future<List<ProductionSlot>> getProductionSlots() async {
    final List<dynamic>? data = await _apiRequest('GET', '/production-slots');
    if (data == null) {
      return [];
    }
    return data.map((json) => ProductionSlot.fromJson(json)).toList();
  }
Future<PanelDisplayData> transferPanelAction({
    required String panelNoPp,
    required String action,
    required String actor,
    String? slot,
    DateTime? startDate,
    DateTime? productionDate,
    DateTime? fatDate,
    DateTime? allDoneDate,
    String? vendorId, 
  }) async {
    final url = '$_baseUrl/panels/$panelNoPp/transfer';

    final Map<String, dynamic> body = {
      'action': action,
      'actor': actor,
    };
    if (slot != null) {
      body['slot'] = slot;
    }
    if (startDate != null) {
      body['start_date'] = startDate.toUtc().toIso8601String();
    }
    if (productionDate != null) {
      body['production_date'] = productionDate.toUtc().toIso8601String();
    }
    if (fatDate != null) {
      body['fat_date'] = fatDate.toUtc().toIso8601String();
    }
    if (allDoneDate != null) {
      body['all_done_date'] = allDoneDate.toUtc().toIso8601String();
    }
    if (vendorId != null) {
      body['vendor_id'] = vendorId;
    }

    try {
      final responseData = await _apiRequest(
        'POST',
        url.substring(_baseUrl.length),
        body: body,
      );

      if (responseData != null) {
        // [PERBAIKAN] Langsung gunakan factory dari PanelDisplayData
        return PanelDisplayData.fromJson(responseData);
      } else {
        throw Exception('Failed to transfer panel: No data received from server');
      }
    } catch (e) {
      rethrow;
    }
  }

Future<void> registerDeviceToken({
    required String username,
    required String token,
  }) async {
    try {
      await _apiRequest(
        'POST',
        '/user/register-device',
        body: {
          'username': username,
          'token': token,
        },
      );
      print("✅ FCM Token berhasil dikirim ke server untuk user: $username");
    } catch (e) {
      print("❌ Gagal mengirim FCM token ke server: $e");
    }
  }
}