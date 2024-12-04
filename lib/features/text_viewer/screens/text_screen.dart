// lib/features/text_viewer/screens/text_screen.dart
import 'package:flutter/material.dart';
import '../models/material.dart';

class TextScreen extends StatelessWidget {
  final List<LessonMaterial>? pdfMaterials;
  final VoidCallback onRetry;

  const TextScreen({
    super.key,
    this.pdfMaterials,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    if (pdfMaterials == null || pdfMaterials!.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              '教材を読み込めませんでした',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              child: const Text('再試行'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: pdfMaterials!.length,
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      itemBuilder: (context, index) {
        final material = pdfMaterials![index];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Image.network(
            material.blobUrl,
            fit: BoxFit.contain,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                        : null,
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.purple),
                  ),
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.grey),
                      const SizedBox(height: 8),
                      Text(
                        'ページ ${index + 1} を読み込めませんでした',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}