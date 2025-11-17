import 'dart:math';
import 'package:flutter/material.dart';


const List<Color> _userAvatarColors = [
  Color(0xFFFF5DD1), 
  Color(0xFF0400FF), 
  Color(0xFF00B2FF), 
  Color(0xFFFF9E50), 
  Color(0xFFFF0000), 
];



Color _getColorForUser(String userId) {
  
  
  final index = userId.hashCode % _userAvatarColors.length;
  return _userAvatarColors[index];
}


User _userFromId(String id) {
  if (id == '1') return admin;
  if (id == '2') return abacusUser;
  return abacusUser;
}


class User {
  final String id;
  final String name;
  final String avatarInitials;
  final Color avatarColor;

  
  User({
    required this.id,
    required this.name,
    required this.avatarInitials,
    Color? avatarColor, 
  }) : this.avatarColor =
           avatarColor ??
           _getColorForUser(id); 

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



final User admin = User(id: '1', name: 'admin', avatarInitials: 'AD');
final User abacusUser = User(
  id: '2',
  name: 'abacus_user1',
  avatarInitials: 'AU',
);


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
