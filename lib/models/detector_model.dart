import 'dart:convert';

// Detection result model
class DetectionResult {
  final String id;
  final String fileKey;
  final String detectionType;
  final String category;
  final double confidence;
  final String analysisJson;
  final DetectionAnalysis analysis;
  final int timeCost;
  final String dataSource;
  final DateTime timestamp;

  DetectionResult({
    required this.id,
    required this.fileKey,
    required this.detectionType,
    required this.category,
    required this.confidence,
    required this.analysisJson,
    DetectionAnalysis? analysis,
    required this.timeCost,
    required this.dataSource,
    DateTime? timestamp,
  }) : 
    this.analysis = analysis ?? DetectionAnalysis.fromJson(
      analysisJson.isNotEmpty 
        ? jsonDecode(analysisJson) 
        : {'overall': '', 'featurePoints': [], 'suggestions': []}
    ),
    this.timestamp = timestamp ?? DateTime.now();

  // Create detection result from JSON
  factory DetectionResult.fromJson(Map<String, dynamic> json) {
    final analysisText = json['analysis'] ?? '';
    Map<String, dynamic> analysisMap = {};
    
    // Try to parse analysis as JSON if it's a string
    if (analysisText is String && analysisText.isNotEmpty) {
      try {
        analysisMap = jsonDecode(analysisText);
      } catch (e) {
        // If it's not valid JSON, treat it as the overall description
        analysisMap = {
          'overall': analysisText,
          'featurePoints': [],
          'suggestions': []
        };
      }
    }
    
    return DetectionResult(
      id: json['id'] ?? '',
      fileKey: json['fileKey'] ?? '',
      detectionType: json['detectionType'] ?? '',
      category: json['category'] ?? '',
      confidence: (json['confidence'] ?? 0.0).toDouble(),
      analysisJson: analysisText,
      analysis: DetectionAnalysis.fromJson(analysisMap),
      timeCost: json['timeCost'] ?? 0,
      dataSource: json['dataSource'] ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : null,
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fileKey': fileKey,
      'detectionType': detectionType,
      'category': category,
      'confidence': confidence,
      'analysis': analysisJson,
      'timeCost': timeCost,
      'dataSource': dataSource,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

// Detection data model
class DetectionData {
  String id;
  final double confidence;
  final String category;
  final DetectionAnalysis analysis;
  final List<String> suggestions;
  final String detection_type;
  final int timeCost;
  final DataSourceInfo dataSource;
  final DateTime timestamp;
  final List<DetectionResult> _results;

  // 存储原始检测结果列表用于向后兼容
  List<DetectionResult> get results => _results.isNotEmpty ? _results : [toDetectionResult()];
  String get detectionType => detection_type;

  DetectionData({
    required this.id,
    required this.confidence,
    required this.category,
    required this.analysis,
    required this.suggestions,
    required this.detection_type,
    required this.timeCost,
    required this.dataSource,
    DateTime? timestamp,
    List<DetectionResult>? results,
  }) : 
    this.timestamp = timestamp ?? DateTime.now(),
    this._results = results ?? [];

  // Create detection data from JSON
  factory DetectionData.fromJson(Map<String, dynamic> json) {
    // Check if the JSON contains 'results' array (old format)
    if (json.containsKey('results')) {
      // Handle old format with results array
      final resultsList = (json['results'] as List?)
          ?.map((result) => DetectionResult.fromJson(result))
          .toList() ?? [];

      if (resultsList.isNotEmpty) {
        // Convert first result to the new format
        final firstResult = resultsList.first;
        return DetectionData(
          id: firstResult.id,
          confidence: firstResult.confidence,
          category: firstResult.category,
          analysis: firstResult.analysis,
          suggestions: firstResult.analysis.suggestions,
          detection_type: firstResult.detectionType,
          timeCost: firstResult.timeCost,
          dataSource: DataSourceInfo.fromString(firstResult.dataSource),
          timestamp: firstResult.timestamp,
          results: resultsList,
        );
      } else {
        // Empty results, create default
        return DetectionData(
          id: '',
          confidence: 0.0,
          category: '',
          analysis: DetectionAnalysis.fromJson({}),
          suggestions: [],
          detection_type: json['detectionType'] ?? 'RISK',
          timeCost: 0,
          dataSource: DataSourceInfo.fromString(''),
          timestamp: json['timestamp'] != null
              ? DateTime.parse(json['timestamp'])
              : null,
        );
      }
    }
    
    // Handle new format (direct properties)
    // Parse analysis
    Map<String, dynamic> analysisMap = {};
    if (json['analysis'] != null) {
      analysisMap = json['analysis'] is String 
          ? jsonDecode(json['analysis']) 
          : json['analysis'];
    }

    // Parse suggestions
    List<String> suggestionsList = [];
    if (json['suggestions'] != null) {
      suggestionsList = (json['suggestions'] as List)
          .map((item) => item.toString())
          .toList();
    }

    // Parse dataSource
    Map<String, dynamic> dataSourceMap = {};
    if (json['dataSource'] != null) {
      dataSourceMap = json['dataSource'] is String 
          ? jsonDecode(json['dataSource']) 
          : json['dataSource'];
    }

    return DetectionData(
      id: json['id'] ?? '',
      confidence: (json['confidence'] ?? 0.0).toDouble(),
      category: json['category'] ?? '',
      analysis: DetectionAnalysis.fromJson(analysisMap),
      suggestions: suggestionsList,
      detection_type: json['detection_type'] ?? 'RISK',
      timeCost: json['timeCost'] ?? 0,
      dataSource: DataSourceInfo.fromJson(dataSourceMap),
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : null,
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'confidence': confidence,
      'category': category,
      'analysis': {
        'overall': analysis.overall,
        'featurePoints': analysis.featurePoints.map((point) => {
          'keyword': point.keyword,
          'description': point.description,
        }).toList(),
      },
      'suggestions': suggestions,
      'detection_type': detection_type,
      'timeCost': timeCost,
      'dataSource': dataSource.toJson(),
      'timestamp': timestamp.toIso8601String(),
    };
  }

  // Convert to DetectionResult (for backward compatibility)
  DetectionResult toDetectionResult() {
    final analysisJson = jsonEncode({
      'overall': analysis.overall,
      'featurePoints': analysis.featurePoints.map((point) => {
        'keyword': point.keyword,
        'description': point.description,
      }).toList(),
      'suggestions': suggestions,
    });

    String dataSourceString = '';
    try {
      dataSourceString = jsonEncode(dataSource.toJson());
    } catch (e) {
      // Ignore error
    }

    return DetectionResult(
      id: id,
      fileKey: '',
      detectionType: detection_type,
      category: category,
      confidence: confidence,
      analysisJson: analysisJson,
      analysis: analysis,
      timeCost: timeCost,
      dataSource: dataSourceString,
      timestamp: timestamp,
    );
  }

  // Create DetectionData from a DetectionResult
  factory DetectionData.fromDetectionResult(DetectionResult result) {
    return DetectionData(
      id: result.id,
      confidence: result.confidence,
      category: result.category,
      analysis: result.analysis,
      suggestions: result.analysis.suggestions,
      detection_type: result.detectionType,
      timeCost: result.timeCost,
      dataSource: DataSourceInfo.fromString(result.dataSource),
      timestamp: result.timestamp,
    );
  }

  // Create a new DetectionData instance with a list of DetectionResults
  factory DetectionData.withResults(List<DetectionResult> results, String detectionType) {
    if (results.isEmpty) {
      return DetectionData(
        id: '',
        confidence: 0.0,
        category: '',
        analysis: DetectionAnalysis.fromJson({}),
        suggestions: [],
        detection_type: detectionType,
        timeCost: 0,
        dataSource: DataSourceInfo.fromString(''),
        timestamp: DateTime.now(),
        results: [], 
      );
    }

    final firstResult = results.first;
    return DetectionData(
      id: firstResult.id,
      confidence: firstResult.confidence,
      category: firstResult.category,
      analysis: firstResult.analysis,
      suggestions: firstResult.analysis.suggestions,
      detection_type: detectionType,
      timeCost: firstResult.timeCost,
      dataSource: DataSourceInfo.fromString(firstResult.dataSource),
      timestamp: firstResult.timestamp,
      results: results, 
    );
  }
}

// Detector response model
class DetectorResponse {
  final String status;
  final String message;
  final DetectionData data;

  DetectorResponse({
    required this.status,
    required this.message,
    required this.data,
  });

  // Create detector response from JSON
  factory DetectorResponse.fromJson(Map<String, dynamic> json) {
    DetectionData detectionData = DetectionData.fromJson(json['data']['summary'] ?? {});
    detectionData.id=json['data']['id']?? '';
    return DetectorResponse(
      status: json['status'] ?? '',
      message: json['message'] ?? '',
      data: detectionData,
    );
  }
}

// Detection analysis model
class DetectionAnalysis {
  final String overall;
  final List<FeaturePoint> featurePoints;
  final List<String> suggestions;

  DetectionAnalysis({
    required this.overall,
    required this.featurePoints,
    required this.suggestions,
  });

  factory DetectionAnalysis.fromJson(Map<String, dynamic> json) {
    var pointsJson = json['featurePoints'] as List?;
    List<FeaturePoint> points = [];
    if (pointsJson != null) {
      points = pointsJson
          .map((pointJson) => FeaturePoint.fromJson(pointJson as Map<String, dynamic>))
          .toList();
    }

    var suggestionsJson = json['suggestions'] as List?;
    List<String> suggestions = [];
    if (suggestionsJson != null) {
      suggestions = suggestionsJson.map((s) => s as String).toList();
    }

    return DetectionAnalysis(
      overall: json['overall'] as String? ?? '',
      featurePoints: points,
      suggestions: suggestions,
    );
  }
}

// Feature point model
class FeaturePoint {
  final String keyword;
  final String description;

  FeaturePoint({required this.keyword, required this.description});

  factory FeaturePoint.fromJson(Map<String, dynamic> json) {
    return FeaturePoint(
      keyword: json['keyword'] as String? ?? '',
      description: json['description'] as String? ?? '',
    );
  }
}

// Data source info model
class DataSourceInfo {
  final String province;
  final String city;
  final String phoneNum;

  DataSourceInfo({
    required this.province,
    required this.city,
    required this.phoneNum,
  });

  factory DataSourceInfo.fromJson(Map<String, dynamic> json) {
    return DataSourceInfo(
      province: json['province'] ?? '',
      city: json['city'] ?? '',
      phoneNum: json['phoneNum'] ?? '',
    );
  }

  // Create from JSON string (for backward compatibility)
  factory DataSourceInfo.fromString(String dataSourceStr) {
    if (dataSourceStr.isEmpty) {
      return DataSourceInfo(
        province: '',
        city: '',
        phoneNum: '',
      );
    }

    try {
      final json = jsonDecode(dataSourceStr) as Map<String, dynamic>;
      return DataSourceInfo.fromJson(json);
    } catch (e) {
      // If parsing fails, return default values
      return DataSourceInfo(
        province: '',
        city: '',
        phoneNum: '',
      );
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'province': province,
      'city': city,
      'phoneNum': phoneNum,
    };
  }
}

// Data source model
class DataSource {
  final List<FileInfo> files;

  DataSource({required this.files});

  factory DataSource.fromJson(Map<String, dynamic> json) {
    var filesJson = json['files'] as List?;
    List<FileInfo> files = [];
    if (filesJson != null) {
      files = filesJson
          .map((fileJson) => FileInfo.fromJson(fileJson as Map<String, dynamic>))
          .toList();
    }
    return DataSource(files: files);
  }
}

// File info model
class FileInfo {
  final String type;
  final String fileName;
  final String fileKey;

  FileInfo({required this.type, required this.fileName, required this.fileKey});

  factory FileInfo.fromJson(Map<String, dynamic> json) {
    return FileInfo(
      type: json['type'] as String? ?? '',
      fileName: json['fileName'] as String? ?? '',
      fileKey: json['fileKey'] as String? ?? '',
    );
  }
}
