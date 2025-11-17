

import 'package:secpanel/models/approles.dart';

class Company {
  final String id;
  final String name;
  final AppRole role;
  final String? username; 

  Company({
    required this.id,
    required this.name,
    required this.role,
    this.username, 
  });

  
  factory Company.fromMap(Map<String, dynamic> map) {
    
    final roleString = map['role'] as String?;

    return Company(
      
      id: map['id'] as String? ?? map['username'] as String? ?? '',
      name: map['name'] as String? ?? 'Unknown Company',
      
      role: AppRole.values.firstWhere(
        
        (e) => e.name == roleString?.toLowerCase(),
        
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