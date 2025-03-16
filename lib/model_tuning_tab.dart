import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ModelTuningTab extends StatefulWidget {
  @override
  State<ModelTuningTab> createState() => _ModelTuningTabState();
}

class _ModelTuningTabState extends State<ModelTuningTab> {
  // 选择模型训练方式
  String _selectedTrainingMethod = 'SFT';
  
  // 选择GPU服务器
  String _selectedServer = '服务器1';
  
  // 选择调优能力
  List<String> _selectedCapabilities = ['TEXT_FEATURE'];
  
  // 选择模型
  String _selectedModelType = '预置模型';
  
  // 训练方式
  String _selectedTrainingType = '高效训练';
  
  // 选择验证数据
  String _selectedValidationType = '自动切分';
  
  // 模型名称
  final TextEditingController _modelNameController = TextEditingController();
  
  @override
  void dispose() {
    _modelNameController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 选择模型训练方式
            const Text(
              '选择模型训练方式',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                fontFamily: 'HarmonyOS_Sans',
              ),
            ),
            const SizedBox(height: 16),
            _buildTrainingMethodCards(),
            const SizedBox(height: 40),
            
            // 选择GPU服务器
            const Text(
              '选择GPU服务器',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                fontFamily: 'HarmonyOS_Sans',
              ),
            ),
            const SizedBox(height: 16),
            _buildServerSelection(),
            const SizedBox(height: 40),
            
            // 选择调优能力
            const Text(
              '选择调优能力',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                fontFamily: 'HarmonyOS_Sans',
              ),
            ),
            const SizedBox(height: 16),
            _buildCapabilitiesSelection(),
            const SizedBox(height: 40),
            
            // 选择模型
            const Text(
              '选择模型',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                fontFamily: 'HarmonyOS_Sans',
              ),
            ),
            const SizedBox(height: 16),
            _buildModelTypeSelection(),
            const SizedBox(height: 16),
            _buildModelDropdown(),
            const SizedBox(height: 40),
            
            // 训练方式
            const Text(
              '训练方式',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                fontFamily: 'HarmonyOS_Sans',
              ),
            ),
            const SizedBox(height: 16),
            _buildTrainingTypeSelection(),
            const SizedBox(height: 40),
            
            // 模型名称
            const Text(
              '模型名称',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                fontFamily: 'HarmonyOS_Sans',
              ),
            ),
            const SizedBox(height: 16),
            _buildModelNameInput(),
            const SizedBox(height: 40),
            
            // 选择训练数据
            const Text(
              '选择训练数据',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                fontFamily: 'HarmonyOS_Sans',
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '请选择数据集版本，仅支持模型已发布的数据集版本。如无数据，请前往模型数据集导入或选择有数据集版本的模型',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontFamily: 'HarmonyOS_Sans',
              ),
            ),
            const SizedBox(height: 16),
            _buildDatasetDropdown(),
            const SizedBox(height: 40),
            
            // 选择验证数据
            const Text(
              '选择验证数据',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                fontFamily: 'HarmonyOS_Sans',
              ),
            ),
            const SizedBox(height: 16),
            _buildValidationSelection(),
            const SizedBox(height: 60),
            
            // 底部按钮
            _buildBottomButtons(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // 训练方式卡片
  Widget _buildTrainingMethodCards() {
    return Row(
      children: [
        Expanded(
          child: _buildMethodCard(
            'SFT微调训练',
            '有监督微调，增强模型拟合多领域能力，提供全参和高效训练方式',
            'SFT',
            Colors.indigo,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildMethodCard(
            'GRPO训练',
            '更加先进的强化学习算法，引入人类反馈，降低幻觉，使得模型输出更符合人类偏好',
            'GRPO',
            Colors.blue,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildMethodCard(
            'CPT继续预训练',
            '通过无标注让数据进行无监督预训练，强化或新增模型特定能力',
            'CPT',
            Colors.purple,
          ),
        ),
      ],
    );
  }

  // 单个训练方式卡片
  Widget _buildMethodCard(String title, String description, String value, Color accentColor) {
    final isSelected = _selectedTrainingMethod == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTrainingMethod = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? accentColor.withOpacity(0.5) : Colors.grey.shade200,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(8),
          color: isSelected ? accentColor.withOpacity(0.05) : Colors.white,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'HarmonyOS_Sans',
                  ),
                ),
                const Spacer(),
                Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? accentColor : Colors.grey.shade300,
                      width: 1,
                    ),
                    color: isSelected ? accentColor : Colors.transparent,
                  ),
                  child: isSelected
                      ? Icon(
                          Icons.check,
                          size: 12,
                          color: Colors.white,
                        )
                      : null,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontFamily: 'HarmonyOS_Sans',
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // 模型类型选择
  Widget _buildModelTypeSelection() {
    return Row(
      children: [
        _buildRadioOption('预置模型', '预置模型'),
        const SizedBox(width: 24),
        _buildRadioOption('自定义模型', '自定义模型'),
      ],
    );
  }

  // 单选框选项
  Widget _buildRadioOption(String label, String value, {String? groupValue}) {
    final currentGroup = groupValue ?? (
      value == '预置模型' || value == '自定义模型' ? _selectedModelType :
      value == '高效训练' || value == '全参训练' ? _selectedTrainingType :
      _selectedValidationType
    );
    
    return Row(
      children: [
        Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: currentGroup == value ? Color(0xFF6366F1) : Colors.grey.shade300,
              width: 2,
            ),
            color: Colors.white,
          ),
          child: currentGroup == value
              ? Center(
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFF6366F1),
                    ),
                  ),
                )
              : null,
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () {
            setState(() {
              if (value == '预置模型' || value == '自定义模型') {
                _selectedModelType = value;
              } else if (value == '高效训练' || value == '全参训练') {
                _selectedTrainingType = value;
              } else {
                _selectedValidationType = value;
              }
            });
          },
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade800,
              fontFamily: 'HarmonyOS_Sans',
            ),
          ),
        ),
      ],
    );
  }

  // 模型下拉选择
  Widget _buildModelDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                hint: const Text('请选择'),
                value: null,
                isExpanded: true,
                icon: const Icon(Icons.keyboard_arrow_down),
                style: TextStyle(color: Colors.grey.shade800, fontSize: 14),
                onChanged: (String? newValue) {
                  // 下拉选择逻辑
                },
                items: const [],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 训练类型选择
  Widget _buildTrainingTypeSelection() {
    return Row(
      children: [
        _buildRadioOption('高效训练', '高效训练'),
        const SizedBox(width: 24),
        _buildRadioOption('全参训练', '全参训练'),
      ],
    );
  }

  // 模型名称输入
  Widget _buildModelNameInput() {
    return TextFormField(
      controller: _modelNameController,
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: Color(0xFF6366F1)),
        ),
        suffixText: '0/50',
        suffixStyle: TextStyle(color: Colors.grey.shade500, fontSize: 12),
      ),
      onChanged: (text) {
        setState(() {
          // 更新字符计数
        });
      },
      maxLength: 50,
      maxLengthEnforcement: MaxLengthEnforcement.enforced,
      buildCounter: (context, {required currentLength, required isFocused, maxLength}) {
        return null; // 隐藏默认计数器
      },
    );
  }

  // GPU服务器选择
  Widget _buildServerSelection() {
    final servers = ['服务器1', '服务器2', '服务器3', '服务器4'];
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedServer,
                isExpanded: true,
                icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey.shade600),
                style: TextStyle(
                  color: Colors.grey.shade800, 
                  fontSize: 14,
                  fontFamily: 'HarmonyOS_Sans',
                ),
                dropdownColor: Colors.white,
                borderRadius: BorderRadius.circular(8),
                elevation: 2,
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedServer = newValue;
                    });
                  }
                },
                items: servers.map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(
                      value,
                      style: const TextStyle(
                        fontFamily: 'HarmonyOS_Sans',
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 调优能力选择
  Widget _buildCapabilitiesSelection() {
    final capabilities = [
      'TEXT_FEATURE', 
      'IMAGE_FEATURE', 
      'AUDIO_FEATURE', 
      'VIDEO_FEATURE', 
      'PRECISE_DETECTION', 
      'FAST_DETECTION', 
      'REPORT_GENERATOR'
    ];

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(4),
      ),
      padding: const EdgeInsets.all(12),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: capabilities.map((capability) {
          final isSelected = _selectedCapabilities.contains(capability);
          return GestureDetector(
            onTap: () {
              setState(() {
                if (isSelected) {
                  _selectedCapabilities.remove(capability);
                } else {
                  _selectedCapabilities.add(capability);
                }
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF6366F1).withOpacity(0.1) : Colors.white,
                border: Border.all(
                  color: isSelected ? const Color(0xFF6366F1) : Colors.grey.shade300,
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isSelected) ...[
                    const Icon(
                      Icons.check,
                      size: 16,
                      color: Color(0xFF6366F1),
                    ),
                    const SizedBox(width: 4),
                  ],
                  Text(
                    capability,
                    style: TextStyle(
                      fontSize: 14,
                      color: isSelected ? const Color(0xFF6366F1) : Colors.grey.shade700,
                      fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // 数据集下拉选择
  Widget _buildDatasetDropdown() {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade200),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      hint: const Text('请选择'),
                      value: null,
                      isExpanded: true,
                      icon: const Icon(Icons.keyboard_arrow_down),
                      style: TextStyle(color: Colors.grey.shade800, fontSize: 14),
                      onChanged: (String? newValue) {
                        // 下拉选择逻辑
                      },
                      items: const [],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        OutlinedButton(
          onPressed: () {
            // 管理训练集逻辑
          },
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            side: BorderSide(color: Colors.indigo.shade400),
            foregroundColor: Colors.indigo.shade400,
          ),
          child: const Text('管理训练集'),
        ),
      ],
    );
  }

  // 验证选择
  Widget _buildValidationSelection() {
    return Row(
      children: [
        _buildRadioOption('自动切分', '自动切分'),
        const SizedBox(width: 24),
        _buildRadioOption('选择验证集', '选择验证集'),
      ],
    );
  }

  // 底部按钮
  Widget _buildBottomButtons() {
    return Row(
      children: [
        ElevatedButton(
          onPressed: () {
            // 开始训练逻辑
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6366F1),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            textStyle: const TextStyle(fontSize: 14),
          ),
          child: const Text('开始训练'),
        ),
        const SizedBox(width: 16),
        TextButton(
          onPressed: () {
            // 取消逻辑
          },
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            foregroundColor: Colors.grey.shade700,
            textStyle: const TextStyle(fontSize: 14),
          ),
          child: const Text('取消'),
        ),
      ],
    );
  }
}
