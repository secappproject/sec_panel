import 'package:secpanel/models/approles.dart';

class Company {
  String id;
  // String password;
  String name;
  AppRole role;
  Company({
    required this.id,
    // required this.password,
    required this.name,
    required this.role,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      // 'password': password,
      'name': name, 'role': role.name,
    };
  }

  
  factory Company.fromMap(Map<String, dynamic> map) {
    final roleString = map['role'] as String? ?? ''; // Ambil role sebagai string
    return Company(
      id: map['id'] as String,
      name: map['name'] as String,
      // Ubah string ke lowercase sebelum mencari di enum
      role: AppRole.values.firstWhere(
        (e) => e.name == roleString.toLowerCase(),
        // Jika tidak ditemukan, berikan nilai default agar tidak crash
        orElse: () => AppRole.viewer, 
      ),
    );
  }
}
