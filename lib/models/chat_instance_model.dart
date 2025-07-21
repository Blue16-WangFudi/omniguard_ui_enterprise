import 'file_model.dart';
import 'detector_model.dart';

// 聊天实例模型，用于管理多个聊天会话
class ChatInstance {
  final String id; // 唯一标识符
  String title; // 聊天标题
  List<ChatMessage> messages; // 消息列表
  final DateTime createdAt; // 创建时间
  final DateTime lastUpdatedAt; // 最后更新时间
  final bool isActive; // 是否为活动实例

  ChatInstance({
    required this.id,
    this.title = '',
    List<ChatMessage>? messages,
    DateTime? createdAt,
    DateTime? lastUpdatedAt,
    this.isActive = false,
  }) : 
    this.messages = messages ?? [],
    this.createdAt = createdAt ?? DateTime.now(),
    this.lastUpdatedAt = lastUpdatedAt ?? DateTime.now();

  // 创建一个新的实例，带有更新的属性
  ChatInstance copyWith({
    String? id,
    String? title,
    List<ChatMessage>? messages,
    DateTime? createdAt,
    DateTime? lastUpdatedAt,
    bool? isActive,
  }) {
    return ChatInstance(
      id: id ?? this.id,
      title: title ?? this.title,
      messages: messages ?? this.messages,
      createdAt: createdAt ?? this.createdAt,
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
      isActive: isActive ?? this.isActive,
    );
  }

  // 从用户输入或文件名生成标题
  static String generateTitle(String? userText, List<FileAttachment> files) {
    if (userText != null && userText.isNotEmpty) {
      // 取用户输入的前10个字符作为标题
      return userText.length > 10 ? userText.substring(0, 10) : userText;
    } else if (files.isNotEmpty) {
      // 如果只有文件，使用第一个文件名作为标题
      String fileName = files.first.originalName;
      return fileName.length > 10 ? fileName.substring(0, 10) : fileName;
    } else {
      // 默认标题
      return '新任务';
    }
  }
}

// Message model to store chat messages (移动自right_panel.dart)
class ChatMessage {
  final String text;
  List<FileAttachment> files;
  final DateTime timestamp;
  final bool isUser; // true if sent by user, false if from system
  final DetectionData? detectionData; // Add detection data field
  final ThinkingStatus? thinkingStatus; // Add thinking status field
  final String? detectionMode; // Store the detection mode used when sending the message
  final String? reportUrl; // 添加报告URL字段

  ChatMessage({
    required this.text,
    this.files = const [],
    required this.isUser,
    this.detectionData,
    this.thinkingStatus,
    this.detectionMode,
    this.reportUrl, // 初始化报告URL字段
  }) : timestamp = DateTime.now();
}

// Enum to represent the thinking status of the AI (移动自right_panel.dart)
enum ThinkingStatus {
  thinking,    // AI is processing the request
  completed,   // AI has finished processing
  cancelled    // User cancelled the response
}
