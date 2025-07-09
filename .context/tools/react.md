# React 工具规则文档

## 工具概述
React是用于构建用户界面的JavaScript库，特别适合构建单页应用程序(SPA)和复杂的交互式UI。

### 适用场景
- 现代Web应用开发
- 单页应用程序(SPA)
- 组件化UI开发
- 需要复杂状态管理的应用
- 高性能用户界面

### 核心特性
- 组件化架构
- 虚拟DOM优化
- 单向数据流
- 丰富的生态系统
- 强大的开发工具

## 最佳实践

### 项目结构规范
```
src/
├── components/          # 可复用组件
│   ├── ui/             # 基础UI组件
│   ├── forms/          # 表单组件
│   └── layout/         # 布局组件
├── pages/              # 页面组件
├── hooks/              # 自定义Hooks
├── services/           # API服务
├── utils/              # 工具函数
├── types/              # TypeScript类型定义
├── styles/             # 样式文件
└── __tests__/          # 测试文件
```

### 组件设计原则
- **单一职责**: 每个组件只负责一个功能
- **可复用性**: 设计通用的、可配置的组件
- **组合优于继承**: 使用组合模式构建复杂组件
- **Props接口清晰**: 明确的Props类型和默认值
- **状态最小化**: 只在必要时使用本地状态

### 状态管理策略
```typescript
// 本地状态 - 简单组件状态
const [count, setCount] = useState(0);

// 上下文状态 - 跨组件共享
const ThemeContext = createContext();

// 全局状态 - 复杂应用状态
// 推荐: Zustand, Redux Toolkit, Jotai
```

## 配置规范

### 标准配置模板
```json
// package.json
{
  "name": "react-app",
  "scripts": {
    "dev": "vite",
    "build": "vite build",
    "preview": "vite preview",
    "test": "vitest",
    "lint": "eslint src --ext ts,tsx",
    "type-check": "tsc --noEmit"
  },
  "dependencies": {
    "react": "^18.2.0",
    "react-dom": "^18.2.0"
  },
  "devDependencies": {
    "@types/react": "^18.2.0",
    "@types/react-dom": "^18.2.0",
    "@vitejs/plugin-react": "^4.0.0",
    "typescript": "^5.0.0",
    "vite": "^4.4.0"
  }
}
```

### TypeScript配置
```json
// tsconfig.json
{
  "compilerOptions": {
    "target": "ES2020",
    "lib": ["ES2020", "DOM", "DOM.Iterable"],
    "module": "ESNext",
    "skipLibCheck": true,
    "moduleResolution": "bundler",
    "allowImportingTsExtensions": true,
    "resolveJsonModule": true,
    "isolatedModules": true,
    "noEmit": true,
    "jsx": "react-jsx",
    "strict": true,
    "noUnusedLocals": true,
    "noUnusedParameters": true,
    "noFallthroughCasesInSwitch": true
  },
  "include": ["src"],
  "references": [{ "path": "./tsconfig.node.json" }]
}
```

### ESLint配置
```json
// .eslintrc.json
{
  "extends": [
    "eslint:recommended",
    "@typescript-eslint/recommended",
    "plugin:react/recommended",
    "plugin:react-hooks/recommended"
  ],
  "rules": {
    "react/react-in-jsx-scope": "off",
    "react/prop-types": "off",
    "@typescript-eslint/no-unused-vars": "error"
  }
}
```

## 常见问题与解决方案

### 性能问题
```typescript
// 问题: 不必要的重渲染
// 解决: 使用React.memo和useMemo
const ExpensiveComponent = React.memo(({ data }) => {
  const processedData = useMemo(() => 
    expensiveCalculation(data), [data]
  );
  return <div>{processedData}</div>;
});

// 问题: 大列表性能
// 解决: 虚拟化列表
import { FixedSizeList as List } from 'react-window';
```

### 状态管理问题
```typescript
// 问题: Props drilling
// 解决: Context API或状态管理库
const UserContext = createContext();

// 问题: 异步状态管理
// 解决: 使用React Query或SWR
import { useQuery } from '@tanstack/react-query';
const { data, isLoading, error } = useQuery({
  queryKey: ['users'],
  queryFn: fetchUsers
});
```

### 类型安全问题
```typescript
// 问题: Props类型不明确
// 解决: 明确的TypeScript接口
interface ButtonProps {
  variant: 'primary' | 'secondary';
  size?: 'sm' | 'md' | 'lg';
  onClick: () => void;
  children: React.ReactNode;
}

const Button: React.FC<ButtonProps> = ({ 
  variant, 
  size = 'md', 
  onClick, 
  children 
}) => {
  return (
    <button 
      className={`btn btn-${variant} btn-${size}`}
      onClick={onClick}
    >
      {children}
    </button>
  );
};
```

## 性能优化

### 代码分割
```typescript
// 路由级别的代码分割
import { lazy, Suspense } from 'react';
const LazyComponent = lazy(() => import('./LazyComponent'));

function App() {
  return (
    <Suspense fallback={<div>Loading...</div>}>
      <LazyComponent />
    </Suspense>
  );
}
```

### 图片优化
```typescript
// 响应式图片
const ResponsiveImage = ({ src, alt }) => (
  <picture>
    <source media="(min-width: 768px)" srcSet={`${src}-large.webp`} />
    <source media="(min-width: 480px)" srcSet={`${src}-medium.webp`} />
    <img src={`${src}-small.webp`} alt={alt} loading="lazy" />
  </picture>
);
```

### Bundle优化
```javascript
// vite.config.js
export default {
  build: {
    rollupOptions: {
      output: {
        manualChunks: {
          vendor: ['react', 'react-dom'],
          ui: ['@mui/material', '@emotion/react']
        }
      }
    }
  }
};
```

## 安全考虑

### XSS防护
```typescript
// 避免dangerouslySetInnerHTML
// 使用DOMPurify清理HTML
import DOMPurify from 'dompurify';

const SafeHTML = ({ html }) => (
  <div dangerouslySetInnerHTML={{
    __html: DOMPurify.sanitize(html)
  }} />
);
```

### 环境变量安全
```typescript
// 只暴露必要的环境变量
// VITE_开头的变量会被暴露到客户端
const API_URL = import.meta.env.VITE_API_URL;
// 敏感信息不要使用VITE_前缀
```

## 集成方式

### 与状态管理库集成
```typescript
// Zustand集成
import { create } from 'zustand';

interface AppState {
  user: User | null;
  setUser: (user: User) => void;
}

const useAppStore = create<AppState>((set) => ({
  user: null,
  setUser: (user) => set({ user }),
}));
```

### 与路由集成
```typescript
// React Router集成
import { BrowserRouter, Routes, Route } from 'react-router-dom';

function App() {
  return (
    <BrowserRouter>
      <Routes>
        <Route path="/" element={<Home />} />
        <Route path="/about" element={<About />} />
      </Routes>
    </BrowserRouter>
  );
}
```

## 更新策略

### 版本管理
- 跟随React官方发布节奏
- 主版本更新前充分测试
- 使用React DevTools监控性能
- 关注React RFC了解未来特性

### 迁移指南
- 逐步迁移到新特性
- 使用codemod工具自动化迁移
- 保持依赖库的兼容性
- 建立完善的测试覆盖

## 高级模式与技巧

### 自定义Hooks模式
```typescript
// 数据获取Hook
function useApi<T>(url: string) {
  const [data, setData] = useState<T | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<Error | null>(null);

  useEffect(() => {
    const fetchData = async () => {
      try {
        setLoading(true);
        const response = await fetch(url);
        if (!response.ok) throw new Error('Failed to fetch');
        const result = await response.json();
        setData(result);
      } catch (err) {
        setError(err as Error);
      } finally {
        setLoading(false);
      }
    };

    fetchData();
  }, [url]);

  return { data, loading, error };
}

// 本地存储Hook
function useLocalStorage<T>(key: string, initialValue: T) {
  const [storedValue, setStoredValue] = useState<T>(() => {
    try {
      const item = window.localStorage.getItem(key);
      return item ? JSON.parse(item) : initialValue;
    } catch (error) {
      return initialValue;
    }
  });

  const setValue = (value: T | ((val: T) => T)) => {
    try {
      const valueToStore = value instanceof Function ? value(storedValue) : value;
      setStoredValue(valueToStore);
      window.localStorage.setItem(key, JSON.stringify(valueToStore));
    } catch (error) {
      console.error('Error saving to localStorage:', error);
    }
  };

  return [storedValue, setValue] as const;
}

// 防抖Hook
function useDebounce<T>(value: T, delay: number): T {
  const [debouncedValue, setDebouncedValue] = useState<T>(value);

  useEffect(() => {
    const handler = setTimeout(() => {
      setDebouncedValue(value);
    }, delay);

    return () => {
      clearTimeout(handler);
    };
  }, [value, delay]);

  return debouncedValue;
}
```

### 高阶组件(HOC)模式
```typescript
// 认证HOC
function withAuth<P extends object>(Component: React.ComponentType<P>) {
  return function AuthenticatedComponent(props: P) {
    const { user, loading } = useAuth();

    if (loading) return <div>Loading...</div>;
    if (!user) return <div>Please login</div>;

    return <Component {...props} />;
  };
}

// 错误边界HOC
class ErrorBoundary extends React.Component<
  { children: React.ReactNode; fallback: React.ComponentType<{ error: Error }> },
  { hasError: boolean; error: Error | null }
> {
  constructor(props: any) {
    super(props);
    this.state = { hasError: false, error: null };
  }

  static getDerivedStateFromError(error: Error) {
    return { hasError: true, error };
  }

  componentDidCatch(error: Error, errorInfo: React.ErrorInfo) {
    console.error('Error caught by boundary:', error, errorInfo);
  }

  render() {
    if (this.state.hasError) {
      const FallbackComponent = this.props.fallback;
      return <FallbackComponent error={this.state.error!} />;
    }

    return this.props.children;
  }
}
```

### Render Props模式
```typescript
// 数据提供者组件
interface DataProviderProps<T> {
  url: string;
  children: (data: {
    data: T | null;
    loading: boolean;
    error: Error | null;
    refetch: () => void;
  }) => React.ReactNode;
}

function DataProvider<T>({ url, children }: DataProviderProps<T>) {
  const [data, setData] = useState<T | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<Error | null>(null);

  const fetchData = useCallback(async () => {
    try {
      setLoading(true);
      setError(null);
      const response = await fetch(url);
      if (!response.ok) throw new Error('Failed to fetch');
      const result = await response.json();
      setData(result);
    } catch (err) {
      setError(err as Error);
    } finally {
      setLoading(false);
    }
  }, [url]);

  useEffect(() => {
    fetchData();
  }, [fetchData]);

  return <>{children({ data, loading, error, refetch: fetchData })}</>;
}

// 使用示例
function UserList() {
  return (
    <DataProvider<User[]> url="/api/users">
      {({ data, loading, error, refetch }) => {
        if (loading) return <div>Loading users...</div>;
        if (error) return <div>Error: {error.message}</div>;
        if (!data) return <div>No data</div>;

        return (
          <div>
            <button onClick={refetch}>Refresh</button>
            {data.map(user => (
              <div key={user.id}>{user.name}</div>
            ))}
          </div>
        );
      }}
    </DataProvider>
  );
}

## 故障排查指南

### 常见错误及解决方案
```typescript
// 错误1: Cannot read property of undefined
// 原因: 异步数据未加载完成就尝试访问
// ❌ 错误示例
function UserProfile({ userId }: { userId: string }) {
  const [user, setUser] = useState<User>();

  useEffect(() => {
    fetchUser(userId).then(setUser);
  }, [userId]);

  return <div>{user.name}</div>; // 错误：user可能为undefined
}

// ✅ 正确示例
function UserProfile({ userId }: { userId: string }) {
  const [user, setUser] = useState<User | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    setLoading(true);
    fetchUser(userId)
      .then(setUser)
      .finally(() => setLoading(false));
  }, [userId]);

  if (loading) return <div>Loading...</div>;
  if (!user) return <div>User not found</div>;

  return <div>{user.name}</div>;
}

// 错误2: Memory leak - 组件卸载后仍然执行setState
// ❌ 错误示例
function Component() {
  const [data, setData] = useState(null);

  useEffect(() => {
    fetchData().then(setData); // 组件卸载后可能仍然执行
  }, []);

  return <div>{data}</div>;
}

// ✅ 正确示例
function Component() {
  const [data, setData] = useState(null);

  useEffect(() => {
    let cancelled = false;

    fetchData().then(result => {
      if (!cancelled) {
        setData(result);
      }
    });

    return () => {
      cancelled = true;
    };
  }, []);

  return <div>{data}</div>;
}

// 错误3: 无限重渲染
// ❌ 错误示例
function Component() {
  const [count, setCount] = useState(0);

  // 每次渲染都会创建新的对象，导致无限循环
  useEffect(() => {
    console.log('Effect runs');
  }, [{ count }]);

  return <div>{count}</div>;
}

// ✅ 正确示例
function Component() {
  const [count, setCount] = useState(0);

  useEffect(() => {
    console.log('Effect runs');
  }, [count]); // 直接使用原始值

  return <div>{count}</div>;
}
```

### 性能问题诊断
```typescript
// 使用React DevTools Profiler
// 1. 安装React DevTools浏览器扩展
// 2. 在Profiler标签页中录制组件渲染
// 3. 分析渲染时间和重渲染原因

// 检测不必要的重渲染
function useWhyDidYouUpdate(name: string, props: Record<string, any>) {
  const previous = useRef<Record<string, any>>();

  useEffect(() => {
    if (previous.current) {
      const allKeys = Object.keys({ ...previous.current, ...props });
      const changedProps: Record<string, any> = {};

      allKeys.forEach(key => {
        if (previous.current![key] !== props[key]) {
          changedProps[key] = {
            from: previous.current![key],
            to: props[key]
          };
        }
      });

      if (Object.keys(changedProps).length) {
        console.log('[why-did-you-update]', name, changedProps);
      }
    }

    previous.current = props;
  });
}

// 使用示例
function ExpensiveComponent(props: any) {
  useWhyDidYouUpdate('ExpensiveComponent', props);

  return <div>Expensive computation...</div>;
}
```

### 调试技巧
```typescript
// 1. 使用React DevTools
// - 检查组件树结构
// - 查看props和state
// - 分析性能问题

// 2. 自定义调试Hook
function useDebugValue(value: any, formatter?: (value: any) => string) {
  React.useDebugValue(value, formatter);
  return value;
}

// 3. 条件断点
function Component() {
  const [count, setCount] = useState(0);

  // 在开发环境中添加调试信息
  if (process.env.NODE_ENV === 'development') {
    console.log('Component render:', { count });
  }

  return <div>{count}</div>;
}

// 4. 错误边界调试
function ErrorFallback({ error, resetErrorBoundary }: any) {
  return (
    <div role="alert">
      <h2>Something went wrong:</h2>
      <pre>{error.message}</pre>
      <button onClick={resetErrorBoundary}>Try again</button>
    </div>
  );
}
```

## React开发最佳实践检查清单

### 组件设计
```markdown
- [ ] 组件职责单一，功能明确
- [ ] Props接口清晰，类型安全
- [ ] 合理使用默认Props
- [ ] 避免过深的组件嵌套
- [ ] 使用组合而非继承
```

### 状态管理
```markdown
- [ ] 状态提升到合适的层级
- [ ] 避免不必要的全局状态
- [ ] 使用useReducer处理复杂状态
- [ ] 合理使用Context避免prop drilling
- [ ] 异步状态使用专门的库管理
```

### 性能优化
```markdown
- [ ] 使用React.memo避免不必要重渲染
- [ ] 合理使用useMemo和useCallback
- [ ] 实现代码分割和懒加载
- [ ] 优化列表渲染性能
- [ ] 避免在render中创建对象和函数
```

### 代码质量
```markdown
- [ ] TypeScript类型定义完整
- [ ] ESLint规则配置合理
- [ ] 组件测试覆盖充分
- [ ] 错误边界处理完善
- [ ] 可访问性(a11y)考虑周全
```

### 安全性
```markdown
- [ ] 避免XSS攻击风险
- [ ] 敏感数据不暴露到客户端
- [ ] 使用HTTPS和CSP策略
- [ ] 输入验证和清理
- [ ] 第三方依赖安全审计
```
```
