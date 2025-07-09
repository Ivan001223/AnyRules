# Docker 工具规则文档

## 工具概述
Docker是一个开源的容器化平台，用于开发、部署和运行应用程序。

### 适用场景
- 应用程序容器化
- 开发环境标准化
- 微服务部署
- CI/CD流水线
- 云原生应用开发

### 核心概念
- **镜像(Image)**: 只读的应用程序模板
- **容器(Container)**: 镜像的运行实例
- **Dockerfile**: 构建镜像的指令文件
- **仓库(Registry)**: 存储和分发镜像的服务

## 最佳实践

### Dockerfile 最佳实践
```dockerfile
# 使用官方基础镜像
FROM node:18-alpine AS base

# 设置工作目录
WORKDIR /app

# 复制package文件并安装依赖（利用缓存层）
COPY package*.json ./
RUN npm ci --only=production && npm cache clean --force

# 多阶段构建 - 构建阶段
FROM base AS builder
COPY . .
RUN npm run build

# 多阶段构建 - 生产阶段
FROM base AS production

# 创建非root用户
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nextjs -u 1001

# 复制构建产物
COPY --from=builder --chown=nextjs:nodejs /app/dist ./dist
COPY --from=builder --chown=nextjs:nodejs /app/public ./public

# 切换到非root用户
USER nextjs

# 暴露端口
EXPOSE 3000

# 健康检查
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:3000/health || exit 1

# 启动命令
CMD ["node", "dist/index.js"]

# 标签信息
LABEL maintainer="your-email@example.com" \
      version="1.0.0" \
      description="Node.js应用容器"
```

### 优化策略
```dockerfile
# Python应用优化示例
FROM python:3.11-slim AS base

# 设置环境变量
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

# 安装系统依赖
RUN apt-get update && apt-get install -y \
    build-essential \
    curl \
    && rm -rf /var/lib/apt/lists/*

# 创建应用用户
RUN groupadd -r appuser && useradd -r -g appuser appuser

WORKDIR /app

# 安装Python依赖
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# 复制应用代码
COPY --chown=appuser:appuser . .

# 切换用户
USER appuser

# 暴露端口
EXPOSE 8000

# 启动命令
CMD ["gunicorn", "--bind", "0.0.0.0:8000", "app:app"]

# Go应用优化示例
FROM golang:1.21-alpine AS builder

WORKDIR /app

# 复制go mod文件
COPY go.mod go.sum ./
RUN go mod download

# 复制源代码
COPY . .

# 构建应用
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o main .

# 最小化生产镜像
FROM alpine:latest

RUN apk --no-cache add ca-certificates
WORKDIR /root/

# 复制二进制文件
COPY --from=builder /app/main .

# 暴露端口
EXPOSE 8080

# 启动命令
CMD ["./main"]
```

## 配置规范

### docker-compose.yml 配置
```yaml
version: '3.8'

services:
  # Web应用
  web:
    build:
      context: .
      dockerfile: Dockerfile
      target: production
    ports:
      - "3000:3000"
    environment:
      - NODE_ENV=production
      - DATABASE_URL=postgresql://user:password@db:5432/myapp
      - REDIS_URL=redis://redis:6379
    depends_on:
      db:
        condition: service_healthy
      redis:
        condition: service_started
    volumes:
      - ./logs:/app/logs
    networks:
      - app-network
    restart: unless-stopped
    deploy:
      resources:
        limits:
          cpus: '0.5'
          memory: 512M
        reservations:
          cpus: '0.25'
          memory: 256M

  # 数据库
  db:
    image: postgres:15-alpine
    environment:
      POSTGRES_DB: myapp
      POSTGRES_USER: user
      POSTGRES_PASSWORD: password
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./init.sql:/docker-entrypoint-initdb.d/init.sql
    ports:
      - "5432:5432"
    networks:
      - app-network
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U user -d myapp"]
      interval: 10s
      timeout: 5s
      retries: 5
    restart: unless-stopped

  # Redis缓存
  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"
    volumes:
      - redis_data:/data
    networks:
      - app-network
    command: redis-server --appendonly yes
    restart: unless-stopped

  # Nginx反向代理
  nginx:
    image: nginx:alpine
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf
      - ./ssl:/etc/nginx/ssl
    depends_on:
      - web
    networks:
      - app-network
    restart: unless-stopped

  # 监控
  prometheus:
    image: prom/prometheus:latest
    ports:
      - "9090:9090"
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml
      - prometheus_data:/prometheus
    networks:
      - app-network
    restart: unless-stopped

  grafana:
    image: grafana/grafana:latest
    ports:
      - "3001:3000"
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=admin
    volumes:
      - grafana_data:/var/lib/grafana
    networks:
      - app-network
    restart: unless-stopped

volumes:
  postgres_data:
  redis_data:
  prometheus_data:
  grafana_data:

networks:
  app-network:
    driver: bridge
```

### 环境配置
```yaml
# docker-compose.override.yml (开发环境)
version: '3.8'

services:
  web:
    build:
      target: development
    volumes:
      - .:/app
      - /app/node_modules
    environment:
      - NODE_ENV=development
      - DEBUG=app:*
    command: npm run dev

  db:
    ports:
      - "5432:5432"
    environment:
      POSTGRES_DB: myapp_dev

# docker-compose.prod.yml (生产环境)
version: '3.8'

services:
  web:
    image: myapp:latest
    deploy:
      replicas: 3
      update_config:
        parallelism: 1
        delay: 10s
      restart_policy:
        condition: on-failure
        delay: 5s
        max_attempts: 3

  db:
    environment:
      POSTGRES_PASSWORD_FILE: /run/secrets/db_password
    secrets:
      - db_password

secrets:
  db_password:
    external: true
```

## 常见问题与解决方案

### 镜像大小优化
```dockerfile
# 问题：镜像过大
# 解决方案：

# 1. 使用Alpine基础镜像
FROM node:18-alpine instead of FROM node:18

# 2. 多阶段构建
FROM node:18-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

FROM node:18-alpine AS production
WORKDIR /app
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/node_modules ./node_modules
CMD ["node", "dist/index.js"]

# 3. 清理缓存和临时文件
RUN apt-get update && apt-get install -y \
    build-essential \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# 4. 使用.dockerignore
# .dockerignore
node_modules
npm-debug.log
.git
.gitignore
README.md
.env
coverage
.nyc_output
```

### 容器安全
```dockerfile
# 安全最佳实践

# 1. 使用非root用户
RUN groupadd -r appuser && useradd -r -g appuser appuser
USER appuser

# 2. 最小权限原则
RUN chmod +x /app/start.sh && \
    chown appuser:appuser /app/start.sh

# 3. 扫描漏洞
# 使用工具如 Trivy, Clair 扫描镜像

# 4. 签名镜像
# 使用 Docker Content Trust
export DOCKER_CONTENT_TRUST=1

# 5. 限制资源
# docker-compose.yml
deploy:
  resources:
    limits:
      cpus: '0.5'
      memory: 512M
    reservations:
      cpus: '0.25'
      memory: 256M
```

### 网络配置
```yaml
# 自定义网络
networks:
  frontend:
    driver: bridge
  backend:
    driver: bridge
    internal: true  # 内部网络，不能访问外网

services:
  web:
    networks:
      - frontend
      - backend
  
  db:
    networks:
      - backend  # 只在后端网络

# 端口映射
ports:
  - "3000:3000"        # host:container
  - "127.0.0.1:3000:3000"  # 只绑定本地
  - "3000"             # 随机主机端口

# 服务发现
services:
  web:
    depends_on:
      - db
    environment:
      - DB_HOST=db  # 使用服务名作为主机名
```

## 性能优化

### 构建优化
```dockerfile
# 缓存优化
# 将变化频率低的操作放在前面
COPY package*.json ./
RUN npm ci

# 将变化频率高的操作放在后面
COPY . .
RUN npm run build

# 并行构建
FROM base AS deps
COPY package*.json ./
RUN npm ci

FROM base AS builder
COPY --from=deps /app/node_modules ./node_modules
COPY . .
RUN npm run build

FROM base AS runner
COPY --from=deps /app/node_modules ./node_modules
COPY --from=builder /app/dist ./dist
```

### 运行时优化
```yaml
# 资源限制
services:
  web:
    deploy:
      resources:
        limits:
          cpus: '1.0'
          memory: 1G
        reservations:
          cpus: '0.5'
          memory: 512M

# 健康检查
healthcheck:
  test: ["CMD", "curl", "-f", "http://localhost:3000/health"]
  interval: 30s
  timeout: 10s
  retries: 3
  start_period: 40s

# 重启策略
restart: unless-stopped

# 日志配置
logging:
  driver: "json-file"
  options:
    max-size: "10m"
    max-file: "3"
```

### 监控和调试
```bash
# 容器监控
docker stats
docker logs -f container_name
docker exec -it container_name /bin/sh

# 性能分析
docker system df  # 磁盘使用
docker system prune  # 清理未使用资源

# 网络调试
docker network ls
docker network inspect network_name

# 卷管理
docker volume ls
docker volume inspect volume_name
```

## 安全考虑

### 镜像安全
```dockerfile
# 安全扫描
# 使用官方镜像
FROM node:18-alpine

# 定期更新基础镜像
RUN apk update && apk upgrade

# 移除不必要的包
RUN apk del build-dependencies

# 验证下载文件
RUN wget -O app.tar.gz https://example.com/app.tar.gz && \
    echo "expected_hash app.tar.gz" | sha256sum -c -

# 设置安全标头
LABEL security.scan="enabled"
```

### 运行时安全
```yaml
# docker-compose.yml 安全配置
services:
  web:
    # 只读根文件系统
    read_only: true
    
    # 临时文件系统
    tmpfs:
      - /tmp
      - /var/tmp
    
    # 安全选项
    security_opt:
      - no-new-privileges:true
    
    # 用户命名空间
    user: "1000:1000"
    
    # 限制能力
    cap_drop:
      - ALL
    cap_add:
      - NET_BIND_SERVICE
    
    # 禁用特权模式
    privileged: false
```

## 集成方式

### CI/CD集成
```yaml
# GitHub Actions
name: Docker Build and Deploy

on:
  push:
    branches: [main]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v2
      
      - name: Login to DockerHub
        uses: docker/login-action@v2
        with:
          username: ${{ secrets.DOCKERHUB_USERNAME }}
          password: ${{ secrets.DOCKERHUB_TOKEN }}
      
      - name: Build and push
        uses: docker/build-push-action@v4
        with:
          context: .
          push: true
          tags: myapp:latest
          cache-from: type=gha
          cache-to: type=gha,mode=max
      
      - name: Deploy to production
        run: |
          docker-compose -f docker-compose.prod.yml up -d
```

### Kubernetes集成
```yaml
# deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp
spec:
  replicas: 3
  selector:
    matchLabels:
      app: myapp
  template:
    metadata:
      labels:
        app: myapp
    spec:
      containers:
      - name: myapp
        image: myapp:latest
        ports:
        - containerPort: 3000
        env:
        - name: DATABASE_URL
          valueFrom:
            secretKeyRef:
              name: myapp-secrets
              key: database-url
        resources:
          requests:
            memory: "256Mi"
            cpu: "250m"
          limits:
            memory: "512Mi"
            cpu: "500m"
        livenessProbe:
          httpGet:
            path: /health
            port: 3000
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /ready
            port: 3000
          initialDelaySeconds: 5
          periodSeconds: 5
```

## 更新策略

### 镜像版本管理
```bash
# 语义化版本标签
docker build -t myapp:1.2.3 .
docker build -t myapp:1.2 .
docker build -t myapp:1 .
docker build -t myapp:latest .

# 滚动更新
docker-compose up -d --no-deps web

# 蓝绿部署
docker-compose -f docker-compose.blue.yml up -d
# 测试通过后
docker-compose -f docker-compose.green.yml up -d
docker-compose -f docker-compose.blue.yml down
```

### 备份和恢复
```bash
# 数据卷备份
docker run --rm -v myapp_data:/data -v $(pwd):/backup alpine \
  tar czf /backup/backup.tar.gz -C /data .

# 数据库备份
docker exec postgres_container pg_dump -U user myapp > backup.sql

# 恢复数据
docker run --rm -v myapp_data:/data -v $(pwd):/backup alpine \
  tar xzf /backup/backup.tar.gz -C /data
```

## 输出模板

### Docker部署清单
```markdown
# Docker部署清单

## 构建检查
- [ ] Dockerfile优化完成
- [ ] 多阶段构建配置
- [ ] 安全扫描通过
- [ ] 镜像大小合理

## 配置检查
- [ ] 环境变量配置
- [ ] 卷挂载配置
- [ ] 网络配置
- [ ] 健康检查配置

## 安全检查
- [ ] 非root用户运行
- [ ] 最小权限原则
- [ ] 敏感信息保护
- [ ] 网络隔离配置

## 监控检查
- [ ] 日志配置
- [ ] 指标收集
- [ ] 告警配置
- [ ] 性能监控

## 部署验证
- [ ] 服务启动正常
- [ ] 健康检查通过
- [ ] 功能测试通过
- [ ] 性能测试通过
```
