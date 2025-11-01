# omniguard_ui

**请注意：**我们对工程进行了重构和整合，因此目前该仓库已经不再更新，新仓库请见：https://github.com/Blue16-WangFudi/omniguard
**Note**: This repository is no longer actively maintained due to project refactoring and consolidation. Please refer to the new repository at: https://github.com/Blue16-WangFudi/omniguard

“全智卫安——高效精准的多模态风险内容融合分析解决方案”是面向网络安全与内容治理领域的一项创新性人工智能系统，致力于解决当前风险识别技术在跨模态理解、可解释性与部署灵活性方面的核心痛点。项目依托华为云技术生态，融合MindSpore、ModelArts、IoTDA、LiteOS等核心技术，构建了一套集多模态识别、智能推理与边缘计算于一体的全栈式安全解决方案。

本作品创新性地提出三大核心技术：一是基于类MoE架构的多模态融合推理系统，整合DeepSeek、Qwen及Chain-of-Thought（CoT）技术，实现对文本、图像、音频、视频等多源数据的协同分析，完成“特征分解—类别判定—摘要生成”的三阶段深度语义挖掘；二是RuleMind多模态规则引擎，结合RAG实现动态规则检索，支持企业自定义风险策略，显著提升检测精度与结果可解释性；三是ElasticBrain弹性调度引擎，采用WebSocket RPC通信与可扩展任务队列，构建“一主多从”分布式架构，实现算力资源的高效调度与低成本私有化部署。

系统采用模块化设计，涵盖云端API服务、企业端管理平台、移动端应用及智能终端设备。企业端基于Flutter开发，支持多平台运行，提供风险检测、数据分析、模型调优等可视化功能；边缘端基于OrangePi与STM32搭建，集成LiteOS实现低功耗实时监测，已在高校实验室完成工业生产监控、会议安全检测等场景试点。项目采用开源模式，通过API调用、硬件销售与技术服务实现商业化落地，广泛适用于教育、政务、金融、安防等领域，助力构建可信、高效、智能的风险防控体系。

OmniGuard – An Efficient and Accurate Multimodal Risk Content Fusion Analysis Solution is an innovative AI system designed for cybersecurity and content governance. It addresses critical challenges in current risk detection technologies—particularly in cross-modal understanding, interpretability, and deployment flexibility. Built upon Huawei Cloud’s technology ecosystem, OmniGuard integrates core technologies such as MindSpore, ModelArts, IoTDA, and LiteOS to deliver a full-stack security solution that combines multimodal recognition, intelligent reasoning, and edge computing.

The project introduces three core innovations:

MoE-inspired Multimodal Fusion Reasoning System: Leveraging DeepSeek, Qwen, and Chain-of-Thought (CoT) techniques, this system enables collaborative analysis of multimodal data—including text, images, audio, and video—through a three-stage semantic pipeline: feature decomposition → category classification → summary generation.
RuleMind Multimodal Rule Engine: Enhanced with Retrieval-Augmented Generation (RAG), this engine supports dynamic rule retrieval and allows enterprises to define custom risk policies, significantly improving detection accuracy and result interpretability.
ElasticBrain Elastic Scheduling Engine: Built on WebSocket-based RPC communication and an extensible task queue, this engine implements a “one-master, multiple-workers” distributed architecture, enabling efficient compute resource scheduling and cost-effective private deployment.
The system adopts a modular design, encompassing cloud-based APIs, an enterprise management platform, a mobile application, and intelligent edge devices. The enterprise client is developed with Flutter for cross-platform compatibility, offering visualized functionalities such as risk detection, data analytics, and model fine-tuning. The edge devices are built on OrangePi and STM32 microcontrollers, integrated with LiteOS for low-power, real-time monitoring. Pilot deployments have already been successfully conducted in university labs for industrial production monitoring and meeting security scenarios.

OmniGuard follows an open-source model and achieves commercialization through API services, hardware sales, and technical support. It is widely applicable across education, government, finance, public safety, and other sectors, empowering the construction of a trustworthy, efficient, and intelligent risk prevention and control ecosystem.


