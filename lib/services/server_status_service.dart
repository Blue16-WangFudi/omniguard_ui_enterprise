import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ServerStatusService {
  static const String apiUrl = 'http://47.119.178.225:8090/api/v5/server/status';
  static const String token = '0c97a6b8-9142-486c-a304-83a3e745614b';
  dynamic _lastStatus = {};
  // Singleton pattern
  static final ServerStatusService _instance = ServerStatusService._internal();
  
  factory ServerStatusService() {
    return _instance;
  }
  
  ServerStatusService._internal();
  
  // Stream controller for server status data
  final _statusController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get statusStream => _statusController.stream;
  
  Timer? _timer;
  bool _isPolling = false;
  
  // Start polling the server status
  void startPolling() {
    if (_isPolling) return;
    
    _isPolling = true;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      fetchServerStatus();
    });
    
    // Fetch immediately upon starting
    fetchServerStatus();
  }
  
  // Stop polling
  void stopPolling() {
    _timer?.cancel();
    _timer = null;
    _isPolling = false;
  }
  
  // Fetch the server status
  Future<void> fetchServerStatus() async {
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'token': token,
          'data': {
            'serverId': 'ckj45d5gdg2f0dgc'
          }
        }),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body)['data'];
        _lastStatus = data;
        _statusController.add(data);
      } else {
        if (_lastStatus.isEmpty){
          _statusController.addError('Failed to fetch server status: ${response.statusCode}');
        }
        else{
          print(1);
        _statusController.add(_lastStatus);
        }
      }
    } catch (e) {
       if (_lastStatus.isEmpty){
          _statusController.addError('Error fetching server status: $e');
       }
       else{
        print(2);
        _statusController.add(_lastStatus);
       }
    }
  }
  
  // Dispose resources
  void dispose() {
    stopPolling();
    _statusController.close();
  }
}
