// lib/models/chat_message.dart

import 'dart:io';
import 'package:secpanel/models/issuetest.dart';

class ChatMessage {
  final String id;
  final String? text;
  final User sender; // Ganti 'user' menjadi 'sender' untuk kejelasan
  final DateTime timestamp;
  final List<String> imageUrls; // Mengubah List<File> menjadi List<String>
  final Issue? repliedIssue;

  ChatMessage({
    required this.id,
    this.text,
    required this.sender, // Ganti 'user' menjadi 'sender'
    required this.timestamp,
    this.imageUrls = const [], // --- PERBAIKAN: Gunakan 'imageUrls' ---
    this.repliedIssue,
  });

  // Factory constructor untuk membuat objek ChatMessage dari JSON
  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    // Implementasi User.fromJson dan Issue.fromJson mungkin diperlukan
    // Untuk saat ini, kita akan membuat User dummy atau mencari dari daftar global
    User sender;
    if (json['senderId'] == '1') {
      sender = admin;
    } else {
      sender = abacusUser;
    }

    Issue? repliedIssue;
    if (json['repliedIssue'] != null) {
      // Ini akan kompleks jika Issue juga punya field kompleks.
      // Untuk demo, kita asumsikan ID issue bisa dicocokkan dengan data dummy
      final issueId = json['repliedIssue']['id'];
      final dummyIssues = generateDummyIssues(); // Panggil fungsi ini
      repliedIssue = dummyIssues.firstWhere(
        (issue) => issue.id == issueId,
        orElse: () => dummyIssues.first,
      );
    }

    return ChatMessage(
      id: json['id'],
      text: json['text'],
      sender: sender, // Gunakan sender yang sudah didapatkan
      timestamp: DateTime.parse(json['timestamp']),
      imageUrls: List<String>.from(json['imageUrls'] ?? []),
      repliedIssue: repliedIssue,
    );
  }

  // Method untuk mengubah objek ChatMessage menjadi JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'senderId': sender.id, // Simpan hanya ID sender
      'timestamp': timestamp.toIso8601String(),
      'imageUrls': imageUrls,
      'repliedIssue': repliedIssue != null
          ? {
              'id': repliedIssue!.id,
              'title': repliedIssue!.title,
              'description': repliedIssue!.description,
              'type': repliedIssue!.type,
              'status': repliedIssue!.status,
              // Jangan simpan lastLog dari issue agar tidak terlalu kompleks
            }
          : null,
    };
  }
}
