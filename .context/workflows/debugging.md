# 调试工作流程规则文档

## 工作流程概述

### 系统化调试方法
```yaml
调试流程:
  1. 问题识别 → 明确问题现象和影响范围
  2. 信息收集 → 收集日志、错误信息、环境数据
  3. 问题复现 → 在可控环境中重现问题
  4. 假设形成 → 基于信息分析提出可能原因
  5. 假设验证 → 通过测试验证或排除假设
  6. 解决方案 → 实施修复并验证效果
  7. 预防措施 → 建立预防机制避免再次发生
```

### 调试优先级
- **P0 - 紧急**: 生产环境崩溃，影响所有用户
- **P1 - 高**: 核心功能异常，影响大部分用户
- **P2 - 中**: 部分功能问题，影响少数用户
- **P3 - 低**: 边缘情况，用户体验问题

## 问题识别阶段

### 问题分类
```yaml
问题类型:
  功能性问题:
    - 功能无法正常工作
    - 输出结果不正确
    - 业务逻辑错误
    
  性能问题:
    - 响应时间过长
    - 内存泄漏
    - CPU使用率过高
    - 数据库查询慢
    
  安全问题:
    - 权限绕过
    - 数据泄露
    - 注入攻击
    
  兼容性问题:
    - 浏览器兼容性
    - 设备适配问题
    - 版本兼容性
```

### 问题描述模板
```markdown
# 问题报告

## 基本信息
- **问题标题**: [简洁描述问题]
- **发现时间**: [YYYY-MM-DD HH:mm:ss]
- **影响级别**: [P0/P1/P2/P3]
- **环境**: [生产/测试/开发]
- **报告人**: [姓名]

## 问题描述
- **现象**: [详细描述问题现象]
- **预期行为**: [描述正确的行为应该是什么]
- **实际行为**: [描述实际发生的情况]
- **影响范围**: [受影响的用户/功能/系统]

## 复现步骤
1. [步骤1]
2. [步骤2]
3. [步骤3]
4. [观察到的问题]

## 环境信息
- **操作系统**: [Windows/macOS/Linux版本]
- **浏览器**: [Chrome/Firefox/Safari版本]
- **应用版本**: [版本号]
- **相关配置**: [特殊配置信息]

## 附加信息
- **错误日志**: [相关错误日志]
- **截图/录屏**: [问题截图或录屏]
- **相关链接**: [相关文档或讨论链接]
```

## 信息收集阶段

### 日志收集策略
```javascript
// 前端错误收集
class ErrorCollector {
  constructor() {
    this.setupGlobalErrorHandlers();
  }

  setupGlobalErrorHandlers() {
    // JavaScript错误
    window.addEventListener('error', (event) => {
      this.logError({
        type: 'javascript',
        message: event.message,
        filename: event.filename,
        lineno: event.lineno,
        colno: event.colno,
        stack: event.error?.stack,
        timestamp: new Date().toISOString(),
        userAgent: navigator.userAgent,
        url: window.location.href
      });
    });

    // Promise未捕获错误
    window.addEventListener('unhandledrejection', (event) => {
      this.logError({
        type: 'promise',
        message: event.reason?.message || 'Unhandled Promise Rejection',
        stack: event.reason?.stack,
        timestamp: new Date().toISOString(),
        userAgent: navigator.userAgent,
        url: window.location.href
      });
    });

    // 资源加载错误
    window.addEventListener('error', (event) => {
      if (event.target !== window) {
        this.logError({
          type: 'resource',
          message: `Failed to load ${event.target.tagName}`,
          source: event.target.src || event.target.href,
          timestamp: new Date().toISOString(),
          url: window.location.href
        });
      }
    }, true);
  }

  logError(errorInfo) {
    // 发送到错误收集服务
    fetch('/api/errors', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(errorInfo)
    }).catch(console.error);
  }
}

// 后端日志记录
import winston from 'winston';

const logger = winston.createLogger({
  level: 'info',
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.errors({ stack: true }),
    winston.format.json()
  ),
  transports: [
    new winston.transports.File({ 
      filename: 'logs/error.log', 
      level: 'error' 
    }),
    new winston.transports.File({ 
      filename: 'logs/combined.log' 
    })
  ]
});

// 请求日志中间件
const requestLogger = (req, res, next) => {
  const start = Date.now();
  
  res.on('finish', () => {
    const duration = Date.now() - start;
    logger.info('HTTP Request', {
      method: req.method,
      url: req.url,
      statusCode: res.statusCode,
      duration,
      userAgent: req.get('User-Agent'),
      ip: req.ip,
      userId: req.user?.id
    });
  });
  
  next();
};
```

### 性能数据收集
```javascript
// 前端性能监控
class PerformanceMonitor {
  constructor() {
    this.collectPageLoadMetrics();
    this.collectUserInteractionMetrics();
  }

  collectPageLoadMetrics() {
    window.addEventListener('load', () => {
      setTimeout(() => {
        const navigation = performance.getEntriesByType('navigation')[0];
        const paint = performance.getEntriesByType('paint');
        
        const metrics = {
          // 页面加载时间
          loadTime: navigation.loadEventEnd - navigation.loadEventStart,
          domContentLoaded: navigation.domContentLoadedEventEnd - navigation.domContentLoadedEventStart,
          
          // 首次绘制时间
          firstPaint: paint.find(p => p.name === 'first-paint')?.startTime,
          firstContentfulPaint: paint.find(p => p.name === 'first-contentful-paint')?.startTime,
          
          // 网络时间
          dnsLookup: navigation.domainLookupEnd - navigation.domainLookupStart,
          tcpConnect: navigation.connectEnd - navigation.connectStart,
          request: navigation.responseStart - navigation.requestStart,
          response: navigation.responseEnd - navigation.responseStart,
          
          // 页面信息
          url: window.location.href,
          timestamp: new Date().toISOString()
        };

        this.sendMetrics('page-load', metrics);
      }, 0);
    });
  }

  collectUserInteractionMetrics() {
    // 监控长任务
    if ('PerformanceObserver' in window) {
      const observer = new PerformanceObserver((list) => {
        list.getEntries().forEach((entry) => {
          if (entry.duration > 50) { // 长任务阈值
            this.sendMetrics('long-task', {
              duration: entry.duration,
              startTime: entry.startTime,
              name: entry.name,
              url: window.location.href,
              timestamp: new Date().toISOString()
            });
          }
        });
      });
      
      observer.observe({ entryTypes: ['longtask'] });
    }
  }

  sendMetrics(type, data) {
    fetch('/api/metrics', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ type, data })
    }).catch(console.error);
  }
}
```

## 问题复现阶段

### 复现环境搭建
```yaml
环境准备:
  本地环境:
    - 确保与生产环境版本一致
    - 配置相同的环境变量
    - 使用相同的数据库状态
    
  测试环境:
    - 部署问题版本代码
    - 恢复问题发生时的数据状态
    - 配置相同的外部依赖
    
  容器化环境:
    - 使用Docker确保环境一致性
    - 记录所有依赖版本
    - 可重复的构建过程
```

### 复现策略
```javascript
// 自动化复现脚本
class BugReproducer {
  constructor(testCase) {
    this.testCase = testCase;
    this.attempts = 0;
    this.maxAttempts = 10;
  }

  async reproduce() {
    console.log(`开始复现问题: ${this.testCase.title}`);
    
    for (let i = 0; i < this.maxAttempts; i++) {
      this.attempts++;
      console.log(`第 ${this.attempts} 次尝试...`);
      
      try {
        await this.setupEnvironment();
        const result = await this.executeSteps();
        
        if (this.isIssueReproduced(result)) {
          console.log('问题成功复现!');
          await this.captureDebugInfo(result);
          return { success: true, attempts: this.attempts, result };
        }
      } catch (error) {
        console.log(`尝试 ${this.attempts} 失败:`, error.message);
        await this.captureFailureInfo(error);
      } finally {
        await this.cleanup();
      }
    }
    
    return { success: false, attempts: this.attempts };
  }

  async setupEnvironment() {
    // 重置数据库状态
    await this.resetDatabase();
    
    // 清理缓存
    await this.clearCache();
    
    // 设置测试数据
    await this.setupTestData();
  }

  async executeSteps() {
    const results = [];
    
    for (const step of this.testCase.steps) {
      const result = await this.executeStep(step);
      results.push(result);
      
      // 添加延迟以模拟真实用户行为
      await this.delay(step.delay || 100);
    }
    
    return results;
  }

  isIssueReproduced(results) {
    return this.testCase.expectedFailure(results);
  }

  async captureDebugInfo(result) {
    // 捕获日志
    const logs = await this.captureLogs();
    
    // 捕获网络请求
    const networkRequests = await this.captureNetworkRequests();
    
    // 捕获系统状态
    const systemState = await this.captureSystemState();
    
    // 保存调试信息
    await this.saveDebugInfo({
      result,
      logs,
      networkRequests,
      systemState,
      timestamp: new Date().toISOString()
    });
  }
}
```

## 假设验证阶段

### 调试工具使用
```javascript
// 浏览器调试技巧
class BrowserDebugger {
  // 条件断点
  setConditionalBreakpoint(condition) {
    // 在Chrome DevTools中设置条件断点
    console.log(`设置条件断点: ${condition}`);
  }

  // 监控变量变化
  watchVariable(obj, prop) {
    let value = obj[prop];
    Object.defineProperty(obj, prop, {
      get() {
        return value;
      },
      set(newValue) {
        console.log(`${prop} 从 ${value} 变为 ${newValue}`);
        debugger; // 触发断点
        value = newValue;
      }
    });
  }

  // 性能分析
  profileFunction(fn, name) {
    return function(...args) {
      console.time(name);
      const result = fn.apply(this, args);
      console.timeEnd(name);
      return result;
    };
  }

  // 内存使用监控
  monitorMemory() {
    if (performance.memory) {
      const memory = performance.memory;
      console.log({
        used: Math.round(memory.usedJSHeapSize / 1048576) + ' MB',
        total: Math.round(memory.totalJSHeapSize / 1048576) + ' MB',
        limit: Math.round(memory.jsHeapSizeLimit / 1048576) + ' MB'
      });
    }
  }
}

// Node.js调试工具
class NodeDebugger {
  // 内存泄漏检测
  detectMemoryLeaks() {
    const memUsage = process.memoryUsage();
    console.log({
      rss: Math.round(memUsage.rss / 1024 / 1024) + ' MB',
      heapTotal: Math.round(memUsage.heapTotal / 1024 / 1024) + ' MB',
      heapUsed: Math.round(memUsage.heapUsed / 1024 / 1024) + ' MB',
      external: Math.round(memUsage.external / 1024 / 1024) + ' MB'
    });
  }

  // CPU性能分析
  profileCPU(duration = 5000) {
    const profiler = require('v8-profiler-next');
    const title = `CPU-${Date.now()}`;
    
    profiler.startProfiling(title, true);
    
    setTimeout(() => {
      const profile = profiler.stopProfiling(title);
      profile.export((error, result) => {
        if (!error) {
          require('fs').writeFileSync(`${title}.cpuprofile`, result);
          console.log(`CPU profile saved: ${title}.cpuprofile`);
        }
      });
    }, duration);
  }

  // 异步调用栈追踪
  enableAsyncHooks() {
    const async_hooks = require('async_hooks');
    
    const hook = async_hooks.createHook({
      init(asyncId, type, triggerAsyncId) {
        console.log(`异步操作创建: ${type} (${asyncId}) 由 ${triggerAsyncId} 触发`);
      },
      before(asyncId) {
        console.log(`异步操作开始: ${asyncId}`);
      },
      after(asyncId) {
        console.log(`异步操作结束: ${asyncId}`);
      },
      destroy(asyncId) {
        console.log(`异步操作销毁: ${asyncId}`);
      }
    });
    
    hook.enable();
    return hook;
  }
}
```

### 数据库调试
```sql
-- 慢查询分析
EXPLAIN ANALYZE SELECT 
  u.id, u.name, p.title 
FROM users u 
JOIN posts p ON u.id = p.user_id 
WHERE u.created_at > '2024-01-01';

-- 查看执行计划
EXPLAIN (ANALYZE, BUFFERS, FORMAT JSON) 
SELECT * FROM large_table WHERE indexed_column = 'value';

-- 监控活跃连接
SELECT 
  pid,
  now() - pg_stat_activity.query_start AS duration,
  query,
  state
FROM pg_stat_activity
WHERE (now() - pg_stat_activity.query_start) > interval '5 minutes';

-- 查看锁等待
SELECT 
  blocked_locks.pid AS blocked_pid,
  blocked_activity.usename AS blocked_user,
  blocking_locks.pid AS blocking_pid,
  blocking_activity.usename AS blocking_user,
  blocked_activity.query AS blocked_statement,
  blocking_activity.query AS current_statement_in_blocking_process
FROM pg_catalog.pg_locks blocked_locks
JOIN pg_catalog.pg_stat_activity blocked_activity 
  ON blocked_activity.pid = blocked_locks.pid
JOIN pg_catalog.pg_locks blocking_locks 
  ON blocking_locks.locktype = blocked_locks.locktype
JOIN pg_catalog.pg_stat_activity blocking_activity 
  ON blocking_activity.pid = blocking_locks.pid
WHERE NOT blocked_locks.granted;
```

## 解决方案实施

### 修复策略
```yaml
修复类型:
  热修复 (Hotfix):
    - 适用于紧急生产问题
    - 最小化变更范围
    - 快速验证和部署
    
  常规修复:
    - 完整的测试覆盖
    - 代码审查流程
    - 渐进式部署
    
  重构修复:
    - 解决根本架构问题
    - 长期技术债务清理
    - 全面的回归测试
```

### 修复验证
```javascript
// 自动化验证脚本
class FixValidator {
  constructor(originalIssue, fix) {
    this.originalIssue = originalIssue;
    this.fix = fix;
  }

  async validate() {
    console.log('开始验证修复效果...');
    
    // 1. 验证原问题已解决
    const issueResolved = await this.verifyIssueResolved();
    
    // 2. 验证没有引入新问题
    const noRegression = await this.verifyNoRegression();
    
    // 3. 验证性能没有下降
    const performanceOk = await this.verifyPerformance();
    
    // 4. 验证边缘情况
    const edgeCasesOk = await this.verifyEdgeCases();
    
    const result = {
      issueResolved,
      noRegression,
      performanceOk,
      edgeCasesOk,
      overall: issueResolved && noRegression && performanceOk && edgeCasesOk
    };
    
    await this.generateReport(result);
    return result;
  }

  async verifyIssueResolved() {
    try {
      // 重新执行原始的失败场景
      const result = await this.executeOriginalScenario();
      return result.success;
    } catch (error) {
      console.error('验证原问题解决时出错:', error);
      return false;
    }
  }

  async verifyNoRegression() {
    try {
      // 运行回归测试套件
      const testResults = await this.runRegressionTests();
      return testResults.passed / testResults.total >= 0.95; // 95%通过率
    } catch (error) {
      console.error('回归测试失败:', error);
      return false;
    }
  }

  async verifyPerformance() {
    try {
      const beforeMetrics = this.originalIssue.performanceBaseline;
      const afterMetrics = await this.measureCurrentPerformance();
      
      // 性能不能下降超过10%
      return afterMetrics.responseTime <= beforeMetrics.responseTime * 1.1;
    } catch (error) {
      console.error('性能验证失败:', error);
      return false;
    }
  }
}
```

## 预防措施

### 监控告警
```javascript
// 实时监控系统
class MonitoringSystem {
  constructor() {
    this.metrics = new Map();
    this.alerts = [];
    this.thresholds = {
      responseTime: 1000,
      errorRate: 0.01,
      memoryUsage: 0.8,
      cpuUsage: 0.8
    };
  }

  // 收集指标
  collectMetric(name, value, tags = {}) {
    const metric = {
      name,
      value,
      tags,
      timestamp: Date.now()
    };
    
    this.metrics.set(`${name}-${Date.now()}`, metric);
    this.checkThresholds(metric);
  }

  // 检查阈值
  checkThresholds(metric) {
    const threshold = this.thresholds[metric.name];
    if (threshold && metric.value > threshold) {
      this.triggerAlert({
        type: 'threshold_exceeded',
        metric: metric.name,
        value: metric.value,
        threshold,
        timestamp: metric.timestamp
      });
    }
  }

  // 触发告警
  triggerAlert(alert) {
    this.alerts.push(alert);
    console.warn('告警触发:', alert);
    
    // 发送通知
    this.sendNotification(alert);
  }

  // 发送通知
  async sendNotification(alert) {
    // 发送到Slack、邮件等
    try {
      await fetch('/api/alerts', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(alert)
      });
    } catch (error) {
      console.error('发送告警通知失败:', error);
    }
  }
}
```

### 错误预防
```javascript
// 防御性编程
class DefensiveProgramming {
  // 输入验证
  static validateInput(input, schema) {
    if (!input) {
      throw new Error('输入不能为空');
    }
    
    // 使用schema验证
    const result = schema.validate(input);
    if (result.error) {
      throw new Error(`输入验证失败: ${result.error.message}`);
    }
    
    return result.value;
  }

  // 安全的数组访问
  static safeArrayAccess(array, index, defaultValue = null) {
    if (!Array.isArray(array) || index < 0 || index >= array.length) {
      return defaultValue;
    }
    return array[index];
  }

  // 安全的对象属性访问
  static safeGet(obj, path, defaultValue = null) {
    const keys = path.split('.');
    let current = obj;
    
    for (const key of keys) {
      if (current == null || typeof current !== 'object') {
        return defaultValue;
      }
      current = current[key];
    }
    
    return current !== undefined ? current : defaultValue;
  }

  // 重试机制
  static async retry(fn, maxAttempts = 3, delay = 1000) {
    for (let attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        return await fn();
      } catch (error) {
        if (attempt === maxAttempts) {
          throw error;
        }
        
        console.warn(`尝试 ${attempt} 失败，${delay}ms后重试:`, error.message);
        await new Promise(resolve => setTimeout(resolve, delay));
        delay *= 2; // 指数退避
      }
    }
  }
}
```

## 输出模板

### 调试报告模板
```markdown
# 调试报告

## 问题概述
- **问题ID**: {issue_id}
- **问题标题**: {title}
- **发现时间**: {discovery_time}
- **解决时间**: {resolution_time}
- **影响级别**: {severity}
- **负责人**: {assignee}

## 问题分析
### 根本原因
{root_cause_analysis}

### 影响范围
- **受影响用户**: {affected_users}
- **受影响功能**: {affected_features}
- **业务影响**: {business_impact}

## 解决方案
### 修复措施
{fix_description}

### 验证结果
- **功能验证**: {functional_verification}
- **性能验证**: {performance_verification}
- **回归测试**: {regression_test_results}

## 预防措施
### 短期措施
{short_term_prevention}

### 长期措施
{long_term_prevention}

## 经验教训
{lessons_learned}

## 相关资源
- **代码变更**: {code_changes}
- **相关文档**: {related_docs}
- **监控链接**: {monitoring_links}
```
