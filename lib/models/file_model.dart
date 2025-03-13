import 'dart:io';
import 'dart:math';

enum FileUploadStatus {
  pending,   // File selected but not yet uploaded
  uploading, // File is currently uploading
  completed, // File upload completed successfully
  error      // File upload failed
}

class FileAttachment {
  final String id; // Unique identifier for the file attachment
  final File file;
  final String originalName;
  String? uploadedUrl; // URL after successful upload
  FileUploadStatus status;
  double uploadProgress; // 0.0 to 1.0
  String? uniqueFileName; // Generated name for OBS storage
  
  FileAttachment({
    String? id,
    required this.file,
    required this.originalName,
    this.uploadedUrl,
    this.status = FileUploadStatus.pending,
    this.uploadProgress = 0.0,
    this.uniqueFileName,
  }) : id = id ?? _generateUniqueId();
  
  // Generate a random unique ID
  static String _generateUniqueId() {
    final random = Random();
    return DateTime.now().millisecondsSinceEpoch.toString() + 
           random.nextInt(10000).toString();
  }
  
  // Helper to check if file is uploading
  bool get isUploading => status == FileUploadStatus.uploading;
  
  // Helper to check if file is uploaded successfully
  bool get isUploaded => status == FileUploadStatus.completed && uploadedUrl != null;
  
  // Helper to check if file upload failed
  bool get isError => status == FileUploadStatus.error;
  
  // Create a copy of this object with updated properties
  FileAttachment copyWith({
    File? file,
    String? originalName,
    String? uploadedUrl,
    FileUploadStatus? status,
    double? uploadProgress,
    String? uniqueFileName,
  }) {
    return FileAttachment(
      id: this.id, // Preserve the same ID
      file: file ?? this.file,
      originalName: originalName ?? this.originalName,
      uploadedUrl: uploadedUrl ?? this.uploadedUrl,
      status: status ?? this.status,
      uploadProgress: uploadProgress ?? this.uploadProgress,
      uniqueFileName: uniqueFileName ?? this.uniqueFileName,
    );
  }
}
