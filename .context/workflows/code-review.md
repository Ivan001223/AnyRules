# 代码审查工作流程规则文档

## 工作流程概述

### 代码审查目标
- **质量保证**: 确保代码质量和一致性
- **知识共享**: 团队成员间的技术交流和学习
- **缺陷预防**: 在代码合并前发现和修复问题
- **标准执行**: 确保编码规范和最佳实践的执行
- **安全检查**: 识别潜在的安全漏洞

### 审查类型
- **同行审查**: 团队成员间的相互审查
- **专家审查**: 资深开发者对关键代码的审查
- **自动化审查**: 工具辅助的代码质量检查
- **架构审查**: 对系统设计和架构的审查

## 审查前准备

### 提交者准备清单
```markdown
## 代码提交前检查清单

### 基础检查
- [ ] 代码编译通过，无语法错误
- [ ] 所有单元测试通过
- [ ] 代码格式化符合团队规范
- [ ] 移除了调试代码和注释
- [ ] 更新了相关文档

### 功能检查
- [ ] 实现了所有需求功能
- [ ] 处理了边界条件和异常情况
- [ ] 添加了适当的错误处理
- [ ] 性能满足要求
- [ ] 安全考虑已实施

### 测试检查
- [ ] 添加了新功能的测试用例
- [ ] 测试覆盖率达到要求
- [ ] 集成测试通过
- [ ] 手动测试验证功能正确

### 文档检查
- [ ] 代码注释清晰准确
- [ ] API文档已更新
- [ ] 变更日志已记录
- [ ] 部署说明已更新
```

### Pull Request模板
```markdown
## Pull Request 描述

### 变更概述
简要描述本次变更的目的和内容

### 变更类型
- [ ] 新功能 (feature)
- [ ] 缺陷修复 (bugfix)
- [ ] 性能优化 (performance)
- [ ] 重构 (refactor)
- [ ] 文档更新 (docs)
- [ ] 测试改进 (test)
- [ ] 构建/CI改进 (build)

### 相关Issue
- 关闭 #123
- 相关 #456

### 测试说明
描述如何测试这些变更：
1. 步骤一
2. 步骤二
3. 预期结果

### 截图/演示
如果适用，添加截图或GIF演示

### 检查清单
- [ ] 代码遵循项目编码规范
- [ ] 自测通过
- [ ] 添加了必要的测试
- [ ] 文档已更新
- [ ] 无破坏性变更，或已在描述中说明

### 审查要点
请审查者特别关注：
- 性能影响
- 安全考虑
- 错误处理
- 边界条件

### 部署注意事项
- [ ] 需要数据库迁移
- [ ] 需要配置变更
- [ ] 需要重启服务
- [ ] 其他部署要求
```

## 审查执行流程

### 审查者工作流程
```typescript
// 代码审查工作流程
class CodeReviewWorkflow {
  
  // 1. 初始审查
  async initialReview(pullRequest: PullRequest): Promise<ReviewResult> {
    const checks = [
      this.checkBasicRequirements(pullRequest),
      this.checkCodeStyle(pullRequest),
      this.checkTestCoverage(pullRequest),
      this.checkDocumentation(pullRequest)
    ];
    
    const results = await Promise.all(checks);
    return this.consolidateResults(results);
  }
  
  // 2. 深度审查
  async deepReview(pullRequest: PullRequest): Promise<ReviewResult> {
    const analysis = {
      logic: await this.analyzeLogic(pullRequest),
      performance: await this.analyzePerformance(pullRequest),
      security: await this.analyzeSecurity(pullRequest),
      architecture: await this.analyzeArchitecture(pullRequest)
    };
    
    return this.generateDetailedFeedback(analysis);
  }
  
  // 3. 安全审查
  async securityReview(pullRequest: PullRequest): Promise<SecurityResult> {
    const securityChecks = [
      this.checkInputValidation(pullRequest),
      this.checkAuthenticationAuthorization(pullRequest),
      this.checkDataExposure(pullRequest),
      this.checkInjectionVulnerabilities(pullRequest),
      this.checkCryptographicUsage(pullRequest)
    ];
    
    return await this.runSecurityAnalysis(securityChecks);
  }
  
  private async checkBasicRequirements(pr: PullRequest): Promise<CheckResult> {
    return {
      hasTests: pr.files.some(f => f.path.includes('test')),
      hasDocumentation: pr.description.length > 50,
      followsNamingConvention: this.validateNaming(pr.files),
      noDebugCode: !this.containsDebugCode(pr.files)
    };
  }
  
  private async analyzeLogic(pr: PullRequest): Promise<LogicAnalysis> {
    return {
      complexity: this.calculateComplexity(pr.files),
      edgeCases: this.identifyEdgeCases(pr.files),
      errorHandling: this.checkErrorHandling(pr.files),
      businessLogic: this.validateBusinessLogic(pr.files)
    };
  }
  
  private async analyzePerformance(pr: PullRequest): Promise<PerformanceAnalysis> {
    return {
      algorithmComplexity: this.analyzeAlgorithms(pr.files),
      databaseQueries: this.analyzeDatabaseUsage(pr.files),
      memoryUsage: this.analyzeMemoryPatterns(pr.files),
      networkCalls: this.analyzeNetworkUsage(pr.files)
    };
  }
}
```

### 审查标准和检查点
```yaml
# 代码审查检查点配置
review_standards:
  
  code_quality:
    - name: "代码可读性"
      criteria:
        - 变量和函数命名清晰
        - 代码结构逻辑清晰
        - 适当的注释和文档
      weight: high
    
    - name: "代码复杂度"
      criteria:
        - 函数长度适中（<50行）
        - 圈复杂度合理（<10）
        - 嵌套层级不超过3层
      weight: high
    
    - name: "错误处理"
      criteria:
        - 适当的异常处理
        - 错误信息有意义
        - 资源正确释放
      weight: critical

  functionality:
    - name: "需求实现"
      criteria:
        - 完整实现需求功能
        - 处理边界条件
        - 用户体验良好
      weight: critical
    
    - name: "测试覆盖"
      criteria:
        - 单元测试覆盖率>80%
        - 集成测试完整
        - 测试用例有意义
      weight: high

  performance:
    - name: "算法效率"
      criteria:
        - 时间复杂度合理
        - 空间复杂度优化
        - 避免不必要的计算
      weight: medium
    
    - name: "资源使用"
      criteria:
        - 内存使用合理
        - 数据库查询优化
        - 网络请求最小化
      weight: medium

  security:
    - name: "输入验证"
      criteria:
        - 所有输入都经过验证
        - 防止注入攻击
        - 数据清理和转义
      weight: critical
    
    - name: "权限控制"
      criteria:
        - 适当的访问控制
        - 敏感操作需要授权
        - 最小权限原则
      weight: critical
    
    - name: "数据保护"
      criteria:
        - 敏感数据加密
        - 安全的数据传输
        - 避免信息泄露
      weight: critical

  maintainability:
    - name: "代码结构"
      criteria:
        - 模块化设计
        - 低耦合高内聚
        - 遵循设计模式
      weight: medium
    
    - name: "文档完整性"
      criteria:
        - API文档完整
        - 代码注释充分
        - 变更说明清晰
      weight: medium
```

### 反馈模板
```markdown
## 代码审查反馈模板

### 总体评价
- **代码质量**: ⭐⭐⭐⭐⭐ (1-5星)
- **功能完整性**: ⭐⭐⭐⭐⭐
- **测试覆盖**: ⭐⭐⭐⭐⭐
- **文档质量**: ⭐⭐⭐⭐⭐

### 🔴 必须修复 (Blocking Issues)
1. **安全问题**: 
   - 文件: `src/auth/login.ts:45`
   - 问题: SQL注入漏洞
   - 建议: 使用参数化查询

2. **功能缺陷**:
   - 文件: `src/user/service.ts:123`
   - 问题: 未处理空值情况
   - 建议: 添加空值检查

### 🟡 建议改进 (Suggestions)
1. **性能优化**:
   - 文件: `src/data/repository.ts:67`
   - 问题: N+1查询问题
   - 建议: 使用批量查询或预加载

2. **代码可读性**:
   - 文件: `src/utils/helper.ts:34`
   - 问题: 函数过于复杂
   - 建议: 拆分为多个小函数

### 🟢 做得很好 (Positive Feedback)
1. **测试覆盖**: 新功能的测试用例很全面
2. **错误处理**: 异常处理逻辑清晰
3. **文档**: API文档更新及时

### 📝 学习要点
1. **设计模式**: 很好地使用了策略模式
2. **最佳实践**: 遵循了SOLID原则
3. **工具使用**: TypeScript类型定义很准确

### 下一步行动
- [ ] 修复所有阻塞性问题
- [ ] 考虑性能优化建议
- [ ] 更新相关文档
- [ ] 重新提交审查
```

## 自动化审查工具

### 静态代码分析配置
```yaml
# .eslintrc.yml
extends:
  - eslint:recommended
  - '@typescript-eslint/recommended'
  - prettier

rules:
  # 代码质量
  complexity: [error, 10]
  max-depth: [error, 3]
  max-lines-per-function: [error, 50]
  max-params: [error, 4]
  
  # 安全规则
  no-eval: error
  no-implied-eval: error
  no-new-func: error
  no-script-url: error
  
  # TypeScript特定
  '@typescript-eslint/no-any': warn
  '@typescript-eslint/explicit-function-return-type': warn
  '@typescript-eslint/no-unused-vars': error

# SonarQube配置
sonar.projectKey=my-project
sonar.sources=src
sonar.tests=tests
sonar.typescript.lcov.reportPaths=coverage/lcov.info
sonar.coverage.exclusions=**/*.test.ts,**/*.spec.ts

# 质量门禁
sonar.qualitygate.wait=true
sonar.qualitygate.timeout=300

quality_gates:
  coverage: 80%
  duplicated_lines: <3%
  maintainability_rating: A
  reliability_rating: A
  security_rating: A
```

### CI/CD集成
```yaml
# .github/workflows/code-review.yml
name: Code Review Automation

on:
  pull_request:
    branches: [main, develop]

jobs:
  automated-review:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
        with:
          fetch-depth: 0
      
      - name: Setup Node.js
        uses: actions/setup-node@v3
        with:
          node-version: '18'
          cache: 'npm'
      
      - name: Install dependencies
        run: npm ci
      
      - name: Lint check
        run: npm run lint
      
      - name: Type check
        run: npm run type-check
      
      - name: Unit tests
        run: npm run test:coverage
      
      - name: Security scan
        run: npm audit --audit-level=moderate
      
      - name: SonarCloud Scan
        uses: SonarSource/sonarcloud-github-action@master
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
          SONAR_TOKEN: ${{ secrets.SONAR_TOKEN }}
      
      - name: Comment PR
        uses: actions/github-script@v6
        with:
          script: |
            const fs = require('fs');
            const coverage = JSON.parse(fs.readFileSync('coverage/coverage-summary.json'));
            const coveragePercent = coverage.total.lines.pct;
            
            const comment = `
            ## 自动化审查结果
            
            ### 测试覆盖率
            - **行覆盖率**: ${coveragePercent}%
            - **分支覆盖率**: ${coverage.total.branches.pct}%
            - **函数覆盖率**: ${coverage.total.functions.pct}%
            
            ### 质量检查
            - ✅ 代码格式检查通过
            - ✅ 类型检查通过
            - ✅ 单元测试通过
            - ✅ 安全扫描通过
            
            请等待人工审查完成。
            `;
            
            github.rest.issues.createComment({
              issue_number: context.issue.number,
              owner: context.repo.owner,
              repo: context.repo.repo,
              body: comment
            });

  assign-reviewers:
    runs-on: ubuntu-latest
    steps:
      - name: Auto-assign reviewers
        uses: actions/github-script@v6
        with:
          script: |
            const { data: files } = await github.rest.pulls.listFiles({
              owner: context.repo.owner,
              repo: context.repo.repo,
              pull_number: context.issue.number
            });
            
            // 根据文件类型分配审查者
            const reviewers = new Set();
            
            files.forEach(file => {
              if (file.filename.includes('security') || file.filename.includes('auth')) {
                reviewers.add('security-team');
              }
              if (file.filename.includes('database') || file.filename.includes('migration')) {
                reviewers.add('database-team');
              }
              if (file.filename.includes('frontend') || file.filename.includes('ui')) {
                reviewers.add('frontend-team');
              }
            });
            
            if (reviewers.size > 0) {
              await github.rest.pulls.requestReviewers({
                owner: context.repo.owner,
                repo: context.repo.repo,
                pull_number: context.issue.number,
                reviewers: Array.from(reviewers)
              });
            }
```

## 审查后流程

### 反馈处理
```typescript
// 审查反馈处理流程
class ReviewFeedbackHandler {
  
  async processReviewComments(
    pullRequest: PullRequest, 
    comments: ReviewComment[]
  ): Promise<ActionPlan> {
    
    const categorizedComments = this.categorizeComments(comments);
    const actionPlan = this.createActionPlan(categorizedComments);
    
    return actionPlan;
  }
  
  private categorizeComments(comments: ReviewComment[]): CategorizedComments {
    return {
      blocking: comments.filter(c => c.severity === 'blocking'),
      suggestions: comments.filter(c => c.severity === 'suggestion'),
      questions: comments.filter(c => c.type === 'question'),
      praise: comments.filter(c => c.type === 'praise')
    };
  }
  
  private createActionPlan(comments: CategorizedComments): ActionPlan {
    return {
      mustFix: comments.blocking.map(c => ({
        file: c.file,
        line: c.line,
        issue: c.content,
        priority: 'high'
      })),
      shouldConsider: comments.suggestions.map(c => ({
        file: c.file,
        line: c.line,
        suggestion: c.content,
        priority: 'medium'
      })),
      needsDiscussion: comments.questions.map(c => ({
        file: c.file,
        line: c.line,
        question: c.content,
        priority: 'low'
      }))
    };
  }
  
  async trackResolution(
    pullRequest: PullRequest,
    actionPlan: ActionPlan
  ): Promise<ResolutionStatus> {
    
    const resolutions = await Promise.all([
      this.checkBlockingIssuesResolved(actionPlan.mustFix),
      this.checkSuggestionsAddressed(actionPlan.shouldConsider),
      this.checkQuestionsAnswered(actionPlan.needsDiscussion)
    ]);
    
    return {
      blockingResolved: resolutions[0],
      suggestionsAddressed: resolutions[1],
      questionsAnswered: resolutions[2],
      readyForMerge: resolutions[0] && resolutions[1]
    };
  }
}
```

### 合并标准
```yaml
# 合并要求配置
merge_requirements:
  
  required_approvals:
    count: 2
    dismiss_stale_reviews: true
    require_code_owner_reviews: true
    required_status_checks:
      - continuous-integration
      - security-scan
      - code-quality-check
  
  branch_protection:
    enforce_admins: true
    required_pull_request_reviews:
      required_approving_review_count: 2
      dismiss_stale_reviews: true
      require_code_owner_reviews: true
    restrictions:
      users: []
      teams: ["core-team"]
  
  quality_gates:
    - name: "测试覆盖率"
      threshold: 80
      metric: "line_coverage"
    
    - name: "代码重复率"
      threshold: 3
      metric: "duplicated_lines_density"
    
    - name: "安全评级"
      threshold: "A"
      metric: "security_rating"
    
    - name: "可维护性评级"
      threshold: "A"
      metric: "maintainability_rating"

  automated_checks:
    - lint_check: required
    - type_check: required
    - unit_tests: required
    - integration_tests: required
    - security_scan: required
    - performance_test: optional
```

## 输出模板

### 审查报告模板
```markdown
# 代码审查报告

## 基本信息
- **PR编号**: #123
- **提交者**: @developer
- **审查者**: @reviewer1, @reviewer2
- **审查时间**: 2024-01-15
- **代码行数**: +150 -50

## 审查结果
- **总体评分**: 8/10
- **建议状态**: 需要修改后合并
- **预计修改时间**: 2小时

## 详细反馈

### 🔴 阻塞性问题 (2个)
1. **安全漏洞**: SQL注入风险
2. **功能缺陷**: 边界条件未处理

### 🟡 改进建议 (3个)
1. **性能优化**: 数据库查询优化
2. **代码结构**: 函数拆分
3. **测试补充**: 边界测试用例

### 🟢 优秀实践 (2个)
1. **错误处理**: 异常处理完善
2. **文档质量**: 注释清晰

## 学习收获
- 了解了新的设计模式应用
- 学习了性能优化技巧
- 掌握了安全编码实践

## 后续行动
- [ ] 修复安全漏洞
- [ ] 处理边界条件
- [ ] 优化数据库查询
- [ ] 补充测试用例
- [ ] 重新提交审查
```
