import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;

class FileUtils {
  // Get file name from path (without directory path)
  static String getFileName(String filePath) {
    return path.basename(filePath);
  }
  
  // Get file extension
  static String getFileExtension(String fileName) {
    return path.extension(fileName).toLowerCase().replaceAll('.', '');
  }
  
  // Check if file is an image
  static bool isImage(String fileName) {
    final extension = getFileExtension(fileName);
    return ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'].contains(extension);
  }
  
  // Check if file is a video
  static bool isVideo(String fileName) {
    final extension = getFileExtension(fileName);
    return ['mp4', 'avi', 'mov', 'wmv', 'flv', 'mkv', 'webm'].contains(extension);
  }
  
  // Check if file is an audio
  static bool isAudio(String fileName) {
    final extension = getFileExtension(fileName);
    return ['mp3', 'wav', 'ogg', 'aac', 'flac', 'm4a', 'wma'].contains(extension);
  }
  
  // Check if file is a document
  static bool isDocument(String fileName) {
    final extension = getFileExtension(fileName);
    return ['doc', 'docx', 'pdf', 'xls', 'xlsx', 'ppt', 'pptx'].contains(extension);
  }
  
  // Check if file is a text file
  static bool isText(String fileName) {
    final extension = getFileExtension(fileName);
    return ['txt', 'rtf', 'md', 'json', 'xml', 'html', 'css', 'js'].contains(extension);
  }
  
  // Get icon for file type
  static Widget getFileIcon(File file, {double size = 40}) {
    final fileName = getFileName(file.path);
    
    if (isImage(fileName)) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.file(
          file,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Icon(Icons.image, size: size, color: Colors.blue);
          },
        ),
      );
    } else if (isVideo(fileName)) {
      return Icon(Icons.video_file, size: size, color: Colors.red);
    } else if (isAudio(fileName)) {
      return Icon(Icons.audio_file, size: size, color: Colors.orange);
    } else if (isDocument(fileName)) {
      return Icon(Icons.description, size: size, color: Colors.blue);
    } else if (isText(fileName)) {
      return Icon(Icons.text_snippet, size: size, color: Colors.green);
    } else {
      return Icon(Icons.insert_drive_file, size: size, color: Colors.grey);
    }
  }
}
