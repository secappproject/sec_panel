

import 'dart:io';
import 'package:secpanel/models/issuetest.dart';

class ChatMessage {
  final String id;
  final String? text;
  final User sender; 
  final DateTime timestamp;
  final List<String> imageUrls; 
  final Issue? repliedIssue;

  ChatMessage({
    required this.id,
    this.text,
    required this.sender, 
    required this.timestamp,
    this.imageUrls = const [], 
    this.repliedIssue,
  });

  
  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    
    
    User sender;
    if (json['senderId'] == '1') {
      sender = admin;
    } else {
      sender = abacusUser;
    }

    Issue? repliedIssue;
    if (json['repliedIssue'] != null) {
      
      
      final issueId = json['repliedIssue']['id'];
      final dummyIssues = generateDummyIssues(); 
      repliedIssue = dummyIssues.firstWhere(
        (issue) => issue.id == issueId,
        orElse: () => dummyIssues.first,
      );
    }

    return ChatMessage(
      id: json['id'],
      text: json['text'],
      sender: sender, 
      timestamp: DateTime.parse(json['timestamp']),
      imageUrls: List<String>.from(json['imageUrls'] ?? []),
      repliedIssue: repliedIssue,
    );
  }

  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'senderId': sender.id, 
      'timestamp': timestamp.toIso8601String(),
      'imageUrls': imageUrls,
      'repliedIssue': repliedIssue != null
          ? {
              'id': repliedIssue!.id,
              'title': repliedIssue!.title,
              'description': repliedIssue!.description,
              'type': repliedIssue!.type,
              'status': repliedIssue!.status,
              
            }
          : null,
    };
  }
}
