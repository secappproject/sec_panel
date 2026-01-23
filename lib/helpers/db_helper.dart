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
      return "http://localhost:8099";

    } else {
      if (Platform.isAndroid) {

      return "http://localhost:8099";
      } else {

      return "http://localhost:8099";
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
    
    
    if (e.toString().contains('Database error')) {
      print('DEBUG: Re-throwing existing Database error');
      rethrow;
    }
    
    throw Exception('Request error: $e');
  }
  }

  
  
  

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

    
    
    return data.map((json) => PanelDisplayData.fromJson(json)).toList();
  }

  
  static dynamic? _database;
  Future<dynamic> get database async => _database ??= await _initDatabase();
  Future<dynamic> _initDatabase() async => Future.value(null);

  
  
  

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
  
  
  if (data is List && data.isNotEmpty) {
    return Company.fromMap(data[0] as Map<String, dynamic>);
  }
  
  
  if (data is Map<String, dynamic>) {
    return Company.fromMap(data);
  }
  
  throw Exception('Unexpected response format: ${data.runtimeType}');
}

  Future<List<String>> searchUsernames(String query) async {
    
    if (query.isEmpty) {
      return [];
    }
    try {
      
      final encodedQuery = Uri.encodeComponent(query);
      final data = await _apiRequest('GET', '/accounts/search?q=$encodedQuery');

      if (data != null && data is List) {
        
        return List<String>.from(data);
      }
      return [];
    } catch (e) {
      
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

    
    if (data == null || data is! List) {
      return [];
    }

    return (data as List).map((e) => Company.fromMap(e)).toList();
  }

  Future<List<CompanyAccount>> getAllCompanyAccounts() async {
    final dynamic data = await _apiRequest('GET', '/accounts');

    
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

  

  Future<List<Map<String, dynamic>>> getColleagueAccountsForDisplay(
    String companyName,
    String currentUsername,
  ) async {
    final endpoint =
        '/users/colleagues/display?company_name=$companyName&current_username=$currentUsername';

    
    final List<dynamic>? data = await _apiRequest('GET', endpoint);

    
    
    if (data == null) {
      return [];
    }

    
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
  Future<List<Company>> getG3Vendors() => _getCompaniesByRole(AppRole.g3);
  Future<List<Company>> getWHSVendors() =>
      _getCompaniesByRole(AppRole.warehouse);

    Future<List<Company>> _getCompaniesByRole(AppRole role) async {
      final List<dynamic>? data = await _apiRequest( 
        'GET',
        '/vendors?role=${role.name}',
      );
      if (data == null) return []; 
      return data.map((map) => Company.fromMap(map)).toList();
    }

  
  Future<bool> isNoPpTaken(String noPp) async {
    try {
      
      
      final data = await _apiRequest('GET', '/panel/exists/no-pp/$noPp');

      
      if (data is Map<String, dynamic> && data.containsKey('exists')) {
        return data['exists'] as bool? ?? false;
      }

      
      
      return false;
    } catch (e) {
      
      
      debugPrint("Error checking No. PP existence: $e");
      
      
      
      return false;
    }
  }

  Future<int> insertPanel(Panel panel) async {
    await _apiRequest('POST', '/panels', body: panel.toMapForApi());
    return 1;
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
      
      
      
      rethrow;
    }
  }

  Future<List<Panel>> getAllPanels() async {
    final dynamic data = await _apiRequest('GET', '/panels/all');

    
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
      '/palet', 
      body: {'panel_no_pp': panelNoPp, 'vendor': vendorId},
    );
  }

  Future<void> deleteCorepart(String panelNoPp, String vendorId) async {
    await _apiRequest(
      'DELETE',
      '/corepart', 
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

  Future<Map<String, List<dynamic>>> getFilteredDataForExport({
    required Company currentUser,
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

    
    void addListToParams(String key, List<String>? list) {
      if (list != null && list.isNotEmpty) {
        queryParams[key] = list.join(',');
      }
    }

    
    void addEnumListToParams(String key, List<dynamic>? list) {
      if (list != null && list.isNotEmpty) {
        queryParams[key] = list.map((e) => e.toString().split('.').last).join(',');
      }
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
        'issues': [],
        'comments': [],
        'additional_srs': [],
      };
    }
    
    final Map<String, dynamic> data = responseData;
    print('DEBUG: Issues from backend: ${data['issues']}'); 
    print('DEBUG: Comments from backend: ${data['comments']}');
    print('DEBUG: SRs from backend: ${data['additional_srs']}');
    
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
      'issues': data['issues'] as List<dynamic>? ?? [],
      'comments': data['comments'] as List<dynamic>? ?? [],
      'additional_srs': data['additional_srs'] as List<dynamic>? ?? [],
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
          .join('; '); 
    } catch (e) {
      return 'Error formatting remarks';
    }
  }
Future<Excel> generateCustomExportExcel({
    required bool includePanelData,
    required bool includeUserData,
    required bool includeIssueData,
    required bool includeSrData,
    required Company currentUser,
    required List<PanelDisplayData> filteredPanels,
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

    final validPanelIds = filteredPanels
        .map((p) => p.panel.noPp.trim().toLowerCase())
        .toSet();

    bool isMatch(String rawItemPp) {
      final itemPp = rawItemPp.trim().toLowerCase();
      
      
      if (validPanelIds.contains(itemPp)) return true;

      for (final validPp in validPanelIds) {
        if (validPp.contains(itemPp) || itemPp.contains(validPp)) {
          return true;
        }
      }
      return false;
    }

    
    if (includePanelData) {
      final panelSheet = excel['Panel'];
      final panelHeaders = [
        'PP Panel', 'Panel No', 'WBS', 'PROJECT', 'Panel Type', 'Start Assembly',
        'Panel Remarks', 'Busbar Remarks', 'Target Delivery', 'Actual Delivery ke SEC',
        'Panel', 'Busbar', 'Progres Panel', 'Status Corepart', 'Status Palet',
        'Status Busbar', 'Status Component', 'Close Date Busbar', 'AO Busbar',
        'Current Position', 'Production/Subcon. Date', 'FAT Date', 'All Done Date',
      ];
      panelSheet.appendRow(panelHeaders.map((h) => TextCellValue(h)).toList());

      for (final panelData in filteredPanels) {
        final panel = panelData.panel;
        final latestAoBusbar = (panel.aoBusbarPcc != null &&
                (panel.aoBusbarMcc == null ||
                    panel.aoBusbarPcc!.isAfter(panel.aoBusbarMcc!)))
            ? panel.aoBusbarPcc
            : panel.aoBusbarMcc;

        final latestCloseDateBusbar = (panel.closeDateBusbarPcc != null &&
                (panel.closeDateBusbarMcc == null ||
                    panel.closeDateBusbarPcc!.isAfter(panel.closeDateBusbarMcc!)))
            ? panel.closeDateBusbarPcc
            : panel.closeDateBusbarMcc;

        final status = panel.statusPenyelesaian ?? 'Warehouse';
        String? positionText;
        switch (status) {
          case 'Production':
            positionText = 'Production (${RegExp(r'Cell\s+\d+').firstMatch(panel.productionSlot!)?.group(0) ?? panel.productionSlot! ?? 'N/A'})';
            break;
          case 'FAT': positionText = 'FAT'; break;
          case 'Done': positionText = 'Done'; break;
          case 'VendorWarehouse': default: positionText = 'Warehouse'; break;
        }
        panelSheet.appendRow([
          TextCellValue(panel.noPp.startsWith('TEMP_') ? 'Belum Diatur' : panel.noPp),
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
          TextCellValue(panel.statusComponent ?? ''),
          TextCellValue(formatDate(latestCloseDateBusbar) ?? ''),
          TextCellValue(formatDate(latestAoBusbar) ?? ''),
          TextCellValue(positionText),
          TextCellValue(formatDate(panelData.productionDate) ?? ''),
          TextCellValue(formatDate(panelData.fatDate) ?? ''),
          TextCellValue(formatDate(panelData.allDoneDate) ?? ''),
        ]);
      }
    }

    
    if (includeIssueData) {
      final issueSheet = excel['Issues'];
      
      
      CellStyle commentStyle = CellStyle(
        textWrapping: TextWrapping.WrapText, 
        verticalAlign: VerticalAlign.Top,
        fontFamily: getFontFamily(FontFamily.Arial),
      );

      
      issueSheet.appendRow([
        'PP Panel', 'WBS', 'Panel No', 'Issue ID', 'Judul', 'Deskripsi', 'Status', 'Dibuat Oleh', 'Tanggal Dibuat', 'Komentar', 'Ada Gambar?', 'Email Notifikasi'
      ].map((h) => TextCellValue(h)).toList());

      
      
      issueSheet.setColumnWidth(9, 60.0); 

      final List<IssueForExport> allIssues = ((data['issues'] as List<dynamic>?) ?? []).map((i) => IssueForExport.fromMap(i)).toList();
      final List<CommentForExport> comments = ((data['comments'] as List<dynamic>?) ?? []).map((c) => CommentForExport.fromMap(c)).toList();

      final filteredIssues = allIssues.where((issue) => isMatch(issue.panelNoPp)).toList();

      
      final Map<int, List<CommentForExport>> commentsByIssue = {};
      for (var comment in comments) {
        (commentsByIssue[comment.issueId] ??= []).add(comment);
      }

      for (final issue in filteredIssues) {
        
        StringBuffer sb = StringBuffer();
        int rootCommentCount = 1;
        
        final issueComments = commentsByIssue[issue.issueId] ?? [];
        final rootComments = issueComments.where((c) => c.replyToCommentId == null).toList();
        final replyComments = issueComments.where((c) => c.replyToCommentId != null).toList();

        for (var root in rootComments) {
          
          String cleanRootText = root.text.replaceAll('**', '').replaceAll('"', '').trim();
          
          
          if (cleanRootText.isEmpty) continue; 

          
          sb.write('$rootCommentCount. ${root.senderId}: "$cleanRootText"\n');
          
          
          final replies = replyComments.where((r) => r.replyToCommentId == root.commentId).toList();
          
          if (replies.isNotEmpty) {
            
            sb.write('      Balasan:\n'); 
            
            for (var reply in replies) {
              String cleanReplyText = reply.text.replaceAll('**', '').replaceAll('"', '').trim();
              if (cleanReplyText.isEmpty) continue;

              
              sb.write('      - ${reply.senderId}: "$cleanReplyText"\n');
            }
          }

          
          sb.write('\n'); 
          rootCommentCount++;
        }
        
        String finalCommentText = sb.toString().trim(); 

        
        issueSheet.appendRow([
          TextCellValue(issue.panelNoPp.startsWith('TEMP_') ? 'Belum Diatur' : issue.panelNoPp),
          TextCellValue(issue.panelNoWbs ?? ''),
          TextCellValue(issue.panelNoPanel ?? ''),
          TextCellValue(issue.issueId.toString()),
          TextCellValue(issue.title),
          TextCellValue(issue.description),
          TextCellValue(issue.status),
          TextCellValue(issue.createdBy),
          TextCellValue(formatDate(issue.createdAt) ?? ''),
          TextCellValue(finalCommentText), 
          TextCellValue(issue.hasImages ? 'TRUE' : 'FALSE'), 
          TextCellValue(issue.notifyEmail ?? '-'),
        ]);
        
        int rowIndex = issueSheet.maxRows - 1; 
        
        
        var cell = issueSheet.cell(CellIndex.indexByColumnRow(columnIndex: 9, rowIndex: rowIndex));
        
        
        cell.cellStyle = commentStyle;
      }
    }
    
    if (includeSrData) {
      final srSheet = excel['Additional SR'];
      srSheet.appendRow([
        'PP Panel', 'WBS', 'Panel No', 'No. PO', 'Item', 'Qty', 'Supplier', 'Status', 'Remarks (No. DO)', 'Received Date', 'Close Date'
      ].map((h) => TextCellValue(h)).toList());

      final List<AdditionalSRForExport> allSrs = ((data['additional_srs'] as List<dynamic>?) ?? []).map((s) => AdditionalSRForExport.fromMap(s)).toList();

      
      final filteredSrs = allSrs.where((sr) => isMatch(sr.panelNoPp)).toList();

      print("DEBUG SR: Total Server: ${allSrs.length}, Filtered: ${filteredSrs.length}");

      for (final sr in filteredSrs) {
        srSheet.appendRow([
          TextCellValue(sr.panelNoPp.trim().toUpperCase().startsWith('TEMP_') ? 'Belum Diatur' : sr.panelNoPp),
          TextCellValue(sr.panelNoWbs ?? ''),
          TextCellValue(sr.panelNoPanel ?? ''),
          TextCellValue(sr.poNumber),
          TextCellValue(sr.item),
          TextCellValue(sr.quantity.toString()),
          TextCellValue(sr.supplier ?? ''),
          TextCellValue(sr.status),
          TextCellValue(sr.remarks),
          TextCellValue(formatDate(sr.receivedDate) ?? ''),
          TextCellValue(formatDate(sr.closeDate) ?? ''),
        ]);
      }
    }

    return excel;
  }
  
  Future<String> generateCustomExportJson({
    required bool includePanelData,
    required bool includeUserData,
    required bool includeIssueData,
    required bool includeSrData,
    required Company currentUser,
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
      'issues': includeIssueData.toString(),
      'srs': includeSrData.toString(),
      'role': currentUser.role.name,
      'company_id': currentUser.id,
    };

    void addListToParams(String key, List<String>? list) {
      if (list != null && list.isNotEmpty) queryParams[key] = list.join(',');
    }

    void addEnumListToParams(String key, List<dynamic>? list) {
      if (list != null && list.isNotEmpty)
        queryParams[key] = list.map((e) => e.toString().split('.').last).join(',');
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

  Future<String> generateFilteredDatabaseJson({
    required Map<String, bool> tablesToInclude,
    required Company currentUser,
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

    void addListToParams(String key, List<String>? list) {
      if (list != null && list.isNotEmpty) queryParams[key] = list.join(',');
    }

    void addEnumListToParams(String key, List<dynamic>? list) {
      if (list != null && list.isNotEmpty)
        queryParams[key] = list.map((e) => e.toString().split('.').last).join(',');
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
      
      final data = await _apiRequest('GET', '/account/exists/$username');

      
      
      if (data is Map<String, dynamic> && data.containsKey('exists')) {
        
        
        return data['exists'] as bool? ?? false;
      }

      
      
      return false;
    } catch (e) {
      
      
      
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
    
    return data.map((json) => IssueWithPhotos.fromJson(json)).toList();
  }

  
  Future<IssueWithPhotos> getIssueById(int issueId) async {
    final data = await _apiRequest('GET', '/issues/$issueId');
    if (data == null) {
      throw Exception('Issue with ID $issueId not found.');
    }
    return IssueWithPhotos.fromJson(data);
  }

  
  Future<void> createIssueForPanel(
    String panelNoPp,
    Map<String, dynamic> issueData,
  ) async {
    await _apiRequest('POST', '/panels/$panelNoPp/issues', body: issueData);
  }

  
  Future<void> updateIssue(int issueId, Map<String, dynamic> issueData) async {
    await _apiRequest('PUT', '/issues/$issueId', body: issueData);
  }

  
  Future<void> deleteIssue(int issueId) async {
    await _apiRequest('DELETE', '/issues/$issueId');
  }

  
  Future<List<Map<String, dynamic>>> getIssueTitles() async {
    final List<dynamic>? data = await _apiRequest('GET', '/issue-titles');
    if (data == null) return [];
    return List<Map<String, dynamic>>.from(data);
  }

  
  Future<void> createIssueTitle(String title) async {
    await _apiRequest('POST', '/issue-titles', body: {'title': title});
  }

  
  Future<void> updateIssueTitle(int id, String newTitle) async {
    await _apiRequest('PUT', '/issue-titles/$id', body: {'title': newTitle});
  }

  
  Future<void> deleteIssueTitle(int id) async {
    await _apiRequest('DELETE', '/issue-titles/$id');
  }

  
  Future<void> addPhotoToIssue(int issueId, String base64Photo) async {
    await _apiRequest(
      'POST',
      '/issues/$issueId/photos',
      body: {'photo': base64Photo},
    );
  }

  
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
    required List<Uint8List> images, 
  }) async {
    List<String> base64Images = [];
    for (var imageBytes in images) { 
      
      final base64String = 'data:image/jpeg;base64,${base64Encode(imageBytes)}';
      base64Images.add(base64String);
    }

    final body = {
      'text': text,
      'sender_id': senderId,
      'reply_to_comment_id': replyToCommentId,
      'reply_to_user_id': replyToUserId,
      'images': base64Images,
    };

    final responseData = await _apiRequest(
      'POST',
      '/issues/$issueId/comments',
      body: body,
    );

    if (responseData != null && responseData['id'] != null) {
      return responseData['id'];
    } else {
      throw Exception('Failed to get comment ID from server');
    }
  }
  Future<void> updateComment({
    required String commentId,
    required String text,
    required List<String> existingImageUrls,
    required List<Uint8List> newImages, 
  }) async {
    List<String> finalImages = List.from(existingImageUrls);

    for (var imageBytes in newImages) { 
      
      final base64String = 'data:image/jpeg;base64,${base64Encode(imageBytes)}';
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
    required String replyToCommentId, 
  }) async {
    final body = {
      'question': question,
      'sender_id': senderId,
      'reply_to_comment_id': replyToCommentId, 
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
      body: sr.toMap(), 
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
      body: sr.toMap(), 
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
    
    return List<String>.from(data);
  }
  
  
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
  String? newVendorRole,
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
    body['vendorId'] = vendorId;
  }
  if (newVendorRole != null) {
    body['newVendorRole'] = newVendorRole;
  }
  try {
    final responseData = await _apiRequest(
      'POST',
      url.substring(_baseUrl.length),
      body: body,
    );

    if (responseData is Map<String, dynamic>) {
      if (responseData.containsKey('panel')) {
        return PanelDisplayData.fromJson(responseData);
      } else {
        throw Exception(
          'Failed to transfer panel: Server returned an unexpected response.',
        );
      }
    } else {
      throw Exception(
        'Failed to transfer panel: Invalid response from server. Expected a Map, got ${responseData.runtimeType}',
      );
    }

  } catch (e) {
    rethrow;
  }
}

Future<Panel> changePanelNoPp(String oldNoPp, Panel updatedPanel) async {
  final responseData = await _apiRequest(
    'PUT',
    '/panels/$oldNoPp/change-pp',
    body: updatedPanel.toMapForApi(),
  );

  if (responseData is Map<String, dynamic>) {
    return Panel.fromMap(responseData);
  } else {
    throw Exception(
      'Failed to change Panel No PP: Invalid response from server. Expected a Map, got ${responseData.runtimeType}',
    );
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
