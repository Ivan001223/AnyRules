#!/bin/bash

# Node.js API 项目初始化脚本
# 用法: ./init-node-api.sh <project-name> [database]
# 数据库选项: mongodb, postgresql, mysql

set -e

PROJECT_NAME=${1:-"my-api"}
DATABASE=${2:-"mongodb"}

echo "🚀 初始化 Node.js API 项目: $PROJECT_NAME (数据库: $DATABASE)"

# 检查必要工具
command -v node >/dev/null 2>&1 || { echo "❌ Node.js 未安装"; exit 1; }
command -v npm >/dev/null 2>&1 || { echo "❌ npm 未安装"; exit 1; }

# 创建项目目录
mkdir -p $PROJECT_NAME
cd $PROJECT_NAME

# 初始化 package.json
npm init -y

# 安装基础依赖
echo "📦 安装基础依赖..."
npm install express cors helmet morgan dotenv bcryptjs jsonwebtoken
npm install -D typescript @types/node @types/express @types/cors @types/bcryptjs @types/jsonwebtoken
npm install -D nodemon ts-node eslint prettier @typescript-eslint/eslint-plugin @typescript-eslint/parser

# 根据数据库类型安装相应依赖
case $DATABASE in
  "mongodb")
    echo "📦 安装 MongoDB 依赖..."
    npm install mongoose
    npm install -D @types/mongoose
    ;;
  "postgresql")
    echo "📦 安装 PostgreSQL 依赖..."
    npm install pg sequelize
    npm install -D @types/pg
    ;;
  "mysql")
    echo "📦 安装 MySQL 依赖..."
    npm install mysql2 sequelize
    ;;
  *)
    echo "❌ 未知数据库类型: $DATABASE"
    exit 1
    ;;
esac

# 创建 TypeScript 配置
cat > tsconfig.json << 'EOF'
{
  "compilerOptions": {
    "target": "ES2020",
    "module": "commonjs",
    "lib": ["ES2020"],
    "outDir": "./dist",
    "rootDir": "./src",
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true,
    "resolveJsonModule": true,
    "declaration": true,
    "declarationMap": true,
    "sourceMap": true
  },
  "include": ["src/**/*"],
  "exclude": ["node_modules", "dist"]
}
EOF

# 创建目录结构
mkdir -p src/{routes,controllers,models,middleware,utils,types,config}

# 创建主应用文件
cat > src/app.ts << 'EOF'
import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import morgan from 'morgan';
import dotenv from 'dotenv';

import { errorHandler } from './middleware/errorHandler';
import { notFound } from './middleware/notFound';
import userRoutes from './routes/userRoutes';

dotenv.config();

const app = express();

// 中间件
app.use(helmet());
app.use(cors());
app.use(morgan('combined'));
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true }));

// 路由
app.use('/api/users', userRoutes);

// 健康检查
app.get('/health', (req, res) => {
  res.status(200).json({ status: 'OK', timestamp: new Date().toISOString() });
});

// 错误处理中间件
app.use(notFound);
app.use(errorHandler);

export default app;
EOF

# 创建服务器启动文件
cat > src/server.ts << 'EOF'
import app from './app';
import { connectDatabase } from './config/database';

const PORT = process.env.PORT || 3000;

async function startServer() {
  try {
    // 连接数据库
    await connectDatabase();
    
    // 启动服务器
    app.listen(PORT, () => {
      console.log(`🚀 服务器运行在端口 ${PORT}`);
      console.log(`📊 健康检查: http://localhost:${PORT}/health`);
    });
  } catch (error) {
    console.error('❌ 服务器启动失败:', error);
    process.exit(1);
  }
}

startServer();
EOF

# 创建数据库配置
case $DATABASE in
  "mongodb")
    cat > src/config/database.ts << 'EOF'
import mongoose from 'mongoose';

export async function connectDatabase(): Promise<void> {
  try {
    const mongoUri = process.env.MONGODB_URI || 'mongodb://localhost:27017/myapi';
    await mongoose.connect(mongoUri);
    console.log('✅ MongoDB 连接成功');
  } catch (error) {
    console.error('❌ MongoDB 连接失败:', error);
    throw error;
  }
}
EOF
    ;;
  "postgresql")
    cat > src/config/database.ts << 'EOF'
import { Sequelize } from 'sequelize';

const sequelize = new Sequelize(
  process.env.DATABASE_URL || 'postgresql://localhost:5432/myapi',
  {
    logging: process.env.NODE_ENV === 'development' ? console.log : false,
  }
);

export async function connectDatabase(): Promise<void> {
  try {
    await sequelize.authenticate();
    console.log('✅ PostgreSQL 连接成功');
  } catch (error) {
    console.error('❌ PostgreSQL 连接失败:', error);
    throw error;
  }
}

export { sequelize };
EOF
    ;;
esac

# 创建用户模型
case $DATABASE in
  "mongodb")
    cat > src/models/User.ts << 'EOF'
import mongoose, { Document, Schema } from 'mongoose';
import bcrypt from 'bcryptjs';

export interface IUser extends Document {
  name: string;
  email: string;
  password: string;
  createdAt: Date;
  updatedAt: Date;
  comparePassword(candidatePassword: string): Promise<boolean>;
}

const userSchema = new Schema<IUser>({
  name: { type: String, required: true },
  email: { type: String, required: true, unique: true },
  password: { type: String, required: true },
}, {
  timestamps: true,
});

userSchema.pre('save', async function(next) {
  if (!this.isModified('password')) return next();
  this.password = await bcrypt.hash(this.password, 12);
  next();
});

userSchema.methods.comparePassword = async function(candidatePassword: string): Promise<boolean> {
  return bcrypt.compare(candidatePassword, this.password);
};

export default mongoose.model<IUser>('User', userSchema);
EOF
    ;;
esac

# 创建控制器
cat > src/controllers/userController.ts << 'EOF'
import { Request, Response, NextFunction } from 'express';
import jwt from 'jsonwebtoken';
import User from '../models/User';

const generateToken = (id: string): string => {
  return jwt.sign({ id }, process.env.JWT_SECRET || 'fallback-secret', {
    expiresIn: '30d',
  });
};

export const registerUser = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const { name, email, password } = req.body;

    const userExists = await User.findOne({ email });
    if (userExists) {
      return res.status(400).json({ message: '用户已存在' });
    }

    const user = await User.create({ name, email, password });

    res.status(201).json({
      _id: user._id,
      name: user.name,
      email: user.email,
      token: generateToken(user._id.toString()),
    });
  } catch (error) {
    next(error);
  }
};

export const loginUser = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const { email, password } = req.body;

    const user = await User.findOne({ email });
    if (user && (await user.comparePassword(password))) {
      res.json({
        _id: user._id,
        name: user.name,
        email: user.email,
        token: generateToken(user._id.toString()),
      });
    } else {
      res.status(401).json({ message: '邮箱或密码错误' });
    }
  } catch (error) {
    next(error);
  }
};

export const getUsers = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const users = await User.find({}).select('-password');
    res.json(users);
  } catch (error) {
    next(error);
  }
};
EOF

# 创建路由
cat > src/routes/userRoutes.ts << 'EOF'
import express from 'express';
import { registerUser, loginUser, getUsers } from '../controllers/userController';
import { protect } from '../middleware/auth';

const router = express.Router();

router.post('/register', registerUser);
router.post('/login', loginUser);
router.get('/', protect, getUsers);

export default router;
EOF

# 创建中间件
cat > src/middleware/auth.ts << 'EOF'
import { Request, Response, NextFunction } from 'express';
import jwt from 'jsonwebtoken';
import User from '../models/User';

interface AuthRequest extends Request {
  user?: any;
}

export const protect = async (req: AuthRequest, res: Response, next: NextFunction) => {
  try {
    let token;

    if (req.headers.authorization && req.headers.authorization.startsWith('Bearer')) {
      token = req.headers.authorization.split(' ')[1];
    }

    if (!token) {
      return res.status(401).json({ message: '未授权访问' });
    }

    const decoded = jwt.verify(token, process.env.JWT_SECRET || 'fallback-secret') as any;
    req.user = await User.findById(decoded.id).select('-password');

    next();
  } catch (error) {
    res.status(401).json({ message: '令牌无效' });
  }
};
EOF

cat > src/middleware/errorHandler.ts << 'EOF'
import { Request, Response, NextFunction } from 'express';

export const errorHandler = (err: any, req: Request, res: Response, next: NextFunction) => {
  let error = { ...err };
  error.message = err.message;

  console.error(err);

  // Mongoose 错误处理
  if (err.name === 'CastError') {
    const message = '资源未找到';
    error = { message, statusCode: 404 };
  }

  if (err.code === 11000) {
    const message = '重复字段值';
    error = { message, statusCode: 400 };
  }

  if (err.name === 'ValidationError') {
    const message = Object.values(err.errors).map((val: any) => val.message).join(', ');
    error = { message, statusCode: 400 };
  }

  res.status(error.statusCode || 500).json({
    success: false,
    error: error.message || '服务器错误',
  });
};
EOF

cat > src/middleware/notFound.ts << 'EOF'
import { Request, Response, NextFunction } from 'express';

export const notFound = (req: Request, res: Response, next: NextFunction) => {
  const error = new Error(`路径未找到 - ${req.originalUrl}`);
  res.status(404);
  next(error);
};
EOF

# 创建环境变量文件
cat > .env.example << 'EOF'
NODE_ENV=development
PORT=3000
JWT_SECRET=your-super-secret-jwt-key
MONGODB_URI=mongodb://localhost:27017/myapi
EOF

cp .env.example .env

# 更新 package.json 脚本
npm pkg set scripts.dev="nodemon src/server.ts"
npm pkg set scripts.build="tsc"
npm pkg set scripts.start="node dist/server.js"
npm pkg set scripts.lint="eslint src/**/*.ts"
npm pkg set scripts.format="prettier --write src/**/*.ts"

# 创建 ESLint 配置
cat > .eslintrc.js << 'EOF'
module.exports = {
  parser: '@typescript-eslint/parser',
  extends: [
    '@typescript-eslint/recommended',
  ],
  parserOptions: {
    ecmaVersion: 2020,
    sourceType: 'module',
  },
  rules: {
    '@typescript-eslint/no-unused-vars': 'error',
    '@typescript-eslint/explicit-function-return-type': 'warn',
  },
};
EOF

# 创建 Prettier 配置
cat > .prettierrc << 'EOF'
{
  "semi": true,
  "trailingComma": "es5",
  "singleQuote": true,
  "printWidth": 80,
  "tabWidth": 2
}
EOF

# 创建 .gitignore
cat > .gitignore << 'EOF'
node_modules/
dist/
.env
*.log
.DS_Store
coverage/
EOF

# 初始化 Git
git init
git add .
git commit -m "Initial commit: Node.js API project setup"

echo "✅ Node.js API 项目 $PROJECT_NAME 初始化完成！"
echo "📁 项目目录: $(pwd)"
echo "🚀 启动开发服务器: npm run dev"
echo "📦 构建项目: npm run build"
echo "🔧 记得配置 .env 文件中的环境变量"
