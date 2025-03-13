import 'dart:io';
import 'dart:math';
import 'package:http/http.dart' as http;

class ObsService {
  // OBS configuration
  static const String accessKey = "1TRLU6YPNLDWNPFAVWZJ";
  static const String secretKey = "1NBGoa0JSExA2hvowEXGZnyrvbm5s3VTGWstsyeP";
  static const String endpoint = "omniguard.obs.cn-north-4.myhuaweicloud.com";
  static const String region = "cn-north-4";
  static const String bucketName = "omniguard";
  static const bool debugMode = true; // u5f00u542fu8c03u8bd5u8f93u51fa
  
  // Generate random string for filename
  static String _generateRandomString(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return String.fromCharCodes(
      List.generate(length, (index) => chars.codeUnitAt(random.nextInt(chars.length)))
    );
  }
  
  // Generate unique filename: timestamp_randomString.extension
  static String generateUniqueFilename(String originalFilename) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final randomString = _generateRandomString(8);
    final extension = originalFilename.split('.').last;
    
    return "${timestamp}_$randomString.$extension";
  }
  
  // Get content type based on file extension
  static String _getContentType(String filename) {
    // Default content type
    String contentType = 'application/octet-stream';
    
    final ext = filename.split('.').last.toLowerCase();
    if (['jpg', 'jpeg', 'png', 'gif', 'bmp'].contains(ext)) {
      contentType = 'image/${ext == 'jpg' ? 'jpeg' : ext}';
    } else if (['mp4', 'avi', 'mov'].contains(ext)) {
      contentType = 'video/${ext}';
    } else if (['mp3', 'wav', 'ogg'].contains(ext)) {
      contentType = 'audio/${ext}';
    } else if (['pdf'].contains(ext)) {
      contentType = 'application/pdf';
    } else if (['doc', 'docx'].contains(ext)) {
      contentType = 'application/msword';
    } else if (['txt'].contains(ext)) {
      contentType = 'text/plain';
    }
    
    return contentType;
  }
  
  // u8c03u8bd5u8f93u51fau51fdu6570
  static void _debugPrint(String message) {
    if (debugMode) {
      print(message);
    }
  }
  
  // u4f7fu7528u7b80u5355u76f4u63a5u7684u65b9u5f0fu4e0au4f20u6587u4ef6
  static Future<String?> uploadFile(File file, {Function(double)? onProgress}) async {
    try {
      // u62a5u544au521du59cbu8fdbu5ea6
      if (onProgress != null) {
        onProgress(0.0);
      }
      
      // u83b7u53d6u539fu59cbu6587u4ef6u540du5e76u751fu6210u552fu4e00u6587u4ef6u540d
      final originalFilename = file.path.split(Platform.isWindows ? '\\' : '/').last;
      final uniqueFilename = generateUniqueFilename(originalFilename);
      final objectKey = "resource/$uniqueFilename";
      
      // u6784u5efau4e0au4f20URL
      final url = 'https://$endpoint/$objectKey';
      
      // u8bfbu53d6u6587u4ef6u5185u5bb9
      final fileBytes = await file.readAsBytes();
      
      // u83b7u53d6u5185u5bb9u7c7bu578b
      final contentType = _getContentType(originalFilename);
      
      // u6784u5efau8bf7u6c42u5934
      final headers = {
        'Content-Type': contentType,
        'x-obs-acl': 'public-read',
      };
      
      _debugPrint('\nu4e0au4f20URL: $url');
      _debugPrint('u8bf7u6c42u5934: $headers');
      
      // u53d1u9001PUTu8bf7u6c42
      final response = await http.put(
        Uri.parse(url),
        headers: headers,
        body: fileBytes
      );
      
      _debugPrint('\nu54cdu5e94u72b6u6001u7801: ${response.statusCode}');
      _debugPrint('u54cdu5e94u5185u5bb9: ${response.body}');
      
      // u5982u679cu7b80u5355u65b9u6cd5u4e0du6210u529fuff0cu5c1du8bd5u4f7fu7528u8868u5355u4e0au4f20
      if (response.statusCode == 403) {
        _debugPrint('\nu76f4u63a5u4e0au4f20u5931u8d25uff0cu5c1du8bd5u4f7fu7528u8868u5355u4e0au4f20...');
        return await _uploadWithFormData(file);
      }
      
      // u62a5u544au4e0au4f20u5b8cu6210
      if (onProgress != null) {
        onProgress(1.0);
      }
      
      // u68c0u67e5u662fu5426u4e0au4f20u6210u529f
      if (response.statusCode == 200) {
        final fileUrl = 'https://$endpoint/$objectKey';
        _debugPrint('\nu4e0au4f20u6210u529f! URL: $fileUrl');
        return fileUrl;
      } else {
        _debugPrint("\nu4e0au4f20u5931u8d25uff0cu72b6u6001u7801: ${response.statusCode}");
        _debugPrint("u9519u8befu4fe1u606f: ${response.body}");
        return null;
      }
    } catch (e) {
      _debugPrint("\nu4e0au4f20u6587u4ef6u65f6u51fau9519: $e");
      return null;
    }
  }
  
  // u4f7fu7528u8868u5355u6570u636eu4e0au4f20
  static Future<String?> _uploadWithFormData(File file) async {
    try {
      // u83b7u53d6u6587u4ef6u4fe1u606f
      final originalFilename = file.path.split(Platform.isWindows ? '\\' : '/').last;
      final uniqueFilename = generateUniqueFilename(originalFilename);
      final objectKey = "resource/$uniqueFilename";
      final fileBytes = await file.readAsBytes();
      
      // u751fu6210u8868u5355u4e0au4f20URL
      final uploadUrl = 'https://$bucketName.obs.$region.myhuaweicloud.com/';
      
      // u521bu5efamultipartu8bf7u6c42
      var request = http.MultipartRequest('POST', Uri.parse(uploadUrl));
      
      // u6dfbu52a0u6587u4ef6
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          fileBytes,
          filename: originalFilename,
        )
      );
      
      // u6dfbu52a0u5fc5u8981u7684u5b57u6bb5 - OBSu8981u6c42u7684u6700u5c0fu5b57u6bb5u96c6
      request.fields['key'] = objectKey;
      request.fields['x-obs-acl'] = 'public-read';
      
      _debugPrint('\nu8868u5355u4e0au4f20URL: $uploadUrl');
      _debugPrint('u8868u5355u5b57u6bb5: ${request.fields}');
      
      // u53d1u9001u8bf7u6c42
      final streamResponse = await request.send();
      final response = await http.Response.fromStream(streamResponse);
      
      _debugPrint('\nu8868u5355u4e0au4f20u54cdu5e94u72b6u6001u7801: ${response.statusCode}');
      _debugPrint('u8868u5355u4e0au4f20u54cdu5e94u5185u5bb9: ${response.body}');
      
      // u68c0u67e5u662fu5426u4e0au4f20u6210u529f
      if (response.statusCode == 200 || response.statusCode == 201) {
        final fileUrl = 'https://$endpoint/$objectKey';
        _debugPrint('\nu8868u5355u4e0au4f20u6210u529f! URL: $fileUrl');
        return fileUrl;
      } else {
        // u5982u679cu4e0au4f20u5931u8d25uff0cu53efu80fdu9700u8981u5347u7ea7u5230u4f7fu7528u9884u7b7eu540du7684URL
        _debugPrint("\nu8868u5355u4e0au4f20u5931u8d25uff0cu53efu4ee5u5c1du8bd5u4f7fu7528u9884u7b7eu540dURLu65b9u5f0f");
        return null;
      }
    } catch (e) {
      _debugPrint("\nu8868u5355u4e0au4f20u51fau9519: $e");
      return null;
    }
  }
  
  // 将文本内容上传为txt文件
  static Future<String?> uploadTextAsTxt(String textContent, {Function(double)? onProgress}) async {
    try {
      // 报告初始进度
      if (onProgress != null) {
        onProgress(0.0);
      }
      
      // 生成唯一文件名
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final randomString = _generateRandomString(8);
      final uniqueFilename = "${timestamp}_$randomString.txt";
      final objectKey = "resource/$uniqueFilename";
      
      // 构建上传URL
      final url = 'https://$endpoint/$objectKey';
      
      // 设置内容类型
      final contentType = 'text/plain';
      
      // 构建请求头
      final headers = {
        'Content-Type': contentType,
        'x-obs-acl': 'public-read',
      };
      
      _debugPrint('\n上传文本为TXT，URL: $url');
      
      // 发送PUT请求
      final response = await http.put(
        Uri.parse(url),
        headers: headers,
        body: textContent
      );
      
      _debugPrint('\n响应状态码: ${response.statusCode}');
      
      // 检查响应
      if (response.statusCode == 200) {
        // 返回可访问的URL
        final publicUrl = 'https://$endpoint/$objectKey';
        
        // 报告完成进度
        if (onProgress != null) {
          onProgress(1.0);
        }
        
        _debugPrint('文本上传成功，公共URL: $publicUrl');
        return publicUrl;
      } else {
        _debugPrint('上传失败: ${response.body}');
        return null;
      }
    } catch (e) {
      _debugPrint('上传文本异常: $e');
      return null;
    }
  }
}
