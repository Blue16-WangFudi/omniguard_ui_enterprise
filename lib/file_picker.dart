import 'dart:io';
import 'package:flutter/material.dart';

class FilePickerService {
  /// A simple mock file picker for demonstration purposes
  /// In a real application, this would use a file picker plugin
  static Future<List<File>?> pickFiles() async {
    // This is just a placeholder for demonstration
    // In a real app, you would use something like file_picker package
    return [File('dummy_file.txt')];
  }
}

class FileAttachment extends StatelessWidget {
  final String fileName;
  final VoidCallback onRemove;

  const FileAttachment({Key? key, required this.fileName, required this.onRemove}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(fileName, style: const TextStyle(fontFamily: 'HarmonyOS_Sans')),
      deleteIcon: const Icon(Icons.close, size: 16),
      onDeleted: onRemove,
    );
  }
}
