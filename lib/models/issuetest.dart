import 'dart:math';
import 'package:flutter/material.dart';

// --- LANGKAH 1: Ganti daftar warna dengan palet baru Anda ---
const List<Color> _userAvatarColors = [
  Color(0xFFFF5DD1), // Pink
  Color(0xFF0400FF), // Blue
  Color(0xFF00B2FF), // Light Blue
  Color(0xFFFF9E50), // Orange
  Color(0xFFFF0000), // Red
];

// --- LANGKAH 2: Buat fungsi untuk memilih warna secara konsisten ---
// Fungsi ini akan selalu menghasilkan warna yang sama untuk ID yang sama.
Color _getColorForUser(String userId) {
  // Ambil hash code dari ID user dan gunakan modulo untuk memilih indeks warna
  // Ini memastikan 'admin' (id '1') akan selalu mendapat warna yang sama, dst.
  final index = userId.hashCode % _userAvatarColors.length;
  return _userAvatarColors[index];
}

// Helper function to find a user by ID
User _userFromId(String id) {
  if (id == '1') return admin;
  if (id == '2') return abacusUser;
  return abacusUser;
}

// --- LANGKAH 3: Perbarui kelas User ---
class User {
  final String id;
  final String name;
  final String avatarInitials;
  final Color avatarColor;

  // Constructor diubah untuk mengatur warna secara otomatis
  User({
    required this.id,
    required this.name,
    required this.avatarInitials,
    Color? avatarColor, // Jadikan parameter ini opsional
  }) : this.avatarColor =
           avatarColor ??
           _getColorForUser(id); // Jika warna tidak diberikan, panggil fungsi

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'avatarInitials': avatarInitials,
    'avatarColor': avatarColor.value,
  };

  factory User.fromJson(Map<String, dynamic> json) => User(
    id: json['id'],
    name: json['name'],
    avatarInitials: json['avatarInitials'],
    // Biarkan constructor yang menangani warnanya
  );
}

class LogEntry {
  final User user;
  final String action;
  final DateTime timestamp;

  LogEntry({required this.user, required this.action, required this.timestamp});

  Map<String, dynamic> toJson() => {
    'userId': user.id,
    'action': action,
    'timestamp': timestamp.toIso8601String(),
  };

  factory LogEntry.fromJson(Map<String, dynamic> json) => LogEntry(
    user: _userFromId(json['userId']),
    action: json['action'],
    timestamp: DateTime.parse(json['timestamp']),
  );
}

class Issue {
  final String id;
  final String panelNoPp;
  final String title;
  final String description;
  final String type;
  final String status;
  final LogEntry lastLog;
  final List<String> imageUrls;

  Issue({
    required this.id,
    required this.panelNoPp,
    required this.title,
    required this.description,
    required this.type,
    required this.status,
    required this.lastLog,
    this.imageUrls = const [],
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'panelNoPp': panelNoPp,
    'title': title,
    'description': description,
    'type': type,
    'status': status,
    'lastLog': lastLog.toJson(),
    'imageUrls': imageUrls,
  };

  factory Issue.fromJson(Map<String, dynamic> json) => Issue(
    id: json['id'],
    panelNoPp: json['panelNoPp'],
    title: json['title'],
    description: json['description'],
    type: json['type'],
    status: json['status'],
    lastLog: LogEntry.fromJson(json['lastLog']),
    imageUrls: List<String>.from(json['imageUrls'] ?? []),
  );
}

// --- LANGKAH 4: Sederhanakan pembuatan user dummy ---
// Kita tidak perlu lagi mengatur warna secara manual di sini
final User admin = User(id: '1', name: 'admin', avatarInitials: 'AD');
final User abacusUser = User(
  id: '2',
  name: 'abacus_user1',
  avatarInitials: 'AU',
);

// Fungsi ini tidak perlu diubah, karena warna user sudah konsisten
List<Issue> generateDummyIssues() {
  return [
    Issue(
      id: '1',
      panelNoPp: 'F05_NO PP',
      title: 'Missing Pallet',
      description: 'Lorem ipsum sir dolot amet ipsum si...',
      type: 'Masalah 3',
      status: 'solved',
      lastLog: LogEntry(
        user: admin,
        action: 'menandai solved',
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
      ),
      imageUrls: [
        'assets/images/dummy-photo.png',
        'assets/images/dummy-photo.png',
      ],
    ),
    Issue(
      id: '2',
      panelNoPp: 'F05_NO PP',
      title: 'Scratch on Busbar',
      description: 'Ditemukan goresan pada busbar panel X...',
      type: 'Masalah Kualitas',
      status: 'unsolved',
      lastLog: LogEntry(
        user: abacusUser,
        action: 'mengubah issue',
        timestamp: DateTime.now().subtract(const Duration(hours: 3)),
      ),
      imageUrls: ['assets/images/dummy-photo.png'],
    ),
    Issue(
      id: '3',
      panelNoPp: 'G12_PANEL_UTAMA',
      title: 'Kabel Terkelupas',
      description: 'Kabel fasa R terkelupas dekat terminal.',
      type: 'Masalah Keamanan',
      status: 'unsolved',
      lastLog: LogEntry(
        user: admin,
        action: 'membuat issue',
        timestamp: DateTime.now().subtract(const Duration(minutes: 25)),
      ),
      imageUrls: [],
    ),
  ];
}
