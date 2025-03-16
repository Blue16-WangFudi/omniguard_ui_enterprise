import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ServerStatusService {
  static const String apiUrl = 'http://47.119.178.225:8090/api/v4/server/status';
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
      // print(_lastStatus);
        // print(jsonDecode(response.body));
      // print(jsonDecode(response.body));
      if (response.statusCode == 200) {
      // if (true){
        final data = jsonDecode(response.body)['data'];
        _lastStatus = data;
        // print(data);
        // final data = {
        //   "id": "67d04437a433de17b579877e",
        //   "serverId": "ckj45d5gdg2f0dgc",
        //   "serverName": "OminGuard_Client",
        //   "network": "1.21",
        //   "performance": 2650,
        //   "capabilities": {
        //     "model_text_feature": {
        //       "serverId": "ckj45d5gdg2f0dgc",
        //       "capabilityType": "TEXT_FEATURE",
        //       "location": "REMOTE",
        //       "name": "model_text_feature",
        //       "taskQueue": {}
        //     },
        //     "model_image_feature": {
        //       "serverId": "ckj45d5gdg2f0dgc",
        //       "capabilityType": "IMAGE_FEATURE",
        //       "location": "REMOTE",
        //       "name": "model_image_feature",
        //       "taskQueue": {}
        //     },
        //     "model_audio_feature": {
        //       "serverId": "ckj45d5gdg2f0dgc",
        //       "capabilityType": "AUDIO_FEATURE",
        //       "location": "REMOTE",
        //       "name": "model_audio_feature",
        //       "taskQueue": {}
        //     },
        //     "model_video_feature": {
        //       "serverId": "ckj45d5gdg2f0dgc",
        //       "capabilityType": "VIDEO_FEATURE",
        //       "location": "REMOTE",
        //       "name": "model_video_feature",
        //       "taskQueue": {}
        //     },
        //     "model_precise_detection": {
        //       "serverId": "ckj45d5gdg2f0dgc",
        //       "capabilityType": "PRECISE_DETECTION",
        //       "location": "REMOTE",
        //       "name": "model_precise_detection",
        //       "taskQueue": {}
        //     },
        //     "model_fast_detection": {
        //       "serverId": "ckj45d5gdg2f0dgc",
        //       "capabilityType": "FAST_DETECTION",
        //       "location": "REMOTE",
        //       "name": "model_fast_detection",
        //       "taskQueue": {}
        //     },
        //     "report_generator": {
        //       "serverId": "ckj45d5gdg2f0dgc",
        //       "capabilityType": "REPORT_GENERATOR",
        //       "location": "REMOTE",
        //       "name": "report_generator",
        //       "taskQueue": {}
        //     }
        //   },
        //   "systemInfo": {
        //     "current_time": {
        //       "year": 2025,
        //       "month": 3,
        //       "day": 11,
        //       "hour": 22,
        //       "minute": 9,
        //       "second": 57
        //     },
        //     "public_ip": "TODO",
        //     "cpu_utilization": {
        //       "current": 14.7,
        //       "max": 7200
        //     },
        //     "memory_utilization": {
        //       "percent": 15.4,
        //       "total": 135010557952
        //     },
        //     "disk_utilization": {
        //       "percent": 93.0,
        //       "total": 982820896768
        //     },
        //     "disk_io": {
        //       "read": 145213349376,
        //       "write": 20589606400
        //     },
        //     "network_bandwidth": {
        //       "downlink": 0.0,
        //       "uplink": 0.0
        //     },
        //     "network_io": {
        //       "send": 1867782832,
        //       "received": 2112277686
        //     },
        //     "system_info": {
        //       "system": "Linux",
        //       "name": "ubuntu-SYS-7048GR-TR",
        //       "release": "6.8.0-52-generic",
        //       "version": "#53~22.04.1-Ubuntu SMP PREEMPT_DYNAMIC Wed Jan 15 19:18:46 UTC 2",
        //       "machine": "x86_64",
        //       "processor": "x86_64",
        //       "boot_time": 1741513266.0
        //     },
        //     "gpu_utilization": [
        //       {
        //         "id": 0,
        //         "name": "NVIDIA GeForce RTX 2080 Ti",
        //         "load": 0.0,
        //         "memory_total": 22528.0,
        //         "memory_used": 8.0,
        //         "memory_utilization": 0.03551136363636364
        //       },
        //       {
        //         "id": 1,
        //         "name": "NVIDIA GeForce RTX 2080 Ti",
        //         "load": 0.0,
        //         "memory_total": 22528.0,
        //         "memory_used": 8.0,
        //         "memory_utilization": 0.03551136363636364
        //       },
        //       {
        //         "id": 2,
        //         "name": "NVIDIA GeForce RTX 2080 Ti",
        //         "load": 0.0,
        //         "memory_total": 22528.0,
        //         "memory_used": 8.0,
        //         "memory_utilization": 0.03551136363636364
        //       },
        //       {
        //         "id": 3,
        //         "name": "NVIDIA GeForce RTX 2080 Ti",
        //         "load": 0.0,
        //         "memory_total": 22528.0,
        //         "memory_used": 8.0,
        //         "memory_utilization": 0.03551136363636364
        //       }
        //     ]
        //   }
        // };
        // print(data);
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
