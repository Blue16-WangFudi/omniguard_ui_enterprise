// 数据分析选项卡
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart';

class DataAnalysisTab extends StatefulWidget {
  @override
  _DataAnalysisTabState createState() => _DataAnalysisTabState();
}

class _DataAnalysisTabState extends State<DataAnalysisTab> {
  bool _isLoading = true;
  String _errorMessage = '';
  
  // 风险数据和AIGC数据
  List<CategoryData> _riskData = [];
  List<CategoryData> _aiData = [];
  
  @override
  void initState() {
    super.initState();
    _fetchData();
  }
  
  // 获取数据
  Future<void> _fetchData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });
      
      // 并行发送两个请求
      final results = await Future.wait([
        _fetchCategoryData('RISK'),
        _fetchCategoryData('AI'),
      ]);
      
      setState(() {
        _riskData = results[0];
        // print(_riskData);
        _aiData = results[1];
        // print(_aiData);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = '数据加载失败: ${e.toString()}';
        _isLoading = false;
      });
    }
  }
  
  // 获取分类数据
  Future<List<CategoryData>> _fetchCategoryData(String detectionType) async {
    final url = Uri.parse('http://47.119.178.225:8090/api/v4/detector/result/category');
    
    final response = await http.post(
      url,
      headers: {
    'Content-Type': 'application/json; charset=utf-8',
    'Accept-Charset': 'utf-8'
  },
  encoding: utf8,
      body: jsonEncode({
        'token': '0c97a6b8-9142-486c-a304-83a3e745614b',
        'data': {
          'detectionType': detectionType
        }
      }),
    );
    if (response.statusCode == 200) {
      final jsonData = jsonDecode(utf8.decode(response.bodyBytes));
      
      
      if (jsonData['code'] == 'SUCCESS') {
        final List<dynamic> categories = jsonData['data'];
        
        // 计算总ID数量
        int totalIds = 0;
        for (var category in categories) {
          totalIds += (category['ids'] as List).length;
        }
        
        // 构建分类数据列表
        return categories.map((category) {
          final String categoryName = category['category'] ?? "Unknown";
          final List<dynamic> ids = category['ids'] as List;
          final double percentage = totalIds > 0 ? ids.length / totalIds * 100 : 0;
          
          return CategoryData(
            detectionType: category['detectionType'],
            category: categoryName.isEmpty ? '未分类' : categoryName,
            idsCount: ids.length,
            percentage: percentage,
            color: _getCategoryColor(categories.indexOf(category)),
          );
        }).toList();
      } else {
        throw Exception('API错误: ${jsonData['msg']}');
      }
    } else {
      throw Exception('请求失败，状态码: ${response.statusCode}');
    }
  }
  
  // 获取分类颜色
  Color _getCategoryColor(int index) {
    final colors = [
      Color(0xFF4285F4), // Google Blue
      Color(0xFFEA4335), // Google Red
      Color(0xFFFBBC05), // Google Yellow
      Color(0xFF34A853), // Google Green
      Color(0xFF5E35B1), // Deep Purple
      Color(0xFF00ACC1), // Cyan
      Color(0xFFFF7043), // Deep Orange
      Color(0xFF9E9E9E), // Grey
      Color(0xFF3949AB), // Indigo
      Color(0xFFEC407A), // Pink
      Color(0xFF7CB342), // Light Green
      Color(0xFFFFCA28), // Amber
    ];
    
    return colors[index % colors.length];
  }
  
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }
    
    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red),
            SizedBox(height: 16),
            Text(
              _errorMessage,
              style: TextStyle(
                fontSize: 16,
                color: Colors.red,
                fontFamily: 'HarmonyOS_Sans',
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: _fetchData,
              child: Text('重试'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF1A66FF),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }
    
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '数据分析',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              fontFamily: 'HarmonyOS_Sans',
            ),
          ),
          SizedBox(height: 32),
          Expanded(
            child: Row(
              children: [
                // 风险数据占比
                Expanded(
                  child: _buildChartSection(
                    '风险数据占比',
                    _riskData,
                    'RISK',
                  ),
                ),
                SizedBox(width: 32),
                // AIGC数据占比
                Expanded(
                  child: _buildChartSection(
                    'AIGC检测占比',
                    _aiData,
                    'AI',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  // 构建图表区域
  Widget _buildChartSection(String title, List<CategoryData> data, String type) {
    if (data.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bar_chart, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              '暂无${type == 'RISK' ? '风险' : 'AIGC'}数据',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
                fontFamily: 'HarmonyOS_Sans',
              ),
            ),
          ],
        ),
      );
    }
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'HarmonyOS_Sans',
              ),
            ),
            SizedBox(height: 16),
            Expanded(
              child: Row(
                children: [
                  // 圆环图
                  Expanded(
                    flex: 3,
                    child: _buildPieChart(data),
                  ),
                  // 图例
                  Expanded(
                    flex: 2,
                    child: _buildLegend(data),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // 构建圆环图
  Widget _buildPieChart(List<CategoryData> data) {
    return AspectRatio(
      aspectRatio: 1,
      child: PieChart(
        PieChartData(
          sectionsSpace: 2,
          centerSpaceRadius: 70,
          sections: data.map((item) {
            return PieChartSectionData(
              color: item.color,
              value: item.percentage,
              title: '${item.percentage.toStringAsFixed(1)}%',
              radius: 100,
              titleStyle: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontFamily: 'HarmonyOS_Sans',
              ),
            );
          }).toList(),
          borderData: FlBorderData(show: false),
        ),
      ),
    );
  }
  
  // 构建图例
  Widget _buildLegend(List<CategoryData> data) {
    return ListView.builder(
      itemCount: data.length,
      itemBuilder: (context, index) {
        final item = data[index];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: item.color,
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${item.category} (${item.idsCount})',
                  style: TextStyle(
                    fontSize: 14,
                    fontFamily: 'HarmonyOS_Sans',
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// 分类数据模型
class CategoryData {
  final String detectionType;
  final String category;
  final int idsCount;
  final double percentage;
  final Color color;
  
  CategoryData({
    required this.detectionType,
    required this.category,
    required this.idsCount,
    required this.percentage,
    required this.color,
  });
}
