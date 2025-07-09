# 测试工具规则文档

## 工具概述
测试是软件开发的重要组成部分，确保代码质量、功能正确性和系统稳定性。

### 测试类型
- **单元测试**: 测试单个函数或组件
- **集成测试**: 测试组件间的交互
- **端到端测试**: 测试完整的用户流程
- **性能测试**: 测试系统性能和负载能力
- **安全测试**: 测试系统安全性

### 测试金字塔
```
    /\
   /  \     E2E Tests (10%)
  /____\    
 /      \   Integration Tests (20%)
/________\  Unit Tests (70%)
```

## 最佳实践

### 测试原则
- **FIRST原则**: Fast(快速)、Independent(独立)、Repeatable(可重复)、Self-Validating(自验证)、Timely(及时)
- **AAA模式**: Arrange(准备)、Act(执行)、Assert(断言)
- **Given-When-Then**: 给定条件、当执行操作、那么期望结果

### 单元测试最佳实践
```javascript
// Jest 单元测试示例
describe('UserService', () => {
  let userService;
  let mockRepository;

  beforeEach(() => {
    // Arrange - 准备测试环境
    mockRepository = {
      findById: jest.fn(),
      create: jest.fn(),
      update: jest.fn(),
      delete: jest.fn()
    };
    userService = new UserService(mockRepository);
  });

  describe('createUser', () => {
    it('should create user with valid data', async () => {
      // Arrange
      const userData = {
        name: '张三',
        email: 'zhangsan@example.com',
        age: 25
      };
      const expectedUser = { id: 1, ...userData };
      mockRepository.create.mockResolvedValue(expectedUser);

      // Act
      const result = await userService.createUser(userData);

      // Assert
      expect(result).toEqual(expectedUser);
      expect(mockRepository.create).toHaveBeenCalledWith(userData);
      expect(mockRepository.create).toHaveBeenCalledTimes(1);
    });

    it('should throw error for invalid email', async () => {
      // Arrange
      const invalidUserData = {
        name: '张三',
        email: 'invalid-email',
        age: 25
      };

      // Act & Assert
      await expect(userService.createUser(invalidUserData))
        .rejects
        .toThrow('邮箱格式不正确');
    });

    it('should handle repository errors', async () => {
      // Arrange
      const userData = { name: '李四', email: 'lisi@example.com' };
      const dbError = new Error('数据库连接失败');
      mockRepository.create.mockRejectedValue(dbError);

      // Act & Assert
      await expect(userService.createUser(userData))
        .rejects
        .toThrow('数据库连接失败');
    });
  });

  describe('getUserById', () => {
    it('should return user when found', async () => {
      // Arrange
      const userId = 1;
      const expectedUser = { id: 1, name: '王五', email: 'wangwu@example.com' };
      mockRepository.findById.mockResolvedValue(expectedUser);

      // Act
      const result = await userService.getUserById(userId);

      // Assert
      expect(result).toEqual(expectedUser);
      expect(mockRepository.findById).toHaveBeenCalledWith(userId);
    });

    it('should return null when user not found', async () => {
      // Arrange
      const userId = 999;
      mockRepository.findById.mockResolvedValue(null);

      // Act
      const result = await userService.getUserById(userId);

      // Assert
      expect(result).toBeNull();
    });
  });
});

// 参数化测试
describe('validateEmail', () => {
  test.each([
    ['valid@example.com', true],
    ['user.name@domain.co.uk', true],
    ['invalid-email', false],
    ['@example.com', false],
    ['user@', false],
    ['', false],
    [null, false],
    [undefined, false]
  ])('validateEmail(%s) should return %s', (email, expected) => {
    expect(validateEmail(email)).toBe(expected);
  });
});
```

### 集成测试
```javascript
// API集成测试
describe('User API Integration Tests', () => {
  let app;
  let testDb;

  beforeAll(async () => {
    // 设置测试数据库
    testDb = await setupTestDatabase();
    app = createApp({ database: testDb });
  });

  afterAll(async () => {
    await testDb.close();
  });

  beforeEach(async () => {
    // 清理测试数据
    await testDb.query('DELETE FROM users');
  });

  describe('POST /api/users', () => {
    it('should create user successfully', async () => {
      const userData = {
        name: '集成测试用户',
        email: 'integration@test.com',
        age: 30
      };

      const response = await request(app)
        .post('/api/users')
        .send(userData)
        .expect(201);

      expect(response.body).toMatchObject({
        name: userData.name,
        email: userData.email,
        age: userData.age
      });
      expect(response.body).toHaveProperty('id');
      expect(response.body).toHaveProperty('createdAt');

      // 验证数据库中的数据
      const dbUser = await testDb.query(
        'SELECT * FROM users WHERE email = $1',
        [userData.email]
      );
      expect(dbUser.rows).toHaveLength(1);
    });

    it('should return 400 for duplicate email', async () => {
      // 先创建一个用户
      await testDb.query(
        'INSERT INTO users (name, email, age) VALUES ($1, $2, $3)',
        ['现有用户', 'existing@test.com', 25]
      );

      const duplicateUserData = {
        name: '重复用户',
        email: 'existing@test.com',
        age: 30
      };

      const response = await request(app)
        .post('/api/users')
        .send(duplicateUserData)
        .expect(400);

      expect(response.body).toHaveProperty('error');
      expect(response.body.error).toContain('邮箱已存在');
    });
  });

  describe('GET /api/users/:id', () => {
    it('should return user by id', async () => {
      // 先创建测试用户
      const insertResult = await testDb.query(
        'INSERT INTO users (name, email, age) VALUES ($1, $2, $3) RETURNING id',
        ['测试用户', 'test@example.com', 28]
      );
      const userId = insertResult.rows[0].id;

      const response = await request(app)
        .get(`/api/users/${userId}`)
        .expect(200);

      expect(response.body).toMatchObject({
        id: userId,
        name: '测试用户',
        email: 'test@example.com',
        age: 28
      });
    });

    it('should return 404 for non-existent user', async () => {
      const response = await request(app)
        .get('/api/users/99999')
        .expect(404);

      expect(response.body).toHaveProperty('error');
      expect(response.body.error).toContain('用户不存在');
    });
  });
});

// 数据库集成测试
describe('UserRepository Integration Tests', () => {
  let repository;
  let testDb;

  beforeAll(async () => {
    testDb = await setupTestDatabase();
    repository = new UserRepository(testDb);
  });

  afterAll(async () => {
    await testDb.close();
  });

  beforeEach(async () => {
    await testDb.query('DELETE FROM users');
  });

  it('should create and retrieve user', async () => {
    const userData = {
      name: '数据库测试用户',
      email: 'db@test.com',
      age: 35
    };

    // 创建用户
    const createdUser = await repository.create(userData);
    expect(createdUser).toHaveProperty('id');
    expect(createdUser.name).toBe(userData.name);

    // 检索用户
    const retrievedUser = await repository.findById(createdUser.id);
    expect(retrievedUser).toEqual(createdUser);
  });

  it('should handle concurrent user creation', async () => {
    const users = Array.from({ length: 10 }, (_, i) => ({
      name: `并发用户${i}`,
      email: `concurrent${i}@test.com`,
      age: 20 + i
    }));

    // 并发创建用户
    const createPromises = users.map(user => repository.create(user));
    const createdUsers = await Promise.all(createPromises);

    expect(createdUsers).toHaveLength(10);
    createdUsers.forEach((user, index) => {
      expect(user.name).toBe(users[index].name);
      expect(user.email).toBe(users[index].email);
    });

    // 验证所有用户都被创建
    const allUsers = await repository.findAll();
    expect(allUsers).toHaveLength(10);
  });
});
```

### 端到端测试
```javascript
// Playwright E2E测试
import { test, expect } from '@playwright/test';

test.describe('用户注册流程', () => {
  test.beforeEach(async ({ page }) => {
    // 清理测试数据
    await page.goto('/test/cleanup');
    await page.goto('/register');
  });

  test('完整的用户注册流程', async ({ page }) => {
    // 填写注册表单
    await page.fill('[data-testid="name-input"]', '端到端测试用户');
    await page.fill('[data-testid="email-input"]', 'e2e@test.com');
    await page.fill('[data-testid="password-input"]', 'SecurePassword123!');
    await page.fill('[data-testid="confirm-password-input"]', 'SecurePassword123!');

    // 提交表单
    await page.click('[data-testid="register-button"]');

    // 验证成功页面
    await expect(page.locator('[data-testid="success-message"]')).toBeVisible();
    await expect(page.locator('[data-testid="success-message"]')).toContainText('注册成功');

    // 验证重定向到仪表板
    await expect(page).toHaveURL('/dashboard');
    await expect(page.locator('[data-testid="user-name"]')).toContainText('端到端测试用户');
  });

  test('表单验证错误显示', async ({ page }) => {
    // 提交空表单
    await page.click('[data-testid="register-button"]');

    // 验证错误消息
    await expect(page.locator('[data-testid="name-error"]')).toBeVisible();
    await expect(page.locator('[data-testid="name-error"]')).toContainText('姓名不能为空');

    await expect(page.locator('[data-testid="email-error"]')).toBeVisible();
    await expect(page.locator('[data-testid="email-error"]')).toContainText('邮箱不能为空');

    await expect(page.locator('[data-testid="password-error"]')).toBeVisible();
    await expect(page.locator('[data-testid="password-error"]')).toContainText('密码不能为空');
  });

  test('密码强度验证', async ({ page }) => {
    await page.fill('[data-testid="name-input"]', '测试用户');
    await page.fill('[data-testid="email-input"]', 'test@example.com');
    await page.fill('[data-testid="password-input"]', '123');
    await page.fill('[data-testid="confirm-password-input"]', '123');

    await page.click('[data-testid="register-button"]');

    await expect(page.locator('[data-testid="password-error"]')).toBeVisible();
    await expect(page.locator('[data-testid="password-error"]')).toContainText('密码强度不足');
  });

  test('邮箱重复检查', async ({ page }) => {
    // 先注册一个用户
    await page.fill('[data-testid="name-input"]', '第一个用户');
    await page.fill('[data-testid="email-input"]', 'duplicate@test.com');
    await page.fill('[data-testid="password-input"]', 'SecurePassword123!');
    await page.fill('[data-testid="confirm-password-input"]', 'SecurePassword123!');
    await page.click('[data-testid="register-button"]');

    // 等待注册完成
    await expect(page).toHaveURL('/dashboard');

    // 返回注册页面尝试使用相同邮箱
    await page.goto('/register');
    await page.fill('[data-testid="name-input"]', '第二个用户');
    await page.fill('[data-testid="email-input"]', 'duplicate@test.com');
    await page.fill('[data-testid="password-input"]', 'AnotherPassword123!');
    await page.fill('[data-testid="confirm-password-input"]', 'AnotherPassword123!');
    await page.click('[data-testid="register-button"]');

    // 验证错误消息
    await expect(page.locator('[data-testid="email-error"]')).toBeVisible();
    await expect(page.locator('[data-testid="email-error"]')).toContainText('邮箱已被使用');
  });
});

// 跨浏览器测试
test.describe('跨浏览器兼容性', () => {
  ['chromium', 'firefox', 'webkit'].forEach(browserName => {
    test(`在 ${browserName} 中测试基本功能`, async ({ page }) => {
      await page.goto('/');
      
      // 测试基本导航
      await page.click('[data-testid="login-link"]');
      await expect(page).toHaveURL('/login');
      
      // 测试表单交互
      await page.fill('[data-testid="email-input"]', 'test@example.com');
      await page.fill('[data-testid="password-input"]', 'password123');
      
      // 验证表单状态
      await expect(page.locator('[data-testid="login-button"]')).toBeEnabled();
    });
  });
});
```

## 配置规范

### Jest 配置
```javascript
// jest.config.js
module.exports = {
  // 测试环境
  testEnvironment: 'node', // 或 'jsdom' 用于浏览器环境

  // 测试文件匹配模式
  testMatch: [
    '**/__tests__/**/*.(test|spec).(js|ts)',
    '**/*.(test|spec).(js|ts)'
  ],

  // 覆盖率配置
  collectCoverage: true,
  coverageDirectory: 'coverage',
  coverageReporters: ['text', 'lcov', 'html', 'json'],
  
  // 覆盖率阈值
  coverageThreshold: {
    global: {
      branches: 80,
      functions: 80,
      lines: 80,
      statements: 80
    },
    './src/services/': {
      branches: 90,
      functions: 90,
      lines: 90,
      statements: 90
    }
  },

  // 忽略覆盖率的文件
  coveragePathIgnorePatterns: [
    '/node_modules/',
    '/tests/',
    '/coverage/',
    '/.next/',
    '/dist/'
  ],

  // 设置文件
  setupFilesAfterEnv: ['<rootDir>/tests/setup.js'],

  // 模块路径映射
  moduleNameMapping: {
    '^@/(.*)$': '<rootDir>/src/$1',
    '^@/components/(.*)$': '<rootDir>/src/components/$1',
    '^@/utils/(.*)$': '<rootDir>/src/utils/$1'
  },

  // 转换配置
  transform: {
    '^.+\\.(js|jsx|ts|tsx)$': 'babel-jest'
  },

  // 清理模拟
  clearMocks: true,
  restoreMocks: true,

  // 测试超时
  testTimeout: 10000,

  // 并行测试
  maxWorkers: '50%',

  // 详细输出
  verbose: true
};

// tests/setup.js - 测试设置文件
import '@testing-library/jest-dom';

// 全局测试配置
global.console = {
  ...console,
  // 在测试中静默某些日志
  log: jest.fn(),
  debug: jest.fn(),
  info: jest.fn(),
  warn: jest.fn(),
  error: jest.fn()
};

// 模拟环境变量
process.env.NODE_ENV = 'test';
process.env.DATABASE_URL = 'postgresql://test:test@localhost:5432/test_db';

// 全局测试工具
global.testUtils = {
  createMockUser: (overrides = {}) => ({
    id: 1,
    name: '测试用户',
    email: 'test@example.com',
    createdAt: new Date(),
    ...overrides
  }),

  createMockRequest: (overrides = {}) => ({
    body: {},
    params: {},
    query: {},
    headers: {},
    user: null,
    ...overrides
  }),

  createMockResponse: () => {
    const res = {};
    res.status = jest.fn().mockReturnValue(res);
    res.json = jest.fn().mockReturnValue(res);
    res.send = jest.fn().mockReturnValue(res);
    res.cookie = jest.fn().mockReturnValue(res);
    res.clearCookie = jest.fn().mockReturnValue(res);
    return res;
  }
};

// 异步测试超时处理
beforeEach(() => {
  jest.setTimeout(10000);
});

// 测试数据库清理
afterEach(async () => {
  // 清理测试数据
  if (global.testDb) {
    await global.testDb.query('DELETE FROM users WHERE email LIKE %test%');
  }
});
```

### Playwright 配置
```javascript
// playwright.config.js
import { defineConfig, devices } from '@playwright/test';

export default defineConfig({
  // 测试目录
  testDir: './tests/e2e',

  // 并行运行
  fullyParallel: true,

  // 失败时重试
  retries: process.env.CI ? 2 : 0,

  // 工作进程数
  workers: process.env.CI ? 1 : undefined,

  // 报告器
  reporter: [
    ['html'],
    ['json', { outputFile: 'test-results.json' }],
    ['junit', { outputFile: 'test-results.xml' }]
  ],

  // 全局设置
  use: {
    // 基础URL
    baseURL: 'http://localhost:3000',

    // 浏览器上下文选项
    viewport: { width: 1280, height: 720 },
    ignoreHTTPSErrors: true,
    screenshot: 'only-on-failure',
    video: 'retain-on-failure',
    trace: 'retain-on-failure',

    // 等待策略
    actionTimeout: 10000,
    navigationTimeout: 30000
  },

  // 项目配置 - 不同浏览器
  projects: [
    {
      name: 'chromium',
      use: { ...devices['Desktop Chrome'] }
    },
    {
      name: 'firefox',
      use: { ...devices['Desktop Firefox'] }
    },
    {
      name: 'webkit',
      use: { ...devices['Desktop Safari'] }
    },
    {
      name: 'Mobile Chrome',
      use: { ...devices['Pixel 5'] }
    },
    {
      name: 'Mobile Safari',
      use: { ...devices['iPhone 12'] }
    }
  ],

  // 开发服务器
  webServer: {
    command: 'npm run dev',
    port: 3000,
    reuseExistingServer: !process.env.CI
  }
});
```

## 常见问题与解决方案

### 测试隔离
```javascript
// 问题：测试间相互影响
// 解决：确保每个测试的独立性

describe('UserService', () => {
  let userService;
  let mockDb;

  beforeEach(() => {
    // 每个测试前重新创建实例
    mockDb = createMockDatabase();
    userService = new UserService(mockDb);
  });

  afterEach(() => {
    // 清理副作用
    jest.clearAllMocks();
    mockDb.reset();
  });

  // 测试用例...
});

// 数据库测试隔离
describe('Database Integration', () => {
  beforeEach(async () => {
    // 使用事务确保隔离
    await db.beginTransaction();
  });

  afterEach(async () => {
    // 回滚事务
    await db.rollbackTransaction();
  });
});
```

### 异步测试
```javascript
// 问题：异步操作测试困难
// 解决：正确处理Promise和async/await

describe('Async Operations', () => {
  it('should handle async operations correctly', async () => {
    // 使用 async/await
    const result = await asyncFunction();
    expect(result).toBe('expected');
  });

  it('should handle Promise rejections', async () => {
    // 测试Promise拒绝
    await expect(failingAsyncFunction()).rejects.toThrow('Error message');
  });

  it('should handle timeouts', async () => {
    // 设置超时
    jest.setTimeout(15000);
    
    const result = await longRunningOperation();
    expect(result).toBeDefined();
  });
});

// 模拟定时器
describe('Timer Tests', () => {
  beforeEach(() => {
    jest.useFakeTimers();
  });

  afterEach(() => {
    jest.useRealTimers();
  });

  it('should handle delayed operations', () => {
    const callback = jest.fn();
    setTimeout(callback, 1000);

    // 快进时间
    jest.advanceTimersByTime(1000);
    
    expect(callback).toHaveBeenCalled();
  });
});
```

### 模拟和存根
```javascript
// HTTP请求模拟
import axios from 'axios';
jest.mock('axios');
const mockedAxios = axios as jest.Mocked<typeof axios>;

describe('API Service', () => {
  it('should fetch user data', async () => {
    const userData = { id: 1, name: '张三' };
    mockedAxios.get.mockResolvedValue({ data: userData });

    const result = await apiService.getUser(1);
    
    expect(result).toEqual(userData);
    expect(mockedAxios.get).toHaveBeenCalledWith('/api/users/1');
  });
});

// 模块模拟
jest.mock('../utils/logger', () => ({
  info: jest.fn(),
  error: jest.fn(),
  warn: jest.fn()
}));

// 部分模拟
jest.mock('../config', () => ({
  ...jest.requireActual('../config'),
  DATABASE_URL: 'test://localhost/test_db'
}));

// 动态模拟
describe('Dynamic Mocking', () => {
  it('should handle different scenarios', () => {
    const mockFunction = jest.fn();
    
    // 第一次调用返回成功
    mockFunction.mockReturnValueOnce('success');
    
    // 第二次调用抛出错误
    mockFunction.mockImplementationOnce(() => {
      throw new Error('Failed');
    });
    
    expect(mockFunction()).toBe('success');
    expect(() => mockFunction()).toThrow('Failed');
  });
});
```

## 性能测试

### 负载测试
```javascript
// 使用Artillery进行负载测试
// artillery.yml
config:
  target: 'http://localhost:3000'
  phases:
    - duration: 60
      arrivalRate: 10
    - duration: 120
      arrivalRate: 50
    - duration: 60
      arrivalRate: 10

scenarios:
  - name: "用户注册流程"
    weight: 70
    flow:
      - post:
          url: "/api/users"
          json:
            name: "负载测试用户{{ $randomString() }}"
            email: "load{{ $randomString() }}@test.com"
            password: "TestPassword123!"
      - think: 2

  - name: "用户查询"
    weight: 30
    flow:
      - get:
          url: "/api/users/{{ $randomInt(1, 1000) }}"
      - think: 1

// 性能断言
import { performance } from 'perf_hooks';

describe('Performance Tests', () => {
  it('should process large dataset efficiently', async () => {
    const largeDataset = generateLargeDataset(10000);
    
    const startTime = performance.now();
    const result = await processDataset(largeDataset);
    const endTime = performance.now();
    
    const duration = endTime - startTime;
    
    expect(result).toHaveLength(10000);
    expect(duration).toBeLessThan(1000); // 应在1秒内完成
  });

  it('should handle concurrent requests', async () => {
    const concurrentRequests = Array.from({ length: 100 }, (_, i) => 
      apiService.getUser(i + 1)
    );
    
    const startTime = performance.now();
    const results = await Promise.all(concurrentRequests);
    const endTime = performance.now();
    
    expect(results).toHaveLength(100);
    expect(endTime - startTime).toBeLessThan(5000); // 5秒内完成
  });
});
```

## 输出模板

### 测试报告模板
```markdown
# 测试执行报告

## 测试概要
- **执行时间**: {execution_time}
- **测试环境**: {test_environment}
- **测试版本**: {version}

## 测试结果统计
- **总测试数**: {total_tests}
- **通过**: {passed_tests} ({pass_rate}%)
- **失败**: {failed_tests}
- **跳过**: {skipped_tests}

## 覆盖率报告
- **语句覆盖率**: {statement_coverage}%
- **分支覆盖率**: {branch_coverage}%
- **函数覆盖率**: {function_coverage}%
- **行覆盖率**: {line_coverage}%

## 性能指标
- **平均执行时间**: {avg_execution_time}ms
- **最慢测试**: {slowest_test} ({slowest_time}ms)
- **内存使用**: {memory_usage}MB

## 失败测试详情
{failed_test_details}

## 建议
{recommendations}
```
