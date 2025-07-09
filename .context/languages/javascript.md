# JavaScript 语言规则文档

## 语言特性

### 核心优势
- **动态类型**: 灵活的类型系统，运行时类型检查
- **函数式编程**: 支持高阶函数、闭包、函数式编程范式
- **原型继承**: 基于原型的面向对象编程
- **事件驱动**: 异步编程和事件处理机制
- **跨平台**: 浏览器、Node.js、移动端等多平台支持

### 现代JavaScript特性
```javascript
// ES6+ 特性示例

// 解构赋值
const { name, age, ...rest } = user;
const [first, second, ...others] = array;

// 模板字符串
const message = `Hello, ${name}! You are ${age} years old.`;

// 箭头函数
const multiply = (a, b) => a * b;
const users = data.map(item => ({ ...item, processed: true }));

// Promise和async/await
const fetchUser = async (id) => {
  try {
    const response = await fetch(`/api/users/${id}`);
    return await response.json();
  } catch (error) {
    console.error('Failed to fetch user:', error);
    throw error;
  }
};

// 模块系统
export const utils = {
  formatDate: (date) => new Intl.DateTimeFormat('zh-CN').format(date),
  debounce: (fn, delay) => {
    let timeoutId;
    return (...args) => {
      clearTimeout(timeoutId);
      timeoutId = setTimeout(() => fn.apply(this, args), delay);
    };
  }
};

// 类和继承
class User {
  constructor(name, email) {
    this.name = name;
    this.email = email;
  }
  
  async save() {
    const response = await fetch('/api/users', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ name: this.name, email: this.email })
    });
    return response.json();
  }
}

class AdminUser extends User {
  constructor(name, email, permissions) {
    super(name, email);
    this.permissions = permissions;
  }
  
  hasPermission(permission) {
    return this.permissions.includes(permission);
  }
}
```

## 编码规范

### 命名约定
```javascript
// 变量和函数: camelCase
const userName = 'zhangsan';
const userAge = 25;
const getUserInfo = () => {};
const calculateTotalPrice = (items) => {};

// 常量: UPPER_SNAKE_CASE
const API_BASE_URL = 'https://api.example.com';
const MAX_RETRY_ATTEMPTS = 3;
const DEFAULT_TIMEOUT = 5000;

// 类: PascalCase
class UserService {}
class PaymentProcessor {}
class DatabaseConnection {}

// 私有属性/方法: 下划线前缀
class User {
  constructor(name) {
    this.name = name;
    this._id = Math.random(); // 私有属性
  }
  
  _validateEmail(email) { // 私有方法
    return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);
  }
}

// 文件名: kebab-case
// user-service.js
// payment-processor.js
// database-connection.js
```

### 代码组织
```javascript
// 模块结构
// user-service.js
import { validateEmail, hashPassword } from './utils.js';
import { database } from './database.js';

/**
 * 用户服务类
 * 处理用户相关的业务逻辑
 */
export class UserService {
  constructor(db = database) {
    this.db = db;
  }

  /**
   * 创建新用户
   * @param {Object} userData - 用户数据
   * @param {string} userData.name - 用户名
   * @param {string} userData.email - 邮箱
   * @param {string} userData.password - 密码
   * @returns {Promise<Object>} 创建的用户对象
   */
  async createUser({ name, email, password }) {
    // 输入验证
    if (!name || !email || !password) {
      throw new Error('缺少必需的用户信息');
    }

    if (!validateEmail(email)) {
      throw new Error('邮箱格式不正确');
    }

    // 检查邮箱是否已存在
    const existingUser = await this.db.findUserByEmail(email);
    if (existingUser) {
      throw new Error('邮箱已被使用');
    }

    // 创建用户
    const hashedPassword = await hashPassword(password);
    const user = await this.db.createUser({
      name,
      email,
      password: hashedPassword,
      createdAt: new Date()
    });

    // 返回用户信息（不包含密码）
    const { password: _, ...userWithoutPassword } = user;
    return userWithoutPassword;
  }

  /**
   * 根据ID获取用户
   * @param {string} id - 用户ID
   * @returns {Promise<Object|null>} 用户对象或null
   */
  async getUserById(id) {
    if (!id) {
      throw new Error('用户ID不能为空');
    }

    const user = await this.db.findUserById(id);
    if (!user) {
      return null;
    }

    const { password, ...userWithoutPassword } = user;
    return userWithoutPassword;
  }
}

// 默认导出
export default UserService;
```

### 错误处理
```javascript
// 自定义错误类
export class ValidationError extends Error {
  constructor(message, field) {
    super(message);
    this.name = 'ValidationError';
    this.field = field;
  }
}

export class NotFoundError extends Error {
  constructor(resource) {
    super(`${resource} not found`);
    this.name = 'NotFoundError';
  }
}

// 错误处理模式
const handleApiCall = async (apiCall) => {
  try {
    const result = await apiCall();
    return { success: true, data: result };
  } catch (error) {
    console.error('API调用失败:', error);
    
    if (error instanceof ValidationError) {
      return { success: false, error: 'validation', message: error.message };
    }
    
    if (error instanceof NotFoundError) {
      return { success: false, error: 'not_found', message: error.message };
    }
    
    return { success: false, error: 'unknown', message: '未知错误' };
  }
};

// 使用示例
const result = await handleApiCall(() => userService.createUser(userData));
if (!result.success) {
  console.error('用户创建失败:', result.message);
}
```

## 项目结构

### 推荐目录结构
```
project/
├── src/
│   ├── components/      # 可复用组件
│   ├── services/        # 业务逻辑服务
│   ├── utils/           # 工具函数
│   ├── constants/       # 常量定义
│   ├── types/           # 类型定义(JSDoc)
│   ├── styles/          # 样式文件
│   └── index.js         # 入口文件
├── tests/               # 测试文件
├── docs/                # 文档
├── public/              # 静态资源
├── .eslintrc.js         # ESLint配置
├── .prettierrc          # Prettier配置
├── package.json
└── README.md
```

### 模块导入导出
```javascript
// 命名导出 (推荐)
export const formatDate = (date) => {
  return new Intl.DateTimeFormat('zh-CN').format(date);
};

export const validateEmail = (email) => {
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);
};

// 默认导出
export default class ApiClient {
  constructor(baseURL) {
    this.baseURL = baseURL;
  }
}

// 重新导出
export { UserService } from './user-service.js';
export { PaymentService } from './payment-service.js';

// 导入示例
import ApiClient from './api-client.js';
import { formatDate, validateEmail } from './utils.js';
import { UserService, PaymentService } from './services/index.js';
```

## 依赖管理

### package.json配置
```json
{
  "name": "javascript-project",
  "version": "1.0.0",
  "description": "JavaScript项目示例",
  "type": "module",
  "main": "src/index.js",
  "scripts": {
    "start": "node src/index.js",
    "dev": "nodemon src/index.js",
    "test": "jest",
    "test:watch": "jest --watch",
    "test:coverage": "jest --coverage",
    "lint": "eslint src --ext .js",
    "lint:fix": "eslint src --ext .js --fix",
    "format": "prettier --write src/**/*.js",
    "build": "webpack --mode production"
  },
  "dependencies": {
    "lodash": "^4.17.21",
    "axios": "^1.4.0",
    "date-fns": "^2.30.0"
  },
  "devDependencies": {
    "jest": "^29.5.0",
    "eslint": "^8.42.0",
    "prettier": "^2.8.8",
    "nodemon": "^2.0.22",
    "webpack": "^5.88.0"
  },
  "engines": {
    "node": ">=16.0.0",
    "npm": ">=8.0.0"
  }
}
```

### ESLint配置
```javascript
// .eslintrc.js
module.exports = {
  env: {
    browser: true,
    es2021: true,
    node: true,
    jest: true
  },
  extends: [
    'eslint:recommended'
  ],
  parserOptions: {
    ecmaVersion: 'latest',
    sourceType: 'module'
  },
  rules: {
    'indent': ['error', 2],
    'linebreak-style': ['error', 'unix'],
    'quotes': ['error', 'single'],
    'semi': ['error', 'always'],
    'no-unused-vars': 'error',
    'no-console': 'warn',
    'prefer-const': 'error',
    'no-var': 'error',
    'arrow-spacing': 'error',
    'object-curly-spacing': ['error', 'always'],
    'array-bracket-spacing': ['error', 'never'],
    'comma-dangle': ['error', 'never'],
    'eol-last': 'error',
    'no-trailing-spaces': 'error'
  }
};
```

## 测试策略

### 单元测试
```javascript
// user-service.test.js
import { UserService } from '../src/services/user-service.js';
import { ValidationError, NotFoundError } from '../src/errors.js';

describe('UserService', () => {
  let userService;
  let mockDb;

  beforeEach(() => {
    mockDb = {
      findUserByEmail: jest.fn(),
      findUserById: jest.fn(),
      createUser: jest.fn()
    };
    userService = new UserService(mockDb);
  });

  describe('createUser', () => {
    it('should create user with valid data', async () => {
      const userData = {
        name: '张三',
        email: 'zhangsan@example.com',
        password: 'password123'
      };

      mockDb.findUserByEmail.mockResolvedValue(null);
      mockDb.createUser.mockResolvedValue({
        id: '123',
        ...userData,
        password: 'hashed_password',
        createdAt: new Date()
      });

      const result = await userService.createUser(userData);

      expect(result).toHaveProperty('id');
      expect(result.name).toBe(userData.name);
      expect(result.email).toBe(userData.email);
      expect(result).not.toHaveProperty('password');
      expect(mockDb.createUser).toHaveBeenCalledWith(
        expect.objectContaining({
          name: userData.name,
          email: userData.email
        })
      );
    });

    it('should throw error for invalid email', async () => {
      const userData = {
        name: '张三',
        email: 'invalid-email',
        password: 'password123'
      };

      await expect(userService.createUser(userData))
        .rejects
        .toThrow('邮箱格式不正确');
    });

    it('should throw error for duplicate email', async () => {
      const userData = {
        name: '张三',
        email: 'existing@example.com',
        password: 'password123'
      };

      mockDb.findUserByEmail.mockResolvedValue({ id: '456' });

      await expect(userService.createUser(userData))
        .rejects
        .toThrow('邮箱已被使用');
    });
  });

  describe('getUserById', () => {
    it('should return user without password', async () => {
      const userId = '123';
      const userData = {
        id: userId,
        name: '张三',
        email: 'zhangsan@example.com',
        password: 'hashed_password'
      };

      mockDb.findUserById.mockResolvedValue(userData);

      const result = await userService.getUserById(userId);

      expect(result).toEqual({
        id: userId,
        name: '张三',
        email: 'zhangsan@example.com'
      });
      expect(result).not.toHaveProperty('password');
    });

    it('should return null for non-existent user', async () => {
      mockDb.findUserById.mockResolvedValue(null);

      const result = await userService.getUserById('999');

      expect(result).toBeNull();
    });
  });
});
```

### 集成测试
```javascript
// api.integration.test.js
import request from 'supertest';
import app from '../src/app.js';

describe('User API Integration Tests', () => {
  beforeEach(async () => {
    // 清理测试数据库
    await cleanupDatabase();
  });

  describe('POST /api/users', () => {
    it('should create user and return 201', async () => {
      const userData = {
        name: '测试用户',
        email: 'test@example.com',
        password: 'password123'
      };

      const response = await request(app)
        .post('/api/users')
        .send(userData)
        .expect(201);

      expect(response.body).toHaveProperty('id');
      expect(response.body.name).toBe(userData.name);
      expect(response.body.email).toBe(userData.email);
      expect(response.body).not.toHaveProperty('password');
    });

    it('should return 400 for invalid data', async () => {
      const invalidData = {
        name: '',
        email: 'invalid-email',
        password: '123'
      };

      const response = await request(app)
        .post('/api/users')
        .send(invalidData)
        .expect(400);

      expect(response.body).toHaveProperty('error');
    });
  });
});
```

## 性能优化

### 内存管理
```javascript
// 避免内存泄漏
class EventManager {
  constructor() {
    this.listeners = new Map();
  }

  addEventListener(element, event, handler) {
    element.addEventListener(event, handler);
    
    // 记录监听器以便清理
    if (!this.listeners.has(element)) {
      this.listeners.set(element, []);
    }
    this.listeners.get(element).push({ event, handler });
  }

  cleanup() {
    // 清理所有事件监听器
    for (const [element, listeners] of this.listeners) {
      listeners.forEach(({ event, handler }) => {
        element.removeEventListener(event, handler);
      });
    }
    this.listeners.clear();
  }
}

// 防抖和节流
const debounce = (func, delay) => {
  let timeoutId;
  return function (...args) {
    clearTimeout(timeoutId);
    timeoutId = setTimeout(() => func.apply(this, args), delay);
  };
};

const throttle = (func, limit) => {
  let inThrottle;
  return function (...args) {
    if (!inThrottle) {
      func.apply(this, args);
      inThrottle = true;
      setTimeout(() => inThrottle = false, limit);
    }
  };
};
```

### 异步优化
```javascript
// 并发控制
const limitConcurrency = (tasks, limit) => {
  return new Promise((resolve, reject) => {
    const results = [];
    let running = 0;
    let completed = 0;
    let index = 0;

    const runNext = () => {
      if (index >= tasks.length) {
        if (completed === tasks.length) {
          resolve(results);
        }
        return;
      }

      const currentIndex = index++;
      const task = tasks[currentIndex];
      running++;

      task()
        .then(result => {
          results[currentIndex] = result;
        })
        .catch(error => {
          results[currentIndex] = { error };
        })
        .finally(() => {
          running--;
          completed++;
          runNext();
        });
    };

    // 启动初始任务
    for (let i = 0; i < Math.min(limit, tasks.length); i++) {
      runNext();
    }
  });
};

// 缓存机制
const createCache = (maxSize = 100) => {
  const cache = new Map();
  
  return {
    get(key) {
      if (cache.has(key)) {
        // LRU: 移到最后
        const value = cache.get(key);
        cache.delete(key);
        cache.set(key, value);
        return value;
      }
      return undefined;
    },
    
    set(key, value) {
      if (cache.has(key)) {
        cache.delete(key);
      } else if (cache.size >= maxSize) {
        // 删除最旧的项
        const firstKey = cache.keys().next().value;
        cache.delete(firstKey);
      }
      cache.set(key, value);
    },
    
    clear() {
      cache.clear();
    }
  };
};
```

## 安全实践

### 输入验证和清理
```javascript
// 输入验证
const validateInput = {
  email: (email) => {
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    return emailRegex.test(email);
  },
  
  password: (password) => {
    // 至少8位，包含大小写字母和数字
    const passwordRegex = /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)[a-zA-Z\d@$!%*?&]{8,}$/;
    return passwordRegex.test(password);
  },
  
  sanitizeString: (str) => {
    return str.replace(/[<>\"'&]/g, (match) => {
      const escapeMap = {
        '<': '&lt;',
        '>': '&gt;',
        '"': '&quot;',
        "'": '&#x27;',
        '&': '&amp;'
      };
      return escapeMap[match];
    });
  }
};

// XSS防护
const escapeHtml = (unsafe) => {
  return unsafe
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#039;');
};

// CSRF防护
const generateCSRFToken = () => {
  return crypto.randomBytes(32).toString('hex');
};
```

## 生态系统

### 推荐工具链
- **构建工具**: Webpack, Vite, Rollup
- **测试框架**: Jest, Mocha, Cypress
- **代码质量**: ESLint, Prettier, JSHint
- **包管理**: npm, yarn, pnpm
- **文档生成**: JSDoc, Storybook

### 常用库推荐
```javascript
// 实用工具库
import _ from 'lodash';
import dayjs from 'dayjs';
import axios from 'axios';

// 函数式编程
import { pipe, map, filter, reduce } from 'ramda';

// 数据验证
import Joi from 'joi';
import validator from 'validator';

// 状态管理
import { createStore } from 'redux';
import { atom, useAtom } from 'jotai';
```
