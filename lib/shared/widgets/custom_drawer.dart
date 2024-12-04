// lib/shared/widgets/custom_drawer.dart
import 'package:flutter/material.dart';
import '../../features/text_viewer/models/material.dart';
import '../../features/text_viewer/services/material_service.dart';
import 'package:intl/intl.dart';

class CustomDrawer extends StatefulWidget {
  final Function(int) onUnitSelected;
  final int currentUnitId;

  const CustomDrawer({
    super.key,
    required this.onUnitSelected,
    required this.currentUnitId,
  });

  @override
  State<CustomDrawer> createState() => _CustomDrawerState();
}

class _CustomDrawerState extends State<CustomDrawer> {
  final MaterialService _materialService = MaterialService();
  List<LessonMaterial>? _materials;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMaterials();
  }

  Future<void> _loadMaterials() async {
    try {
      final materials = await _materialService.getMaterialsByUnit(widget.currentUnitId);
      setState(() {
        if (materials['pdfs'] is List) {
          _materials = materials['pdfs'];
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('教材の読み込みに失敗しました')),
        );
      }
    }
  }

  String _formatDate(DateTime date) {
    final formatter = DateFormat('HH:mm');
    return formatter.format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          Container(
            height: MediaQuery.of(context).padding.top + kToolbarHeight,
            width: double.infinity,
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
            child: const Center(
              child: Text(
                '講義一覧',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          if (_isLoading)
            const Expanded(
              child: Center(
                child: CircularProgressIndicator(),
              ),
            )
          else if (_materials == null || _materials!.isEmpty)
            const Expanded(
              child: Center(
                child: Text('教材が見つかりません'),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: _materials!.length,
                itemBuilder: (context, index) {
                  final material = _materials![index];
                  final isSelected = material.unitId == widget.currentUnitId;

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isSelected ? Colors.purple : Colors.grey[200],
                      child: Icon(
                        Icons.description,
                        color: isSelected ? Colors.white : Colors.grey,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      material.title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    subtitle: Text(
                      _formatDate(material.createdAt),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    trailing: IconButton(
                      icon: Icon(
                        Icons.bookmark_border,
                        color: isSelected ? Colors.purple : Colors.grey[400],
                      ),
                      onPressed: () {
                        // ブックマーク機能の実装
                      },
                    ),
                    selected: isSelected,
                    selectedTileColor: Colors.purple.withOpacity(0.05),
                    onTap: () {
                      widget.onUnitSelected(material.unitId);
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}