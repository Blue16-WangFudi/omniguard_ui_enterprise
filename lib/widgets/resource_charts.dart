import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class ResourceCharts {
  // Maximum number of data points to keep in the chart
  static const int maxDataPoints = 60; // 1 minute of data at 1 second intervals

  // Network chart - combines bandwidth and I/O in one chart
  static Widget buildNetworkChart(
    List<double> downloadData,
    List<double> uploadData,
    String title,
  ) {
    return _buildLineChart(
      title: title,
      lines: [
        _buildLine(downloadData, Colors.green),
        _buildLine(uploadData, Colors.red),
      ],
      yAxisName: 'MB/s',
      legends: ['下载', '上传'],
    );
  }

  // CPU utilization chart
  static Widget buildCpuChart(List<double> cpuData, String title) {
    return _buildLineChart(
      title: title,
      lines: [_buildLine(cpuData, Colors.blue)],
      yAxisName: '%',
      maxY: 100,
      legends: ['CPU'],
    );
  }

  // Memory utilization chart
  static Widget buildMemoryChart(List<double> memoryData, String title) {
    return _buildLineChart(
      title: title,
      lines: [_buildLine(memoryData, Colors.purple)],
      yAxisName: '%',
      maxY: 100,
      legends: ['内存'],
    );
  }

  // GPU memory utilization chart
  static Widget buildGpuMemoryChart(List<double> gpuMemoryData, String title) {
    return _buildLineChart(
      title: title,
      lines: [_buildLine(gpuMemoryData, Colors.deepOrange)],
      yAxisName: '%',
      maxY: 100,
      legends: ['GPU内存'],
    );
  }

  // Helper function to build a single line chart
  static Widget _buildLineChart({
    required String title,
    required List<LineChartBarData> lines,
    required String yAxisName,
    required List<String> legends,
    double? maxY,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Chart title
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                fontFamily: 'HarmonyOS_Sans',
              ),
            ),
            const SizedBox(height: 24),
            // Chart
            SizedBox(
              height: 180,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: true,
                    horizontalInterval: maxY != null ? maxY / 5 : null,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: Colors.grey.withOpacity(0.2),
                        strokeWidth: 1,
                      );
                    },
                    getDrawingVerticalLine: (value) {
                      return FlLine(
                        color: Colors.grey.withOpacity(0.2),
                        strokeWidth: 1,
                      );
                    },
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    leftTitles: AxisTitles(
                      axisNameWidget: Text(
                        yAxisName,
                        style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                      ),
                      axisNameSize: 24,
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toInt().toString(),
                            style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      axisNameWidget: Text(
                        '时间 (秒)',
                        style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                      ),
                      axisNameSize: 24,
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() % 10 == 0) {
                            return Text(
                              value.toInt().toString(),
                              style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                            );
                          }
                          return const SizedBox();
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(color: Colors.grey.withOpacity(0.2)),
                  ),
                  minX: 0,
                  maxX: maxDataPoints.toDouble() - 1,
                  minY: 0,
                  maxY: maxY,
                  lineBarsData: lines,
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Legend
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (int i = 0; i < lines.length; i++) ...[                  
                  if (i > 0) const SizedBox(width: 24),
                  Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: lines[i].color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        i < legends.length ? legends[i] : '',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[700],
                          fontFamily: 'HarmonyOS_Sans',
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Helper function to build a line for the chart
  static LineChartBarData _buildLine(List<double> data, Color color) {
    final spots = <FlSpot>[];
    
    for (int i = 0; i < data.length; i++) {
      spots.add(FlSpot(i.toDouble(), data[i]));
    }

    return LineChartBarData(
      spots: spots,
      isCurved: true,
      color: color,
      barWidth: 2,
      isStrokeCapRound: true,
      dotData: const FlDotData(show: false),
      belowBarData: BarAreaData(
        show: true,
        color: color.withOpacity(0.1),
      ),
    );
  }
}
