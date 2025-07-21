import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'models/chat_instance_model.dart';

class LeftPanel extends StatefulWidget {
  final List<ChatInstance> chatInstances;
  final Function(String) onSelectInstance;
  final Function() onNewInstance;
  final String activeInstanceId;
  final Function() onConsoleButtonPressed;
  final Function(String)? onRemoveInstance;

  const LeftPanel({
    super.key, 
    required this.chatInstances,
    required this.onSelectInstance,
    required this.onNewInstance,
    required this.activeInstanceId,
    required this.onConsoleButtonPressed,
    this.onRemoveInstance,
  });
  
  @override
  State<LeftPanel> createState() => _LeftPanelState();
}

class _LeftPanelState extends State<LeftPanel> with SingleTickerProviderStateMixin {
  final Set<String> _displayedInstances = {};
  Map<String, int> _previousInstancePositions = {};
  bool _isAddingNew = false;
  
  void _handleRemoveInstance(String instanceId) {
    if (true) {
      // widget.onRemoveInstance!(instanceId);
      setState(() {
        widget.chatInstances.removeWhere((instance) => instance.id == instanceId);
      });
    }
  }
  
  @override
  void initState() {
    super.initState();
    for (var instance in widget.chatInstances) {
      _displayedInstances.add(instance.id);
    }
    _updatePreviousPositions();
  }
  
  void _updatePreviousPositions() {
    _previousInstancePositions = {};
    for (int i = 0; i < widget.chatInstances.length; i++) {
      _previousInstancePositions[widget.chatInstances[i].id] = i;
    }
  }
  
  @override
  void didUpdateWidget(LeftPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.chatInstances.length > oldWidget.chatInstances.length) {
      for (var instance in widget.chatInstances) {
        if (!_displayedInstances.contains(instance.id)) {
          _displayedInstances.add(instance.id);
        }
      }
      
      setState(() {
        _isAddingNew = true;
      });
      
      Future.delayed(Duration(milliseconds: 600), () {
        if (mounted) {
          setState(() {
            _isAddingNew = false;
            _updatePreviousPositions();
          });
        }
      });
    } else {
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
          Padding(
            padding: const EdgeInsets.only(bottom: 40),
            child: Row(
              children: [
                SvgPicture.asset(
                    'assets/logo/logo_1.svg', 
                    height: 40,
                  ),                
                SizedBox(width: 10,),
                SvgPicture.asset(
                    'assets/logo/logo_2.svg', 
                    height: 40,
                  ),              
              ],
            ),
          ),
          
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
              elevation: WidgetStateProperty.all(0), 
              backgroundColor: WidgetStateProperty.all(Colors.blue.shade50),
              foregroundColor: WidgetStateProperty.all(Colors.blue),
              padding: WidgetStateProperty.all(
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
              shape: WidgetStateProperty.all(
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            ),
          ),
          
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
                    
                    final int previousPosition = _previousInstancePositions[instance.id] ?? index;
                    
                    return AnimatedChatItem(
                      key: ValueKey(instance.id),
                      instance: instance,
                      isActive: isActive,
                      isNew: isNew,
                      previousPosition: previousPosition,
                      currentPosition: index,
                      isAddingNew: _isAddingNew,
                      onTap: () => widget.onSelectInstance(instance.id),
                      onLongPress: () => _handleRemoveInstance(instance.id),
                    );
                  },
                ),
            ),
          ),
          
          TextButton.icon(
            onPressed: widget.onConsoleButtonPressed, 
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

class AnimatedChatItem extends StatefulWidget {
  final ChatInstance instance;
  final bool isActive;
  final bool isNew;
  final int previousPosition;
  final int currentPosition;
  final bool isAddingNew;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  
  const AnimatedChatItem({
    Key? key,
    required this.instance,
    required this.isActive,
    required this.isNew,
    required this.previousPosition,
    required this.currentPosition,
    required this.isAddingNew,
    required this.onTap,
    this.onLongPress,
  }) : super(key: key);
  
  @override
  State<AnimatedChatItem> createState() => _AnimatedChatItemState();
}

class _AnimatedChatItemState extends State<AnimatedChatItem> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _slideAnimation; 
  late Animation<double> _opacityAnimation; 
  late Animation<double> _moveAnimation; 
  
  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _initializeAnimations();
    
    if (widget.isNew) {
      _controller.forward(from: 0.0);
    } else if (widget.isAddingNew && widget.previousPosition != widget.currentPosition) {
      _controller.forward(from: 0.0);
    } else {
      _controller.value = 1.0;
    }
  }
  
  void _initializeAnimations() {
    _slideAnimation = Tween<double>(
      begin: widget.isNew ? -240.0 : 0.0, 
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutQuart,
    ));
    
    _opacityAnimation = Tween<double>(
      begin: widget.isNew ? 0.0 : 1.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));
    
    double beginOffset = 0.0;
    
    if (widget.isAddingNew) {
      if (widget.isNew) {
        beginOffset = -50.0;
      } else if (widget.previousPosition < widget.currentPosition) {
        beginOffset = -72.0; 
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
    
    bool positionChanged = widget.currentPosition != oldWidget.currentPosition ||
                           widget.previousPosition != oldWidget.previousPosition;
    bool stateChanged = widget.isAddingNew != oldWidget.isAddingNew ||
                        widget.isNew != oldWidget.isNew ||
                        widget.isActive != oldWidget.isActive;
    
    if (!oldWidget.isAddingNew && widget.isAddingNew) {
      _initializeAnimations();
      
      if (widget.isNew) {
        _controller.forward(from: 0.0);
      } else if (positionChanged) {
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
          offset: Offset(_slideAnimation.value, _moveAnimation.value),
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: widget.onTap,
                onLongPress: widget.onLongPress,
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
