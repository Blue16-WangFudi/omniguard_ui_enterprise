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
      maxY: 100,
      lines: [
        _buildLine(downloadData, Colors.green.shade400),
        _buildLine(uploadData, Colors.red.shade400),
      ],
      yAxisName: 'MB/s',
      legends: ['下载', '上传'],
    );
  }

  // CPU utilization chart
  static Widget buildCpuChart(List<double> cpuData, String title) {
    return _buildLineChart(
      title: title,
      lines: [_buildLine(cpuData, Colors.blue.shade500)],
      yAxisName: '%',
      maxY: 100,
      legends: ['CPU'],
    );
  }

  // Memory utilization chart
  static Widget buildMemoryChart(List<double> memoryData, String title) {
    return _buildLineChart(
      title: title,
      lines: [_buildLine(memoryData, Colors.purple.shade400)],
      yAxisName: '%',
      maxY: 100,
      legends: ['内存'],
    );
  }

  // GPU memory utilization chart
  static Widget buildGpuMemoryChart(List<double> gpuMemoryData, String title) {
    return _buildLineChart(
      title: title,
      lines: [_buildLine(gpuMemoryData, Colors.deepOrange.shade400)],
      yAxisName: '%',
      maxY: 100,
      legends: ['显存'],
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
    final bgColor = Colors.white;
    final gridColor = Colors.grey.withOpacity(0.15);
    
    return Card(
      elevation: 0, 
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200), 
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [bgColor, bgColor.withOpacity(0.95)],
          ),
        ),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 4,
                  height: 16,
                  decoration: BoxDecoration(
                    color: lines.isNotEmpty ? lines[0].color : Colors.blue,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'HarmonyOS_Sans',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
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
                        color: gridColor,
                        strokeWidth: 1,
                        dashArray: [5, 5], 
                      );
                    },
                    getDrawingVerticalLine: (value) {
                      return FlLine(
                        color: gridColor,
                        strokeWidth: 1,
                        dashArray: [5, 5], 
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
                        style: TextStyle(fontSize: 11, color: Colors.grey[700]),
                      ),
                      axisNameSize: 12,
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 25,
                        interval: maxY != null ? maxY / 4 : null,
                        getTitlesWidget: (value, meta) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: Text(
                              value.toInt().toString(),
                              style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                              textAlign: TextAlign.end,
                            ),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      axisNameSize: 0, 
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 20, 
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
                    border: Border.all(color: gridColor),
                  ),
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      tooltipMargin: 8,
                      tooltipPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      tooltipRoundedRadius: 8,
                      tooltipBorder: BorderSide(color: Colors.transparent),
                      getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                        return touchedBarSpots.map((barSpot) {
                          final index = barSpot.barIndex;
                          final legend = index < legends.length ? legends[index] : '';
                          return LineTooltipItem(
                            '$legend: ${barSpot.y.toStringAsFixed(1)}',
                            TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              backgroundColor: Colors.grey[700],
                            ),
                          );
                        }).toList();
                      },
                    ),
                  ),
                  minX: 0,
                  maxX: maxDataPoints.toDouble() - 1,
                  minY: 0,
                  maxY: maxY,
                  lineBarsData: lines,
                ),
              ),
            ),
            const SizedBox(height: 8), 
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '时间 (秒)',
                  style: TextStyle(fontSize: 10, color: Colors.grey[700]),
                ),
                const SizedBox(width: 20),
                for (int i = 0; i < lines.length; i++) ...[                  
                  if (i > 0) const SizedBox(width: 16),
                  Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: lines[i].color,
                          borderRadius: BorderRadius.circular(2), 
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        i < legends.length ? legends[i] : '',
                        style: TextStyle(
                          fontSize: 11,
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
      isCurved: false, 
      color: color,
      barWidth: 2.5, 
      isStrokeCapRound: false, 
      dotData: FlDotData(
        show: false,
        getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
          radius: 2,
          color: color,
          strokeWidth: 1,
          strokeColor: Colors.white,
        ),
      ),
      belowBarData: BarAreaData(
        show: true,
        gradient: LinearGradient(
          colors: [color.withOpacity(0.2), color.withOpacity(0.05)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
    );
  }
}
