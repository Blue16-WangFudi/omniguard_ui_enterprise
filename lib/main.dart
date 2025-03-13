import 'package:flutter/material.dart';
import 'console_panel.dart';
import 'left_panel.dart';
import 'detection_panel.dart';
import 'models/chat_instance_model.dart';
import 'dart:math'; // For generating random IDs

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OmniGuard AI',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.white,
        fontFamily: 'HarmonyOS_Sans',
      ),
      home: const ChatScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  // 所有聊天实例的列表
  List<ChatInstance> _chatInstances = [];
  // 当前活动的聊天实例ID
  String? _activeInstanceId;
  // 是否显示控制台面板
  bool _showConsolePanel = false;
  
  @override
  void initState() {
    super.initState();
    // 初始化时创建一个新的聊天实例
    _createNewInstance();
  }
  
  // 创建新的聊天实例
  void _createNewInstance() {
    final String id = _generateId();
    final newInstance = ChatInstance(
      id: id,
      title: '新任务',
    );
    
    setState(() {
      // 将新的聊天实例添加到列表的开头，而不是末尾
      _chatInstances.insert(0, newInstance);
      _activeInstanceId = id; // 设置为活动实例
      _showConsolePanel = false; // 切换到聊天面板
    });
  }
  
  // 生成唯一ID
  String _generateId() {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final random = Random();
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final randomStr = List.generate(8, (index) => chars[random.nextInt(chars.length)]).join('');
    return '$timestamp-$randomStr';
  }
  
  // 更新聊天实例
  void _updateInstance(ChatInstance updatedInstance) {
    setState(() {
      final index = _chatInstances.indexWhere((instance) => instance.id == updatedInstance.id);
      if (index != -1) {
        _chatInstances[index] = updatedInstance;
      }
    });
  }
  
  // 选择聊天实例
  void _selectInstance(String id) {
    setState(() {
      _activeInstanceId = id;
      _showConsolePanel = false; // 切换到聊天面板
    });
  }
  
  // 切换控制台面板显示
  void _toggleConsolePanel() {
    setState(() {
      _showConsolePanel = !_showConsolePanel; // 切换控制台面板显示
    });
  }

  @override
  Widget build(BuildContext context) {
    // 当前活动的聊天实例
    ChatInstance? activeInstance;
    if (_activeInstanceId != null) {
      activeInstance = _chatInstances.firstWhere(
        (instance) => instance.id == _activeInstanceId,
        orElse: () => _chatInstances.isNotEmpty ? _chatInstances.first : ChatInstance(
          id: _generateId(),
          title: '新任务',
        ),
      );
    }
    
    return Scaffold(
      body: Row(
        children: [
          // 左侧面板 - 显示聊天实例列表
          LeftPanel(
            chatInstances: _chatInstances,
            activeInstanceId: _activeInstanceId ?? '',
            onSelectInstance: _selectInstance,
            onNewInstance: _createNewInstance,
            onConsoleButtonPressed: _toggleConsolePanel, // 处理控制台按钮点击事件
          ),
          
          // 右侧面板 - 根据状态显示控制台或聊天界面
          if (_showConsolePanel)
            // 显示控制台面板
             

                    Expanded(
                       child: ConsolePanel(),
                    )
              
          else if (activeInstance != null)
            // 显示当前活动聊天实例
            DetectionPanel(
              chatInstance: activeInstance,
              onUpdateInstance: _updateInstance,
              onConsoleButtonPressed: _toggleConsolePanel, // 处理控制台按钮点击事件
            ),
        ],
      ),
    );
  }
}
