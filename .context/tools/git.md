# Git 工具规则文档

## 工具概述
Git是分布式版本控制系统，用于跟踪代码变更、协作开发和版本管理。

### 适用场景
- 代码版本控制
- 团队协作开发
- 分支管理和合并
- 代码审查流程
- 发布版本管理
- 代码备份和恢复

### 核心特性
- 分布式架构
- 分支管理
- 变更追踪
- 合并冲突解决
- 标签和发布管理

## 最佳实践

### 分支策略
```bash
# Git Flow 分支模型
main/master     # 生产分支，只包含稳定代码
develop         # 开发分支，集成最新功能
feature/*       # 功能分支，开发新功能
release/*       # 发布分支，准备发布版本
hotfix/*        # 热修复分支，修复生产问题

# 示例工作流
git checkout develop
git pull origin develop
git checkout -b feature/user-authentication
# 开发功能...
git add .
git commit -m "feat: implement user authentication"
git push origin feature/user-authentication
# 创建Pull Request到develop分支
```

### 提交信息规范
```bash
# 提交信息格式
<type>(<scope>): <description>

[optional body]

[optional footer(s)]

# 提交类型
feat:     新功能
fix:      错误修复
docs:     文档更新
style:    代码格式调整(不影响功能)
refactor: 代码重构
test:     测试相关
chore:    构建过程或辅助工具的变动
perf:     性能优化
ci:       CI/CD相关

# 示例
feat(auth): add user login functionality

Implement JWT-based authentication system with:
- Login endpoint with email/password validation
- Token generation and verification
- Password hashing with bcrypt

Closes #123
```

### 代码审查流程
```bash
# Pull Request工作流
1. 创建功能分支
git checkout -b feature/new-feature

2. 开发和提交
git add .
git commit -m "feat: implement new feature"

3. 推送分支
git push origin feature/new-feature

4. 创建Pull Request
# 在GitHub/GitLab上创建PR

5. 代码审查
# 团队成员审查代码

6. 修改和更新
git add .
git commit -m "fix: address review comments"
git push origin feature/new-feature

7. 合并到主分支
# 审查通过后合并
```

## 配置规范

### 全局配置
```bash
# 用户信息配置
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"

# 编辑器配置
git config --global core.editor "code --wait"

# 默认分支名
git config --global init.defaultBranch main

# 自动换行处理
git config --global core.autocrlf input  # Linux/Mac
git config --global core.autocrlf true   # Windows

# 颜色输出
git config --global color.ui auto

# 别名配置
git config --global alias.st status
git config --global alias.co checkout
git config --global alias.br branch
git config --global alias.ci commit
git config --global alias.unstage 'reset HEAD --'
git config --global alias.last 'log -1 HEAD'
git config --global alias.visual '!gitk'
```

### .gitignore配置
```bash
# Node.js项目
node_modules/
npm-debug.log*
yarn-debug.log*
yarn-error.log*
.env
.env.local
.env.development.local
.env.test.local
.env.production.local
dist/
build/
.DS_Store
*.log

# IDE文件
.vscode/
.idea/
*.swp
*.swo
*~

# 操作系统文件
Thumbs.db
.DS_Store

# 临时文件
*.tmp
*.temp
.cache/

# 测试覆盖率
coverage/
.nyc_output/

# 数据库文件
*.sqlite
*.db
```

### Git Hooks配置
```bash
#!/bin/sh
# .git/hooks/pre-commit
# 提交前检查

echo "Running pre-commit checks..."

# 运行代码检查
npm run lint
if [ $? -ne 0 ]; then
  echo "Lint failed. Please fix the issues before committing."
  exit 1
fi

# 运行测试
npm run test
if [ $? -ne 0 ]; then
  echo "Tests failed. Please fix the issues before committing."
  exit 1
fi

# 检查提交信息格式
commit_regex='^(feat|fix|docs|style|refactor|test|chore|perf|ci)(\(.+\))?: .{1,50}'
if ! grep -qE "$commit_regex" "$1"; then
  echo "Invalid commit message format. Please use conventional commits."
  exit 1
fi

echo "Pre-commit checks passed!"
```

## 常见问题与解决方案

### 合并冲突解决
```bash
# 当合并出现冲突时
git merge feature-branch
# Auto-merging file.txt
# CONFLICT (content): Merge conflict in file.txt

# 查看冲突文件
git status

# 手动解决冲突后
git add file.txt
git commit -m "resolve merge conflict in file.txt"

# 使用合并工具
git config --global merge.tool vimdiff
git mergetool

# 取消合并
git merge --abort
```

### 历史记录管理
```bash
# 查看提交历史
git log --oneline --graph --decorate --all

# 修改最后一次提交
git commit --amend -m "new commit message"

# 交互式rebase整理提交
git rebase -i HEAD~3

# 撤销提交但保留更改
git reset --soft HEAD~1

# 完全撤销提交和更改
git reset --hard HEAD~1

# 撤销已推送的提交
git revert <commit-hash>
```

### 分支管理
```bash
# 查看所有分支
git branch -a

# 删除本地分支
git branch -d feature-branch

# 强制删除本地分支
git branch -D feature-branch

# 删除远程分支
git push origin --delete feature-branch

# 清理已删除的远程分支引用
git remote prune origin

# 重命名分支
git branch -m old-name new-name

# 跟踪远程分支
git branch --set-upstream-to=origin/main main
```

### 暂存和恢复
```bash
# 暂存当前更改
git stash

# 暂存包含未跟踪文件
git stash -u

# 查看暂存列表
git stash list

# 应用最新暂存
git stash pop

# 应用特定暂存
git stash apply stash@{1}

# 删除暂存
git stash drop stash@{1}

# 清空所有暂存
git stash clear
```

## 性能优化

### 大型仓库优化
```bash
# 浅克隆
git clone --depth 1 <repository-url>

# 部分克隆
git clone --filter=blob:none <repository-url>

# 稀疏检出
git config core.sparseCheckout true
echo "src/" > .git/info/sparse-checkout
git read-tree -m -u HEAD

# 垃圾回收
git gc --aggressive --prune=now

# 清理未跟踪文件
git clean -fd
```

### 网络优化
```bash
# 配置代理
git config --global http.proxy http://proxy.company.com:8080
git config --global https.proxy https://proxy.company.com:8080

# 增加缓冲区大小
git config --global http.postBuffer 524288000

# 启用并行传输
git config --global http.maxRequestBuffer 100M
git config --global http.threads 5
```

## 安全考虑

### SSH密钥管理
```bash
# 生成SSH密钥
ssh-keygen -t ed25519 -C "your.email@example.com"

# 添加到SSH代理
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519

# 测试SSH连接
ssh -T git@github.com

# 配置多个SSH密钥
# ~/.ssh/config
Host github.com
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_ed25519_github

Host gitlab.com
    HostName gitlab.com
    User git
    IdentityFile ~/.ssh/id_ed25519_gitlab
```

### 敏感信息保护
```bash
# 从历史中移除敏感文件
git filter-branch --force --index-filter \
  'git rm --cached --ignore-unmatch secrets.txt' \
  --prune-empty --tag-name-filter cat -- --all

# 使用git-secrets防止敏感信息提交
git secrets --register-aws
git secrets --install
git secrets --scan

# 配置.gitignore忽略敏感文件
echo "*.key" >> .gitignore
echo "*.pem" >> .gitignore
echo ".env" >> .gitignore
```

### 签名验证
```bash
# 配置GPG签名
git config --global user.signingkey <key-id>
git config --global commit.gpgsign true

# 签名提交
git commit -S -m "signed commit"

# 验证签名
git log --show-signature
```

## 集成方式

### CI/CD集成
```yaml
# GitHub Actions示例
name: CI/CD Pipeline

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3
      with:
        fetch-depth: 0  # 获取完整历史用于分析
    
    - name: Setup Node.js
      uses: actions/setup-node@v3
      with:
        node-version: '18'
        cache: 'npm'
    
    - name: Install dependencies
      run: npm ci
    
    - name: Run linting
      run: npm run lint
    
    - name: Run tests
      run: npm run test:coverage
    
    - name: Check commit messages
      run: |
        npx commitlint --from HEAD~1 --to HEAD --verbose
```

### 代码质量集成
```bash
# SonarQube集成
sonar-scanner \
  -Dsonar.projectKey=my-project \
  -Dsonar.sources=src \
  -Dsonar.host.url=http://localhost:9000 \
  -Dsonar.login=<token>

# Husky集成
npm install --save-dev husky
npx husky install

# 添加pre-commit hook
npx husky add .husky/pre-commit "npm run lint && npm run test"

# 添加commit-msg hook
npx husky add .husky/commit-msg 'npx --no -- commitlint --edit "$1"'
```

## 更新策略

### 版本管理
```bash
# 语义化版本标签
git tag -a v1.0.0 -m "Release version 1.0.0"
git push origin v1.0.0

# 自动版本管理
npm install --save-dev standard-version
npm run release

# 查看版本历史
git tag -l --sort=-version:refname

# 检出特定版本
git checkout v1.0.0
```

### 维护策略
```bash
# 定期清理
git remote prune origin
git gc --auto

# 检查仓库健康状态
git fsck --full

# 优化仓库大小
git repack -ad
git prune-packed

# 分析仓库大小
git count-objects -vH
```

## 团队协作

### 工作流程规范
```markdown
# 团队Git工作流程

## 分支命名规范
- feature/功能名称
- bugfix/问题描述
- hotfix/紧急修复
- release/版本号

## 提交频率
- 每个逻辑单元一次提交
- 每日至少一次推送
- 功能完成后及时创建PR

## 代码审查要求
- 所有代码必须经过审查
- 至少一名同事审查通过
- 自动化测试必须通过
- 符合代码规范要求

## 合并策略
- 使用Squash and Merge保持历史清洁
- 删除已合并的功能分支
- 保护主分支不允许直接推送
```

### 冲突预防
```bash
# 定期同步主分支
git checkout main
git pull origin main
git checkout feature-branch
git rebase main

# 小步提交减少冲突
git add -p  # 部分暂存
git commit -m "partial implementation"

# 使用merge工具
git config --global merge.tool vscode
git config --global mergetool.vscode.cmd 'code --wait $MERGED'
```
