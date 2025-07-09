# AnyRules 智能上下文工程系统

## 系统概述

AnyRules是一个AI驱动的智能上下文工程系统，通过深度语义理解和智能推理，能够根据用户的具体需求和项目特征，自主调取相应的专业规则文档，提供精准的开发指导和建议。

## 项目结构

```
.context/
├── personas/               # 专家人格规则 (12个专家)
│   ├── architect.md        # 架构师专家
│   ├── frontend.md         # 前端专家
│   ├── backend.md          # 后端专家
│   ├── security.md         # 安全专家
│   ├── analyzer.md         # 分析师专家
│   ├── qa.md              # QA专家
│   ├── algorithm.md        # 算法专家
│   ├── devops.md          # DevOps专家
│   ├── datascience.md     # 数据科学专家
│   ├── mobile.md          # 移动开发专家
│   ├── cloud.md           # 云架构专家
│   └── product.md         # 产品管理专家
├── languages/              # 编程语言规则 (13种语言)
│   ├── typescript.md       # TypeScript开发规范
│   ├── javascript.md       # JavaScript规范
│   ├── python.md          # Python开发规范
│   ├── rust.md            # Rust开发规范
│   ├── go.md              # Go语言开发规范
│   ├── java.md            # Java开发规范
│   ├── cpp.md             # C++开发规范
│   ├── swift.md           # Swift开发规范
│   ├── kotlin.md          # Kotlin开发规范
│   ├── csharp.md          # C#开发规范
│   ├── php.md             # PHP开发规范
│   ├── ruby.md            # Ruby开发规范
│   └── dart.md            # Dart开发规范
├── tools/                 # 工具专用规则 (9个工具)
│   ├── react.md           # React框架规则
│   ├── vue.md             # Vue.js框架规则
│   ├── nextjs.md          # Next.js框架规则
│   ├── nodejs.md          # Node.js后端规则
│   ├── docker.md          # Docker容器化规则
│   ├── kubernetes.md      # Kubernetes编排规则
│   ├── postgresql.md      # PostgreSQL数据库规则
│   ├── git.md             # Git工作流规则
│   └── testing.md         # 测试策略规则
├── workflows/             # 工作流程规则 (4个流程)
│   ├── development.md     # 开发流程
│   ├── debugging.md       # 调试流程
│   ├── deployment.md      # 部署流程
│   └── code-review.md     # 代码审查流程
├── patterns/              # 设计模式规则 (2个模式集)
│   ├── architecture.md    # 架构模式
│   └── design-patterns.md # 设计模式
├── ai-config/             # AI配置规则 (11个配置)
│   ├── intent-recognition.md        # 意图识别
│   ├── expert-collaboration.md      # 专家协作
│   ├── knowledge-fusion.md          # 知识融合
│   ├── dynamic-role-management.md   # 动态角色管理
│   ├── collaboration-workflows.md   # 协作工作流
│   ├── intelligent-recommendation.md # 智能推荐
│   ├── adaptive-learning.md         # 自适应学习
│   ├── quality-assessment.md        # 质量评估
│   ├── user-behavior-analysis.md    # 用户行为分析
│   ├── performance-dashboard.md     # 性能仪表板
│   └── mcp-protocol.md             # MCP协议支持
└── scripts/               # 实用脚本工具 (8个脚本)
    ├── init-react-project.sh       # React项目初始化
    ├── init-node-api.sh           # Node.js API初始化
    ├── deploy-docker.sh           # Docker部署脚本
    ├── code-quality-check.sh      # 代码质量检查
    ├── backup-database.sh         # 数据库备份
    ├── system-monitor.py          # 系统监控
    ├── log-analyzer.py            # 日志分析
    └── load-test.py               # 负载测试
```

## 智能感知机制

### 关键词触发
系统会根据用户输入的关键词自动识别需要调取的规则文档：

```yaml
性能优化: personas/analyzer.md + personas/backend.md
React组件: personas/frontend.md + tools/react.md + languages/typescript.md
Vue应用: personas/frontend.md + tools/vue.md + languages/typescript.md
Next.js项目: personas/frontend.md + tools/nextjs.md + languages/typescript.md
API设计: personas/backend.md + personas/architect.md + workflows/development.md
数据库优化: personas/backend.md + tools/postgresql.md + personas/analyzer.md
安全审计: personas/security.md + personas/analyzer.md
测试策略: personas/qa.md + tools/testing.md
部署流程: workflows/deployment.md + tools/docker.md + tools/kubernetes.md
机器学习: personas/algorithm.md + languages/python.md
代码审查: workflows/code-review.md + personas/qa.md
Java开发: languages/java.md + 相关框架规则
C++优化: languages/cpp.md + personas/algorithm.md
```

### 技术栈检测
根据文件扩展名和项目配置自动识别技术栈：

```yaml
.ts/.tsx: languages/typescript.md + tools/react.md
.vue: tools/vue.md + languages/typescript.md
.py: languages/python.md + 相关框架规则
.js/.jsx: languages/javascript.md + tools/nodejs.md
.rs: languages/rust.md + 相关工具规则
.go: languages/go.md + 相关工具规则
.java: languages/java.md + 相关框架规则
.cpp/.hpp: languages/cpp.md + 相关工具规则
package.json: tools/nodejs.md + languages/javascript.md
pom.xml: languages/java.md + 相关工具规则
CMakeLists.txt: languages/cpp.md + 相关工具规则
Cargo.toml: languages/rust.md
go.mod: languages/go.md
docker-compose.yml: tools/docker.md + workflows/deployment.md
kubernetes/: tools/kubernetes.md + workflows/deployment.md
```

### 任务类型识别
自动判断任务类型并调取相应的工作流程：

```yaml
开发任务: workflows/development.md + 相关技术栈规则
调试任务: workflows/debugging.md + personas/analyzer.md
测试任务: tools/testing.md + personas/qa.md
部署任务: workflows/deployment.md + tools/docker.md + tools/kubernetes.md
代码审查: workflows/code-review.md + personas/qa.md
安全审查: personas/security.md + 相关技术规则
算法优化: personas/algorithm.md + 相关语言规则
```

## 专家协作矩阵

不同专家人格之间的协作模式：

| 主导专家 | 协作专家 | 适用场景 |
|---------|---------|---------|
| 架构师 | 后端专家 + 安全专家 | 系统架构设计 |
| 前端专家 | QA专家 + 安全专家 | 用户界面开发 |
| 后端专家 | 安全专家 + 分析师 | API和服务开发 |
| 算法专家 | 分析师 + 后端专家 | 算法优化和机器学习 |
| 数据科学专家 | 算法专家 + 分析师 | 数据分析和建模 |
| 移动开发专家 | 前端专家 + QA专家 | 移动应用开发 |
| 云架构专家 | DevOps专家 + 安全专家 | 云原生架构设计 |
| DevOps专家 | 后端专家 + 安全专家 | CI/CD和运维自动化 |
| 分析师 | 架构师 + 后端专家 | 性能优化 |
| QA专家 | 所有专家 | 质量保证和代码审查 |
| 安全专家 | 所有专家 | 安全审查 |
| 产品管理专家 | 前端专家 + QA专家 | 产品需求和用户体验 |

## 使用示例

### 示例1: React性能优化
**用户输入**: "帮我优化这个React组件的性能"

**系统响应**:
1. **识别**: "优化" + "React" + "性能"
2. **调取规则**:
   - `personas/analyzer.md` (性能分析专家)
   - `personas/frontend.md` (前端专家)
   - `tools/react.md` (React最佳实践)
   - `languages/typescript.md` (如果是TS项目)
3. **融合执行**: 基于多个专业规则提供综合优化建议

### 示例2: 微服务架构设计
**用户输入**: "设计一个微服务架构来处理用户订单系统"

**系统响应**:
1. **识别**: "设计" + "微服务架构" + "系统"
2. **调取规则**:
   - `personas/architect.md` (架构师专家)
   - `personas/backend.md` (后端专家)
   - `personas/security.md` (安全考虑)
   - `patterns/architecture.md` (架构模式)
   - `workflows/development.md` (开发流程)
3. **协作执行**: 多人格协作提供完整架构方案

### 示例3: CI/CD流水线搭建
**用户输入**: "搭建一个完整的CI/CD部署流水线"

**系统响应**:
1. **识别**: "CI/CD" + "部署" + "流水线"
2. **调取规则**:
   - `workflows/deployment.md` (部署流程)
   - `tools/docker.md` (容器化)
   - `tools/testing.md` (测试策略)
   - `tools/git.md` (版本控制)
   - `personas/security.md` (安全考虑)
3. **系统化执行**: 提供完整的CI/CD解决方案

## 文档内容概览

### 专家人格文档特色
- **架构师**: 系统设计、技术选型、架构模式
- **前端专家**: React/Vue开发、性能优化、用户体验
- **后端专家**: API设计、数据库优化、微服务架构
- **算法专家**: 机器学习、深度学习、算法优化、数据结构
- **安全专家**: 安全防护、合规检查、漏洞修复
- **分析师**: 性能分析、问题诊断、数据洞察
- **QA专家**: 测试策略、质量保证、代码审查
- **DevOps专家**: CI/CD流水线、容器化部署、运维自动化
- **数据科学专家**: 数据分析、机器学习建模、统计分析
- **移动开发专家**: iOS/Android开发、跨平台解决方案
- **云架构专家**: 云原生架构、微服务治理、分布式系统
- **产品管理专家**: 需求分析、产品规划、用户体验设计

### 编程语言文档特色
- **TypeScript**: 类型系统、高级特性、最佳实践
- **JavaScript**: ES6+特性、异步编程、性能优化
- **Python**: 现代特性、异步编程、数据处理、机器学习
- **Java**: Spring Boot、企业级开发、JVM优化
- **C++**: 现代C++、性能优化、系统编程
- **Rust**: 所有权系统、并发安全、性能优化
- **Go**: 并发编程、微服务开发、性能优化
- **Swift**: iOS开发、SwiftUI、性能优化
- **Kotlin**: Android开发、多平台开发、协程
- **C#**: .NET开发、异步编程、企业应用
- **PHP**: 现代PHP、Laravel框架、Web开发
- **Ruby**: Rails框架、元编程、Web开发
- **Dart**: Flutter开发、异步编程、跨平台

### 工具框架文档特色
- **React**: 组件设计、状态管理、性能优化
- **Vue.js**: 组合式API、响应式系统、生态集成
- **Next.js**: 全栈React框架、SSR/SSG、性能优化
- **Node.js**: 服务端开发、API设计、性能调优
- **Docker**: 容器化、部署策略、安全配置
- **Kubernetes**: 容器编排、服务网格、云原生
- **PostgreSQL**: 高级查询、性能优化、数据建模
- **Git**: 工作流程、分支策略、协作规范
- **Testing**: 测试策略、自动化测试、质量保证

### 工作流程文档特色
- **开发流程**: 完整的软件开发生命周期
- **调试流程**: 系统化的问题诊断和解决
- **部署流程**: 多种部署策略和自动化流程
- **代码审查**: 质量保证、知识共享、最佳实践

### 设计模式文档特色
- **架构模式**: 微服务、事件驱动、CQRS等架构模式
- **设计模式**: 创建型、结构型、行为型设计模式

### AI配置文档特色
- **意图识别**: 深度语义理解、多层次意图分析
- **专家协作**: 动态角色分配、协作工作流程
- **知识融合**: 多专家观点整合、冲突解决机制
- **智能推荐**: 上下文感知推荐、个性化建议
- **自适应学习**: 持续优化、反馈学习机制

## 扩展能力

### 动态扩展
- 可以轻松添加新的专家人格规则文档
- 可以为新技术栈创建专门的工具规则
- 可以根据项目需要定制工作流程
- 支持动态生成缺失的规则文档

### 自定义配置
- 可以调整专家协作权重
- 可以自定义关键词触发规则
- 可以配置技术栈检测规则
- 可以定制输出格式和模板

### 持续优化
- 根据使用效果自动调整规则权重
- 基于用户反馈优化文档内容
- 定期更新技术栈和最佳实践
- 持续改进智能感知算法

## 系统优势

1. **智能化**: AI驱动的自动需求识别和规则调取
2. **专业化**: 12个专业领域专家，覆盖全栈开发
3. **系统化**: 完整覆盖软件开发各个环节
4. **协作化**: 多专家协作提供综合解决方案
5. **可扩展**: 支持动态添加和自定义规则
6. **实用性**: 包含大量实际代码示例和最佳实践
7. **全栈覆盖**: 从前端到后端，从算法到部署的全方位支持
8. **现代技术**: 涵盖最新的技术栈和最佳实践
9. **多语言支持**: 支持13种主流编程语言
10. **工具集成**: 集成9个常用开发工具和框架

## 系统统计

- **专家人格**: 12个专业领域专家
- **编程语言**: 13种主流编程语言规则
- **工具框架**: 9个常用开发工具规则
- **工作流程**: 4个标准化工作流程
- **设计模式**: 2个模式集合
- **AI配置**: 11个智能配置模块
- **实用脚本**: 8个自动化脚本工具
- **总计**: 60+个专业规则文档

## 使用方法
- 将本仓库的.context/目录复制到您的项目根目录中
- 将本仓库的.mainrules文件或文件内容复制到您的{项目根目录}下（适用于 ClaudeCode 和 Gemini CLI）
  - 将本仓库的.mainrules文件内容复制到RooCode.设置.提示词.添加到上下文内
  - 将本仓库的.mainrules文件内容复制到Cursor.Setting.Rules&Memories.UserRules内
  - 将本仓库的.mainrules文件内容复制到Tare.设置.规则.个人规则内

## 开发历程

### 第一阶段：基础框架建设
- 建立了完整的专家人格体系（12个专业领域专家）
- 构建了多语言支持框架（13种编程语言）
- 开发了工具集成规则（9个常用开发工具）
- 设计了标准化工作流程（4个核心流程）

### 第二阶段：智能化升级
- 实现深度语义理解和意图识别
- 开发智能专家匹配算法
- 建立置信度评估和动态调整机制
- 构建多层次上下文记忆系统
- 优化专家协作和知识传递机制

### 第三阶段：协作优化
- 实现动态角色切换和主导权转移
- 开发多专家协作模式（并行、串行、混合）
- 建立知识融合决策和观点整合算法
- 构建冲突解决机制和仲裁策略
- 完善质量保证和持续优化体系

### 第四阶段：生态完善
- 新增移动开发、云架构、数据科学等专业领域
- 扩展编程语言支持（Swift、Kotlin、C#、PHP、Ruby、Dart）
- 集成MCP协议支持和性能监控
- 开发实用脚本工具集
- 建立用户行为分析和自适应学习机制

## 技术特性

### AI驱动的核心能力
- **深度语义理解**: 四层意图分析框架
- **智能专家匹配**: 多因子评分算法
- **动态上下文感知**: 实时环境分析
- **自适应学习**: 基于反馈的持续优化
- **多模态协作**: 文本、代码、配置的综合处理

### 企业级特性
- **高可扩展性**: 模块化架构，支持动态扩展
- **高可用性**: 分布式部署，故障自动恢复
- **安全性**: 多层安全防护，数据加密传输
- **性能优化**: 智能缓存，响应时间优化
- **监控告警**: 实时性能监控和异常告警
