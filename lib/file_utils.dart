import 'dart:io';
import 'package:path/path.dart' as path;

class FileUtils {
  /// Gets the file size in human-readable format
  static String getFileSizeString(int size) {
    if (size < 1024) {
      return '$size B';
    } else if (size < 1024 * 1024) {
      return '${(size / 1024).toStringAsFixed(1)} KB';
    } else if (size < 1024 * 1024 * 1024) {
      return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(size / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }
  
  /// Gets the file extension
  static String getFileExtension(String filePath) {
    return path.extension(filePath).toLowerCase().replaceFirst('.', '');
  }
  
  /// Determines if the file is an image
  static bool isImageFile(String filePath) {
    final ext = getFileExtension(filePath);
    return ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'].contains(ext);
  }
  
  /// Determines if the file is a video
  static bool isVideoFile(String filePath) {
    final ext = getFileExtension(filePath);
    return ['mp4', 'avi', 'mov', 'wmv', 'flv', 'mkv', 'webm'].contains(ext);
  }
  
  /// Determines if the file is a document
  static bool isDocumentFile(String filePath) {
    final ext = getFileExtension(filePath);
    return ['pdf', 'doc', 'docx', 'txt', 'rtf', 'xls', 'xlsx', 'ppt', 'pptx'].contains(ext);
  }
}
