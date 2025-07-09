# MCP (Model Context Protocol) 协议集成配置

## 🔗 MCP服务器详细配置

### Context7服务器
```yaml
服务器标识: mcp__context7__*
核心工具:
  resolve-library-id:
    功能: 解析库标识符和版本信息
    触发条件: 
      - 导入错误: "ModuleNotFoundError"
      - 库查询: 用户询问特定库/框架
      - API集成: 需要官方文档时
      - 版本兼容: 版本冲突问题
    输入参数:
      - library: 库名称
      - version: 版本范围或"latest"
      - ecosystem: npm/pip/cargo/go等
    输出结果:
      - 标准库ID
      - 版本信息
      - 依赖关系
      - 官方文档链接

  get-library-docs:
    功能: 获取官方文档和代码示例
    触发条件:
      - API文档查询
      - 使用示例请求
      - 最佳实践查询
    输入参数:
      - library_id: 标准库标识
      - module: 功能模块名
      - doc_type: api_reference/tutorial/examples
    输出结果:
      - 官方文档内容
      - 代码示例
      - API参考
      - 最佳实践建议

  version-specific:
    功能: 获取特定版本的文档和迁移指南
    触发条件:
      - 版本兼容性查询
      - 升级迁移需求
      - 变更日志查询
    输入参数:
      - library: 库名称
      - from_version: 源版本
      - to_version: 目标版本
    输出结果:
      - 迁移指南
      - 破坏性变更
      - 兼容性信息
      - 升级建议

自动触发示例:
  错误驱动:
    - "Cannot resolve module 'react-router-dom'" → resolve-library-id
    - "useNavigate is not a function" → get-library-docs
    - "Warning: componentWillMount is deprecated" → version-specific
  
  查询驱动:
    - "React Router v6怎么用？" → resolve-library-id + get-library-docs
    - "从Vue 2升级到Vue 3" → version-specific
    - "Next.js的API路由" → get-library-docs
```

### Sequential服务器
```yaml
服务器标识: mcp__sequential-thinking__*
核心工具:
  analyze-problem:
    功能: 深度问题分析和分解
    触发条件:
      - 复杂问题描述
      - 多步骤任务
      - 系统设计需求
      - 架构规划
    输入参数:
      - problem: 问题描述
      - context: 上下文信息
      - constraints: 约束条件
      - goals: 目标要求
    输出结果:
      - 问题分解树
      - 依赖关系图
      - 优先级排序
      - 风险评估

  generate-solution-steps:
    功能: 生成详细的解决方案步骤
    触发条件:
      - 需要实施步骤
      - 复杂流程设计
      - 项目规划
    输入参数:
      - analysis_result: 问题分析结果
      - target: 目标要求
      - resources: 资源约束
      - timeline: 时间限制
    输出结果:
      - 详细步骤序列
      - 检查点设置
      - 风险缓解措施
      - 成功标准

  validate-logic:
    功能: 验证逻辑一致性
    触发条件:
      - 方案检查需求
      - 逻辑验证
      - 一致性确认
    输入参数:
      - solution: 解决方案
      - logic_chain: 逻辑链
      - validation_rules: 验证规则
    输出结果:
      - 验证报告
      - 逻辑漏洞
      - 改进建议
      - 一致性评分

  optimize-approach:
    功能: 优化解决方案
    触发条件:
      - 性能优化需求
      - 效率提升
      - 资源优化
    输入参数:
      - current_solution: 当前方案
      - optimization_goals: 优化目标
      - constraints: 约束条件
    输出结果:
      - 优化建议
      - 改进方案
      - 效果预测
      - 实施建议

智能触发关键词:
  - "如何设计" → analyze-problem + generate-solution-steps
  - "为什么" → analyze-problem + validate-logic
  - "优化" → analyze-problem + optimize-approach
  - "步骤" → generate-solution-steps
  - "检查" → validate-logic
```

### Magic服务器
```yaml
服务器标识: mcp__magic__*
核心工具:
  component-builder:
    功能: 生成UI组件
    触发条件:
      - UI组件需求
      - React/Vue组件创建
      - 组件库开发
    输入参数:
      - component_type: 组件类型
      - framework: React/Vue/Angular
      - features: 功能特性列表
      - styling: 样式系统
    输出结果:
      - 完整组件代码
      - 类型定义
      - 样式文件
      - 使用示例

  component-refiner:
    功能: 优化组件代码
    触发条件:
      - 组件优化需求
      - 代码重构
      - 性能提升
    输入参数:
      - component_code: 现有组件代码
      - optimization_goals: 优化目标
      - constraints: 约束条件
    输出结果:
      - 优化后的代码
      - 性能改进说明
      - 最佳实践应用
      - 测试建议

  component-inspiration:
    功能: 获取设计灵感
    触发条件:
      - 设计灵感需求
      - UI模式查询
      - 组件参考
    输入参数:
      - component_type: 组件类型
      - design_style: 设计风格
      - use_case: 使用场景
    输出结果:
      - 设计参考
      - 实现建议
      - 最佳实践
      - 相关资源

  logo-search:
    功能: 搜索logo和图标
    触发条件:
      - 图标需求
      - Logo设计
      - 视觉元素查找
    输入参数:
      - search_terms: 搜索关键词
      - style: 图标风格
      - format: 文件格式
    输出结果:
      - 图标资源
      - 使用许可
      - 下载链接
      - 使用建议

自动触发场景:
  - "创建登录组件" → component-builder
  - "优化这个组件" → component-refiner
  - "需要一个按钮设计" → component-inspiration
  - "找个图标" → logo-search
```

### Puppeteer服务器
```yaml
服务器标识: mcp__puppeteer__*
核心工具:
  browser-connect:
    功能: 连接浏览器实例
    触发条件:
      - 浏览器自动化需求
      - 测试执行
      - 页面操作
    输入参数:
      - headless: 无头模式
      - viewport: 视窗大小
      - user_agent: 用户代理
      - proxy: 代理设置
    输出结果:
      - 浏览器实例
      - 连接状态
      - 会话信息
      - 配置确认

  navigation:
    功能: 页面导航和操作
    触发条件:
      - 页面访问
      - URL跳转
      - 页面交互
    输入参数:
      - url: 目标URL
      - wait_until: 等待条件
      - timeout: 超时设置
      - actions: 操作序列
    输出结果:
      - 页面状态
      - 加载时间
      - 错误信息
      - 操作结果

  testing:
    功能: 自动化测试执行
    触发条件:
      - 功能测试
      - 用户流程验证
      - 回归测试
    输入参数:
      - test_type: 测试类型
      - test_steps: 测试步骤
      - assertions: 断言条件
      - test_data: 测试数据
    输出结果:
      - 测试结果
      - 执行日志
      - 错误详情
      - 性能数据

  screenshots:
    功能: 截图和视觉验证
    触发条件:
      - 视觉测试
      - UI验证
      - 页面记录
    输入参数:
      - capture_area: 截图区域
      - file_format: 文件格式
      - quality: 图片质量
      - comparison: 对比基准
    输出结果:
      - 截图文件
      - 元数据信息
      - 对比结果
      - 差异分析

  performance-monitoring:
    功能: 性能监控和分析
    触发条件:
      - 性能测试
      - 加载时间监控
      - 资源分析
    输入参数:
      - metrics: 监控指标
      - sampling_rate: 采样频率
      - report_format: 报告格式
    输出结果:
      - 性能数据
      - 分析报告
      - 优化建议
      - 基准对比

智能触发关键词:
  - "测试" → browser-connect + testing
  - "检查页面" → browser-connect + navigation + screenshots
  - "性能" → browser-connect + performance-monitoring
  - "截图" → browser-connect + screenshots
```

### Memory服务器
```yaml
服务器标识: mcp__memory__*
核心工具:
  store-memory:
    功能: 存储重要信息到记忆系统
    触发条件:
      - 用户明确要求记住某些信息
      - 重要的项目配置和设置
      - 成功的解决方案和最佳实践
      - 用户偏好和习惯模式
    输入参数:
      - content: 要存储的内容
      - category: 记忆分类(project/preference/solution/knowledge)
      - importance: 重要性级别(1-10)
      - tags: 标签列表
      - context: 上下文信息
    输出结果:
      - memory_id: 记忆唯一标识
      - storage_status: 存储状态
      - retrieval_keys: 检索关键词
      - expiry_info: 过期信息

  retrieve-memory:
    功能: 从记忆系统检索相关信息
    触发条件:
      - 用户询问之前讨论过的内容
      - 需要项目历史信息
      - 查找相似问题的解决方案
      - 获取用户偏好设置
    输入参数:
      - query: 查询关键词
      - category: 记忆分类过滤
      - time_range: 时间范围
      - similarity_threshold: 相似度阈值
    输出结果:
      - memories: 匹配的记忆列表
      - relevance_scores: 相关性评分
      - context_info: 上下文信息
      - suggestions: 相关建议

  update-memory:
    功能: 更新已存储的记忆信息
    触发条件:
      - 信息发生变化需要更新
      - 用户纠正之前的信息
      - 增加新的相关信息
    输入参数:
      - memory_id: 记忆标识
      - updates: 更新内容
      - merge_strategy: 合并策略
    输出结果:
      - update_status: 更新状态
      - new_version: 新版本信息
      - change_summary: 变更摘要

  forget-memory:
    功能: 删除或淡化特定记忆
    触发条件:
      - 用户要求删除某些信息
      - 过时信息的自动清理
      - 隐私保护需求
    输入参数:
      - memory_id: 记忆标识或查询条件
      - forget_type: 删除类型(hard_delete/soft_delete/fade)
      - reason: 删除原因
    输出结果:
      - forget_status: 删除状态
      - affected_memories: 受影响的记忆
      - backup_info: 备份信息

自动触发场景:
  - "记住这个配置" → store-memory
  - "之前我们讨论过什么？" → retrieve-memory
  - "更新项目信息" → update-memory
  - "忘记这个设置" → forget-memory
```

### Time服务器
```yaml
服务器标识: mcp__time__*
核心工具:
  schedule-task:
    功能: 安排任务和设置提醒
    触发条件:
      - 用户需要安排开发任务
      - 设置项目里程碑
      - 创建定期提醒
      - 规划学习计划
    输入参数:
      - task_name: 任务名称
      - description: 任务描述
      - due_date: 截止时间
      - priority: 优先级
      - recurrence: 重复规则
      - reminders: 提醒设置
    输出结果:
      - task_id: 任务唯一标识
      - schedule_status: 调度状态
      - next_reminder: 下次提醒时间
      - calendar_entry: 日历条目

  track-time:
    功能: 跟踪时间使用和工作进度
    触发条件:
      - 开始工作会话
      - 跟踪项目时间
      - 分析时间使用模式
    输入参数:
      - activity: 活动类型
      - project: 项目名称
      - start_time: 开始时间
      - tags: 活动标签
    输出结果:
      - session_id: 会话标识
      - tracking_status: 跟踪状态
      - elapsed_time: 已用时间
      - productivity_metrics: 生产力指标

  analyze-time:
    功能: 分析时间使用模式和效率
    触发条件:
      - 查看时间使用报告
      - 分析工作效率
      - 优化时间分配
    输入参数:
      - time_range: 分析时间范围
      - granularity: 分析粒度(day/week/month)
      - metrics: 分析指标
    输出结果:
      - time_report: 时间使用报告
      - efficiency_analysis: 效率分析
      - recommendations: 优化建议
      - trends: 趋势分析

  set-reminder:
    功能: 设置智能提醒和通知
    触发条件:
      - 需要定时提醒
      - 重要事件通知
      - 习惯养成提醒
    输入参数:
      - reminder_type: 提醒类型
      - trigger_condition: 触发条件
      - message: 提醒消息
      - frequency: 提醒频率
    输出结果:
      - reminder_id: 提醒标识
      - activation_status: 激活状态
      - next_trigger: 下次触发时间
      - delivery_method: 提醒方式

智能触发关键词:
  - "安排任务" → schedule-task
  - "开始计时" → track-time
  - "时间报告" → analyze-time
  - "提醒我" → set-reminder
```

## 🔄 工具协作模式

### 多工具协同调用
```yaml
架构设计场景:
  Sequential(问题分析) → Context7(最佳实践) → Magic(原型生成) → Puppeteer(功能验证) → Memory(记录方案)

功能开发场景:
  Memory(检索历史) → Context7(API文档) → Magic(组件生成) → Sequential(逻辑优化) → Puppeteer(测试验证) → Memory(存储结果)

问题调试场景:
  Memory(查找相似问题) → Sequential(问题分析) → Context7(解决方案) → Puppeteer(验证修复) → Memory(记录解决方案)

性能优化场景:
  Time(性能基线) → Sequential(性能分析) → Puppeteer(性能监控) → Context7(优化方案) → Puppeteer(效果验证) → Memory(记录优化)

项目管理场景:
  Time(任务规划) → Sequential(任务分解) → Memory(进度跟踪) → Time(提醒管理) → Memory(经验总结)

学习进度场景:
  Memory(学习历史) → Context7(学习资源) → Sequential(学习路径) → Magic(实践项目) → Time(学习计划) → Memory(知识记录)

团队协作场景:
  Memory(团队偏好) → Time(会议安排) → Sequential(任务分配) → Context7(标准规范) → Memory(协作记录)
```

## ⚙️ 配置选项

### 用户控制标志
```yaml
工具控制:
  --c7: 启用Context7文档查询
  --seq: 启用Sequential深度分析
  --magic: 启用Magic组件生成
  --pup: 启用Puppeteer自动化
  --memory: 启用Memory记忆管理
  --time: 启用Time时间管理
  --all-mcp: 启用所有MCP工具
  --no-mcp: 禁用MCP工具，使用原生功能

组合使用:
  --seq --c7: 深度分析 + 文档查询
  --magic --pup: 组件生成 + 自动化测试
  --memory --time: 记忆管理 + 时间跟踪
  --seq --memory: 深度分析 + 经验记录
  --time --memory: 时间管理 + 进度记忆
  --all-mcp: 全功能协作模式
```

### 智能默认行为
```yaml
自动选择策略:
  - 根据用户意图自动选择最佳工具组合
  - 基于历史使用模式优化工具调用
  - 根据任务复杂度动态调整参与度
  - 通过用户反馈持续改进选择算法

错误处理:
  - 工具调用失败时的智能回退
  - 网络问题的自动重试机制
  - 参数错误的自动调整
  - 超时问题的策略优化
```
