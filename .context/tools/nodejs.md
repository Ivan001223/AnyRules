# Node.js 工具规则文档

## 工具概述
Node.js是基于Chrome V8引擎的JavaScript运行时环境，特别适合构建高性能的服务器端应用程序和API。

### 适用场景
- RESTful API开发
- 微服务架构
- 实时应用(WebSocket)
- 中间件和代理服务
- 命令行工具开发
- 服务端渲染(SSR)

### 核心特性
- 事件驱动、非阻塞I/O
- 单线程但高并发
- 丰富的NPM生态系统
- 跨平台支持
- 快速开发和部署

## 最佳实践

### 项目结构规范
```
project/
├── src/
│   ├── controllers/     # 控制器层
│   ├── services/        # 业务逻辑层
│   ├── models/          # 数据模型
│   ├── middleware/      # 中间件
│   ├── routes/          # 路由定义
│   ├── utils/           # 工具函数
│   ├── config/          # 配置文件
│   └── types/           # TypeScript类型定义
├── tests/               # 测试文件
├── docs/                # 文档
├── scripts/             # 构建脚本
├── .env.example         # 环境变量示例
├── package.json
├── tsconfig.json
└── README.md
```

### 代码组织原则
```typescript
// 控制器层 - 处理HTTP请求
export class UserController {
  constructor(private userService: UserService) {}

  async createUser(req: Request, res: Response, next: NextFunction) {
    try {
      const userData = req.body;
      const user = await this.userService.createUser(userData);
      res.status(201).json({ success: true, data: user });
    } catch (error) {
      next(error);
    }
  }

  async getUser(req: Request, res: Response, next: NextFunction) {
    try {
      const { id } = req.params;
      const user = await this.userService.getUserById(id);
      res.json({ success: true, data: user });
    } catch (error) {
      next(error);
    }
  }
}

// 服务层 - 业务逻辑
export class UserService {
  constructor(private userRepository: UserRepository) {}

  async createUser(userData: CreateUserDto): Promise<User> {
    // 验证用户数据
    await this.validateUserData(userData);
    
    // 检查邮箱是否已存在
    const existingUser = await this.userRepository.findByEmail(userData.email);
    if (existingUser) {
      throw new ConflictError('邮箱已存在');
    }

    // 加密密码
    const hashedPassword = await bcrypt.hash(userData.password, 12);
    
    // 创建用户
    return await this.userRepository.create({
      ...userData,
      password: hashedPassword
    });
  }

  private async validateUserData(userData: CreateUserDto): Promise<void> {
    const schema = z.object({
      email: z.string().email(),
      password: z.string().min(8),
      name: z.string().min(1).max(100)
    });

    schema.parse(userData);
  }
}
```

## 配置规范

### package.json配置
```json
{
  "name": "nodejs-api",
  "version": "1.0.0",
  "description": "Node.js API服务",
  "main": "dist/index.js",
  "scripts": {
    "dev": "nodemon src/index.ts",
    "build": "tsc",
    "start": "node dist/index.js",
    "test": "jest",
    "test:watch": "jest --watch",
    "test:coverage": "jest --coverage",
    "lint": "eslint src --ext .ts",
    "lint:fix": "eslint src --ext .ts --fix",
    "format": "prettier --write src/**/*.ts"
  },
  "dependencies": {
    "express": "^4.18.0",
    "cors": "^2.8.5",
    "helmet": "^7.0.0",
    "compression": "^1.7.4",
    "express-rate-limit": "^6.7.0",
    "bcrypt": "^5.1.0",
    "jsonwebtoken": "^9.0.0",
    "zod": "^3.21.0",
    "winston": "^3.8.0"
  },
  "devDependencies": {
    "@types/node": "^20.0.0",
    "@types/express": "^4.17.0",
    "@types/bcrypt": "^5.0.0",
    "@types/jsonwebtoken": "^9.0.0",
    "typescript": "^5.0.0",
    "nodemon": "^2.0.0",
    "jest": "^29.0.0",
    "@types/jest": "^29.0.0",
    "ts-jest": "^29.0.0",
    "supertest": "^6.3.0"
  },
  "engines": {
    "node": ">=18.0.0",
    "npm": ">=8.0.0"
  }
}
```

### TypeScript配置
```json
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "CommonJS",
    "lib": ["ES2022"],
    "outDir": "./dist",
    "rootDir": "./src",
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true,
    "resolveJsonModule": true,
    "declaration": true,
    "declarationMap": true,
    "sourceMap": true,
    "removeComments": true,
    "noImplicitAny": true,
    "noImplicitReturns": true,
    "noImplicitThis": true,
    "noUnusedLocals": true,
    "noUnusedParameters": true,
    "exactOptionalPropertyTypes": true,
    "baseUrl": "./src",
    "paths": {
      "@/*": ["*"],
      "@/controllers/*": ["controllers/*"],
      "@/services/*": ["services/*"],
      "@/models/*": ["models/*"],
      "@/utils/*": ["utils/*"]
    }
  },
  "include": ["src/**/*"],
  "exclude": ["node_modules", "dist", "tests"]
}
```

### 环境配置
```typescript
// config/environment.ts
import { z } from 'zod';

const envSchema = z.object({
  NODE_ENV: z.enum(['development', 'production', 'test']).default('development'),
  PORT: z.string().transform(Number).default('3000'),
  DATABASE_URL: z.string(),
  JWT_SECRET: z.string().min(32),
  JWT_EXPIRES_IN: z.string().default('24h'),
  REDIS_URL: z.string().optional(),
  LOG_LEVEL: z.enum(['error', 'warn', 'info', 'debug']).default('info')
});

export const env = envSchema.parse(process.env);

export const config = {
  server: {
    port: env.PORT,
    env: env.NODE_ENV
  },
  
  database: {
    url: env.DATABASE_URL
  },
  
  auth: {
    jwtSecret: env.JWT_SECRET,
    jwtExpiresIn: env.JWT_EXPIRES_IN
  },
  
  redis: {
    url: env.REDIS_URL
  },
  
  logging: {
    level: env.LOG_LEVEL
  }
};
```

## 常见问题与解决方案

### 内存泄漏防护
```typescript
// 事件监听器清理
class EventManager {
  private listeners: Map<string, Function[]> = new Map();

  addListener(event: string, callback: Function) {
    if (!this.listeners.has(event)) {
      this.listeners.set(event, []);
    }
    this.listeners.get(event)!.push(callback);
  }

  removeListener(event: string, callback: Function) {
    const callbacks = this.listeners.get(event);
    if (callbacks) {
      const index = callbacks.indexOf(callback);
      if (index > -1) {
        callbacks.splice(index, 1);
      }
    }
  }

  cleanup() {
    this.listeners.clear();
  }
}

// 定时器管理
class TimerManager {
  private timers: Set<NodeJS.Timeout> = new Set();

  setTimeout(callback: Function, delay: number): NodeJS.Timeout {
    const timer = setTimeout(() => {
      callback();
      this.timers.delete(timer);
    }, delay);
    
    this.timers.add(timer);
    return timer;
  }

  clearTimeout(timer: NodeJS.Timeout) {
    clearTimeout(timer);
    this.timers.delete(timer);
  }

  cleanup() {
    this.timers.forEach(timer => clearTimeout(timer));
    this.timers.clear();
  }
}
```

### 错误处理机制
```typescript
// 自定义错误类
export class AppError extends Error {
  constructor(
    public statusCode: number,
    message: string,
    public code?: string,
    public isOperational = true
  ) {
    super(message);
    this.name = this.constructor.name;
    Error.captureStackTrace(this, this.constructor);
  }
}

export class ValidationError extends AppError {
  constructor(message: string, public field?: string) {
    super(400, message, 'VALIDATION_ERROR');
  }
}

export class NotFoundError extends AppError {
  constructor(resource: string) {
    super(404, `${resource} not found`, 'NOT_FOUND');
  }
}

// 全局错误处理中间件
export const errorHandler = (
  error: Error,
  req: Request,
  res: Response,
  next: NextFunction
) => {
  let statusCode = 500;
  let message = 'Internal Server Error';
  let code = 'INTERNAL_ERROR';

  if (error instanceof AppError) {
    statusCode = error.statusCode;
    message = error.message;
    code = error.code || 'APP_ERROR';
  } else if (error instanceof z.ZodError) {
    statusCode = 400;
    message = 'Validation failed';
    code = 'VALIDATION_ERROR';
  }

  // 记录错误日志
  logger.error('Error occurred:', {
    error: error.message,
    stack: error.stack,
    url: req.url,
    method: req.method,
    ip: req.ip,
    userAgent: req.get('User-Agent')
  });

  res.status(statusCode).json({
    success: false,
    error: {
      code,
      message,
      ...(process.env.NODE_ENV === 'development' && { stack: error.stack })
    }
  });
};

// 未捕获异常处理
process.on('uncaughtException', (error) => {
  logger.error('Uncaught Exception:', error);
  process.exit(1);
});

process.on('unhandledRejection', (reason, promise) => {
  logger.error('Unhandled Rejection at:', promise, 'reason:', reason);
  process.exit(1);
});
```

### 性能优化策略
```typescript
// 连接池配置
import { Pool } from 'pg';

const pool = new Pool({
  host: 'localhost',
  port: 5432,
  database: 'myapp',
  user: 'username',
  password: 'password',
  max: 20,                    // 最大连接数
  idleTimeoutMillis: 30000,   // 空闲超时
  connectionTimeoutMillis: 2000, // 连接超时
});

// 缓存实现
import Redis from 'ioredis';

class CacheService {
  private redis: Redis;

  constructor() {
    this.redis = new Redis({
      host: 'localhost',
      port: 6379,
      retryDelayOnFailover: 100,
      maxRetriesPerRequest: 3
    });
  }

  async get<T>(key: string): Promise<T | null> {
    const value = await this.redis.get(key);
    return value ? JSON.parse(value) : null;
  }

  async set(key: string, value: any, ttl = 3600): Promise<void> {
    await this.redis.setex(key, ttl, JSON.stringify(value));
  }

  async del(key: string): Promise<void> {
    await this.redis.del(key);
  }

  async invalidatePattern(pattern: string): Promise<void> {
    const keys = await this.redis.keys(pattern);
    if (keys.length > 0) {
      await this.redis.del(...keys);
    }
  }
}

// 请求限流
import rateLimit from 'express-rate-limit';

export const createRateLimiter = (windowMs: number, max: number) => {
  return rateLimit({
    windowMs,
    max,
    message: {
      error: 'Too many requests',
      retryAfter: Math.ceil(windowMs / 1000)
    },
    standardHeaders: true,
    legacyHeaders: false,
    keyGenerator: (req) => {
      return req.ip + ':' + req.path;
    }
  });
};

// 使用示例
app.use('/api/', createRateLimiter(15 * 60 * 1000, 100)); // 15分钟100次
app.use('/api/auth/login', createRateLimiter(15 * 60 * 1000, 5)); // 登录限制更严格
```

## 安全考虑

### 安全中间件配置
```typescript
import helmet from 'helmet';
import cors from 'cors';

// 安全头设置
app.use(helmet({
  contentSecurityPolicy: {
    directives: {
      defaultSrc: ["'self'"],
      styleSrc: ["'self'", "'unsafe-inline'"],
      scriptSrc: ["'self'"],
      imgSrc: ["'self'", "data:", "https:"],
      connectSrc: ["'self'"],
      fontSrc: ["'self'"],
      objectSrc: ["'none'"],
      mediaSrc: ["'self'"],
      frameSrc: ["'none'"]
    }
  },
  crossOriginEmbedderPolicy: false
}));

// CORS配置
app.use(cors({
  origin: (origin, callback) => {
    const allowedOrigins = process.env.ALLOWED_ORIGINS?.split(',') || [];
    if (!origin || allowedOrigins.includes(origin)) {
      callback(null, true);
    } else {
      callback(new Error('Not allowed by CORS'));
    }
  },
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH'],
  allowedHeaders: ['Content-Type', 'Authorization']
}));

// 输入验证和清理
import validator from 'validator';

export const sanitizeInput = (input: string): string => {
  return validator.escape(validator.trim(input));
};

export const validateAndSanitize = (schema: z.ZodSchema) => {
  return (req: Request, res: Response, next: NextFunction) => {
    try {
      // 验证数据结构
      const validatedData = schema.parse(req.body);
      
      // 清理字符串字段
      const sanitizedData = Object.keys(validatedData).reduce((acc, key) => {
        const value = validatedData[key];
        acc[key] = typeof value === 'string' ? sanitizeInput(value) : value;
        return acc;
      }, {} as any);
      
      req.body = sanitizedData;
      next();
    } catch (error) {
      next(new ValidationError('Invalid input data'));
    }
  };
};
```

## 集成方式

### 数据库集成
```typescript
// Prisma ORM集成
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient({
  log: ['query', 'info', 'warn', 'error'],
});

export class UserRepository {
  async create(userData: CreateUserData): Promise<User> {
    return await prisma.user.create({
      data: userData,
      select: {
        id: true,
        email: true,
        name: true,
        createdAt: true,
        updatedAt: true
      }
    });
  }

  async findById(id: string): Promise<User | null> {
    return await prisma.user.findUnique({
      where: { id },
      select: {
        id: true,
        email: true,
        name: true,
        createdAt: true,
        updatedAt: true
      }
    });
  }

  async findByEmail(email: string): Promise<User | null> {
    return await prisma.user.findUnique({
      where: { email }
    });
  }
}

// 事务处理
export class UserService {
  async createUserWithProfile(userData: CreateUserData, profileData: CreateProfileData) {
    return await prisma.$transaction(async (tx) => {
      const user = await tx.user.create({
        data: userData
      });

      const profile = await tx.profile.create({
        data: {
          ...profileData,
          userId: user.id
        }
      });

      return { user, profile };
    });
  }
}
```

### 消息队列集成
```typescript
// Bull队列集成
import Bull from 'bull';
import Redis from 'ioredis';

const redis = new Redis(process.env.REDIS_URL);

// 邮件队列
export const emailQueue = new Bull('email', {
  redis: {
    port: 6379,
    host: 'localhost'
  }
});

// 邮件处理器
emailQueue.process('send-welcome-email', async (job) => {
  const { email, name } = job.data;
  
  try {
    await sendWelcomeEmail(email, name);
    return { success: true };
  } catch (error) {
    throw new Error(`Failed to send email: ${error.message}`);
  }
});

// 添加任务到队列
export const queueWelcomeEmail = async (email: string, name: string) => {
  await emailQueue.add('send-welcome-email', 
    { email, name },
    {
      attempts: 3,
      backoff: {
        type: 'exponential',
        delay: 2000
      }
    }
  );
};
```

## 更新策略

### 版本管理
- 使用语义化版本控制(SemVer)
- 定期更新依赖包，关注安全更新
- 使用npm audit检查安全漏洞
- 保持Node.js版本在LTS范围内

### 部署策略
```dockerfile
# 多阶段构建Dockerfile
FROM node:18-alpine AS builder

WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production

FROM node:18-alpine AS runtime

RUN addgroup -g 1001 -S nodejs
RUN adduser -S nodejs -u 1001

WORKDIR /app
COPY --from=builder /app/node_modules ./node_modules
COPY --chown=nodejs:nodejs . .

USER nodejs

EXPOSE 3000

CMD ["node", "dist/index.js"]
```

### 监控和日志
```typescript
// Winston日志配置
import winston from 'winston';

export const logger = winston.createLogger({
  level: process.env.LOG_LEVEL || 'info',
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.errors({ stack: true }),
    winston.format.json()
  ),
  transports: [
    new winston.transports.File({ filename: 'logs/error.log', level: 'error' }),
    new winston.transports.File({ filename: 'logs/combined.log' }),
    ...(process.env.NODE_ENV !== 'production' ? [
      new winston.transports.Console({
        format: winston.format.simple()
      })
    ] : [])
  ]
});

// 健康检查端点
app.get('/health', async (req, res) => {
  const health = {
    uptime: process.uptime(),
    message: 'OK',
    timestamp: new Date().toISOString(),
    checks: {
      database: await checkDatabaseConnection(),
      redis: await checkRedisConnection(),
      memory: process.memoryUsage(),
      cpu: process.cpuUsage()
    }
  };

  res.status(200).json(health);
});
```
