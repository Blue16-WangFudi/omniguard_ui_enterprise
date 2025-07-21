import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/detector_model.dart';
import '../models/chat_instance_model.dart';
import 'obs_service.dart';

class DetectorService {
  static const String _apiUrl = 'http://47.119.178.225:8090/api/v5/detector/multimodal';
  static const String _token = '0c97a6b8-9142-486c-a304-83a3e745614b';
  static const bool _debugMode = true; // Enable debug output
  
  // Debug print function
  static void _debugPrint(String message) {
    if (_debugMode) {
      print(message);
    }
  }
  
  /// Detect a single file by its URL
  /// 
  /// [fileUrl] - The URL of the file to detect
  /// [mode] - Detection mode, either 'FAST' or 'PRECISE'
  /// [type] - Detection type, either 'RISK' or 'AI'
  /// Returns a DetectionResult if successful, null otherwise
  static Future<DetectionResult?> detectFile(String fileUrl, {String mode = 'FAST', String type = 'RISK'}) async {
    try {
      _debugPrint('开始检测文件URL: $fileUrl');
      // Extract the object key from the URL
      final uri = Uri.parse(fileUrl);
      final objectKey = uri.path.startsWith('/') ? uri.path.substring(1) : uri.path;
      
      _debugPrint('提取的对象键: $objectKey');
      
      // Determine file type based on extension
      String fileType = "OTHER";
      final ext = uri.path.split('.').last.toLowerCase();
      if (['jpg', 'jpeg', 'png', 'gif', 'bmp'].contains(ext)) {
        fileType = "IMAGE";
      } else if (['mp4', 'avi', 'mov'].contains(ext)) {
        fileType = "VIDEO";
      } else if (['mp3', 'wav', 'ogg'].contains(ext)) {
        fileType = "AUDIO";
      } else if (['txt', 'text'].contains(ext)) {
        fileType = "TEXT";
      }
      
      _debugPrint('检测文件类型: $fileType');
      
      // Create the objects list with just this file
      final objects = [{
        "fileKey": objectKey,
        "type": fileType
      }];
      
      _debugPrint('创建对象列表: $objects');
      
      // Call the main detection API
      final result = await detectRisks(objects, detectionMode: mode, detectionType: type);
      
      if (result != null) {
        _debugPrint('检测结果: ${prettyPrintJson(result)}');
        // Process the response
        final response = DetectorResponse.fromJson(result);
        
        // If there are results, return the first one
        if (response.data.results.isNotEmpty) {
          return response.data.results.first;
        }
      }
      
      return null;
    } catch (e) {
      _debugPrint('Error detecting file: $e');
      return null;
    }
  }
  
  /// Detect text content by first uploading it as a txt file to OBS
  /// 
  /// [textContent] - The text content to analyze
  /// [mode] - Detection mode, either 'FAST' or 'PRECISE'
  /// [type] - Detection type, either 'RISK' or 'AI'
  /// Returns a DetectionResult if successful, null otherwise
  static Future<DetectionResult?> detectText(String textContent, {String mode = 'FAST', String type = 'RISK'}) async {
    try {
      _debugPrint('开始检测文本内容: $textContent');
      // First upload the text content as a txt file to OBS
      _debugPrint('上传文本内容到OBS...');
      final fileUrl = await ObsService.uploadTextAsTxt(textContent);
      
      if (fileUrl == null) {
        _debugPrint('Failed to upload text content to OBS');
        return null;
      }
      
      _debugPrint('文本上传成功: $fileUrl');
      
      // Now use the existing file detection method
      final result = await detectFile(fileUrl, mode: mode, type: type);
      
      if (result != null) {
        _debugPrint('文本检测成功,置信度: ${result.confidence}');
      } else {
        _debugPrint('文本检测失败或返回null');
      }
      
      return result;
    } catch (e) {
      _debugPrint('Error detecting text content: $e');
      return null;
    }
  }
  
  /// Call the detector API with the uploaded files
  /// 
  /// [objects] - List of file objects with fileKey and type
  /// [detectionMode] - Detection mode, either 'FAST' or 'PRECISE'
  /// [detectionType] - Detection type, either 'RISK' or 'AI'
  /// Returns the API response as a Map if successful, null otherwise
  static Future<Map<String, dynamic>?> detectRisks(List<Map<String, String>> objects, {String detectionMode = 'PRECISE', String detectionType = 'RISK'}) async {
    try {
      // Prepare the request body
      final Map<String, dynamic> requestBody = {
        "token": _token,
        "data": {
          "detectionType": detectionType,
          "detectionMode": detectionMode,
          "dataSource": {
            "province": "广东",
            "city": "深圳",
            "phoneNum": "15281991073"
          },
          "objects": objects
        }
      };
      
      _debugPrint('调用检测API的请求体: ${prettyPrintJson(requestBody)}');
      
      // Make the API call
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json; charset=utf-8',
        },
        body: jsonEncode(requestBody),
      );
      
      _debugPrint('检测API响应状态: ${response.statusCode}');
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        // Before parsing, ensure correct encoding by decoding the bytes with UTF-8
        // This helps handle Chinese characters properly
        final decodedResponse = utf8.decode(response.bodyBytes);
        _debugPrint('检测API响应体(正确解码): $decodedResponse');
        
        // Parse the properly decoded response
        return jsonDecode(decodedResponse) as Map<String, dynamic>;
      } else {
        _debugPrint('检测API请求失败,状态码: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      _debugPrint('Error calling detector API: $e');
      return null;
    }
  }
  
  /// Process the multimodal API response
  static DetectionResult? processMultimodalResponse(Map<String, dynamic> response) {
    try {
      _debugPrint('Processing API response: ${prettyPrintJson(response)}');
      
      // Check if the response has the expected format
      if (response['code'] == 'SUCCESS' && response['data'] != null) {
        final data = response['data'] as Map<String, dynamic>;
        
        // Create a detection result directly from the data object
        final suggestionsList = data['suggestions'] as List<dynamic>? ?? [];
        final suggestions = suggestionsList.map((item) => item.toString()).toList();
        
        // Construct the analysis JSON with suggestions
        Map<String, dynamic> analysisMap = {};
        if (data['analysis'] != null) {
          analysisMap = data['analysis'] as Map<String, dynamic>;
        } else {
          // Create default analysis with at least an overall message
          analysisMap = {
            'overall': data['category'] ?? '',
            'featurePoints': []
          };
        }
        // Make sure the suggestions are included in the analysis
        analysisMap['suggestions'] = suggestions;
        final analysisJson = jsonEncode(analysisMap);
        
        // Extract data source if it exists
        String dataSourceStr = '';
        if (data['dataSource'] != null) {
          dataSourceStr = jsonEncode(data['dataSource']);
        }
        
        _debugPrint('Successfully parsed detection result with confidence: ${data['confidence']}');
        
        return DetectionResult(
          id: data['id'] ?? '',
          fileKey: '',  // This might be missing in the API response
          detectionType: data['detection_type'] ?? 'RISK',
          category: data['category'] ?? '',
          confidence: (data['confidence'] ?? 0.0).toDouble(),
          analysisJson: analysisJson,
          timeCost: data['timeCost'] ?? 0,
          dataSource: dataSourceStr,
          timestamp: DateTime.now(),
        );
      } else {
        _debugPrint('API response does not have the expected format: code=${response['code']}');
      }
    } catch (e) {
      _debugPrint('Error processing detection response: $e');
    }
    return null;
  }
  
  /// Process the multimodal API response and create a system message with detection data
  static ChatMessage createSystemMessageFromResponse(Map<String, dynamic> response, String detectionMode) {
    try {
      final detectorResponse = DetectorResponse.fromJson(response);
      _debugPrint('u4eceu68c0u6d4bu54cdu5e94u521bu5efau7cfbu7edfu6d88u606f: ${detectorResponse.status}');
      
      if (detectorResponse.data.results.isNotEmpty) {
        _debugPrint('u6210u529fu89e3u6790u68c0u6d4bu7ed3u679cu90fdu6709u5206u6790u5185u5bb9');
        
        // u786eu4fddu6bcfu4e2au7ed3u679cu90fdu6709u5206u6790u5185u5bb9
        final results = detectorResponse.data.results.map((result) {
          if (result.analysis.overall.isEmpty) {
            // u5982u679cu5206u6790u5185u5bb9u4e3au7a7auff0cu8fdbu884cu5904u7406
            _debugPrint('u7ed3u679cu7f3au5c11u5206u6790u5185u5bb9uff0cu8bbeu7f6eu9ed8u8ba4u503c');
            final analysis = DetectionAnalysis(
              overall: "u53efu80fdu5b58u5728u98ceu9669u5185u5bb9uff0cu8bf7u8c28u614eu5904u7406",
              featurePoints: [
                FeaturePoint(keyword: "u98ceu9669u5206u7c7b", description: result.category),
                FeaturePoint(keyword: "u98ceu9669u7ea7u522b", description: result.confidence >= 0.8 ? "u9ad8u5ea6u98ceu9669" : 
                                                  (result.confidence >= 0.5 ? "u4e2du5ea6u98ceu9669" : "u4f4eu5ea6u98ceu9669")),
              ],
              suggestions: ["u5efau8baeu8fdbu4e00u6b65u6838u5b9eu5185u5bb9u771fu5b9eu6027", "u8c28u614eu5904u7406u76f8u5173u4fe1u606f"]
            );
            
            final analysisJson = jsonEncode({
              'overall': analysis.overall,
              'featurePoints': analysis.featurePoints.map((fp) => {
                'keyword': fp.keyword,
                'description': fp.description
              }).toList(),
              'suggestions': analysis.suggestions
            });
            
            return DetectionResult(
              id: result.id,
              fileKey: result.fileKey,
              detectionType: result.detectionType,
              category: result.category,
              confidence: result.confidence,
              analysisJson: analysisJson,
              analysis: analysis,
              timeCost: result.timeCost,
              dataSource: result.dataSource,
              timestamp: result.timestamp
            );
          }
          return result;
        }).toList();
        
        // Use the new withResults factory constructor for backward compatibility
        final detectionData = DetectionData.withResults(
          results,
          detectorResponse.data.detectionType,
        );
        
        // u521bu5efau7cfbu7edfu6d88u606fu5e76u5305u542bu68c0u6d4bu6570u636e
        return ChatMessage(
          text: "u68c0u6d4bu5b8cu6210uff0cu53d1u73b0u5185u5bb9u98ceu9669",
          isUser: false,
          thinkingStatus: ThinkingStatus.completed,
          detectionData: detectionData,
        );
      } else {
        _debugPrint('u6ca1u6709u68c0u6d4bu7ed3u679cuff0cu8fd4u56deu9519u8befu6d88u606f');
        return ChatMessage(
          text: "u65e0u6cd5u68c0u6d4bu5185u5bb9u98ceu9669u3002u8bf7u68c0u67e5u60a8u7684u8f93u5165u6216u6587u4ef6u662fu5426u6b63u786eu3002",
          isUser: false,
          thinkingStatus: ThinkingStatus.completed,
        );
      }
    } catch (e) {
      _debugPrint('u5904u7406u54cdu5e94u65f6u51fau9519: $e');
      return ChatMessage(
        text: "u68c0u6d4bu5185u5bb9u98ceu9669u53d1u751fu9519u8bef: ${e.toString()}",
        isUser: false,
        thinkingStatus: ThinkingStatus.completed,
      );
    }
  }

  /// Directly process an API response and create a chat message with detection data
  static Future<ChatMessage> processApiResponseToMessage(Map<String, dynamic> requestBody, String detectionMode) async {
    try {
      _debugPrint('u76f4u63a5u5904u7406APIu8bf7u6c42u4e3au6d88u606f');
      
      // Make the API call
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json; charset=utf-8',
        },
        body: jsonEncode(requestBody),
      );
      
      _debugPrint('u76f4u63a5APIu8c03u7528u54cdu5e94u72b6u6001: ${response.statusCode}');
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        // Before parsing, ensure correct encoding by decoding the bytes with UTF-8
        final decodedResponse = utf8.decode(response.bodyBytes);
        _debugPrint('u76f4u63a5APIu54cdu5e94u4f53(u6b63u786eu89e3u7801): $decodedResponse');
        
        // Parse the properly decoded response
        final jsonResponse = jsonDecode(decodedResponse) as Map<String, dynamic>;
        
        // Create a system message with the detection results
        return createSystemMessageFromResponse(jsonResponse, detectionMode);
      } else {
        _debugPrint('u76f4u63a5APIu8bf7u6c42u5931u8d25,u72b6u6001u7801: ${response.statusCode}');
        return ChatMessage(
          text: "u68c0u6d4bu8bf7u6c42u5931u8d25uff0cu72b6u6001u7801: ${response.statusCode}",
          isUser: false,
          thinkingStatus: ThinkingStatus.completed,
        );
      }
    } catch (e) {
      _debugPrint('u76f4u63a5u5904u7406APIu8bf7u6c42u65f6u51fau9519: $e');
      return ChatMessage(
        text: "u68c0u6d4bu8bf7u6c42u51fau9519: ${e.toString()}",
        isUser: false,
        thinkingStatus: ThinkingStatus.completed,
      );
    }
  }
  
  // Helper method to prettify JSON for display (useful for debugging)
  static String prettyPrintJson(Map<String, dynamic> json) {
    final encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(json);
  }
}