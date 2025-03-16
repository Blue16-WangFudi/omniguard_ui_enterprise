import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'utils/file_utils.dart';
import 'models/file_model.dart';
import 'services/obs_service.dart';
import 'services/detector_service.dart';
import 'widgets/risk_report_card.dart';
import 'models/detector_model.dart';
import 'models/chat_instance_model.dart';

class DetectionPanel extends StatefulWidget {
  final ChatInstance chatInstance;
  final Function(ChatInstance) onUpdateInstance;
  final VoidCallback onConsoleButtonPressed;

  const DetectionPanel({
    super.key, 
    required this.chatInstance, 
    required this.onUpdateInstance,
    required this.onConsoleButtonPressed,
  });

  @override
  State<DetectionPanel> createState() => _DetectionPanelState();
}

class _DetectionPanelState extends State<DetectionPanel> with SingleTickerProviderStateMixin {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<FileAttachment> _selectedFiles = [];
  bool _hasContent = false;
  bool _showWelcomeMessage = true;
  List<ChatMessage> _messages = [];
  bool _isWaitingForResponse = false;
  String _detectionMode = 'FAST'; // Default to FAST mode
  String _detectionType = 'RISK'; // Default to RISK type
  
  // Animation controllers for the floating text effect
  late AnimationController _floatingController;
  late Animation<double> _floatingAnimation;
  
  // Key for tracking list items and their animations
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  
  // Keep track of the last message count to handle animations
  int _lastMessageCount = 0;
  
  @override
  void initState() {
    super.initState();
    _textController.addListener(_checkContent);
    
    // Load messages from the chat instance
    _messages = widget.chatInstance.messages;
    
    // Only show welcome message for new instances with no messages
    _showWelcomeMessage = _messages.isEmpty;
    
    // Initialize the animation controller for floating effect
    _floatingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300), // 更短的动画时间，加快显示速度
    );
    
    // Create a curved animation for smooth floating motion from above
    _floatingAnimation = Tween<double>(begin: -30, end: 0).animate( // 减小浮动距离
      CurvedAnimation(parent: _floatingController, curve: Curves.easeOutQuad) // 使用更快的动画曲线
    );
    
    // Start the animation after widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _floatingController.forward();
      
      // Initial scroll to bottom when the widget is first built
      _scrollToBottom();
    });
  }

  @override
  void dispose() {
    _textController.removeListener(_checkContent);
    _textController.dispose();
    _scrollController.dispose();
    _floatingController.dispose();
    super.dispose();
  }
  
  @override
  void didUpdateWidget(DetectionPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.chatInstance.id != widget.chatInstance.id) {
      // Chat instance has changed, update messages
      setState(() {
        _lastMessageCount = 0; // Reset message count for new chat instance
        _messages = widget.chatInstance.messages;
        _showWelcomeMessage = _messages.isEmpty;
        _selectedFiles = [];
        _textController.clear();
        _checkContent();
      });
      
      // Restart the animation for the new chat instance
      _floatingController.reset();
      _floatingController.forward();
      
      // Scroll to bottom when chat instance changes
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    } else if (oldWidget.chatInstance.messages.length != widget.chatInstance.messages.length) {
      // Messages have been added or removed
      final int newCount = widget.chatInstance.messages.length;
      final int oldCount = _lastMessageCount;
      
      // Update messages list
      setState(() {
        _messages = widget.chatInstance.messages;
        _lastMessageCount = newCount; // Update the last count
      });
      
      // If messages were added, trigger animations for new messages
      if (newCount > oldCount) {
        // 重置动画控制器并立即播放动画，确保所有气泡动画同步
        _floatingController.reset();
        _floatingController.forward();
      }
      
      // Scroll to bottom when messages change
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    }
  }

  void _checkContent() {
    setState(() {
      _hasContent = _textController.text.isNotEmpty || _selectedFiles.isNotEmpty;
    });
  }

  void _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.any,
      );
      
      if (result != null) {
        setState(() {
          for (var path in result.paths) {
            if (path != null) {
              final file = File(path);
              final fileName = FileUtils.getFileName(file.path);
              _selectedFiles.add(FileAttachment(
                file: file,
                originalName: fileName,
              ));
              
              // Start uploading the file immediately
              _uploadFile(_selectedFiles.last);
            }
          }
          _checkContent();
        });
      }
    } catch (e) {
      // Fallback for demonstration
      setState(() {
        final file = File('dummy_file.txt');
        _selectedFiles.add(FileAttachment(
          file: file,
          originalName: 'dummy_file.txt',
        ));
        _checkContent();
      });
    }
  }
  
  // Upload a file to Huawei OBS
  Future<void> _uploadFile(FileAttachment fileAttachment) async {
    // Set status to uploading
    setState(() {
      // Use the ID to find the file attachment instead of object reference
      final index = _selectedFiles.indexWhere((file) => file.id == fileAttachment.id);
      print("Starting upload - Index by ID: $index");
      if (index != -1) {
        _selectedFiles[index] = fileAttachment.copyWith(
          status: FileUploadStatus.uploading,
          uploadProgress: 0.0,
        );
      }
    });

    try {
      // Upload the file to Huawei OBS with progress tracking
      final String? uploadedUrl = await ObsService.uploadFile(
        fileAttachment.file,
        onProgress: (progress) {
          setState(() {
            // Use the ID to find the file attachment instead of object reference
            final index = _selectedFiles.indexWhere((file) => file.id == fileAttachment.id);
            print("Progress update - Index by ID: $index, Progress: $progress");
            if (index != -1) {
              _selectedFiles[index] = _selectedFiles[index].copyWith(
                uploadProgress: progress,
                // 保持状态为上传中，不要更改状态
                status: FileUploadStatus.uploading,
              );
            }
          });
        },
      );
      print("打印");
      print(uploadedUrl);
      // Update file status based on upload result
      setState(() {
        // Use the ID to find the file attachment instead of object reference
        final index = _selectedFiles.indexWhere((file) => file.id == fileAttachment.id);
        print("Upload complete - Index by ID: $index");
        print("index=$index");
        if (index != -1) {
          if (uploadedUrl != null) {
            // Upload successful
            final updatedFile = _selectedFiles[index].copyWith(
              status: FileUploadStatus.completed,
              uploadProgress: 1.0,
              uploadedUrl: uploadedUrl,
            );
            _selectedFiles[index] = updatedFile;
            
            // 打印调试信息
            print('文件上传成功: ${fileAttachment.originalName}');
            print('状态标记为完成: ${updatedFile.isUploaded}');
            print('上传中状态: ${updatedFile.isUploading}');
          } else {
            // Upload failed
            _selectedFiles[index] = _selectedFiles[index].copyWith(
              status: FileUploadStatus.error,
            );
            print('文件上传失败: ${fileAttachment.originalName}');
          }
        }
      });
    } catch (e) {
      // Handle upload error
      setState(() {
        final index = _selectedFiles.indexWhere((file) => file.id == fileAttachment.id);
        if (index != -1) {
          _selectedFiles[index] = _selectedFiles[index].copyWith(
            status: FileUploadStatus.error,
          );
        }
      });
      print('文件上传发生错误: ${e.toString()}');
    }
  }

  void _sendMessage() async {
    String message = _textController.text.trim();
    
    // Create copy of selected files to use in message
    List<FileAttachment> messageFiles = List.from(_selectedFiles);
    
    // Only proceed if there's a message or files to send
    if (message.isEmpty && messageFiles.isEmpty) return;

    // Create a new message
    final userMessage = ChatMessage(
      text: message,
      files: messageFiles,
      isUser: true,
      detectionMode: _detectionMode, // Store the current detection mode
    );
    
    setState(() {
      // Add user message to chat instance directly
      widget.chatInstance.messages.add(userMessage);
      
      // Update local messages reference for UI
      _messages = widget.chatInstance.messages;
      
      // Clear input and files
      _textController.clear();
      _selectedFiles = [];
      _hasContent = false;
      _showWelcomeMessage = false;
      _isWaitingForResponse = true;

      // Force scroll to bottom after update
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    });
    
    // If there are files or text, detect them
    if (messageFiles.isNotEmpty || message.isNotEmpty) {
      // Add initial "thinking" system message
      final thinkingMessage = ChatMessage(
        text: "系统正在为您检测内容风险...",
        isUser: false,
        thinkingStatus: ThinkingStatus.thinking,
        detectionMode: _detectionMode, // Store the current detection mode
      );
      
      setState(() {
        // Add thinking message to chat instance directly
        widget.chatInstance.messages.add(thinkingMessage);
        
        // Force scroll to bottom after update
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToBottom();
        });
      });
      
      try {
        // Call the detector service to analyze the files and/or text
        List<DetectionResult> detectionResults = [];
        
        // 检查是否所有文件都已上传完成
        bool allFilesUploaded = messageFiles.every((file) => file.isUploaded);
        
        if (!allFilesUploaded) {
          print('等待所有文件上传完成...');
          // 等待所有文件上传完成
          await Future.wait(
            messageFiles.map((file) async {
              // 如果文件未上传完成，等待直到完成
              while (!file.isUploaded && file.status != FileUploadStatus.error) {
                await Future.delayed(const Duration(milliseconds: 500));
              }
            })
          );
          print('所有文件上传已完成');
        }
        
        // 创建所有对象的统一objects数组
        List<Map<String, String>> allObjects = [];
        
        // 如果有文本内容，添加到objects数组
        if (message.isNotEmpty) {
          print('添加文本内容到请求');
          try {
            // 上传文本内容作为txt文件
            final textFileUrl = await ObsService.uploadTextAsTxt(message);
            
            if (textFileUrl != null) {
              // 从URL中提取对象键
              final uri = Uri.parse(textFileUrl);
              final objectKey = uri.path.startsWith('/') ? uri.path.substring(1) : uri.path;
              
              // 添加文本对象到统一请求
              allObjects.add({
                "fileKey": objectKey,
                "type": "TEXT"
              });
              
              print('文本内容已上传并添加到objects: $objectKey');
            } else {
              print('文本上传失败，尝试直接添加');
              // 如果上传失败，尝试直接添加文本
              allObjects.add({
                "fileKey": "text_content",
                "type": "TEXT"
              });
            }
          } catch (e) {
            print('处理文本时出错: $e');
          }
        }
        
        // 添加所有已上传文件的信息到统一objects数组
        for (var file in messageFiles) {
          if (file.isUploaded && file.uploadedUrl != null) {
            // 从URL中提取对象键
            final uri = Uri.parse(file.uploadedUrl!);
            final objectKey = uri.path.startsWith('/') ? uri.path.substring(1) : uri.path;
            
            // 确定文件类型
            String fileType = "OTHER";
            final ext = uri.path.split('.').last.toLowerCase();
            if (['jpg', 'jpeg', 'png', 'gif', 'bmp'].contains(ext)) {
              fileType = "IMAGE";
            } else if (['mp4', 'avi', 'mov'].contains(ext)) {
              fileType = "VIDEO";
            } else if (['mp3', 'wav', 'ogg'].contains(ext)) {
              fileType = "AUDIO";
            } else if (['txt', 'text'].contains(ext)) {
              fileType = "TEXT";
            }
            
            // 添加到统一objects数组
            allObjects.add({
              "fileKey": objectKey,
              "type": fileType
            });
            
            print('添加文件到请求: ${file.originalName} (${file.uploadedUrl})');
          }
        }
        
        // 如果有任何对象，一次性发送所有内容进行检测
        if (allObjects.isNotEmpty) {
          print('一次性检测所有内容, 共 ${allObjects.length} 个对象');
          
          try {
            final apiResponse = await DetectorService.detectRisks(
              allObjects,
              detectionMode: _detectionMode,
              detectionType: _detectionType
            );
            
            if (apiResponse != null) {
              // 处理多模态响应
              final response = DetectorResponse.fromJson(apiResponse);
              if (response.data.results.isNotEmpty) {
                // 将所有结果添加到检测结果列表
                detectionResults.addAll(response.data.results);
                print('成功检测到 ${response.data.results.length} 个内容的结果');
              }
            }
          } catch (e) {
            print('批量检测内容时出错: $e');
          }
        }
        
        if (detectionResults.isNotEmpty) {
          // Group results by file - use new factory method for backward compatibility
          DetectionData detectionData = DetectionData.withResults(
            detectionResults,
            _detectionType,
          );
          
          print('创建完成消息，包含检测结果: ${detectionResults.length} 个结果，第一个结果置信度: ${detectionResults.first.confidence}');
          
          // 确保结果有分析内容，便于风险报告卡展示
          for (int i = 0; i < detectionResults.length; i++) {
            var result = detectionResults[i];
            // if (result.analysis.overall.isEmpty) {
            //   // 如果分析内容为空，设置一个默认值
            //   final analysis = DetectionAnalysis(
            //     overall: "可能存在风险内容，请谨慎处理",
            //     featurePoints: [
            //       FeaturePoint(keyword: "风险分类", description: result.category),
            //       FeaturePoint(keyword: "风险级别", description: result.confidence >= 0.8 ? "高度风险" : 
            //                                         (result.confidence >= 0.5 ? "中度风险" : "低度风险")),
            //     ],
            //     suggestions: ["建议进一步核实内容真实性", "谨慎处理相关信息"]
            //   );
              
            //   // 不能直接修改result，因为它是final，创建新的结果
            //   print('为检测结果添加默认分析内容');
            //   final analysisJson = jsonEncode({
            //     'overall': analysis.overall,
            //     'featurePoints': analysis.featurePoints.map((fp) => {
            //       'keyword': fp.keyword,
            //       'description': fp.description
            //     }).toList(),
            //     'suggestions': analysis.suggestions
            //   });
              
            //   final updatedResult = DetectionResult(
            //     id: result.id,
            //     fileKey: result.fileKey,
            //     detectionType: result.detectionType,
            //     category: result.category,
            //     confidence: result.confidence,
            //     analysisJson: analysisJson,
            //     analysis: analysis,
            //     timeCost: result.timeCost,
            //     dataSource: result.dataSource,
            //     timestamp: result.timestamp
            //   );
              
              // 替换原结果
              // detectionResults[i] = updatedResult;
              // print('替换了第 $i 个结果，添加了默认分析内容');
            // }
          }
          
          // Create completed message with detection results
          _addDetectionResultMessage(detectionResults);
        } else {
          // No valid results
          setState(() {
            // Update the thinking message with an error
            final lastIndex = widget.chatInstance.messages.length - 1;
            if (lastIndex >= 0 && widget.chatInstance.messages[lastIndex].thinkingStatus == ThinkingStatus.thinking) {
              // Create a new error message
              final errorMessage = ChatMessage(
                text: "无法检测内容风险。请检查您的输入或文件是否正确。",
                isUser: false,
                thinkingStatus: ThinkingStatus.completed,
              );
              
              // Replace the thinking message with the error message
              widget.chatInstance.messages.removeLast();
              widget.chatInstance.messages.add(errorMessage);
            }
            
            _isWaitingForResponse = false;
          });
        }
      } catch (e) {
        // Handle any errors during detection
        setState(() {
          // Update the thinking message with an error
          final lastIndex = widget.chatInstance.messages.length - 1;
          if (lastIndex >= 0 && widget.chatInstance.messages[lastIndex].thinkingStatus == ThinkingStatus.thinking) {
            // Create a new error message
            final errorMessage = ChatMessage(
              text: "检测内容风险发生错误: ${e.toString()}",
              isUser: false,
              thinkingStatus: ThinkingStatus.completed,
            );
            
            // Replace the thinking message with the error message
            widget.chatInstance.messages.removeLast();
            widget.chatInstance.messages.add(errorMessage);
          }
          
          _isWaitingForResponse = false;
        });
      }
    } else {
      // No files, just a simple echo response for demo
      setState(() {
        // widget.chatInstance.messages.add(ChatMessage(
        //   text: "我说: $message",
        //   isUser: false,
        // ));
        
        _isWaitingForResponse = false;
        
        // Force scroll to bottom after update
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToBottom();
        });
      });
    }
    
    // Update messages in the chat instance after all processing
    widget.onUpdateInstance(widget.chatInstance);
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      // Use a smoother curve and slightly longer duration for more comfortable animation
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    } else {
      // If the scroll controller isn't ready yet, try again after the frame is rendered
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    }
  }
  
  void _removeFile(int index) {
    if (index >= 0 && index < _selectedFiles.length) {
      setState(() {
        // Remove the file from the files list
        _selectedFiles.removeAt(index);
        
        // Update the chat instance in the parent widget
        _checkContent();
      });
    }
  }

  void _addDetectionResultMessage(List<DetectionResult> results) {
    if (results.isEmpty) return;

    // 创建检测数据对象
    DetectionData detectionData = DetectionData.withResults(
      results,
      _detectionType,
    );
    
    print('======== 添加检测结果消息 ========');
    print('检测结果数量: ${results.length}');
    print('检测数据ID: ${detectionData.id}');
    
    // 创建系统消息
    final resultMessage = ChatMessage(
      text: "检测完成，发现内容风险",
      isUser: false,  // 重要：这是系统消息
      thinkingStatus: ThinkingStatus.completed,
      detectionData: detectionData,
      detectionMode: _detectionMode, // Store the current detection mode
    );
    
    // 为了确保状态更新，在这里手动删除thinking消息并添加结果消息
    setState(() {
      // 移除正在思考的消息(如果有)
      if (widget.chatInstance.messages.isNotEmpty && 
          widget.chatInstance.messages.last.thinkingStatus == ThinkingStatus.thinking) {
        widget.chatInstance.messages.removeLast();
      }
      
      // 添加新的结果消息
      widget.chatInstance.messages.add(resultMessage);
      _isWaitingForResponse = false;
    });
    
    // 强制刷新UI
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {});
      _scrollToBottom();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Chat header and welcome message - only show if _showWelcomeMessage is true
            if (_showWelcomeMessage)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: AnimatedBuilder(
                  animation: _floatingController,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(0, _floatingAnimation.value),
                      child: FadeTransition(
                        opacity: _floatingController,
                        child: child,
                      ),
                    );
                  },
                  child: Column(
                    children: const [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '您好，我是',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'HarmonyOS_Sans',
                              color: Color.fromARGB(255, 0, 0, 0),
                            ),
                          ),
                          Text(
                            '全智卫安',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'HarmonyOS_Sans',
                              color: Color.fromARGB(255, 98, 0, 255),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      Text(
                        '我可以帮助您检测内容风险，例如诈骗短信、聊天记录、AI深度伪造等',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                          fontFamily: 'HarmonyOS_Sans',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
            // Chat messages display area
            if (_messages.isNotEmpty)
              Expanded(
                child: NotificationListener<ScrollNotification>(
                  onNotification: (notification) {
                    // Auto-scroll to bottom when new content is added and we're already near the bottom
                    if (notification is ScrollEndNotification) {
                      if (_scrollController.hasClients && 
                          _scrollController.position.pixels >= 
                          _scrollController.position.maxScrollExtent - 150) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          _scrollToBottom();
                        });
                      }
                    }
                    return false;
                  },
                  child: ListView.builder(
                    key: _listKey, // Associate the key with the list
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      // Apply animation only to the most recent message
                      final bool isNewestMessage = index == _messages.length - 1;
                      
                      return AnimatedBuilder(
                        animation: _floatingController,
                        builder: (context, child) {
                          // For new messages (most recent), don't apply horizontal slide animation
                          if (isNewestMessage) {
                            // 使用更快的曲线使淡入动画更加迅速
                            return FadeTransition(
                              opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                                CurvedAnimation(
                                  parent: _floatingController,
                                  curve: Curves.easeOutQuad
                                )
                              ),
                              child: child,
                            );
                          } 
                          // For existing messages, slide down when a new message is added
                          else {
                            // 减小移动距离并使用更快的曲线
                            final double offsetY = Tween<double>(begin: 12.0, end: 0.0).animate(
                              CurvedAnimation(
                                parent: _floatingController,
                                curve: Curves.easeOutQuad
                              )
                            ).value;
                            
                            return Transform.translate(
                              offset: Offset(0, offsetY),
                              child: child,
                            );
                          }
                        },
                        child: _buildMessageItem(message),
                      );
                    },
                  ),
                ),
              ),
              
            // Show spacer only if welcome message is visible and no messages yet
            if (_showWelcomeMessage && _messages.isEmpty)
              const Spacer(),
            
            // Input area
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.black12),
              ),
              margin: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Message input
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: TextField(
                      controller: _textController,
                      decoration: const InputDecoration(
                        hintText: '在此输入文本...',
                        border: InputBorder.none,
                        hintStyle: TextStyle(color: Colors.black38, fontFamily: 'HarmonyOS_Sans'),
                      ),
                      style: const TextStyle(fontFamily: 'HarmonyOS_Sans'),
                      minLines: 1,
                      maxLines: 5,
                    ),
                  ),
                  
                  // File attachments display area
                  if (_selectedFiles.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _selectedFiles.asMap().entries.map((entry) {
                          final index = entry.key;
                          final fileAttachment = entry.value;
                          final fileName = FileUtils.getFileName(fileAttachment.file.path);
                          
                          // Debug print messages
                          print('Rendering file chip: $fileName');
                          print('  - isUploading: ${fileAttachment.isUploading}');
                          print('  - isUploaded: ${fileAttachment.isUploaded}');
                          print('  - isError: ${fileAttachment.isError}');
                          print('  - status: ${fileAttachment.status}');
                          
                          return Chip(
                            avatar: SizedBox(
                              width: 24,
                              height: 24,
                              child: () {
                                // Using function call to ensure logic clarity
                                if (fileAttachment.status == FileUploadStatus.uploading) {
                                  return _buildUploadProgressIndicator(fileAttachment.uploadProgress);
                                } else if (fileAttachment.status == FileUploadStatus.error) {
                                  return const Icon(Icons.error_outline, size: 20, color: Colors.red);
                                } else if (fileAttachment.status == FileUploadStatus.completed) {
                                  // Ensure completed status shows file type icon
                                  return FileUtils.getFileIcon(fileAttachment.file, size: 20);
                                } else {
                                  // Other statuses (like pending)
                                  return FileUtils.getFileIcon(fileAttachment.file, size: 20);
                                }
                              }(),
                            ),
                            label: Text(fileName, style: const TextStyle(fontFamily: 'HarmonyOS_Sans')),
                            deleteIcon: const Icon(Icons.close, size: 16),
                            onDeleted: () => _removeFile(index),
                          );
                        }).toList(),
                      ),
                    ),
                  
                  // Mode selection buttons
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 12, 7),
                    child: Row(
                      children: [
                        // Detection Mode Toggle Button
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(
                              color: _detectionMode == 'PRECISE' 
                                  ? const Color.fromRGBO(1, 102, 255, 1) 
                                  : Colors.black12,
                              width: _detectionMode == 'PRECISE' ? 1.5 : 1,
                            ),
                          ),
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                // Toggle between FAST and PRECISE modes
                                _detectionMode = _detectionMode == 'FAST' ? 'PRECISE' : 'FAST';
                              });
                            },
                            borderRadius: BorderRadius.circular(15),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              child: Row(
                                children: [
                                  // Switch indicator
                                  Container(
                                    width: 16,
                                    height: 16,
                                    decoration: BoxDecoration(
                                      color: _detectionMode == 'PRECISE' 
                                          ? const Color.fromRGBO(1, 102, 255, 1) 
                                          : Colors.grey.shade400,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // Button text
                                  Text(
                                    '增强模式',
                                    style: TextStyle(
                                      color: _detectionMode == 'PRECISE' 
                                          ? const Color.fromRGBO(1, 102, 255, 1) 
                                          : Colors.black,
                                      fontFamily: 'HarmonyOS_Sans',
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        
                        // Add spacing between the button groups
                        const SizedBox(width: 12),
                        
                        // Detection Type Buttons
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(color: Colors.black12),
                          ),
                          child: Stack(
                            children: [
                              // Animated background indicator for detection type
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                                width: 82, // Width of a single button
                                height: 29, // Height of the buttons
                                margin: EdgeInsets.only(
                                  left: _detectionType == 'RISK' ? 0 : 82, // Move right for AI mode
                                ),
                                decoration: BoxDecoration(
                                  color: const Color.fromRGBO(1, 102, 255, 1),
                                  borderRadius: BorderRadius.circular(15),
                                ),
                              ),
                              // Detection type button row
                              Row(
                                children: [
                                  TextButton(
                                    onPressed: () {
                                      setState(() {
                                        _detectionType = 'RISK';
                                      });
                                    },
                                    style: TextButton.styleFrom(
                                      minimumSize: const Size(90, 36),
                                      padding: EdgeInsets.zero,
                                      backgroundColor: Colors.transparent,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: Text(
                                      '风险检测',
                                      style: TextStyle(
                                        color: _detectionType == 'RISK' ? Colors.white : Colors.black,
                                        fontFamily: 'HarmonyOS_Sans',
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      setState(() {
                                        _detectionType = 'AI';
                                      });
                                    },
                                    style: TextButton.styleFrom(
                                      minimumSize: const Size(90, 36),
                                      padding: EdgeInsets.zero,
                                      backgroundColor: Colors.transparent,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: Text(
                                      'AIGC检测',
                                      style: TextStyle(
                                        color: _detectionType == 'AI' ? Colors.white : Colors.black,
                                        fontFamily: 'HarmonyOS_Sans',
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        
                        const Spacer(),
                        // Send text helper
                        const Text(
                          '支持输入文本、上传文件、发送图片等。',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.black38,
                            fontFamily: 'HarmonyOS_Sans',
                          ),
                        ),
                        const SizedBox(width: 12),
                        // File attachment button
                        IconButton(
                          onPressed: _pickFile,
                          icon: const Icon(Icons.attach_file),
                          color: Colors.black54,
                          tooltip: '添加文件',
                        ),
                        const SizedBox(width: 8),
                        // Send or Pause button
                        _isWaitingForResponse
                          ? IconButton(
                              onPressed: () {
                                // Cancel response functionality
                              },
                              icon: Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.black54, width: 2),
                                ),
                                child: Center(
                                  child: Container(
                                    width: 8,
                                    height: 8,
                                    color: Colors.black54,
                                  ),
                                ),
                              ),
                              tooltip: '暂停',
                            )
                          : IconButton(
                              onPressed: _hasContent ? _sendMessage : null,
                              icon: Icon(Icons.send, color: _hasContent ? Color.fromRGBO(1, 102, 255, 1) : Colors.black38),
                              tooltip: '发送',
                            ),
                      ],
                    ),
                  ),
                ]
                ),
              ),
            
          ],
        ),
      ),
    );
  }
  
  // Helper method to build message item
  Widget _buildMessageItem(ChatMessage message) {
    print('=== u6784u5efau6d88u606fu9879 ===');
    print('u6d88u606fu7c7bu578b: ${message.isUser ? "u7528u6237u6d88u606f" : "u7cfbu7edfu6d88u606f"}');
    print('u662fu5426u5305u542bu68c0u6d4bu6570u636e: ${message.detectionData != null}');
    if (message.detectionData != null) {
      print('检测到消息有检测数据');
      print('检测数据: ID=${message.detectionData?.id ?? "无ID"}');
      print('结果数量: ${message.detectionData?.results.length ?? 0}');
    }
    
    // For thinking status messages, we render a special layout
    if (message.thinkingStatus != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 16.0), // Further reduced vertical padding
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                // System avatar
                Container(
                  width: 40,
                  height: 40,
                  margin: const EdgeInsets.only(right: 8.0),
                  decoration: BoxDecoration(
                    color: Colors.blue[100],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.android,
                      color: Colors.blue,
                    ),
                  ),
                ),
                // Thinking status indicator
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200, width: 1),
                  ),
                  child: Row(
                    children: [
                      // Animated icon based on thinking status
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        transitionBuilder: (Widget child, Animation<double> animation) {
                          return FadeTransition(
                            opacity: animation,
                            child: ScaleTransition(
                              scale: animation,
                              child: child,
                            ),
                          );
                        },
                        child: _buildThinkingStatusIcon(message.thinkingStatus!),
                      ),
                      const SizedBox(width: 8),
                      // Text based on thinking status
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: Text(
                          message.thinkingStatus == ThinkingStatus.thinking
                            ? "系统正在为您检测内容风险..."
                            : message.thinkingStatus == ThinkingStatus.completed
                              ? "检测完成"
                              : "已取消",
                          key: ValueKey<ThinkingStatus>(message.thinkingStatus!),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            // Add risk report card below when detection is completed and results are available
            if (message.thinkingStatus == ThinkingStatus.completed && 
                message.detectionData != null && 
                message.detectionData!.results.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8.0, left: 48.0),
                child: RiskReportCard(
                  detectionData: message.detectionData!,
                  detectionMode: message.detectionMode ?? 'FAST', // Use stored detection mode
                  onExpand: () {
                    // Ensure expanded content is visible by scrolling
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _scrollToBottom();
                    });
                  },
                ),
              ),
          ],
        ),
      );
    }

    // Regular message layout
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!message.isUser) // System avatar
            Container(
              width: 40,
              height: 40,
              margin: const EdgeInsets.only(right: 8.0),
              decoration: BoxDecoration(
                color: Colors.blue[100],
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Center(
                child: Icon(
                  Icons.android,
                  color: Colors.blue,
                ),
              ),
            ),
          Flexible(
            child: message.isUser
              ? ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: (MediaQuery.of(context).size.width - 80) * 0.4), // 限制用户消息宽度不超过中轴线
                  child: _buildMessageContent(message),
                )
              : _buildMessageContent(message),
          ),
          if (message.isUser) // User avatar
            Container(
              width: 40,
              height: 40,
              margin: const EdgeInsets.only(left: 8.0),
              decoration: BoxDecoration(
                color: Colors.blue[100],
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Center(
                child: Icon(
                  Icons.person,
                  color: Colors.blue,
                ),
              ),
            ),
        ],
      ),
    );
  }
  
  // Helper to build the thinking status icon with appropriate styling
  Widget _buildThinkingStatusIcon(ThinkingStatus status) {
    switch (status) {
      case ThinkingStatus.thinking:
        return SizedBox(
          key: const ValueKey('thinking'),
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(const Color.fromRGBO(1, 102, 255, 1)),
          ),
        );
      case ThinkingStatus.completed:
        return Container(
          key: const ValueKey('completed'),
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            color: Colors.green,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check,
            color: Colors.white,
            size: 12,
          ),
        );
      case ThinkingStatus.cancelled:
        return Container(
          key: const ValueKey('cancelled'),
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            color: Colors.red,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.close,
            color: Colors.white,
            size: 12,
          ),
        );
    }
  }
  
  Widget _buildMessageContent(ChatMessage message) {
    // 检查是否有检测结果，并打印调试信息
    if (message.detectionData != null) {
      print('检测到消息有检测数据');
      print('检测数据: ID=${message.detectionData?.id ?? "无ID"}');
      print('是否有结果: ${message.detectionData?.results.isNotEmpty}');
    }
    
    // 如果消息包含检测数据，先显示风险报告卡，再显示其他内容
    if (message.detectionData != null && message.detectionData!.results.isNotEmpty) {
      print('检测到有效的检测结果，显示风险报告卡');
      return Column(
        crossAxisAlignment: message.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          // 消息文本
          if (message.text.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: message.isUser ? const Color.fromRGBO(1, 102, 255, 0.2) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200, width: 1),
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  color: Colors.black87,
                ),
              ),
            ),
          
          // 风险报告卡
          Padding(
            padding: const EdgeInsets.only(top: 12.0),
            child: RiskReportCard(
              detectionData: message.detectionData!,
              detectionMode: message.detectionMode ?? 'FAST', // Use stored detection mode
              onExpand: () {
                // Ensure expanded content is visible by scrolling
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _scrollToBottom();
                });
              },
            ),
          ),
          
          // 文件附件
          if (message.files.isNotEmpty)
            Column(
              crossAxisAlignment: message.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (message.text.isNotEmpty)
                  const SizedBox(height: 8),
                ...message.files.map((file) {
                  return _buildFileAttachment(file, message.isUser);
                }).toList(),
              ],
            ),
        ],
      );
    }
    
    // 默认的消息内容布局
    return Column(
      crossAxisAlignment: message.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        // 消息文本
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: message.isUser ? const Color.fromRGBO(1, 102, 255, 0.2) : Colors.white, // 减淡颜色
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200, width: 1),
          ),
          child: Text(
            message.text,
            style: TextStyle(
              color: Colors.black87,
            ),
          ),
        ),
          
        // 文件附件
        if (message.files.isNotEmpty)
          Column(
            crossAxisAlignment: message.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              // Add spacing between message bubble and file attachments
              if (message.text.isNotEmpty)
                const SizedBox(height: 8), // 添加8像素的垂直间距
              ...message.files.map((file) {
                return _buildFileAttachment(file, message.isUser);
              }).toList(),
            ],
          ),

        // Timestamp
        Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Completed status icon if applicable
              if (!message.isUser && message.thinkingStatus == ThinkingStatus.completed)
                Padding(
                  padding: const EdgeInsets.only(right: 4.0),
                  child: _buildThinkingStatusIcon(message.thinkingStatus!),
                ),
              Text(
                _formatTimestamp(message.timestamp),
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  // Helper method to format timestamp
  String _formatTimestamp(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
  
  // Build circular progress indicator for file uploads
  Widget _buildUploadProgressIndicator(double progress) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // 使用CircularProgressIndicator.adaptive以获得平台特定的动画效果
        CircularProgressIndicator.adaptive(
          value: null, // 设置为null表示不确定进度，使旋转动画更加明显
          strokeWidth: 2,
          valueColor: const AlwaysStoppedAnimation<Color>(Color.fromRGBO(1, 102, 255, 1)),
          backgroundColor: Colors.grey.shade200,
        ),
        // 显示进度百分比
        if (progress > 0)
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            child: Text(
              '${(progress * 100).toInt()}%',
              style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
      ],
    );
  }
  
  // Helper method to build file attachment
  Widget _buildFileAttachment(FileAttachment file, bool isUser) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.black12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: () {
              // 在消息中的附件也使用相同的逻辑
              if (file.status == FileUploadStatus.uploading) {
                return _buildUploadProgressIndicator(file.uploadProgress);
              } else if (file.status == FileUploadStatus.error) {
                return const Icon(Icons.error_outline, size: 20, color: Colors.red);
              } else {
                // 已完成或其他状态
                return FileUtils.getFileIcon(file.file, size: 20);
              }
            }(),
          ),
          const SizedBox(width: 6),
          Text(
            FileUtils.getFileName(file.file.path),
            style: const TextStyle(
              fontSize: 12,
              fontFamily: 'HarmonyOS_Sans',
            ),
          ),
        ],
      ),
    );
  }
}
