import 'package:flutter/material.dart';
import '../models/detector_model.dart';

class RiskReportCard extends StatefulWidget {
  final DetectionData detectionData;
  final String detectionMode;
  final VoidCallback? onExpand;

  const RiskReportCard(
      {Key? key,
      required this.detectionData,
      required this.detectionMode,
      this.onExpand})
      : super(key: key);

  @override
  State<RiskReportCard> createState() => _RiskReportCardState();
}

class _RiskReportCardState extends State<RiskReportCard>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _progressAnimation;
  late AnimationController _expandController;
  late Animation<double> _heightAnimation;

  // Get the first result from the detection data
  DetectionResult? get _mainResult => widget.detectionData.results.isNotEmpty
      ? widget.detectionData.results.first
      : null;

  // Helper method to get risk level based on confidence
  String _getRiskLevel(double confidence) {
    if (confidence >= 0.8) {
      return "高置信度";
    } else if (confidence >= 0.5) {
      return "中置信度";
    } else {
      return "低置信度";
    }
  }

  // Helper method to format confidence as percentage
  String _getConfidencePercentage(double confidence) {
    return "${(confidence * 100).toStringAsFixed(1)}%";
  }

  @override
  void initState() {
    super.initState();

    // 打印调试信息
    print('初始化风险报告卡: ${widget.detectionData.results.length} 个结果');
    if (widget.detectionData.results.isNotEmpty) {
      print('第一个结果置信度: ${widget.detectionData.results.first.confidence}');
    }

    // Use confidence from first result or default to 0
    final progressValue = _mainResult?.confidence.clamp(0.0, 1.0) ?? 0.0;

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: progressValue,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _expandController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _heightAnimation = CurvedAnimation(
      parent: _expandController,
      curve: Curves.easeOut,
    );

    // Add listener to expansion animation to notify parent
    _expandController.addListener(() {
      // Only notify when expanding (not when collapsing)
      if (_expandController.status == AnimationStatus.forward &&
          widget.onExpand != null) {
        widget.onExpand!();
      }
    });

    // 确保动画顺序正确
    _expandController.forward().then((_) {
      _animationController.forward();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _expandController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Get data from the first detection result
    final result = _mainResult;

    // Default values if no result is available
    final confidence = result?.confidence ?? 0.0;
    final category = result?.category ?? "未知";
    final overallAnalysis = result?.analysis.overall ?? "";
    final riskLevel = _getRiskLevel(confidence);
    final percentage = _getConfidencePercentage(confidence);

    // Check if featurePoints exist or are empty
    final hasAnalysis = result?.analysis != null;
    final hasFeaturePointsField =
        hasAnalysis && result?.analysis.featurePoints != null;
    final hasFeaturePoints = hasFeaturePointsField &&
        result?.analysis.featurePoints.isNotEmpty == true;

    return SizeTransition(
      sizeFactor: _heightAnimation,
      axisAlignment: -1.0,
      child: Column(
        // clipBehavior: Clip.none,
        children: [
          // Main card content
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(top: 8, bottom: 2, right: 47),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '综合评价结果',
                        style: TextStyle(
                          fontFamily: 'HarmonyOS_Sans',
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (widget.detectionMode == "PRECISE")
                        Row(
                          children: [
                            Icon(
                              Icons.bolt,
                              color: Colors.orange[600],
                              size: 16,
                            ),
                            Text(
                              '增强模式',
                              style: TextStyle(
                                color: Colors.orange[600],
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),

                Container(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        percentage,
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFFF4500),
                        ),
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$category(${riskLevel})',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: AnimatedBuilder(
                    animation: _progressAnimation,
                    builder: (context, child) {
                      return LinearProgressIndicator(
                        value: _progressAnimation.value,
                        backgroundColor: Colors.grey[200],
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.orange),
                        minHeight: 8,
                        borderRadius: BorderRadius.circular(4),
                      );
                    },
                  ),
                ),

                // FAST 模式下展示分类置信度列表
                if (widget.detectionMode != 'PRECISE' && hasFeaturePoints)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '检测结果',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'HarmonyOS_Sans',
                          ),
                        ),
                        const SizedBox(height: 6),
                        ...result!.analysis.featurePoints
                            .map((p) => _buildCategoryRow(p))
                            .toList(),
                      ],
                    ),
                  ),

                // 精准(增强)模式下的“风险提示/AI特征分析”标题
                if (widget.detectionMode == 'PRECISE')
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                    child: Text(
                      widget.detectionMode == 'AI' ? 'AI特征分析' : '风险提示',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'HarmonyOS_Sans',
                      ),
                    ),
                  ),

                // Check feature points status and display appropriate message
                if (widget.detectionMode == 'PRECISE' &&
                    (!hasAnalysis || !hasFeaturePointsField))
                  // featurePoints 键不存在时显示检测失败信息
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                    child: Text(
                      '检测失败，无法获取风险特征',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.red,
                        fontFamily: 'HarmonyOS_Sans',
                      ),
                    ),
                  )
                else if (widget.detectionMode == 'PRECISE' && !hasFeaturePoints)
                  // featurePoints 为空列表时显示无风险信息
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                    child: Text(
                      widget.detectionMode == 'AI'
                          ? '未检测到明显的AI生成特征'
                          : '未检测到风险，内容安全',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.green,
                        fontFamily: 'HarmonyOS_Sans',
                      ),
                    ),
                  )
                else if (widget.detectionMode == 'PRECISE')
                  // 存在风险特征点时显示特征点列表
                  ...result?.analysis.featurePoints
                          .map((point) => _buildFeaturePoint(point)) ??
                      [],

                // 快速模式底部说明文字
                if (widget.detectionMode != 'PRECISE')
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                    child: Text(
                      '快速检测模式：基于机器学习模型的多类别置信度分析，上述结果按置信度从高到低排序。',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                        fontFamily: 'HarmonyOS_Sans',
                      ),
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                    child: Text(
                      overallAnalysis,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                        fontFamily: 'HarmonyOS_Sans',
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // Download button at bottom right corner
          Row(
            children: [
              Spacer(),
              TextButton.icon(
                onPressed: () {
                  // TODO: Implement download functionality
                  print('下载风险报告');
                },
                icon: const Icon(
                  Icons.document_scanner,
                  color: Color.fromRGBO(1, 102, 255, 1),
                  size: 20,
                ),
                label: const Text(
                  '下载风险报告',
                  style: TextStyle(
                    color: Color.fromRGBO(1, 102, 255, 1),
                    fontSize: 14,
                  ),
                ),
                style: TextButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
              ),
              SizedBox(width: 40),
            ],
          ),

          SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildCategoryRow(FeaturePoint point) {
    final isSafe = point.keyword.contains('无风险');
    final dotColor = isSafe ? Colors.green : const Color(0xFFFF8C00);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
        ),
        child: Container(
          margin: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(right: 8),
                decoration:
                    BoxDecoration(color: dotColor, shape: BoxShape.circle),
              ),
              Expanded(
                child: Text(
                  point.keyword,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
              ),
              Text(
                point.description,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeaturePoint(FeaturePoint point) {
    return Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.white,
          ),
          child: Container(
            margin: const EdgeInsets.fromLTRB(15, 10, 15, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(top: 6, right: 8),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        point.keyword,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        point.description,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ));
  }

  // Decode Chinese unicode characters
  String _decodeChinese(String text) {
    // Decode Unicode escape sequences like \u4F60\u597D to actual Chinese characters
    return text.replaceAllMapped(RegExp(r'\\u([0-9a-fA-F]{4})'), (match) {
      return String.fromCharCode(int.parse(match.group(1)!, radix: 16));
    });
  }
}
