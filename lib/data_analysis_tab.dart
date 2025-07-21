// 数据分析选项卡
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart';

// Badge widget for pie chart
class _Badge extends StatelessWidget {
  final String text;
  final Animation<double> animation;

  const _Badge(this.text, {required this.animation});

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: Duration(milliseconds: 200),
      opacity: animation.value,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
            fontFamily: 'HarmonyOS_Sans',
          ),
        ),
      ),
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

class DataAnalysisTab extends StatefulWidget {
  @override
  _DataAnalysisTabState createState() => _DataAnalysisTabState();
}

class _DataAnalysisTabState extends State<DataAnalysisTab> with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  String _errorMessage = '';
  
  // 风险数据和AIGC数据
  List<CategoryData> _riskData = [];
  List<CategoryData> _aiData = [];
  
  // 动画控制器
  late AnimationController _animationController;
  late Animation<double> _animation;
  
  @override
  void initState() {
    super.initState();
    
    // 初始化动画控制器
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 800),
    );
    
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    
    _fetchData();
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
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
        _aiData = results[1];
        _isLoading = false;
      });
      
      // 启动动画
      _animationController.forward();
    } catch (e) {
      setState(() {
        _errorMessage = '数据加载失败: ${e.toString()}';
        _isLoading = false;
      });
    }
  }
  
  // 获取分类数据
  Future<List<CategoryData>> _fetchCategoryData(String detectionType) async {
    final url = Uri.parse('http://47.119.178.225:8090/api/v5/detector/result/category');
    
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
        List<CategoryData> categoryDataList = categories.map((category) {
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
        
        // 合并小于5%的类别为"其他"
        return _mergeSmallCategories(categoryDataList);
      } else {
        throw Exception('API错误: ${jsonData['msg']}');
      }
    } else {
      throw Exception('请求失败，状态码: ${response.statusCode}');
    }
  }
  
  // 合并小于5%的类别为"其他"
  List<CategoryData> _mergeSmallCategories(List<CategoryData> originalData) {
    // 如果数据不足，直接返回
    if (originalData.length <= 1) {
      return originalData;
    }
    
    // 分离小于5%和大于等于5%的类别
    List<CategoryData> mainCategories = [];
    List<CategoryData> smallCategories = [];
    
    for (var category in originalData) {
      if (category.percentage < 5.0) {
        smallCategories.add(category);
      } else {
        mainCategories.add(category);
      }
    }
    
    // 如果没有小类别，直接返回原始数据
    if (smallCategories.isEmpty) {
      return originalData;
    }
    
    // 合并小类别
    int totalSmallIds = smallCategories.fold(0, (sum, item) => sum + item.idsCount);
    double totalSmallPercentage = smallCategories.fold(0.0, (sum, item) => sum + item.percentage);
    String detectionType = originalData.first.detectionType;
    
    // 创建"其他"类别
    CategoryData otherCategory = CategoryData(
      detectionType: detectionType,
      category: '其他',
      idsCount: totalSmallIds,
      percentage: totalSmallPercentage,
      color: Color(0xFF9E9E9E), // 使用灰色表示"其他"
    );
    
    // 添加"其他"类别到主类别列表
    mainCategories.add(otherCategory);
    
    // 按百分比降序排序
    mainCategories.sort((a, b) => b.percentage.compareTo(a.percentage));
    
    return mainCategories;
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
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
      ),
      child: _buildContent(),
    );
  }
  
  Widget _buildContent() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 60,
              height: 60,
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1A66FF)),
                strokeWidth: 3,
              ),
            ),
            SizedBox(height: 24),
            Text(
              '加载数据分析中...',
              style: TextStyle(
                fontSize: 16,
                color: Colors.black54,
                fontFamily: 'HarmonyOS_Sans',
              ),
            ),
          ],
        ),
      );
    }
    
    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Container(
          constraints: BoxConstraints(maxWidth: 400),
          padding: EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 20,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 80, color: Colors.red.shade300),
              SizedBox(height: 24),
              Text(
                '数据加载失败',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                  fontFamily: 'HarmonyOS_Sans',
                ),
              ),
              SizedBox(height: 12),
              Text(
                _errorMessage,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.black54,
                  fontFamily: 'HarmonyOS_Sans',
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _fetchData,
                icon: Icon(Icons.refresh),
                label: Text('重试'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF1A66FF),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    return 
    SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
      child:Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '数据分析仪表盘',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              fontFamily: 'HarmonyOS_Sans',
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 4),
          Text(
            '全智卫安风险监测与AIGC检测分析概览',
            style: TextStyle(
              fontSize: 14,
              color: Colors.black54,
              fontFamily: 'HarmonyOS_Sans',
            ),
          ),
          SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, constraints) {
              return AnimatedBuilder(
                animation: _animation,
                builder: (context, child) {
                  return Column(
                    children: [
                      Container(
                        height: 350,  
                        child: _buildChartSection(
                          '风险数据占比',
                          _riskData,
                          'RISK',
                        ),
                      ),
                      SizedBox(height: 24),
                      Container(
                        height: 350,  
                        child: _buildChartSection(
                          'AIGC检测占比',
                          _aiData,
                          'AI',
                        ),
                      ),
                    ],
                  );
                },
              );
            }
          ),
        ],
      ),
      )
    );
  }
  
  // 构建图表区域
  Widget _buildChartSection(String title, List<CategoryData> data, String type) {
    if (data.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.bar_chart,
                size: 72,
                color: Colors.grey.shade300,
              ),
              SizedBox(height: 24),
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
        ),
      );
    }
    
    return Container(
      // height: 600,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // 背景装饰
            Positioned(
              top: -100,
              right: -50,
              child: AnimatedBuilder(
                animation: _animation,
                builder: (context, _) {
                  return Transform.rotate(
                    angle: _animation.value * math.pi * 2,
                    child: Opacity(
                      opacity: 0.02,
                      child: Container(
                        width: 300,
                        height: 300,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              type == 'RISK' ? Color(0xFF4285F4) : Color(0xFFEA4335),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }
              ),
            ),
                        Positioned(
              left:20,top:20,
              child:                       
                Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'HarmonyOS_Sans',
                              color: Colors.black87,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            '共${data.map((e) => e.idsCount).reduce((a, b) => a + b)}条数据',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.black54,
                              fontFamily: 'HarmonyOS_Sans',
                            ),
                          ),
                        ],
                      ),
              ),
              Positioned(
                top:20,right:20,child:
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: type == 'RISK' 
                              ? Color(0xFF4285F4).withOpacity(0.1) 
                              : Color(0xFFEA4335).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              type == 'RISK' ? Icons.security : Icons.android,
                              size: 16,
                              color: type == 'RISK' ? Color(0xFF4285F4) : Color(0xFFEA4335),
                            ),
                            SizedBox(width: 6),
                            Text(
                              type == 'RISK' ? '风险监测' : 'AIGC检测',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: type == 'RISK' ? Color(0xFF4285F4) : Color(0xFFEA4335),
                                fontFamily: 'HarmonyOS_Sans',
                              ),
                            ),
                          ],
                        ),
                      ),),

            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                    ],
                  ),
                  SizedBox(height: 24),
                  Flexible(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center
                      ,
                      children: [
                        Flexible(
                          flex: 3,
                          child: AnimatedBuilder(
                            animation: _animation,
                            builder: (context, _) {
                              return _buildPieChart(data);
                            }
                          ),
                        ),
                        // 图例
                        SizedBox(width: 50),
                        Flexible(
                          flex: 2,
                          child: _buildLegend(data),
                        ),
                        
                        // Spacer(),
                      ],
                    ),
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
          centerSpaceRadius: 70 * _animation.value,
          sections: data.map((item) {
            return PieChartSectionData(
              color: item.color,
              value: item.percentage,
              title: '${item.percentage.toStringAsFixed(1)}%',
              radius: 50 * _animation.value,
              titleStyle: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontFamily: 'HarmonyOS_Sans',
              ),
              badgeWidget: item.percentage > 5 ? _Badge(
                item.category,
                animation: _animation,
              ) : null,
              badgePositionPercentageOffset: 1.5,
            );
          }).toList(),
          borderData: FlBorderData(show: false),
        ),
      ),
    );
  }
  
  // 构建图例
  Widget _buildLegend(List<CategoryData> data) {
    return Container(
      margin: EdgeInsets.only(left: 12),
      height: ((data.length + 1) ~/ 2) * 60, // 计算所需高度，每行高度60，确保足够空间
      child: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, // 双排显示
          childAspectRatio: 3.65, // 控制每个项目的宽高比
          crossAxisSpacing: 8, // 横向间距
          mainAxisSpacing: 8, // 纵向间距
        ),
        itemCount: data.length,
        physics: NeverScrollableScrollPhysics(), // 禁用滚动以避免嵌套滚动问题
        itemBuilder: (context, index) {
          final item = data[index];
          final progress = _animation.value;
          
          // 交错动画效果
          final delayedProgress = math.min(1.0, math.max(0.0, 
              (progress - (index * 0.1)) / (1 - (index * 0.1))));
          
          return AnimatedOpacity(
            duration: Duration(milliseconds: 300),
            opacity: delayedProgress,
            child: Transform.translate(
              offset: Offset(20 * (1 - delayedProgress), 0),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.grey.shade100,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: item.color,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: item.color.withOpacity(0.3),
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 6),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            item.category,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              fontFamily: 'HarmonyOS_Sans',
                              color: Colors.black87,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '${item.idsCount}项 · ${item.percentage.toStringAsFixed(1)}%',
                            style: TextStyle(
                              fontSize: 8,
                              color: Colors.black54,
                              fontFamily: 'HarmonyOS_Sans',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
