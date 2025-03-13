import 'package:flutter/material.dart';
import 'left_panel.dart';
import 'right_panel.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';

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
  final TextEditingController _textController = TextEditingController();
  List<File> _selectedFiles = [];
  bool _hasContent = false;

  @override
  void initState() {
    super.initState();
    _textController.addListener(_checkContent);
  }

  @override
  void dispose() {
    _textController.removeListener(_checkContent);
    _textController.dispose();
    super.dispose();
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
              _selectedFiles.add(File(path));
            }
          }
          _checkContent();
        });
      }
    } catch (e) {
      // Fallback for demonstration
      setState(() {
        _selectedFiles.add(File('dummy_file.txt'));
        _checkContent();
      });
    }
  }

  void _removeFile(int index) {
    setState(() {
      _selectedFiles.removeAt(index);
      _checkContent();
    });
  }

  void _sendMessage() {
    if (!_hasContent) return;
    
    // Handle sending message and files here
    print('Sending message: ${_textController.text}');
    print('Sending files: ${_selectedFiles.length}');
    
    // Clear content after sending
    setState(() {
      _textController.clear();
      _selectedFiles.clear();
      _hasContent = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Left panel with logo and buttons
          Container(
            width: 240,
            color: const Color(0xFFF5F7FA),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Logo
                Padding(
                  padding: const EdgeInsets.only(bottom: 40),
                  child: Row(
                    children: [
                      Image.asset('assets/logo.png', width: 36, height: 36,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 36,
                            height: 36,
                            color: Colors.blue,
                            child: const Icon(Icons.shield, color: Colors.white),
                          );
                        },
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        '全智卫安',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // New task button
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('新建识别任务'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade50,
                    foregroundColor: Colors.blue,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                
                const Spacer(),
                
                // Control panel button at bottom
                TextButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.dashboard_outlined, size: 16),
                  label: const Text('控制台'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          
          // Right panel with chat interface
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Chat header and welcome message
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Column(
                      children: [
                        Text(
                          '你好，我是全智卫安',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 12),
                        Text(
                          '我可以识别各类风险隐私内容，你知道吗？AI深度协助。',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const Spacer(),
                  
                  // Input area
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
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
                              hintStyle: TextStyle(color: Colors.black38),
                            ),
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
                                final file = entry.value;
                                final fileName = file.path.split('/').last;
                                return Chip(
                                  label: Text(fileName),
                                  deleteIcon: const Icon(Icons.close, size: 16),
                                  onDeleted: () => _removeFile(entry.key),
                                );
                              }).toList(),
                            ),
                          ),
                        
                        // Actions bar
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              // File attachment button
                              IconButton(
                                onPressed: _pickFile,
                                icon: const Icon(Icons.attach_file),
                                color: Colors.black54,
                                tooltip: '添加文件',
                              ),
                              const Spacer(),
                              // Send text helper
                              const Text(
                                '支持输入文字、上传图片、音频、视频、文档等',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.black38,
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Send button
                              IconButton(
                                onPressed: _hasContent ? _sendMessage : null,
                                icon: const Icon(Icons.send),
                                color: _hasContent ? const Color.fromRGBO(1, 102, 255, 1) : Colors.black38,
                                tooltip: '发送',
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}