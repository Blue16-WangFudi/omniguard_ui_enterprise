import 'package:flutter/material.dart';
import 'package:omni_guard/services/server_status_service.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:omni_guard/widgets/resource_charts.dart';
import 'package:omni_guard/resource_monitoring_tab.dart';
import 'package:omni_guard/widgets/time_range_selector.dart';

import 'data_analysis_tab.dart';
import 'model_tuning_tab.dart';

class ConsolePanel extends StatefulWidget {
  const ConsolePanel({Key? key}) : super(key: key);

  @override
  State<ConsolePanel> createState() => _ConsolePanelState();
}

class _ConsolePanelState extends State<ConsolePanel> {
  // 当前选中的选项卡
  String _selectedTab = '资源监控';

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 顶部标题和按钮区域
        Container(
          padding: const EdgeInsets.all(30),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              // 标题
              const Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: Text(
                  '控制台',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'HarmonyOS_Sans',
                  ),
                ),
              ),
              // 选项卡按钮
              Row(
                children: [
                  _buildTabButton('资源监控'),
                  const SizedBox(width: 12),
                  _buildTabButton('数据分析'),
                  const SizedBox(width: 12),
                  _buildTabButton('模型调优'),
                  const SizedBox(width: 12),
                  _buildTabButton('API文档'),
                ],
              ),
            ],
          ),
        ),
        // 底部内容区域
        Expanded(
          child: Container(
            color: Colors.white,
            child: _buildTabContent(),
          ),
        ),
      ],
    );
  }

  // 构建选项卡按钮
  Widget _buildTabButton(String title) {
    bool isSelected = _selectedTab == title;
    
    return ElevatedButton(
      onPressed: () {
        setState(() {
          _selectedTab = title;
        });
      },
      style: ElevatedButton.styleFrom(
        elevation: 0,
        backgroundColor: isSelected 
            ? const Color.fromRGBO(1, 102, 255, 1) 
            : Colors.white,
        foregroundColor: isSelected 
            ? Colors.white 
            : Colors.black,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: isSelected 
                ? const Color.fromRGBO(1, 102, 255, 1) 
                : Colors.grey.shade300,
            width: 1,
          ),
        ),
      ),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontFamily: 'HarmonyOS_Sans',
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  // 构建内容区域
  Widget _buildTabContent() {
    switch (_selectedTab) {
      case '资源监控':
        return ResourceMonitoringTab();
      case '数据分析':
        return DataAnalysisTab();
      case '模型调优':
        return ModelTuningTab();
      case 'API文档':
        return _APIDocumentationTab();
      default:
        return ResourceMonitoringTab();
    }
  }
}

// 资源监控选项卡



// 模型调优选项卡
// API文档选项卡
class _APIDocumentationTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.article, size: 64, color: Colors.purple),
          SizedBox(height: 16),
          Text(
            'API文档页面',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              fontFamily: 'HarmonyOS_Sans',
            ),
          ),
          SizedBox(height: 8),
          Text(
            '此处提供API接口文档和使用说明',
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
}
