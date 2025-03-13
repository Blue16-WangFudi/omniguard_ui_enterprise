import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'models/chat_instance_model.dart';

class LeftPanel extends StatefulWidget {
  final List<ChatInstance> chatInstances;
  final Function(String) onSelectInstance;
  final Function() onNewInstance;
  final String activeInstanceId;
  final Function() onConsoleButtonPressed;

  const LeftPanel({
    super.key, 
    required this.chatInstances,
    required this.onSelectInstance,
    required this.onNewInstance,
    required this.activeInstanceId,
    required this.onConsoleButtonPressed,
  });
  
  @override
  State<LeftPanel> createState() => _LeftPanelState();
}

class _LeftPanelState extends State<LeftPanel> with SingleTickerProviderStateMixin {
  // 存储已经展示过的实例ID，用于确定哪些是新添加的
  final Set<String> _displayedInstances = {};
  // 存储每个实例的上一次位置
  Map<String, int> _previousInstancePositions = {};
  bool _isAddingNew = false;
  
  @override
  void initState() {
    super.initState();
    // 初始化时记录所有现有实例
    for (var instance in widget.chatInstances) {
      _displayedInstances.add(instance.id);
    }
    
    // 初始化每个实例的上一次位置
    _updatePreviousPositions();
  }
  
  // 更新每个实例的上一次位置
  void _updatePreviousPositions() {
    _previousInstancePositions = {};
    for (int i = 0; i < widget.chatInstances.length; i++) {
      _previousInstancePositions[widget.chatInstances[i].id] = i;
    }
  }
  
  @override
  void didUpdateWidget(LeftPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // 检查是否有新的实例被添加
    if (widget.chatInstances.length > oldWidget.chatInstances.length) {
      // 查找新添加的实例
      for (var instance in widget.chatInstances) {
        if (!_displayedInstances.contains(instance.id)) {
          // 将新实例ID添加到已显示集合中
          _displayedInstances.add(instance.id);
        }
      }
      
      // 直接设置状态触发动画
      setState(() {
        _isAddingNew = true;
      });
      
      // 延迟600毫秒后重置标记并更新每个实例的上一次位置
      Future.delayed(Duration(milliseconds: 600), () {
        if (mounted) {
          setState(() {
            _isAddingNew = false;
            // 更新每个实例的上一次位置
            _updatePreviousPositions();
          });
        }
      });
    } else {
      // 如果没有新实例被添加，则直接更新每个实例的上一次位置
      _updatePreviousPositions();
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      color: const Color(0xFFF5F7FA),
      padding: const EdgeInsets.fromLTRB(20, 40, 20, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo
          Padding(
            padding: const EdgeInsets.only(bottom: 40),
            child: Row(
              children: [
                SvgPicture.asset(
                    'assets/logo/logo_1.svg', // SVG文件路径
                    height: 40,
                  ),                
                SizedBox(width: 10,),
                SvgPicture.asset(
                    'assets/logo/logo_2.svg', // SVG文件路径
                    height: 40,
                  ),              
              ],
            ),
          ),
          
          // New task button
          ElevatedButton.icon(
            onPressed: widget.onNewInstance,
            icon: const Icon(Icons.add, size: 16),
            label: const Text('新建识别任务',
              style:  TextStyle(
                fontSize: 18,
                color: Color.fromARGB(255, 0, 0, 0),
                fontFamily: 'HarmonyOS_Sans',
                fontWeight: FontWeight.w400,
              ),
            ),
            style: ButtonStyle(
              elevation: WidgetStateProperty.all(0), // 禁用所有状态阴影
              backgroundColor: WidgetStateProperty.all(Colors.blue.shade50),
              foregroundColor: WidgetStateProperty.all(Colors.blue),
              padding: WidgetStateProperty.all(
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
              shape: WidgetStateProperty.all(
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            ),
          ),
          
          // Chat instances list
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: widget.chatInstances.isEmpty
                ? Center(child: Text('无聊天记录', style: TextStyle(color: Colors.grey)))
                : ListView.builder(
                  itemCount: widget.chatInstances.length,
                  itemBuilder: (context, index) {
                    final instance = widget.chatInstances[index];
                    final bool isActive = instance.id == widget.activeInstanceId;
                    final bool isNew = index == 0 && instance.id == widget.activeInstanceId && 
                        !_previousInstancePositions.containsKey(instance.id);
                    
                    // 获取实例的上一次位置
                    final int previousPosition = _previousInstancePositions[instance.id] ?? index;
                    
                    // 创建聊天实例列表项，对新创建的实例添加动画
                    return AnimatedChatItem(
                      key: ValueKey(instance.id),
                      instance: instance,
                      isActive: isActive,
                      isNew: isNew,
                      previousPosition: previousPosition,
                      currentPosition: index,
                      isAddingNew: _isAddingNew,
                      onTap: () => widget.onSelectInstance(instance.id),
                    );
                  },
                ),
            ),
          ),
          
          // Control panel button at bottom
          TextButton.icon(
            onPressed: widget.onConsoleButtonPressed, // 使用新的控制台按钮点击回调
            icon: const Icon(Icons.dashboard_outlined, size: 16),
            label: const Text('控制台',                     
            style:  TextStyle(
              fontSize: 18,
              color: Color.fromARGB(255, 0, 0, 0),
              fontFamily: 'HarmonyOS_Sans',
              fontWeight: FontWeight.w400,
            ),),
            style: TextButton.styleFrom(
              foregroundColor: const Color.fromARGB(137, 0, 0, 0),
            ),
          ),
        ],
      ),
    );
  }
}

// 动画聊天项目组件
class AnimatedChatItem extends StatefulWidget {
  final ChatInstance instance;
  final bool isActive;
  final bool isNew;
  final int previousPosition;
  final int currentPosition;
  final bool isAddingNew;
  final VoidCallback onTap;
  
  const AnimatedChatItem({
    Key? key,
    required this.instance,
    required this.isActive,
    required this.isNew,
    required this.previousPosition,
    required this.currentPosition,
    required this.isAddingNew,
    required this.onTap,
  }) : super(key: key);
  
  @override
  State<AnimatedChatItem> createState() => _AnimatedChatItemState();
}

class _AnimatedChatItemState extends State<AnimatedChatItem> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _slideAnimation; // 水平滑动动画（从左侧进入）
  late Animation<double> _opacityAnimation; // 透明度动画
  late Animation<double> _moveAnimation; // 垂直移动动画（下降效果）
  
  @override
  void initState() {
    super.initState();
    
    // 初始化动画控制器
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _initializeAnimations();
    
    // 如果是新项目或位置发生变化，则播放动画
    if (widget.isNew) {
      // 新项目需要从左侧滑入
      _controller.forward(from: 0.0);
    } else if (widget.isAddingNew && widget.previousPosition != widget.currentPosition) {
      // 如果是因为添加新项目导致位置变化的现有项目，播放向下移动的动画
      _controller.forward(from: 0.0);
    } else {
      // 对于其他项目，直接设置动画到结束状态
      _controller.value = 1.0;
    }
  }
  
  void _initializeAnimations() {
    // 新项目的滑动动画 - 从左侧滑入
    _slideAnimation = Tween<double>(
      begin: widget.isNew ? -240.0 : 0.0, // 增加起始距离，使新项目完全从屏幕外进入
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutQuart,
    ));
    
    // 透明度动画 - 配合滑动的淡入效果
    _opacityAnimation = Tween<double>(
      begin: widget.isNew ? 0.0 : 1.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));
    
    // 移动动画 - 当添加新实例时，现有任务卡片平滑下降
    double beginOffset = 0.0;
    
    if (widget.isAddingNew) {
      if (widget.isNew) {
        // 新项目从上方滑入
        beginOffset = -50.0;
      } else if (widget.previousPosition < widget.currentPosition) {
        // 当项目位置增加时（向下移动）
        beginOffset = -72.0; // 卡片高度+间距
      }
    }
    
    _moveAnimation = Tween<double>(
      begin: beginOffset,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));
  }
  
  @override
  void didUpdateWidget(AnimatedChatItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // 检测状态或位置变化
    bool positionChanged = widget.currentPosition != oldWidget.currentPosition ||
                           widget.previousPosition != oldWidget.previousPosition;
    bool stateChanged = widget.isAddingNew != oldWidget.isAddingNew ||
                        widget.isNew != oldWidget.isNew ||
                        widget.isActive != oldWidget.isActive;
    
    // 检查isAddingNew变化，这对动画触发至关重要
    if (!oldWidget.isAddingNew && widget.isAddingNew) {
      _initializeAnimations();
      
      if (widget.isNew) {
        // 新添加的项目
        _controller.forward(from: 0.0);
      } else if (positionChanged) {
        // 由于添加新项目导致位置变化的现有项目
        _controller.forward(from: 0.0);
      }
    } else if (positionChanged || stateChanged) {
      _initializeAnimations();
      
      if (widget.isNew) {
        _controller.forward(from: 0.0);
      } else if (widget.isAddingNew && positionChanged) {
        _controller.forward(from: 0.0);
      }
    }
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          // 组合水平滑动和垂直移动动画
          offset: Offset(_slideAnimation.value, _moveAnimation.value),
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: widget.onTap,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: widget.isActive ? Colors.blue.shade50 : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: widget.isActive ? Colors.blue.shade100 : Colors.transparent,
                      width: 1.0,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.instance.title,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          color: widget.isActive ? Colors.blue : Colors.black87,
                          fontFamily: 'HarmonyOS_Sans',
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '${widget.instance.lastUpdatedAt.year}-${
                          widget.instance.lastUpdatedAt.month.toString().padLeft(2, '0')}-${
                          widget.instance.lastUpdatedAt.day.toString().padLeft(2, '0')} ${
                          widget.instance.lastUpdatedAt.hour.toString().padLeft(2, '0')}:${
                          widget.instance.lastUpdatedAt.minute.toString().padLeft(2, '0')}',
                        style: TextStyle(fontSize: 12, color: Colors.grey, fontFamily: 'HarmonyOS_Sans'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
