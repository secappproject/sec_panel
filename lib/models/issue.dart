import 'package:flutter/material.dart';

const List<Color> _userAvatarColors = [
  Color(0xFFFF5DD1), // Pink
  Color(0xFF0400FF), // Blue
  Color(0xFF00B2FF), // Light Blue
  Color(0xFFFF9E50), // Orange
  Color(0xFFFF0000), // Red
];

Color _getColorForUser(String userId) {
  final index = userId.hashCode % _userAvatarColors.length;
  return _userAvatarColors[index];
}

class User {
  final String id;
  final String name;
  final String avatarInitials;
  final Color avatarColor;

  User({required this.id, required this.name})
    : avatarInitials = name.isNotEmpty
          ? name.substring(0, 2).toUpperCase()
          : '??',
      avatarColor = _getColorForUser(id);
}

class LogEntry {
  final String action;
  final User user;
  final DateTime timestamp;

  LogEntry({required this.action, required this.user, required this.timestamp});

  factory LogEntry.fromJson(Map<String, dynamic> json) {
    String username = json['user'] ?? 'unknown';
    return LogEntry(
      action: json['action'] ?? '',
      user: User(id: username, name: username),
      timestamp: DateTime.parse(json['timestamp']).toLocal(),
    );
  }
}

class Photo {
  final int id;
  final int issueId;
  final String photoData; // base64 string

  Photo({required this.id, required this.issueId, required this.photoData});

  factory Photo.fromJson(Map<String, dynamic> json) {
    return Photo(
      id: json['photo_id'] ?? 0,
      issueId: json['issue_id'] ?? 0,
      photoData: json['photo'] ?? '',
    );
  }
}

class Issue {
  final int id;
  final int chatId;
  final String title;
  final String description;
  final String type;
  final String status;
  final List<LogEntry> logs;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  Issue({
    required this.id,
    required this.chatId,
    required this.title,
    required this.description,
    required this.type,
    required this.status,
    required this.logs,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  LogEntry get lastLog {
    if (logs.isEmpty) {
      return LogEntry(
        action: 'membuat issue',
        user: User(id: createdBy, name: createdBy),
        timestamp: createdAt,
      );
    }
    // Urutkan log dari yang terbaru
    logs.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return logs.first;
  }

  factory Issue.fromJson(Map<String, dynamic> json) {
    var logsList = <LogEntry>[];
    if (json['logs'] != null && json['logs'] is List) {
      logsList = (json['logs'] as List)
          .map((logJson) => LogEntry.fromJson(logJson))
          .toList();
    }

    return Issue(
      id: json['issue_id'] ?? 0,
      chatId: json['chat_id'] ?? 0,
      title: json['issue_title'] ?? 'No Title',
      description: json['issue_description'] ?? '',
      type: json['issue_type'] ?? 'Uncategorized',
      status: json['issue_status'] ?? 'unsolved',
      logs: logsList,
      createdBy: json['created_by'] ?? 'unknown',
      createdAt: DateTime.parse(json['created_at']).toLocal(),
      updatedAt: DateTime.parse(json['updated_at']).toLocal(),
    );
  }
}

class IssueWithPhotos extends Issue {
  final List<Photo> photos;

  IssueWithPhotos({
    required super.id,
    required super.chatId,
    required super.title,
    required super.description,
    required super.type,
    required super.status,
    required super.logs,
    required super.createdBy,
    required super.createdAt,
    required super.updatedAt,
    required this.photos,
  });

  factory IssueWithPhotos.fromJson(Map<String, dynamic> json) {
    var photoList = <Photo>[];
    if (json['photos'] != null && json['photos'] is List) {
      photoList = (json['photos'] as List)
          .map((photoJson) => Photo.fromJson(photoJson))
          .toList();
    }

    final issuePart = Issue.fromJson(json);

    return IssueWithPhotos(
      id: issuePart.id,
      chatId: issuePart.chatId,
      title: issuePart.title,
      description: issuePart.description,
      type: issuePart.type,
      status: issuePart.status,
      logs: issuePart.logs,
      createdBy: issuePart.createdBy,
      createdAt: issuePart.createdAt,
      updatedAt: issuePart.updatedAt,
      photos: photoList,
    );
  }
}
