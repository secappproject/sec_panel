// import 'package:secpanel/models/approles.dart'; // Pastikan ini ada

import 'package:secpanel/models/approles.dart';

class Company {
  final String id;
  final String name;
  final AppRole role;
  final String? username; // Tambahkan properti ini (opsional)

  Company({
    required this.id,
    required this.name,
    required this.role,
    this.username, // Tambahkan di constructor
  });

  // Ganti factory fromMap Anda dengan ini
  factory Company.fromMap(Map<String, dynamic> map) {
    // Ambil nilai role dari map
    final roleString = map['role'] as String?;

    return Company(
      // Gunakan 'id' ATAU 'username' yang dikirim dari backend
      id: map['id'] as String? ?? map['username'] as String? ?? '',
      name: map['name'] as String? ?? 'Unknown Company',
      // Logika pencocokan enum yang lebih aman
      role: AppRole.values.firstWhere(
        // Cocokkan dengan nama enum (diubah ke huruf kecil)
        (e) => e.name == roleString?.toLowerCase(),
        // Jika tidak ditemukan, beri nilai default (misal: viewer)
        orElse: () => AppRole.viewer,
      ),
      username: map['username'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'role': role.name,
      'username': username,
    };
  }
}