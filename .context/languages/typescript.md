# TypeScript 语言规则文档

## 语言特性

### 核心优势
- **静态类型检查**: 编译时发现类型错误
- **智能代码补全**: IDE支持更好的开发体验
- **重构安全**: 类型系统保证重构的安全性
- **渐进式采用**: 可以逐步从JavaScript迁移
- **丰富的类型系统**: 支持泛型、联合类型、交叉类型等

### 类型系统特性
```typescript
// 基础类型
let name: string = "张三";
let age: number = 25;
let isActive: boolean = true;

// 联合类型
type Status = "pending" | "success" | "error";

// 泛型
interface ApiResponse<T> {
  data: T;
  message: string;
  code: number;
}

// 条件类型
type NonNullable<T> = T extends null | undefined ? never : T;
```

## 编码规范

### 命名约定
```typescript
// 变量和函数: camelCase
const userName = "张三";
const getUserInfo = () => {};

// 类和接口: PascalCase
class UserService {}
interface UserProfile {}

// 常量: UPPER_SNAKE_CASE
const API_BASE_URL = "https://api.example.com";

// 类型别名: PascalCase
type UserRole = "admin" | "user" | "guest";

// 枚举: PascalCase
enum OrderStatus {
  PENDING = "pending",
  CONFIRMED = "confirmed",
  SHIPPED = "shipped"
}
```

### 类型定义规范
```typescript
// 接口定义
interface User {
  readonly id: string;
  name: string;
  email: string;
  age?: number; // 可选属性
  roles: UserRole[];
}

// 函数类型
type EventHandler<T> = (event: T) => void;

// 工具类型使用
type PartialUser = Partial<User>;
type UserEmail = Pick<User, 'email'>;
type CreateUserRequest = Omit<User, 'id'>;
```

### 错误处理模式
```typescript
// Result模式
type Result<T, E = Error> = 
  | { success: true; data: T }
  | { success: false; error: E };

// 异步错误处理
async function fetchUser(id: string): Promise<Result<User>> {
  try {
    const user = await api.getUser(id);
    return { success: true, data: user };
  } catch (error) {
    return { 
      success: false, 
      error: error instanceof Error ? error : new Error('Unknown error')
    };
  }
}
```

## 项目结构

### 推荐目录结构
```
src/
├── types/              # 类型定义
│   ├── api.ts         # API相关类型
│   ├── user.ts        # 用户相关类型
│   └── common.ts      # 通用类型
├── services/          # 服务层
│   ├── api/           # API服务
│   └── storage/       # 存储服务
├── utils/             # 工具函数
│   ├── validation.ts  # 验证工具
│   └── formatting.ts  # 格式化工具
├── hooks/             # 自定义Hooks (React)
├── components/        # 组件 (React)
└── __tests__/         # 测试文件
```

### 模块导出规范
```typescript
// 命名导出优于默认导出
export const userService = new UserService();
export const validateEmail = (email: string) => {};

// 类型导出
export type { User, UserRole };
export interface CreateUserRequest {
  name: string;
  email: string;
}

// 重新导出
export { UserService } from './services/UserService';
```

## 依赖管理

### package.json配置
```json
{
  "scripts": {
    "build": "tsc",
    "dev": "tsc --watch",
    "type-check": "tsc --noEmit",
    "lint": "eslint src --ext .ts,.tsx"
  },
  "devDependencies": {
    "typescript": "^5.0.0",
    "@types/node": "^20.0.0",
    "eslint": "^8.0.0",
    "@typescript-eslint/parser": "^6.0.0",
    "@typescript-eslint/eslint-plugin": "^6.0.0"
  }
}
```

### tsconfig.json配置
```json
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "ESNext",
    "lib": ["ES2022", "DOM"],
    "moduleResolution": "bundler",
    "strict": true,
    "noUncheckedIndexedAccess": true,
    "noImplicitReturns": true,
    "noFallthroughCasesInSwitch": true,
    "noUnusedLocals": true,
    "noUnusedParameters": true,
    "exactOptionalPropertyTypes": true,
    "declaration": true,
    "declarationMap": true,
    "sourceMap": true,
    "outDir": "./dist",
    "baseUrl": "./src",
    "paths": {
      "@/*": ["*"],
      "@/types/*": ["types/*"],
      "@/utils/*": ["utils/*"]
    }
  },
  "include": ["src/**/*"],
  "exclude": ["node_modules", "dist", "**/*.test.ts"]
}
```

## 测试策略

### 单元测试
```typescript
// 使用Jest + @types/jest
import { validateEmail } from '../utils/validation';

describe('validateEmail', () => {
  it('should return true for valid email', () => {
    expect(validateEmail('test@example.com')).toBe(true);
  });

  it('should return false for invalid email', () => {
    expect(validateEmail('invalid-email')).toBe(false);
  });
});
```

### 类型测试
```typescript
// 使用tsd进行类型测试
import { expectType, expectError } from 'tsd';
import { User } from '../types/user';

// 测试类型推断
const user: User = { id: '1', name: '张三', email: 'test@example.com', roles: [] };
expectType<string>(user.id);
expectType<string | undefined>(user.age);

// 测试类型错误
expectError<User>({ name: '张三' }); // 缺少必需属性
```

### Mock和Stub
```typescript
// 使用jest.mock
jest.mock('../services/api', () => ({
  getUser: jest.fn().mockResolvedValue({
    id: '1',
    name: '张三',
    email: 'test@example.com'
  })
}));

// 类型安全的mock
const mockGetUser = jest.mocked(api.getUser);
```

## 性能优化

### 编译性能
```json
// tsconfig.json - 优化编译速度
{
  "compilerOptions": {
    "incremental": true,
    "tsBuildInfoFile": ".tsbuildinfo"
  },
  "ts-node": {
    "transpileOnly": true
  }
}
```

### 类型性能
```typescript
// 避免复杂的条件类型
// 不好的例子
type ComplexType<T> = T extends string 
  ? T extends `${infer P}${string}` 
    ? P extends 'a' 
      ? 'A' 
      : 'B' 
    : 'C' 
  : 'D';

// 好的例子 - 简化类型逻辑
type SimpleType<T> = T extends string ? 'String' : 'Other';
```

### 运行时性能
```typescript
// 使用const assertions减少类型计算
const themes = ['light', 'dark'] as const;
type Theme = typeof themes[number]; // 'light' | 'dark'

// 使用索引签名优化对象访问
interface Config {
  [key: string]: string | number | boolean;
}
```

## 安全实践

### 类型安全
```typescript
// 使用品牌类型防止混淆
type UserId = string & { readonly brand: unique symbol };
type ProductId = string & { readonly brand: unique symbol };

const createUserId = (id: string): UserId => id as UserId;
const createProductId = (id: string): ProductId => id as ProductId;

// 编译时会报错
function getUser(id: UserId) {}
const productId = createProductId('123');
// getUser(productId); // 类型错误
```

### 输入验证
```typescript
// 使用Zod进行运行时验证
import { z } from 'zod';

const UserSchema = z.object({
  name: z.string().min(1).max(100),
  email: z.string().email(),
  age: z.number().int().min(0).max(150).optional()
});

type User = z.infer<typeof UserSchema>;

function createUser(input: unknown): Result<User> {
  const result = UserSchema.safeParse(input);
  if (result.success) {
    return { success: true, data: result.data };
  }
  return { success: false, error: new Error(result.error.message) };
}
```

## 生态系统

### 推荐工具链
- **构建工具**: Vite, Webpack, esbuild
- **测试框架**: Jest, Vitest, Playwright
- **代码质量**: ESLint, Prettier, Husky
- **类型工具**: tsd, ts-node, tsx
- **文档生成**: TypeDoc, API Extractor

### 常用类型库
```typescript
// 实用类型库
import type { SetRequired, SetOptional } from 'type-fest';

// 日期处理
import { format, parseISO } from 'date-fns';

// 验证库
import { z } from 'zod';
import * as yup from 'yup';

// 函数式编程
import { pipe, map, filter } from 'fp-ts/function';
```

### 框架集成
```typescript
// React集成
import type { FC, PropsWithChildren } from 'react';

interface ButtonProps {
  variant: 'primary' | 'secondary';
  onClick: () => void;
}

const Button: FC<PropsWithChildren<ButtonProps>> = ({ 
  variant, 
  onClick, 
  children 
}) => {
  return (
    <button onClick={onClick} className={`btn-${variant}`}>
      {children}
    </button>
  );
};

// Node.js集成
import type { Request, Response, NextFunction } from 'express';

interface AuthenticatedRequest extends Request {
  user: User;
}

const authMiddleware = (
  req: Request,
  res: Response,
  next: NextFunction
) => {
  // 认证逻辑
};
```

## 常见问题与解决方案

### 类型错误排查
```typescript
// 问题1: 类型推断失败
// ❌ 错误示例
const data = await fetch('/api/users').then(res => res.json());
// data 类型为 any

// ✅ 正确示例
interface User {
  id: number;
  name: string;
  email: string;
}

const data: User[] = await fetch('/api/users').then(res => res.json());

// 问题2: 联合类型处理
// ❌ 错误示例
function processValue(value: string | number) {
  return value.toUpperCase(); // 错误：number没有toUpperCase方法
}

// ✅ 正确示例
function processValue(value: string | number): string {
  if (typeof value === 'string') {
    return value.toUpperCase();
  }
  return value.toString().toUpperCase();
}

// 问题3: 泛型约束
// ❌ 错误示例
function getProperty<T>(obj: T, key: string) {
  return obj[key]; // 错误：T上不存在索引签名
}

// ✅ 正确示例
function getProperty<T, K extends keyof T>(obj: T, key: K): T[K] {
  return obj[key];
}
```

### 性能优化技巧
```typescript
// 1. 使用const assertions优化类型推断
const themes = ['light', 'dark'] as const;
type Theme = typeof themes[number]; // 'light' | 'dark'

// 2. 使用映射类型减少重复
interface User {
  id: number;
  name: string;
  email: string;
}

// 自动生成可选版本
type PartialUser = Partial<User>;
// 自动生成只读版本
type ReadonlyUser = Readonly<User>;
// 选择特定字段
type UserSummary = Pick<User, 'id' | 'name'>;

// 3. 使用条件类型进行类型计算
type NonNullable<T> = T extends null | undefined ? never : T;
type ApiResponse<T> = T extends string ? { message: T } : { data: T };

// 4. 优化大型联合类型
// ❌ 性能较差
type Status = 'loading' | 'success' | 'error' | 'idle' | 'pending' | 'cancelled';

// ✅ 使用枚举优化
enum Status {
  Loading = 'loading',
  Success = 'success',
  Error = 'error',
  Idle = 'idle',
  Pending = 'pending',
  Cancelled = 'cancelled'
}
```

### 调试技巧
```typescript
// 1. 类型调试工具
type Debug<T> = T extends (...args: any[]) => any
  ? 'Function'
  : T extends object
  ? 'Object'
  : 'Primitive';

// 2. 编译时断言
type Assert<T extends true> = T;
type Test = Assert<1 extends number>; // 通过
// type Test2 = Assert<string extends number>; // 编译错误

// 3. 类型测试
import { expectType } from 'tsd';

function add(a: number, b: number): number {
  return a + b;
}

expectType<number>(add(1, 2));
// expectType<string>(add(1, 2)); // 测试失败

// 4. 运行时类型检查
function isUser(obj: any): obj is User {
  return obj &&
         typeof obj.id === 'number' &&
         typeof obj.name === 'string' &&
         typeof obj.email === 'string';
}

function processUser(data: unknown) {
  if (isUser(data)) {
    // 这里data的类型被缩窄为User
    console.log(data.name);
  }
}
```

## 最佳实践检查清单

### TypeScript代码质量检查清单
```markdown
## 类型安全
- [ ] 避免使用any类型
- [ ] 正确使用联合类型和交叉类型
- [ ] 实现类型守卫函数
- [ ] 使用严格的tsconfig配置

## 性能优化
- [ ] 使用const assertions
- [ ] 优化大型类型定义
- [ ] 避免深层嵌套的条件类型
- [ ] 合理使用类型缓存

## 代码组织
- [ ] 类型定义与实现分离
- [ ] 使用命名空间组织类型
- [ ] 导出必要的类型定义
- [ ] 编写类型文档

## 工具配置
- [ ] ESLint TypeScript规则
- [ ] Prettier格式化配置
- [ ] 编辑器类型检查
- [ ] 构建时类型验证
```
