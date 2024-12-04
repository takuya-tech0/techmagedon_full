// lib/features/text_viewer/services/material_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/material.dart';

class MaterialService {
  static const String baseUrl = 'http://localhost:8000';

  Future<Map<String, dynamic>> getMaterialsByUnit(int unitId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/materials/unit/$unitId'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final decodedBody = utf8.decode(response.bodyBytes);
        final Map<String, dynamic> json = jsonDecode(decodedBody);

        return {
          'video': json['video'] != null ?
          LessonMaterial.fromJson(json['video']) : null,
          'pdfs': (json['pdfs'] as List)
              .map((p) => LessonMaterial.fromJson(p))
              .toList(),
        };
      } else {
        throw Exception('Failed to load materials: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching materials: $e');
    }
  }

  Future<Map<String, dynamic>> getDefaultMaterials() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/materials/default'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final decodedBody = utf8.decode(response.bodyBytes);
        final Map<String, dynamic> json = jsonDecode(decodedBody);

        return {
          'video': json['video'] != null ?
          LessonMaterial.fromJson(json['video']) : null,
          'pdfs': (json['pdfs'] as List)
              .map((p) => LessonMaterial.fromJson(p))
              .toList(),
        };
      } else {
        throw Exception('Failed to load default materials: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching default materials: $e');
    }
  }
}