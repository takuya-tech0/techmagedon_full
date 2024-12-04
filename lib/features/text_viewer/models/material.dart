// lib/features/text_viewer/models/material.dart
import 'package:flutter/foundation.dart';

@immutable
class LessonMaterial {
  final int materialId;
  final int unitId;
  final String title;
  final String description;
  final String materialType;
  final String blobUrl;
  final String blobName;
  final int fileSize;
  final int? pageCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  const LessonMaterial({
    required this.materialId,
    required this.unitId,
    required this.title,
    required this.description,
    required this.materialType,
    required this.blobUrl,
    required this.blobName,
    required this.fileSize,
    this.pageCount,
    required this.createdAt,
    required this.updatedAt,
  });

  factory LessonMaterial.fromJson(Map<String, dynamic> json) {
    return LessonMaterial(
      materialId: json['material_id'],
      unitId: json['unit_id'],
      title: json['title'],
      description: json['description'],
      materialType: json['material_type'],
      blobUrl: json['blob_url'],
      blobName: json['blob_name'],
      fileSize: json['file_size'],
      pageCount: json['page_count'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'material_id': materialId,
      'unit_id': unitId,
      'title': title,
      'description': description,
      'material_type': materialType,
      'blob_url': blobUrl,
      'blob_name': blobName,
      'file_size': fileSize,
      'page_count': pageCount,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  LessonMaterial copyWith({
    int? materialId,
    int? unitId,
    String? title,
    String? description,
    String? materialType,
    String? blobUrl,
    String? blobName,
    int? fileSize,
    int? pageCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return LessonMaterial(
      materialId: materialId ?? this.materialId,
      unitId: unitId ?? this.unitId,
      title: title ?? this.title,
      description: description ?? this.description,
      materialType: materialType ?? this.materialType,
      blobUrl: blobUrl ?? this.blobUrl,
      blobName: blobName ?? this.blobName,
      fileSize: fileSize ?? this.fileSize,
      pageCount: pageCount ?? this.pageCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LessonMaterial &&
        other.materialId == materialId &&
        other.unitId == unitId &&
        other.title == title &&
        other.description == description &&
        other.materialType == materialType &&
        other.blobUrl == blobUrl &&
        other.blobName == blobName &&
        other.fileSize == fileSize &&
        other.pageCount == pageCount &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      materialId,
      unitId,
      title,
      description,
      materialType,
      blobUrl,
      blobName,
      fileSize,
      pageCount,
      createdAt,
      updatedAt,
    );
  }

  @override
  String toString() {
    return 'LessonMaterial(materialId: $materialId, unitId: $unitId, title: $title, '
        'description: $description, materialType: $materialType, blobUrl: $blobUrl, '
        'blobName: $blobName, fileSize: $fileSize, pageCount: $pageCount, '
        'createdAt: $createdAt, updatedAt: $updatedAt)';
  }
}