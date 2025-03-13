import 'package:flutter/material.dart';
import 'package:omni_guard/services/server_status_service.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:omni_guard/widgets/resource_charts.dart';
import 'package:omni_guard/resource_monitoring_tab.dart';
import 'package:omni_guard/widgets/time_range_selector.dart';
import 'dart:async';


class ResourceMonitoringTab extends StatefulWidget {
  @override
  State<ResourceMonitoringTab> createState() => _ResourceMonitoringTabState();
}

class _ResourceMonitoringTabState extends State<ResourceMonitoringTab> {
  final ServerStatusService _statusService = ServerStatusService();
  StreamSubscription? _statusSubscription;
  Map<String, dynamic>? _serverStatus;
  String? _errorMessage;
  
  // Lists to store historical data for charts
  final List<double> _cpuData = [];
  final List<double> _memoryData = [];
  final List<double> _diskData = [];
  final List<double> _downloadData = [];
  final List<double> _uploadData = [];
  final List<double> _gpuMemoryData = [];
  // 时间范围选择
final List<TimeRange> _availableTimeRanges = [
  const TimeRange("1分钟", 60),
  const TimeRange("5分钟", 300),
  const TimeRange("15分钟", 900),
  const TimeRange("30分钟", 1800),
];

// 默认为1分钟时间范围
TimeRange _selectedTimeRange = const TimeRange("1分钟", 60);
void _handleTimeRangeChanged(TimeRange range) {
  setState(() {
    _selectedTimeRange = range;
    // 根据需要限制数据点数量
    int maxPoints = range.seconds;
    
    if (_cpuData.length > maxPoints) {
      _cpuData.removeRange(0, _cpuData.length - maxPoints);
    }
    if (_memoryData.length > maxPoints) {
      _memoryData.removeRange(0, _memoryData.length - maxPoints);
    }
    if (_downloadData.length > maxPoints) {
      _downloadData.removeRange(0, _downloadData.length - maxPoints);
    }
    if (_uploadData.length > maxPoints) {
      _uploadData.removeRange(0, _uploadData.length - maxPoints);
    }
    if (_gpuMemoryData.length > maxPoints) {
      _gpuMemoryData.removeRange(0, _gpuMemoryData.length - maxPoints);
    }
  });
}
  @override
  void initState() {
    super.initState();
    _statusService.startPolling();
    _statusSubscription = _statusService.statusStream.listen(
      (data) {
        if (mounted) {
          setState(() {
            _serverStatus = data;
            _errorMessage = null;
            
            // Update historical data
            _updateChartData();
          });
        }
      },
      onError: (error) {
        if (mounted) {
          setState(() {
            _errorMessage = 'Failed to fetch server status: $error';
          });
        }
      },
    );
  }
  
  @override
  void dispose() {
    _statusSubscription?.cancel();
    _statusService.stopPolling();
    super.dispose();
  }
  
  void _updateChartData() {
    
     if (_serverStatus != null && _serverStatus!.containsKey('systemInfo')) {
        final systemInfo = _serverStatus!['systemInfo'];



    // Add CPU data
    if (systemInfo['cpu_utilization'] != null) {
      double cpuCurrent = systemInfo['cpu_utilization']['current'].toDouble();
      double cpuMax = systemInfo['cpu_utilization']['max'].toDouble();
      double cpuPercent = cpuCurrent/cpuMax;
      _cpuData.add(cpuPercent);
      if (_cpuData.length > ResourceCharts.maxDataPoints) {
        _cpuData.removeAt(0);
      }
    }
    
    // Add memory data
    if (systemInfo['memory_utilization'] != null) {
      double memoryPercent = systemInfo['memory_utilization']['percent'];
      _memoryData.add(memoryPercent);
      if (_memoryData.length > ResourceCharts.maxDataPoints) {
        _memoryData.removeAt(0);
      }
    }
    
    // Add disk data
    if (systemInfo['disk_utilization'] != null) {
      double diskPercent = systemInfo['disk_utilization']['percent'];
      _diskData.add(diskPercent);
      if (_diskData.length > ResourceCharts.maxDataPoints) {
        _diskData.removeAt(0);
      }
    }
    
    // Add network data (convert to MB/s for better display)
    if (systemInfo['network_bandwidth'] != null) {
      double downloadMbps = systemInfo['network_bandwidth']['downlink'] / 1024 / 1024;
      double uploadMbps = systemInfo['network_bandwidth']['uplink'] / 1024 / 1024;
      
      _downloadData.add(downloadMbps);
      _uploadData.add(uploadMbps);
      
      if (_downloadData.length > ResourceCharts.maxDataPoints) {
        _downloadData.removeAt(0);
      }
      if (_uploadData.length > ResourceCharts.maxDataPoints) {
        _uploadData.removeAt(0);
      }
    }
    
    // Add average GPU memory utilization
    if (systemInfo['gpu_utilization'] != null && systemInfo['gpu_utilization'] is List && systemInfo['gpu_utilization'].isNotEmpty) {
      double totalMemUtil = 0;
      int gpuCount = 0;
      
      for (var gpu in systemInfo['gpu_utilization']) {
        if (gpu['memory_utilization'] != null) {
          totalMemUtil += (gpu['memory_utilization'] * 100); // Convert to percentage
          gpuCount++;
        }
      }
      
      if (gpuCount > 0) {
        double avgGpuMemUtil = totalMemUtil / gpuCount;
        _gpuMemoryData.add(avgGpuMemUtil);
        if (_gpuMemoryData.length > ResourceCharts.maxDataPoints) {
          _gpuMemoryData.removeAt(0);
        }
      }
    }
     }
  }

  @override
  Widget build(BuildContext context) {
    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
          ],
        ),
      );
    }

    if (_serverStatus == null) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Server Basic Information Card
Row(
  mainAxisAlignment: MainAxisAlignment.start,
  children: [
              const Text(
                '时间范围: ',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'HarmonyOS_Sans',
                ),
              ),
              const SizedBox(width: 8),
              TimeRangeSelector(
                selectedRange: _selectedTimeRange,
                onRangeSelected: _handleTimeRangeChanged,
                availableRanges: _availableTimeRanges,
              ),
            ],
          ),

          _buildServerInfoCard(),
          const SizedBox(height: 24),
          
          // Charts - two per row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ResourceCharts.buildNetworkChart(
                  _downloadData, 
                  _uploadData, 
                  '网络带宽/IO',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ResourceCharts.buildCpuChart(
                  _cpuData,
                  'CPU 使用率',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ResourceCharts.buildMemoryChart(
                  _memoryData,
                  '内存占用',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ResourceCharts.buildGpuMemoryChart(
                  _gpuMemoryData,
                  'GPU 显存占用',
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Other Cards from the previous implementation
          _buildResourceUsageCard(),
          const SizedBox(height: 16),
          _buildGpuStatsCard(),
          const SizedBox(height: 16),
          _buildNetworkStatsCard(),
          const SizedBox(height: 16),
          _buildSystemInfoCard(),
        ],
      ),
    );
  }

  Widget _buildServerInfoCard() {
    final serverId = _serverStatus?['serverId'] ?? 'N/A';
    final serverName = _serverStatus?['serverName'] ?? 'N/A';
    final network = _serverStatus?['network'] ?? 'N/A';
    final performance = _serverStatus?['performance'] ?? 'N/A';
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '服务器信息',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'HarmonyOS_Sans',
                  ),
                ),
                Chip(
                  label: Text('在线'),
                  backgroundColor: Colors.green[100],
                  labelStyle: TextStyle(color: Colors.green[800]),
                ),
              ],
            ),
            Divider(),
            SizedBox(height: 8),
            _buildInfoRow('服务器ID', serverId),
            _buildInfoRow('服务器名称', serverName),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildScoreCard(
                    '网络状态评分',
                    network.toString(),
                    const Color.fromRGBO(1, 102, 255, 1),
                    Icons.network_check,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: _buildScoreCard(
                    '性能 (FLOPS)',
                    '$performance',
                    Colors.orange,
                    Icons.speed,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontFamily: 'HarmonyOS_Sans',
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              fontFamily: 'HarmonyOS_Sans',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreCard(String title, String value, Color color, IconData icon) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                  fontFamily: 'HarmonyOS_Sans',
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
              fontFamily: 'HarmonyOS_Sans',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResourceUsageCard() {
    final systemInfo = _serverStatus?['systemInfo'];
    
    if (systemInfo == null) {
      return Center(child: Text('No system information available'));
    }
    
    final cpuUtilization = systemInfo['cpu_utilization'] ?? {};
    final memoryUtilization = systemInfo['memory_utilization'] ?? {};
    final diskUtilization = systemInfo['disk_utilization'] ?? {};
    final diskIo = systemInfo['disk_io'] ?? {};
    
    final cpuPercent = (cpuUtilization['current'] ?? 0) / (cpuUtilization['max'] ?? 100) * 100;
    final memoryPercent = memoryUtilization['percent'] ?? 0.0;
    final diskPercent = diskUtilization['percent'] ?? 0.0;
    
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildProgressCard(
                'CPU 使用率',
                cpuPercent.toStringAsFixed(1) + '%',
                cpuPercent / 100,
                Colors.blue,
                '${cpuUtilization['current']} / ${cpuUtilization['max']}',
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: _buildProgressCard(
                '内存使用率',
                memoryPercent.toStringAsFixed(1) + '%',
                memoryPercent / 100,
                Colors.purple,
                _formatBytes(memoryUtilization['total'] ?? 0),
              ),
            ),
          ],
        ),
        SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildProgressCard(
                '磁盘使用率',
                diskPercent.toStringAsFixed(1) + '%',
                diskPercent / 100,
                Colors.amber,
                _formatBytes(diskUtilization['total'] ?? 0),
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: _buildInfoCardSmall(
                '磁盘 I/O',
                '↓ ${_formatBytes(diskIo['read'] ?? 0)}',
                '↑ ${_formatBytes(diskIo['write'] ?? 0)}',
                Colors.teal,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProgressCard(String title, String value, double progress, Color color, String subtitle) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'HarmonyOS_Sans',
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                    fontFamily: 'HarmonyOS_Sans',
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: color.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
            SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontFamily: 'HarmonyOS_Sans',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCardSmall(String title, String value1, String value2, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                fontFamily: 'HarmonyOS_Sans',
              ),
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.arrow_downward, size: 16, color: Colors.green),
                SizedBox(width: 4),
                Text(
                  value1,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'HarmonyOS_Sans',
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.arrow_upward, size: 16, color: Colors.red),
                SizedBox(width: 4),
                Text(
                  value2,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'HarmonyOS_Sans',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGpuStatsCard() {
    final systemInfo = _serverStatus?['systemInfo'];
    
    if (systemInfo == null || systemInfo['gpu_utilization'] == null) {
      return Center(child: Text('No GPU information available'));
    }
    
    final gpuList = systemInfo['gpu_utilization'] as List<dynamic>;
    
    return Column(
      children: [
        for (int i = 0; i < gpuList.length; i += 2)
          Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildGpuCard(gpuList[i]),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: i + 1 < gpuList.length
                        ? _buildGpuCard(gpuList[i + 1])
                        : Container(),
                  ),
                ],
              ),
              SizedBox(height: 16),
            ],
          ),
      ],
    );
  }

  Widget _buildGpuCard(Map<String, dynamic> gpuData) {
    final id = gpuData['id'];
    final name = gpuData['name'] ?? 'Unknown GPU';
    final load = gpuData['load'] ?? 0.0;
    final memoryUsed = gpuData['memory_used'] ?? 0.0;
    final memoryTotal = gpuData['memory_total'] ?? 1.0;
    final memoryPercent = gpuData['memory_utilization'] != null
        ? (gpuData['memory_utilization'] * 100)
        : (memoryUsed / memoryTotal * 100);
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.memory, color: Colors.indigo),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'GPU $id: ${name.split(' ').last}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'HarmonyOS_Sans',
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '负载',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontFamily: 'HarmonyOS_Sans',
                  ),
                ),
                Text(
                  '${load.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'HarmonyOS_Sans',
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            LinearProgressIndicator(
              value: load / 100,
              backgroundColor: Colors.indigo.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation<Color>(Colors.indigo),
              minHeight: 6,
              borderRadius: BorderRadius.circular(3),
            ),
            SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '内存',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontFamily: 'HarmonyOS_Sans',
                  ),
                ),
                Text(
                  '${memoryPercent.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'HarmonyOS_Sans',
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            LinearProgressIndicator(
              value: memoryPercent / 100,
              backgroundColor: Colors.deepPurple.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurple),
              minHeight: 6,
              borderRadius: BorderRadius.circular(3),
            ),
            SizedBox(height: 8),
            Text(
              '${_formatBytes(memoryUsed.toDouble() * 1024 * 1024)} / ${_formatBytes(memoryTotal.toDouble() * 1024 * 1024)}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontFamily: 'HarmonyOS_Sans',
              ),
              textAlign: TextAlign.right,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNetworkStatsCard() {
    final systemInfo = _serverStatus?['systemInfo'];
    
    if (systemInfo == null) {
      return Center(child: Text('No network information available'));
    }
    
    final networkBandwidth = systemInfo['network_bandwidth'] ?? {};
    final networkIo = systemInfo['network_io'] ?? {};
    
    return Row(
      children: [
        Expanded(
          child: _buildInfoCardSmall(
            '网络带宽',
            '↓ ${networkBandwidth['downlink'] ?? 0} MB/s',
            '↑ ${networkBandwidth['uplink'] ?? 0} MB/s',
            Colors.green,
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: _buildInfoCardSmall(
            '网络 I/O',
            '↓ ${_formatBytes(networkIo['received'] ?? 0)}',
            '↑ ${_formatBytes(networkIo['send'] ?? 0)}',
            Colors.cyan,
          ),
        ),
      ],
    );
  }

  Widget _buildSystemInfoCard() {
    final systemInfo = _serverStatus?['systemInfo'];
    
    if (systemInfo == null || systemInfo['system_info'] == null) {
      return Center(child: Text('No system information available'));
    }
    
    final sysInfo = systemInfo['system_info'];
    final currentTime = systemInfo['current_time'];
    final publicIp = systemInfo['public_ip'];
    
    String formattedTime = '时间';
    if (currentTime != null) {
      final year = currentTime['year'];
      final month = currentTime['month'];
      final day = currentTime['day'];
      final hour = currentTime['hour'];
      final minute = currentTime['minute'];
      final second = currentTime['second'];
      
      formattedTime = '$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')} '
          '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}:${second.toString().padLeft(2, '0')}';
    }
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '服务器详细信息',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'HarmonyOS_Sans',
              ),
            ),
            Divider(),
            SizedBox(height: 8),
            _buildInfoRow('系统类型', sysInfo['system'] ?? 'Unknown'),
            _buildInfoRow('系统名称', sysInfo['name'] ?? 'Unknown'),
            _buildInfoRow('系统版本', sysInfo['release'] ?? 'Unknown'),
            _buildInfoRow('系统版本号', sysInfo['version'] ?? 'Unknown'),
            _buildInfoRow('机器类型', sysInfo['machine'] ?? 'Unknown'),
            _buildInfoRow('处理器', sysInfo['processor'] ?? 'Unknown'),
            _buildInfoRow('公网 IP', publicIp ?? 'Unknown'),
            _buildInfoRow('系统时间', formattedTime),
            _buildInfoRow('启动时间', _formatTimestamp(sysInfo['boot_time'] ?? 0)),
          ],
        ),
      ),
    );
  }

  String _formatBytes(dynamic bytes) {
    if (bytes == null) return '0 B';
    
    bytes = bytes.toDouble();
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    var i = 0;
    while (bytes >= 1024 && i < suffixes.length - 1) {
      bytes /= 1024;
      i++;
    }
    return '${bytes.toStringAsFixed(2)} ${suffixes[i]}';
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'Unknown';
    
    try {
      final date = DateTime.fromMillisecondsSinceEpoch((timestamp * 1000).toInt());
      return DateFormat('yyyy-MM-dd HH:mm:ss').format(date);
    } catch (e) {
      return 'Invalid timestamp';
    }
  }
  }
