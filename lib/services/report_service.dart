import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ReportService {
  static const String _apiUrl = 'http://47.119.178.225:8090/api/v5/report/generate';
  static const String _token = '0c97a6b8-9142-486c-a304-83a3e745614b';
  static const bool _debugMode = true; // 启用调试输出
  
  // 调试打印函数
  static void _debugPrint(String message) {
    if (_debugMode) {
      print(message);
    }
  }
  
  /// 根据检测ID列表生成风险报告
  /// 
  /// [detectionIds] - 检测ID列表
  /// [timeout] - 超时时间（毫秒）
  /// 成功时返回报告URL，失败时返回null
  static Future<String?> generateReport(List<String> detectionIds, {int timeout = 100000}) async {
    try {
      _debugPrint('开始生成风险报告，检测ID: $detectionIds');
      
      // 准备请求体
      final Map<String, dynamic> requestBody = {
        "token": _token,
        "data": {
          "detectionIds": detectionIds,
          "timeout": timeout
        }
      };
      
      _debugPrint('调用报告生成API的请求体: ${jsonEncode(requestBody)}');
      
      // 发起API调用
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json; charset=utf-8',
        },
        body: jsonEncode(requestBody),
      );
      
      _debugPrint('报告生成API响应状态: ${response.statusCode}');
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        // 确保使用UTF-8正确解码响应，以便正确处理中文字符
        final decodedResponse = utf8.decode(response.bodyBytes);
        _debugPrint('报告生成API响应体(正确解码): $decodedResponse');
        
        // 解析正确解码的响应
        final responseData = jsonDecode(decodedResponse) as Map<String, dynamic>;
        
        // 检查响应是否成功
        if (responseData['code'] == 'SUCCESS' && responseData['data'] != null) {
          final data = responseData['data'] as Map<String, dynamic>;
          
          // 检查data中是否包含url字段
          if (data['data'] != null && data['data']['url'] != null) {
            final reportUrl = data['data']['url'].toString().trim();
            _debugPrint('成功获取报告URL: $reportUrl');
            return reportUrl;
          } else {
            _debugPrint('响应中没有找到报告URL');
          }
        } else {
          _debugPrint('API响应不成功: ${responseData['code']} - ${responseData['msg']}');
        }
      } else {
        _debugPrint('报告生成API请求失败，状态码: ${response.statusCode}');
      }
      
      return null;
    } catch (e) {
      _debugPrint('生成报告时出错: $e');
      return null;
    }
  }
  
  /// 从聊天消息中收集所有检测ID
  /// 返回不重复的检测ID列表
  static List<String> collectDetectionIdsFromMessages(List<dynamic> messages) {
    final Set<String> uniqueIds = {};
    
    for (var message in messages) {
      // 检查消息是否包含检测数据
      if (message.detectionData != null) {
        // 从检测数据中获取所有结果
        final results = message.detectionData.results;
        if (results != null && results.isNotEmpty) {
          // 将每个结果的ID添加到集合中
          for (var result in results) {
            if (result.id.isNotEmpty) {
              uniqueIds.add(result.id);
            }
          }
        }
      }
    }
    
    return uniqueIds.toList();
  }
}

/// 报告生成响应模型
class ReportResponse {
  final String code;
  final String msg;
  final ReportData data;
  
  ReportResponse({
    required this.code,
    required this.msg,
    required this.data,
  });
  
  factory ReportResponse.fromJson(Map<String, dynamic> json) {
    return ReportResponse(
      code: json['code'] ?? '',
      msg: json['msg'] ?? '',
      data: json['data'] != null 
          ? ReportData.fromJson(json['data']) 
          : ReportData(id: '', createTime: '', detectionIds: [], data: ReportFileData(fileKey: '', url: '')),
    );
  }
}

/// 报告数据模型
class ReportData {
  final String id;
  final String createTime;
  final List<String> detectionIds;
  final ReportFileData data;
  
  ReportData({
    required this.id,
    required this.createTime,
    required this.detectionIds,
    required this.data,
  });
  
  factory ReportData.fromJson(Map<String, dynamic> json) {
    List<String> ids = [];
    if (json['detectionIds'] != null) {
      ids = (json['detectionIds'] as List).map((e) => e.toString()).toList();
    }
    
    return ReportData(
      id: json['id'] ?? '',
      createTime: json['createTime'] ?? '',
      detectionIds: ids,
      data: json['data'] != null 
          ? ReportFileData.fromJson(json['data']) 
          : ReportFileData(fileKey: '', url: ''),
    );
  }
}

/// 报告文件数据模型
class ReportFileData {
  final String fileKey;
  final String url;
  
  ReportFileData({
    required this.fileKey,
    required this.url,
  });
  
  factory ReportFileData.fromJson(Map<String, dynamic> json) {
    return ReportFileData(
      fileKey: json['fileKey'] ?? '',
      url: json['url'] ?? '',
    );
  }
}