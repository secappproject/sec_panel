import 'package:flutter/material.dart';

String? _parseString(dynamic jsonValue) {
  if (jsonValue == null) {
    return null;
  }
  
  if (jsonValue is Map<String, dynamic>) {
    if (jsonValue['Valid'] == true) {
      return jsonValue['String'];
    }
    return null; 
  }
  
  if (jsonValue is String) {
    return jsonValue.isEmpty ? null : jsonValue;
  }
  
  return jsonValue.toString();
}
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

  
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? 'unknown',
      name: json['name'] ?? 'Unknown User',
    );
  }
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
  final String photoData; 

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
  final String status;
  final List<LogEntry> logs;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? notifyEmail;

  Issue({
    required this.id,
    required this.chatId,
    required this.title,
    required this.description,
    required this.status,
    required this.logs,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.notifyEmail, 
  });

  LogEntry get lastLog {
    if (logs.isEmpty) {
      return LogEntry(
        action: 'membuat issue',
        user: User(id: createdBy, name: createdBy),
        timestamp: createdAt,
      );
    }
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
      title: json['issue_title'] ?? 'Uncategorized',
      description: json['issue_description'] ?? '',
      status: json['issue_status'] ?? 'unsolved',
      logs: logsList,
      createdBy: json['created_by'] ?? 'unknown',
      createdAt: DateTime.parse(json['created_at']).toLocal(),
      updatedAt: DateTime.parse(json['updated_at']).toLocal(),
      notifyEmail: json['notify_email'], 
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
    required super.status,
    required super.logs,
    required super.createdBy,
    required super.createdAt,
    required super.updatedAt,
    required this.photos,
    required super.notifyEmail,
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
      status: issuePart.status,
      logs: issuePart.logs,
      createdBy: issuePart.createdBy,
      createdAt: issuePart.createdAt,
      updatedAt: issuePart.updatedAt,
      photos: photoList,      
      notifyEmail: issuePart.notifyEmail, 
    );
  }
}

class IssueComment {
  final String id;
  final User sender;
  final String text;
  final DateTime timestamp;
  final User? replyTo;
  final String? replyToCommentId;
  final bool isEdited;
  final List<String> imageUrls;

  IssueComment({
    required this.id,
    required this.sender,
    required this.text,
    required this.timestamp,
    this.replyTo,
    this.replyToCommentId,
    this.isEdited = false,
    this.imageUrls = const [],
  });
  IssueComment copyWith({
    String? id,
    User? sender,
    String? text,
    DateTime? timestamp,
    User? replyTo,
    String? replyToCommentId,
    List<String>? imageUrls,
    bool? isEdited,
  }) {
    return IssueComment(
      id: id ?? this.id,
      sender: sender ?? this.sender,
      text: text ?? this.text,
      timestamp: timestamp ?? this.timestamp,
      replyTo: replyTo ?? this.replyTo,
      replyToCommentId: replyToCommentId ?? this.replyToCommentId,
      imageUrls: imageUrls ?? this.imageUrls,
      isEdited: isEdited ?? this.isEdited,
    );
  }

  
  factory IssueComment.fromJson(Map<String, dynamic> json) {
    return IssueComment(
      id: json['id'],
      sender: User.fromJson(json['sender']),
      text: json['text'] ?? '',
      timestamp: DateTime.parse(json['timestamp']).toLocal(),
      replyTo: json['reply_to'] != null
          ? User.fromJson(json['reply_to'])
          : null,
      replyToCommentId: json['reply_to_comment_id'],
      isEdited: json['is_edited'] ?? false,
      imageUrls: List<String>.from(json['image_urls'] ?? []),
    );
  }
}
class IssueForExport {
  final String panelNoPp;
  final String? panelNoWbs;
  final String? panelNoPanel;
  final int issueId;
  final String title;
  final String description;
  final String status;
  final String createdBy;
  final DateTime createdAt;

  factory IssueForExport.fromMap(Map<String, dynamic> map) {    
    return IssueForExport(
      panelNoPp: (map['panel_no_pp'] as String? ?? '').trim(),
      panelNoWbs: _parseString(map['panel_no_wbs']),
      panelNoPanel: _parseString(map['panel_no_panel']), 
      issueId: map['issue_id'] ?? 0,
      title: _parseString(map['title']) ?? '', 
      description: _parseString(map['description']) ?? '',
      status: _parseString(map['status']) ?? '', 
      createdBy: _parseString(map['created_by']) ?? '', 
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  IssueForExport({
    required this.panelNoPp,
    this.panelNoWbs,
    this.panelNoPanel,
    required this.issueId,
    required this.title,
    required this.description,
    required this.status,
    required this.createdBy,
    required this.createdAt,
  });
}
class CommentForExport {
  final String commentId; 
  final int issueId;
  final String text;
  final String senderId;
  final String? replyToCommentId;

  CommentForExport({
    required this.commentId, 
    required this.issueId,
    required this.text,
    required this.senderId,
    this.replyToCommentId,
  });

  factory CommentForExport.fromMap(Map<String, dynamic> map) {
    return CommentForExport(
      commentId: map['comment_id']?.toString() ?? '', 
      issueId: map['issue_id'] != null ? map['issue_id'] as int : 0,
      text: map['text']?.toString() ?? '',
      senderId: map['sender_id']?.toString() ?? '',
      replyToCommentId: map['reply_to_comment_id']?.toString(),
    );
  }
}