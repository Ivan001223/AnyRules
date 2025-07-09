# AnyRules上下文工程

## 🎯 系统概述

这是一个完整的AnyRules上下文工程，能够根据用户的具体需求和项目特征，动态调取相应的专业规则文档，提供精准的开发指导和建议。

## 🧠 智能感知机制

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

## 🎭 人格协作矩阵

不同专家人格之间的协作模式：

| 主导人格 | 协作人格 | 适用场景 |
|---------|---------|---------|
| 架构师 | 后端专家 + 安全专家 | 系统架构设计 |
| 前端专家 | QA专家 + 安全专家 | 用户界面开发 |
| 后端专家 | 安全专家 + 分析师 | API和服务开发 |
| 算法专家 | 分析师 + 后端专家 | 算法优化和机器学习 |
| 分析师 | 架构师 + 后端专家 | 性能优化 |
| QA专家 | 所有人格 | 质量保证和代码审查 |
| 安全专家 | 所有人格 | 安全审查 |

## 🚀 使用示例

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

## 📊 文档内容概览

### 人格文档特色
- **架构师**: 系统设计、技术选型、架构模式
- **前端专家**: React/Vue开发、性能优化、用户体验
- **后端专家**: API设计、数据库优化、微服务架构
- **算法专家**: 机器学习、深度学习、算法优化、数据结构
- **安全专家**: 安全防护、合规检查、漏洞修复
- **分析师**: 性能分析、问题诊断、数据洞察
- **QA专家**: 测试策略、质量保证、代码审查

### 语言文档特色
- **TypeScript**: 类型系统、高级特性、最佳实践
- **JavaScript**: ES6+特性、异步编程、性能优化
- **Python**: 现代特性、异步编程、数据处理、机器学习
- **Java**: Spring Boot、企业级开发、JVM优化
- **C++**: 现代C++、性能优化、系统编程
- **Rust**: 所有权系统、并发安全、性能优化
- **Go**: 并发编程、微服务开发、性能优化

### 工具文档特色
- **React**: 组件设计、状态管理、性能优化
- **Vue.js**: 组合式API、响应式系统、生态集成
- **Node.js**: 服务端开发、API设计、性能调优
- **Kubernetes**: 容器编排、服务网格、云原生
- **Docker**: 容器化、部署策略、安全配置
- **Git**: 工作流程、分支策略、协作规范
- **Testing**: 测试策略、自动化测试、质量保证

### 工作流程特色
- **开发流程**: 完整的软件开发生命周期
- **调试流程**: 系统化的问题诊断和解决
- **部署流程**: 多种部署策略和自动化流程
- **代码审查**: 质量保证、知识共享、最佳实践

## 🔧 扩展能力

### 动态扩展
- 可以轻松添加新的人格规则文档
- 可以为新技术栈创建专门的工具规则
- 可以根据项目需要定制工作流程
- 支持动态生成缺失的规则文档

### 自定义配置
- 可以调整人格协作权重
- 可以自定义关键词触发规则
- 可以配置技术栈检测规则
- 可以定制输出格式和模板

### 持续优化
- 根据使用效果自动调整规则权重
- 基于用户反馈优化文档内容
- 定期更新技术栈和最佳实践
- 持续改进智能感知算法

## 🎉 系统优势

1. **智能化**: 自动识别需求并调取相应规则
2. **专业化**: 每个领域都有专门的专家规则
3. **系统化**: 完整覆盖软件开发各个环节
4. **协作化**: 多人格协作提供综合解决方案
5. **可扩展**: 支持动态添加和自定义规则
6. **实用性**: 包含大量实际代码示例和最佳实践
7. **全栈覆盖**: 从前端到后端，从算法到部署的全方位支持
8. **现代技术**: 涵盖最新的技术栈和最佳实践

这个智能上下文工程系统现在已经完全可用，包含**34个专业规则文档**，能够根据您的具体需求动态调取相应的专业规则文档，提供精准的开发指导和建议！🚀

### 🔥 最新扩展
- ✅ **算法专家**: 机器学习、深度学习、传统算法
- ✅ **Java开发**: Spring Boot、企业级开发
- ✅ **C++编程**: 现代C++、性能优化
- ✅ **Vue.js**: 组合式API、现代前端开发
- ✅ **Next.js**: 全栈React框架、SSR/SSG
- ✅ **PostgreSQL**: 高级数据库特性、性能优化
- ✅ **Kubernetes**: 容器编排、云原生部署
- ✅ **代码审查**: 质量保证、团队协作
- ✅ **设计模式**: 创建型、结构型、行为型模式

### 📊 第一阶段优化完成
- ✅ **文档质量提升**: 添加了大量实际代码示例和故障排查指南
- ✅ **覆盖面扩展**: 新增Next.js和PostgreSQL等热门技术栈
- ✅ **最佳实践**: 每个文档都包含详细的检查清单和调试技巧
- ✅ **实用性增强**: 提供了可直接使用的代码模板和配置示例

### 🧠 第二阶段优化完成
- ✅ **深度语义理解**: 四层意图分析框架，精准识别用户真实需求
- ✅ **智能人格匹配**: 基于多因子评分的专家匹配算法
- ✅ **置信度评估**: 动态阈值调整和多轮对话确认机制
- ✅ **上下文继承**: 短期、中期、长期记忆系统
- ✅ **协作优化**: 负载均衡、冲突解决、知识传递机制
- ✅ **技术栈识别**: 多维度深度分析和智能推理引擎

### 🤝 第三阶段优化完成
- ✅ **动态角色切换**: 智能主导权转移和无缝上下文传递
- ✅ **多专家协作**: 并行协作、串行协作、混合协作模式
- ✅ **知识融合决策**: 多维度评分模型和观点整合算法
- ✅ **冲突解决机制**: 证据驱动、权威仲裁、妥协融合策略
- ✅ **协作工作流程**: 全栈开发、问题解决、学习指导标准流程
- ✅ **质量保证体系**: 实时监控、效果评估、持续优化机制
