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
      double cpuPercent = cpuCurrent/cpuMax*100;
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
      double downloadMbps = systemInfo['network_bandwidth']['downlink'] / 1024;
      double uploadMbps = systemInfo['network_bandwidth']['uplink'] / 1024;
      
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
    final systemInfo = _serverStatus?['systemInfo'];
    
    if (systemInfo == null || systemInfo['gpu_utilization'] == null || !(systemInfo['gpu_utilization'] is List) || systemInfo['gpu_utilization'].isEmpty) {
      return SizedBox.shrink();
    }
    
    final gpuList = systemInfo['gpu_utilization'] as List;

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

    return 
    Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
      ),
      child: 
    SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          _buildServerInfoCard(),
          const SizedBox(height: 20),
          

            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                SizedBox(width: 10,),
                Row(
                  children: [
                    Text(
                      '资源占用曲线',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              fontFamily: 'HarmonyOS_Sans',
              color: Colors.black87,
            ),
                    ),
                  ],
                ),
              ],
            ),

      Container(
        margin: EdgeInsets.fromLTRB(10, 10, 10, 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题行


          SizedBox(height: 10),
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

          ],
        ),
      ),
     
        
      
          const SizedBox(height: 24),
                      Row(
              children: [
                SizedBox(width: 10),
                Text(
                  'GPU 状态',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              fontFamily: 'HarmonyOS_Sans',
              color: Colors.black87,
            ),

                ),
                Spacer(),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 255, 255, 255),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${gpuList.length} GPU',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[800],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  
                ),
                
                SizedBox(width: 10),
              ],
            ),
          // Other Cards from the previous implementation
          _buildGpuStatsCard(),
          const SizedBox(height: 16),
        ],
      ),
    )
    );
  }

  Widget _buildServerInfoCard() {

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



    final serverId = _serverStatus?['serverId'] ?? 'N/A';
    final serverName = _serverStatus?['serverName'] ?? 'N/A';
    final network = _serverStatus?['network'] ?? 'N/A';
    // final performance = _serverStatus?['performance'] ?? 'N/A';
    
    // 系统信息
    // final systemInfo = _serverStatus?['systemInfo'];
    final osInfo = systemInfo?['system_info'] ?? {};
    final osName = osInfo['name'] ?? 'Unknown';
    final osVersion = osInfo['version'] ?? 'Unknown';
    final uptime = osInfo?['boot_time'] ?? 0;
    // final lastBootTime = systemInfo?['boot_time'] ?? 0;
    
    // 格式化运行时间
    final Duration uptimeDuration = Duration(milliseconds: uptime.toInt());
    final days = uptimeDuration.inDays;
    final hours = uptimeDuration.inHours % 24;
    final minutes = uptimeDuration.inMinutes % 60;
    final formattedUptime = '$days天 $hours小时 $minutes分钟';
    // print(uptime);
    return Container(
      // elevation: 0,
      color: Colors.transparent,
      // shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
      child: Container(
        decoration: BoxDecoration(
          // color: Colors.white,
        ),
        padding: const EdgeInsets.fromLTRB(10, 25, 10, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题行
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      '服务器信息',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              fontFamily: 'HarmonyOS_Sans',
              color: Colors.black87,
            ),
                    ),
                  ],
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.green.shade300),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: 6),
                      Text(
                        '在线',
                        style: TextStyle(
                          color: Colors.green[800], 
                          fontSize: 12, 
                          fontWeight: FontWeight.w500,
                          fontFamily: 'HarmonyOS_Sans',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            // Divider(height: 32, thickness: 1, color: Colors.grey.shade100),
            SizedBox(height: 12),
            
            // 服务器基本信息
            
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  // 服务器基本信息
                  Expanded(
                    flex: 2,

                    
                    child: Container(
                      padding: EdgeInsets.all(16),

                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),                      
                        child: Column(
                          
                    mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          /**

                          */
                          _buildInfoRow('服务器ID', serverId, icon: Icons.tag, iconColor: const Color.fromRGBO(1, 102, 255, 1)),
                          _buildInfoRow('服务器名称', serverName, icon: Icons.computer, iconColor: const Color.fromRGBO(1, 102, 255, 1)),
                          
                          // 系统信息
                          _buildInfoRow('操作系统', '$osName', icon: Icons.settings, iconColor: Colors.deepPurple),
                          _buildInfoRow('系统版本', '$osVersion', icon: Icons.system_security_update, iconColor: Colors.deepPurple),

                          _buildInfoRow('运行时间', formattedUptime, icon: Icons.timer, iconColor: Colors.amber),
                          _buildServerAbilityRow('服务器能力', ['TEXT_FEATURE', 
                              'IMAGE_FEATURE', 
                              'AUDIO_FEATURE', 
                              'VIDEO_FEATURE', 
                              'PRECISE_DETECTION', 
                              'FAST_DETECTION', 
                              'REPORT_GENERATOR'], icon: Icons.functions, iconColor: Colors.teal),
                        ],
                      ),
                    ),
                  ),
                  
          // 间距
          SizedBox(width: 10),
          
          // 评分卡片
          Expanded(
            flex: 1,
            child: Container(
              padding: EdgeInsets.zero,
              child: Card(
                margin: EdgeInsets.zero,
                elevation: 0,
                color: const Color.fromARGB(255, 255, 255, 255),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  // side: BorderSide(color: Colors.grey.shade200),
                ),
                child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 6),
                      // 网络状态评分
                      _buildCompactNetworkItem('网络状态评分', network.toString(), Icons.signal_cellular_alt, const Color.fromRGBO(1, 102, 255, 1)),
                      SizedBox(height: 6),
                      SizedBox(height: 6),
                      
                      // 下载速率
                      _buildCompactNetworkItem(
                        '下载速率',
                        _getDownloadRate(),
                        Icons.arrow_downward_rounded,
                        Colors.green
                      ),
                      SizedBox(height: 6),
                      SizedBox(height: 6),
                      
                      // 上传速率
                      _buildCompactNetworkItem(
                        '上传速率',
                        _getUploadRate(),
                        Icons.arrow_upward_rounded,
                        Colors.red
                      ),
                      SizedBox(height: 6),
                      SizedBox(height: 6),
                      
                      // 总下载
                      _buildCompactNetworkItem(
                        '总下载',
                        _getTotalDownload(),
                        Icons.cloud_download_outlined,
                        Colors.teal
                      ),
                      SizedBox(height: 6),
                      SizedBox(height: 6),
                      
                      // 总上传
                      _buildCompactNetworkItem(
                        '总上传',
                        _getTotalUpload(),
                        Icons.cloud_upload_outlined,
                        Colors.deepOrange
                      ),
                      SizedBox(height: 6),
                      SizedBox(height: 6),
                      _buildCompactNetworkItem(
                        '活跃连接',
                        _getActiveConnections(),
                        Icons.lan_outlined,
                        Colors.blue,
                      ),
                      SizedBox(height: 6),
                    ],
                  ),
                ),
              ),
            ),
          ),
          ]
      
        ),
      ),
        SizedBox(height: 12,),
         Container(
            
              padding: EdgeInsets.zero,
              child: Card(
                margin: EdgeInsets.zero,
                elevation: 0,
                color: const Color.fromARGB(255, 255, 255, 255),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  // side: BorderSide(color: Colors.grey.shade200),
                ),
                child: Container(

        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  _buildProgressCard(
                          'CPU 使用率',
                          cpuPercent.toStringAsFixed(1) + '%',
                          cpuPercent / 100,
                          Colors.blue,
                          '${cpuUtilization['current']} / ${cpuUtilization['max']}',
                        ),
                      SizedBox(height: 12),
                  _buildProgressCard(
                          '内存使用率',
                          memoryPercent.toStringAsFixed(1) + '%',
                          memoryPercent / 100,
                          Colors.purple,
                          _formatBytes(memoryUtilization['total'] ?? 0),
                        ),
                      SizedBox(height: 12),
                  _buildProgressCard(
                          '磁盘使用率',
                          diskPercent.toStringAsFixed(1) + '%',
                          diskPercent / 100,
                          Colors.amber,
                          _formatBytes(diskUtilization['total'] ?? 0),
                        ),

                    ],
                  ),
                ),
              ),
            ),
          

    ]
    )
      )
    );
  }
  
  Widget _buildInfoRow(String label, String value, {IconData? icon, Color? iconColor}) {
    return Padding(
      padding: const EdgeInsets.only(top:6,bottom: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null)
                // Icon(icon, size: 16, color: iconColor ?? Colors.grey[600]),
                Container(
                  padding: EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: iconColor!.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(icon, size: 16, color: iconColor),
                ),

              if (icon != null)
                SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'HarmonyOS_Sans',
                    ),
              ),
            ],
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 50.0),
              child: Text(
                value,
                textAlign: TextAlign.right,
                softWrap: true,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w400,
                  fontFamily: 'HarmonyOS_Sans',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildServerAbilityRow(String label, List<String> value, {IconData? icon, Color? iconColor}) {
    return Padding(
      padding: const EdgeInsets.only(top:6,bottom: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null)
                Container(
                  padding: EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: iconColor!.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(icon, size: 16, color: iconColor),
                ),

              if (icon != null)
                SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'HarmonyOS_Sans',
                    ),
              ),
            ],
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 50.0),
              child: Wrap(
                spacing: 4.0, // Horizontal spacing between items
                runSpacing: 4.0, // Vertical spacing between lines
                alignment: WrapAlignment.end,
                children: [
                  for (int i = 0; i < value.length; i++)
                    Container(
                      // margin: EdgeInsets.only(bottom: 4.0),
                      padding: EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: Text(
                        value[i],
                        style: TextStyle(
                          fontSize: 12,
                          fontFamily: 'HarmonyOS_Sans',
                        ),
                      ),
                    )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreCard(String title, String value, Color color, IconData icon) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[700],
                  fontFamily: 'HarmonyOS_Sans',
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
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

  Widget _buildProgressCard(String title, String value, double progress, Color color, String subtitle) {
    return Container(
        decoration: BoxDecoration(
          // color: Color.fromRGBO(251, 251, 251, 1),
        ),
        padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
        child: Row(
          children: [
            // Title section (icon + text)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                        Container(
          padding: EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
                  title.contains('CPU') ? Icons.memory_outlined : 
                  title.contains('内存') ? Icons.storage_outlined : 
                  Icons.disc_full_outlined,
                  size: 18,
                  color: color,
                ),
        ),
                SizedBox(width: 8),
                SizedBox(
                  width: 85,
                  child:                 
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'HarmonyOS_Sans',
                    ),
                  ),
                )
              ],
            ),
            SizedBox(width: 16),
            
            // Progress bar section
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Stack(
                    children: [
                      // Background
                      Container(
                        height: 6,
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(255, 223, 223, 223),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 900),
                        curve: Curves.easeInOut,
                        height: 6,
                        width: constraints.maxWidth * progress,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(3),
                          gradient: LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [
                              color,
                              color.withOpacity(0.8),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: color.withOpacity(0.2),
                              blurRadius: 2,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            SizedBox(width: 10),
            
            SizedBox(width: 35,
              child:               Align(
                alignment: Alignment.centerRight,
                child: Text(
                value,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontFamily: 'HarmonyOS_Sans',
                ),
              ),
              )
            ),
            SizedBox(width: 5),
            
            // Usage information
            SizedBox(width: 70,
              child: 
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontFamily: 'HarmonyOS_Sans',
                  ),
                )
            ),
            )
          ],
        ),
      
    );
  }

  Widget _buildInfoCardSmall(String title, String value1, String value2, Color color) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
      child: Container(
        decoration: BoxDecoration(
          color: Color.fromRGBO(251, 251, 251, 1),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(Icons.sync_alt_outlined, size: 14, color: color),
                ),
                SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'HarmonyOS_Sans',
                  ),
                ),
              ],
            ),
            Divider(height: 24, color: Colors.grey.shade100),
            
            // 网络数据卡片
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Color.fromRGBO(251, 251, 251, 1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.blue.shade100.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildNetworkStatItem(
                        icon: Icons.arrow_downward_rounded,
                        label: '下载速率',
                        value: '${value1}',
                        iconColor: Colors.green,
                      ),
                      _buildNetworkStatItem(
                        icon: Icons.arrow_upward_rounded,
                        label: '上传速率',
                        value: '${value2}',
                        iconColor: Colors.red,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGpuStatsCard() {
    final systemInfo = _serverStatus?['systemInfo'];
    
    if (systemInfo == null || systemInfo['gpu_utilization'] == null || !(systemInfo['gpu_utilization'] is List) || systemInfo['gpu_utilization'].isEmpty) {
      return SizedBox.shrink();
    }
    
    final gpuList = systemInfo['gpu_utilization'] as List;
    
    return Container(        
      margin: EdgeInsets.fromLTRB(10, 10, 10, 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),

        padding: const EdgeInsets.fromLTRB(20, 10, 20, 5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // Divider(height: 32, thickness: 1, color: Colors.grey.shade100),
            SizedBox(height: 10),
            // GPU Cards in Rows of Two
            _buildGpuCardsGrid(gpuList),
          ],
        ),
      
    );
  }

  // Helper method to build GPU cards in a grid layout (2 per row)
  Widget _buildGpuCardsGrid(List gpuList) {
    return Column(
      children: [
        for (int i = 0; i < gpuList.length; i += 2)
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // First card in the row
                Expanded(
                  child: _buildGpuCard(gpuList[i]),
                ),
                // Space between cards
                const SizedBox(width: 16),
                // Second card in the row (if exists)
                Expanded(
                  child: (i + 1 < gpuList.length)
                      ? _buildGpuCard(gpuList[i + 1])
                      : const SizedBox(), // Empty placeholder if odd number of GPUs
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildGpuCard(Map<String, dynamic> gpu) {
    final name = gpu['name'] ?? 'Unknown GPU';
    final util = gpu['load'] ?? 0.0; // TODO 修改一下
    final id = gpu['id'] ?? 0;
    // final memory = gpu['memory'] ?? {};
    final usedMemory = gpu['memory_used'] ?? 0;
    final totalMemory = gpu['memory_total'] ?? 1;
    final memoryUtil = totalMemory > 0 ? usedMemory / totalMemory : 0.0;

    return Container(
      // No bottom margin needed as it's handled by the row padding
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color.fromRGBO(251, 251, 251, 1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '#${id} $name',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'HarmonyOS_Sans',
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: util >= 70 ? Colors.red.shade50 : Colors.green.shade50,
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(
                    color: util >= 70 ? Colors.red.shade200 : Colors.green.shade200,
                    width: 1,
                  ),
                ),
                child: Text(
                  util >= 70 ? '高占用' :  util >= 30 ? '中占用' : '低占用',
                  style: TextStyle(
                    color: util >= 70 ? Colors.red.shade700 : Colors.green.shade700,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'HarmonyOS_Sans',
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          
          // GPU Utilization
          _buildProgressBar('GPU 负载', util / 100, Colors.purple),
          SizedBox(height: 12),
          
          // Memory Utilization
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '显存使用率',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[700],
                  fontFamily: 'HarmonyOS_Sans',
                ),
              ),
              Text(
                '${_formatBytes(usedMemory)} / ${_formatBytes(totalMemory)}',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                  fontFamily: 'HarmonyOS_Sans',
                ),
              ),
            ],
          ),
          SizedBox(height: 6),
          _buildProgressBar('', memoryUtil, Colors.blue),
        ],
      ),
    );
  }

  Widget _buildProgressBar(String label, double value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty) 
          Padding(
            padding: const EdgeInsets.only(bottom: 6.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[700],
                    fontFamily: 'HarmonyOS_Sans',
                  ),
                ),
                Text(
                  '${(value * 100).toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 13,
                    color: value >= 0.7 ? Colors.red[700] : Colors.grey[600],
                    fontWeight: value >= 0.7 ? FontWeight.w600 : FontWeight.normal,
                    fontFamily: 'HarmonyOS_Sans',
                  ),
                ),
              ],
            ),
          ),
        LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              children: [
                // Background
                Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 223, 223, 223),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeInOut,
                  height: 8,
                  width: constraints.maxWidth * value,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        color,
                        color.withOpacity(0.8),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.2),
                        blurRadius: 2,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }


  Widget _buildNetworkStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color iconColor,
  }) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 16, color: iconColor),
        ),
        SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontFamily: 'HarmonyOS_Sans',
              ),
            ),
            SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey[800],
                fontFamily: 'HarmonyOS_Sans',
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _getDownloadRate() {
    final systemInfo = _serverStatus?['systemInfo'];
    final networkStats = systemInfo?['network_bandwidth'] ?? {};
    final downloadRate = networkStats['downlink'] ?? 0;
    final downloadMbps = downloadRate / (1024 * 1024);
    return '${downloadMbps.toStringAsFixed(2)} MB/s';
  }

  String _getUploadRate() {
    final systemInfo = _serverStatus?['systemInfo'];
    final networkStats = systemInfo?['network_bandwidth'] ?? {};
    final uploadRate = networkStats['uplink'] ?? 0;
    final uploadMbps = uploadRate / (1024 * 1024);
    return '${uploadMbps.toStringAsFixed(2)} MB/s';
  }

  String _getTotalDownload() {
    final systemInfo = _serverStatus?['systemInfo'];
    final networkStats = systemInfo?['network_io'] ?? {};
    final totalDownload = networkStats['received'] ?? 0;
    return _formatBytes(totalDownload);
  }

  String _getTotalUpload() {
    final systemInfo = _serverStatus?['systemInfo'];
    final networkStats = systemInfo?['network_io'] ?? {};
    final totalUpload = networkStats['send'] ?? 0;
    return _formatBytes(totalUpload);
  }

  String _getActiveConnections() {
    final systemInfo = _serverStatus?['systemInfo'];
    final networkStats = systemInfo?['network_stats'] ?? {};
    final activeConnections = networkStats['active_connections'] ?? 12;
    return '$activeConnections';
  }

  Widget _buildCompactNetworkItem(String title, String value, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        SizedBox(width: 8),             
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'HarmonyOS_Sans',
                    ),
                  ),
        Spacer(),
        Text(
                value,
                textAlign: TextAlign.right,
                softWrap: true,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w400,
                  fontFamily: 'HarmonyOS_Sans',
                ),
              ),
      ],
    );
  }

  Widget _buildCompactNetworkRow(String label1, String value1, IconData icon1, Color color1, String label2, String value2, IconData icon2, Color color2) {
    return Row(
      children: [
        Expanded(
          child: _buildCompactNetworkItem(label1, value1, icon1, color1),
        ),
        SizedBox(width: 16),
        Expanded(
          child: _buildCompactNetworkItem(label2, value2, icon2, color2),
        ),
      ],
    );
  }

  String _formatBytes(dynamic bytes) {
    if (bytes == null) return '0 B';
    
    double numBytes = bytes is int ? bytes.toDouble() : double.tryParse(bytes.toString()) ?? 0.0;
    
    const List<String> units = ['B', 'KB', 'MB', 'GB', 'TB', 'PB', 'EB', 'ZB', 'YB'];
    int unitIndex = 0;
    
    while (numBytes >= 1024 && unitIndex < units.length - 1) {
      numBytes /= 1024;
      unitIndex++;
    }
    
    return '${numBytes.toStringAsFixed(unitIndex > 0 ? 2 : 0)} ${units[unitIndex]}';
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'N/A';
    
    try {
      int timeMs = (timestamp is int) ? timestamp * 1000 : (double.tryParse(timestamp.toString()) ?? 0).toInt() * 1000;
      final DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(timeMs);
      return DateFormat('yyyy-MM-dd HH:mm:ss').format(dateTime);
    } catch (e) {
      return 'Invalid time';
    }
  }
}
