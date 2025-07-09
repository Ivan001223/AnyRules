#!/bin/bash

# React + TypeScript 项目初始化脚本
# 用法: ./init-react-project.sh <project-name> [template]
# 模板选项: basic, full, nextjs

set -e

PROJECT_NAME=${1:-"my-react-app"}
TEMPLATE=${2:-"basic"}

echo "🚀 初始化 React 项目: $PROJECT_NAME (模板: $TEMPLATE)"

# 检查必要工具
command -v node >/dev/null 2>&1 || { echo "❌ Node.js 未安装"; exit 1; }
command -v npm >/dev/null 2>&1 || { echo "❌ npm 未安装"; exit 1; }

case $TEMPLATE in
  "basic")
    echo "📦 创建基础 React + TypeScript 项目..."
    npx create-react-app $PROJECT_NAME --template typescript
    cd $PROJECT_NAME
    
    # 安装常用依赖
    npm install @types/node @types/react @types/react-dom
    npm install -D eslint prettier @typescript-eslint/eslint-plugin @typescript-eslint/parser
    
    # 创建基础配置文件
    cat > .eslintrc.js << 'EOF'
module.exports = {
  extends: [
    'react-app',
    'react-app/jest',
    '@typescript-eslint/recommended'
  ],
  parser: '@typescript-eslint/parser',
  plugins: ['@typescript-eslint'],
  rules: {
    '@typescript-eslint/no-unused-vars': 'error',
    '@typescript-eslint/explicit-function-return-type': 'warn'
  }
};
EOF

    cat > .prettierrc << 'EOF'
{
  "semi": true,
  "trailingComma": "es5",
  "singleQuote": true,
  "printWidth": 80,
  "tabWidth": 2
}
EOF
    ;;
    
  "full")
    echo "📦 创建完整 React + TypeScript 项目..."
    npx create-react-app $PROJECT_NAME --template typescript
    cd $PROJECT_NAME
    
    # 安装完整依赖
    npm install @types/node @types/react @types/react-dom
    npm install react-router-dom @types/react-router-dom
    npm install @reduxjs/toolkit react-redux
    npm install axios
    npm install @mui/material @emotion/react @emotion/styled
    npm install -D eslint prettier @typescript-eslint/eslint-plugin @typescript-eslint/parser
    npm install -D husky lint-staged
    
    # 创建目录结构
    mkdir -p src/{components,pages,hooks,store,utils,types,services}
    
    # 创建基础文件
    cat > src/types/index.ts << 'EOF'
export interface User {
  id: string;
  name: string;
  email: string;
}

export interface ApiResponse<T> {
  data: T;
  message: string;
  success: boolean;
}
EOF

    cat > src/services/api.ts << 'EOF'
import axios from 'axios';

const api = axios.create({
  baseURL: process.env.REACT_APP_API_URL || 'http://localhost:3001/api',
  timeout: 10000,
});

api.interceptors.request.use((config) => {
  const token = localStorage.getItem('token');
  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
  }
  return config;
});

export default api;
EOF
    ;;
    
  "nextjs")
    echo "📦 创建 Next.js + TypeScript 项目..."
    npx create-next-app@latest $PROJECT_NAME --typescript --tailwind --eslint --app
    cd $PROJECT_NAME
    
    # 安装额外依赖
    npm install @next/font lucide-react
    npm install class-variance-authority clsx tailwind-merge
    
    # 创建基础组件
    mkdir -p components/ui
    cat > components/ui/button.tsx << 'EOF'
import { ButtonHTMLAttributes, forwardRef } from 'react';
import { clsx } from 'clsx';

interface ButtonProps extends ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: 'default' | 'destructive' | 'outline' | 'secondary' | 'ghost' | 'link';
  size?: 'default' | 'sm' | 'lg' | 'icon';
}

const Button = forwardRef<HTMLButtonElement, ButtonProps>(
  ({ className, variant = 'default', size = 'default', ...props }, ref) => {
    return (
      <button
        className={clsx(
          'inline-flex items-center justify-center rounded-md text-sm font-medium transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:opacity-50 disabled:pointer-events-none ring-offset-background',
          {
            'bg-primary text-primary-foreground hover:bg-primary/90': variant === 'default',
            'bg-destructive text-destructive-foreground hover:bg-destructive/90': variant === 'destructive',
            'border border-input hover:bg-accent hover:text-accent-foreground': variant === 'outline',
            'bg-secondary text-secondary-foreground hover:bg-secondary/80': variant === 'secondary',
            'hover:bg-accent hover:text-accent-foreground': variant === 'ghost',
            'underline-offset-4 hover:underline text-primary': variant === 'link',
          },
          {
            'h-10 py-2 px-4': size === 'default',
            'h-9 px-3 rounded-md': size === 'sm',
            'h-11 px-8 rounded-md': size === 'lg',
            'h-10 w-10': size === 'icon',
          },
          className
        )}
        ref={ref}
        {...props}
      />
    );
  }
);

Button.displayName = 'Button';

export { Button };
EOF
    ;;
    
  *)
    echo "❌ 未知模板: $TEMPLATE"
    echo "可用模板: basic, full, nextjs"
    exit 1
    ;;
esac

# 通用配置
cat > .gitignore << 'EOF'
# Dependencies
node_modules/
/.pnp
.pnp.js

# Testing
/coverage

# Production
/build
/dist

# Environment variables
.env
.env.local
.env.development.local
.env.test.local
.env.production.local

# Logs
npm-debug.log*
yarn-debug.log*
yarn-error.log*

# IDE
.vscode/
.idea/
*.swp
*.swo

# OS
.DS_Store
Thumbs.db
EOF

# 初始化 Git
git init
git add .
git commit -m "Initial commit: $TEMPLATE React project setup"

echo "✅ 项目 $PROJECT_NAME 初始化完成！"
echo "📁 项目目录: $(pwd)"
echo "🚀 启动开发服务器: npm start"
echo "🧪 运行测试: npm test"
echo "📦 构建项目: npm run build"
