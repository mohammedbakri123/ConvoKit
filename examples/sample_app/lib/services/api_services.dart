import 'dart:convert';
import 'package:flutter/services.dart';

import '../models/user_model.dart';

/// Offline sample user loader backed by bundled `assets/sample_data.json`.
class ApiServices {
  static Future<List<SampleUserModel>> fetchUsers() => getDefaultUsers();

  static Future<List<SampleUserModel>> getDefaultUsers() async {
    final jsonString = await rootBundle.loadString('assets/sample_data.json');
    final Map<String, dynamic> jsonData = jsonDecode(jsonString);
    final List<dynamic> data = jsonData['users'] ?? [];
    return data
        .map(
          (user) => SampleUserModel(
            user['name'] ?? '',
            user['uid'] ?? '',
            user['avatar'] ?? '',
          ),
        )
        .toList();
  }
}
