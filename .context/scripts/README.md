# AnyRules 通用脚本库

这个脚本库包含了各种实用的开发和运维脚本，供AnyRules系统的AI专家调用，以提供更精准和实用的技术支持。

## 📁 脚本列表

### 🚀 项目初始化脚本

#### `init-react-project.sh`
React + TypeScript 项目初始化脚本
```bash
# 基础项目
./init-react-project.sh my-app basic

# 完整项目 (包含路由、状态管理、UI库)
./init-react-project.sh my-app full

# Next.js 项目
./init-react-project.sh my-app nextjs
```

#### `init-node-api.sh`
Node.js API 项目初始化脚本
```bash
# MongoDB 后端
./init-node-api.sh my-api mongodb

# PostgreSQL 后端
./init-node-api.sh my-api postgresql

# MySQL 后端
./init-node-api.sh my-api mysql
```

### 🚀 部署和运维脚本

#### `deploy-docker.sh`
Docker 部署脚本
```bash
# 部署到生产环境
./deploy-docker.sh myapp production

# 部署到测试环境
./deploy-docker.sh myapp staging

# 使用镜像仓库
./deploy-docker.sh myapp production registry.example.com
```

#### `backup-database.sh`
数据库备份脚本
```bash
# 备份 MySQL
./backup-database.sh mysql mydb

# 备份 PostgreSQL
./backup-database.sh postgresql mydb

# 备份 MongoDB
./backup-database.sh mongodb mydb
```

### 📊 监控和诊断脚本

#### `system-monitor.py`
系统监控脚本
```bash
# 基础监控
python system-monitor.py

# 自定义监控间隔和告警阈值
python system-monitor.py --interval 10 --alert-cpu 90 --alert-memory 95

# 输出到文件
python system-monitor.py --output system.log
```

**功能特性:**
- 实时监控 CPU、内存、磁盘、网络使用情况
- 进程监控和排序
- 可配置的告警阈值
- 邮件告警支持
- JSON 格式日志输出

#### `log-analyzer.py`
日志分析脚本
```bash
# 分析 Nginx 日志
python log-analyzer.py /var/log/nginx/access.log --format nginx

# 只分析错误请求
python log-analyzer.py /var/log/nginx/access.log --errors-only

# 分析 JSON 格式日志
python log-analyzer.py app.log --format json --top 20
```

**功能特性:**
- 支持 Nginx、Apache、JSON 格式日志
- 统计分析：IP、URL、状态码、用户代理
- 错误分析和时间分布
- 可视化报告生成

### ⚡ 性能测试脚本

#### `load-test.py`
HTTP 负载测试脚本
```bash
# 基础负载测试
python load-test.py http://example.com --concurrent 50 --requests 1000

# 基于时间的测试
python load-test.py http://example.com --concurrent 20 --duration 300

# 保存测试报告
python load-test.py http://example.com -c 10 -n 100 --output report.json
```

**功能特性:**
- 异步并发请求
- 详细的性能统计 (响应时间、RPS、百分位数)
- 错误分析和状态码统计
- JSON 格式报告输出

### 🔍 代码质量检查脚本

#### `code-quality-check.sh`
代码质量检查脚本
```bash
# 检查当前项目
./code-quality-check.sh

# 检查指定项目并自动修复
./code-quality-check.sh /path/to/project --fix

# 生成详细报告
./code-quality-check.sh . --report quality-report.json
```

**检查项目:**
- **Node.js**: 依赖安全性、ESLint、Prettier、TypeScript
- **Python**: 安全检查、Black、Flake8、MyPy
- **Git**: 未提交更改、大文件、敏感文件
- **Docker**: Dockerfile 最佳实践、.dockerignore
- **安全**: 硬编码密钥、TODO 注释

## 🛠️ 使用前准备

### 权限设置
```bash
# 给脚本执行权限
chmod +x .context/scripts/*.sh
```

### 依赖安装

#### Python 脚本依赖
```bash
# 系统监控脚本
pip install psutil

# 负载测试脚本
pip install aiohttp

# 日志分析脚本 (可选地理位置功能)
pip install geoip2
```

#### 系统工具依赖
```bash
# Ubuntu/Debian
sudo apt-get install jq curl

# macOS
brew install jq curl

# 数据库工具 (根据需要安装)
sudo apt-get install mysql-client postgresql-client mongodb-tools
```

## 🎯 使用场景

### 🆕 新项目启动
1. 使用 `init-react-project.sh` 或 `init-node-api.sh` 快速搭建项目
2. 使用 `code-quality-check.sh` 确保代码质量
3. 使用 `deploy-docker.sh` 容器化部署

### 🐛 问题排查
1. 使用 `system-monitor.py` 监控系统资源
2. 使用 `log-analyzer.py` 分析应用日志
3. 使用 `load-test.py` 进行性能测试

### 🚀 生产运维
1. 使用 `backup-database.sh` 定期备份数据库
2. 使用 `deploy-docker.sh` 自动化部署
3. 使用 `system-monitor.py` 持续监控

### 🧪 质量保证
1. 使用 `code-quality-check.sh` 进行代码审查
2. 使用 `load-test.py` 进行性能测试
3. 集成到 CI/CD 流水线

## 📧 环境变量配置

### 邮件告警配置 (system-monitor.py)
```bash
export SMTP_SERVER="smtp.gmail.com"
export SMTP_PORT="587"
export EMAIL_USER="your-email@gmail.com"
export EMAIL_PASSWORD="your-app-password"
export ALERT_RECIPIENTS="admin@example.com,ops@example.com"
```

### 数据库连接配置
```bash
# MySQL
export MYSQL_HOST="localhost"
export MYSQL_USER="root"
export MYSQL_PASSWORD="password"

# PostgreSQL
export PGHOST="localhost"
export PGUSER="postgres"
export PGPASSWORD="password"

# MongoDB
export MONGO_HOST="localhost"
export MONGO_USER="admin"
export MONGO_PASSWORD="password"
```

## 🔄 定时任务示例

### Crontab 配置
```bash
# 每天凌晨2点备份数据库
0 2 * * * /path/to/backup-database.sh mysql myapp_db

# 每小时检查系统状态
0 * * * * /usr/bin/python3 /path/to/system-monitor.py --interval 60 --output /var/log/system-monitor.log

# 每天分析前一天的日志
0 6 * * * /usr/bin/python3 /path/to/log-analyzer.py /var/log/nginx/access.log.1 --output /var/log/daily-report.json
```

## 🤝 贡献指南

欢迎为脚本库贡献新的脚本或改进现有脚本：

1. **脚本质量**: 确保脚本的可用性和稳定性
2. **错误处理**: 包含完善的错误处理和用户友好的错误信息
3. **文档完整**: 提供详细的使用说明和示例
4. **跨平台**: 尽可能支持多种操作系统
5. **安全性**: 避免硬编码敏感信息，使用环境变量

## 📞 获取帮助

如果您在使用脚本过程中遇到问题：

1. **查看脚本帮助**: 大多数脚本支持 `--help` 参数
2. **检查依赖**: 确保安装了必要的系统工具和 Python 包
3. **权限问题**: 确保脚本有执行权限
4. **咨询AI专家**: 通过AnyRules系统咨询相关专家

---

*AnyRules Scripts Library - 让每一行代码都有最佳的工具支持*
