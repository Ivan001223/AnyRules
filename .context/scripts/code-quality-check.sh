#!/bin/bash

# 代码质量检查脚本
# 用法: ./code-quality-check.sh [project-path] [--fix] [--report output.json]

set -e

PROJECT_PATH=${1:-"."}
FIX_MODE=false
REPORT_FILE=""

# 解析参数
while [[ $# -gt 0 ]]; do
    case $1 in
        --fix)
            FIX_MODE=true
            shift
            ;;
        --report)
            REPORT_FILE="$2"
            shift 2
            ;;
        *)
            if [ -z "$PROJECT_PATH" ]; then
                PROJECT_PATH="$1"
            fi
            shift
            ;;
    esac
done

echo "🔍 开始代码质量检查: $PROJECT_PATH"

# 检查项目路径
if [ ! -d "$PROJECT_PATH" ]; then
    echo "❌ 项目路径不存在: $PROJECT_PATH"
    exit 1
fi

cd "$PROJECT_PATH"

# 初始化报告数据
REPORT_DATA="{\"timestamp\":\"$(date -Iseconds)\",\"project_path\":\"$PROJECT_PATH\",\"checks\":{}}"

# 检查函数
check_nodejs_project() {
    echo "📦 检查 Node.js 项目..."
    
    local nodejs_report="{}"
    
    # 检查 package.json
    if [ -f "package.json" ]; then
        echo "✅ 找到 package.json"
        
        # 检查依赖安全性
        if command -v npm >/dev/null 2>&1; then
            echo "🔒 检查依赖安全性..."
            if npm audit --json > npm_audit.json 2>/dev/null; then
                vulnerabilities=$(jq '.metadata.vulnerabilities.total' npm_audit.json 2>/dev/null || echo "0")
                echo "🛡️ 发现 $vulnerabilities 个安全漏洞"
                nodejs_report=$(echo "$nodejs_report" | jq ".vulnerabilities = $vulnerabilities")
                
                if [ "$vulnerabilities" -gt 0 ] && [ "$FIX_MODE" = true ]; then
                    echo "🔧 尝试修复安全漏洞..."
                    npm audit fix --force
                fi
            fi
            rm -f npm_audit.json
        fi
        
        # 检查过时依赖
        if command -v npm >/dev/null 2>&1; then
            echo "📅 检查过时依赖..."
            outdated_count=$(npm outdated --json 2>/dev/null | jq 'length' 2>/dev/null || echo "0")
            echo "📦 发现 $outdated_count 个过时依赖"
            nodejs_report=$(echo "$nodejs_report" | jq ".outdated_dependencies = $outdated_count")
        fi
        
        # ESLint 检查
        if [ -f ".eslintrc.js" ] || [ -f ".eslintrc.json" ] || [ -f "eslint.config.js" ]; then
            echo "🔍 运行 ESLint..."
            if command -v npx >/dev/null 2>&1; then
                if npx eslint . --format json > eslint_report.json 2>/dev/null; then
                    eslint_errors=$(jq '[.[] | select(.errorCount > 0)] | length' eslint_report.json 2>/dev/null || echo "0")
                    eslint_warnings=$(jq '[.[] | select(.warningCount > 0)] | length' eslint_report.json 2>/dev/null || echo "0")
                    echo "⚠️ ESLint: $eslint_errors 个错误, $eslint_warnings 个警告"
                    nodejs_report=$(echo "$nodejs_report" | jq ".eslint = {\"errors\": $eslint_errors, \"warnings\": $eslint_warnings}")
                    
                    if [ "$FIX_MODE" = true ]; then
                        echo "🔧 尝试自动修复 ESLint 问题..."
                        npx eslint . --fix
                    fi
                fi
                rm -f eslint_report.json
            fi
        fi
        
        # Prettier 检查
        if [ -f ".prettierrc" ] || [ -f ".prettierrc.json" ] || [ -f "prettier.config.js" ]; then
            echo "💅 检查 Prettier 格式..."
            if command -v npx >/dev/null 2>&1; then
                unformatted_files=$(npx prettier --list-different . 2>/dev/null | wc -l || echo "0")
                echo "📝 发现 $unformatted_files 个格式不正确的文件"
                nodejs_report=$(echo "$nodejs_report" | jq ".prettier_issues = $unformatted_files")
                
                if [ "$FIX_MODE" = true ] && [ "$unformatted_files" -gt 0 ]; then
                    echo "🔧 自动格式化文件..."
                    npx prettier --write .
                fi
            fi
        fi
        
        # TypeScript 检查
        if [ -f "tsconfig.json" ]; then
            echo "🔷 检查 TypeScript..."
            if command -v npx >/dev/null 2>&1; then
                if npx tsc --noEmit 2> ts_errors.txt; then
                    echo "✅ TypeScript 编译通过"
                    nodejs_report=$(echo "$nodejs_report" | jq ".typescript_errors = 0")
                else
                    ts_error_count=$(wc -l < ts_errors.txt || echo "0")
                    echo "❌ TypeScript: $ts_error_count 个编译错误"
                    nodejs_report=$(echo "$nodejs_report" | jq ".typescript_errors = $ts_error_count")
                fi
                rm -f ts_errors.txt
            fi
        fi
    fi
    
    REPORT_DATA=$(echo "$REPORT_DATA" | jq ".checks.nodejs = $nodejs_report")
}

check_python_project() {
    echo "🐍 检查 Python 项目..."
    
    local python_report="{}"
    
    # 检查 requirements.txt 或 pyproject.toml
    if [ -f "requirements.txt" ] || [ -f "pyproject.toml" ] || [ -f "Pipfile" ]; then
        echo "✅ 找到 Python 依赖文件"
        
        # 安全检查
        if command -v safety >/dev/null 2>&1; then
            echo "🔒 检查依赖安全性..."
            if [ -f "requirements.txt" ]; then
                vulnerabilities=$(safety check -r requirements.txt --json 2>/dev/null | jq 'length' 2>/dev/null || echo "0")
                echo "🛡️ 发现 $vulnerabilities 个安全漏洞"
                python_report=$(echo "$python_report" | jq ".vulnerabilities = $vulnerabilities")
            fi
        fi
        
        # Black 格式检查
        if command -v black >/dev/null 2>&1; then
            echo "⚫ 检查 Black 格式..."
            if black --check . 2>/dev/null; then
                echo "✅ Black 格式检查通过"
                python_report=$(echo "$python_report" | jq ".black_issues = 0")
            else
                echo "❌ 发现格式问题"
                python_report=$(echo "$python_report" | jq ".black_issues = 1")
                
                if [ "$FIX_MODE" = true ]; then
                    echo "🔧 自动格式化 Python 代码..."
                    black .
                fi
            fi
        fi
        
        # Flake8 检查
        if command -v flake8 >/dev/null 2>&1; then
            echo "🔍 运行 Flake8..."
            flake8_issues=$(flake8 . --count 2>/dev/null || echo "0")
            echo "⚠️ Flake8: $flake8_issues 个问题"
            python_report=$(echo "$python_report" | jq ".flake8_issues = $flake8_issues")
        fi
        
        # MyPy 类型检查
        if command -v mypy >/dev/null 2>&1; then
            echo "🔷 检查 MyPy 类型..."
            if mypy . 2>/dev/null; then
                echo "✅ MyPy 类型检查通过"
                python_report=$(echo "$python_report" | jq ".mypy_errors = 0")
            else
                mypy_errors=$(mypy . 2>&1 | grep "error:" | wc -l || echo "0")
                echo "❌ MyPy: $mypy_errors 个类型错误"
                python_report=$(echo "$python_report" | jq ".mypy_errors = $mypy_errors")
            fi
        fi
    fi
    
    REPORT_DATA=$(echo "$REPORT_DATA" | jq ".checks.python = $python_report")
}

check_git_repository() {
    echo "📚 检查 Git 仓库..."
    
    local git_report="{}"
    
    if [ -d ".git" ]; then
        echo "✅ 找到 Git 仓库"
        
        # 检查未提交的更改
        if git diff --quiet && git diff --cached --quiet; then
            echo "✅ 工作目录干净"
            git_report=$(echo "$git_report" | jq ".uncommitted_changes = false")
        else
            echo "⚠️ 有未提交的更改"
            git_report=$(echo "$git_report" | jq ".uncommitted_changes = true")
        fi
        
        # 检查大文件
        large_files=$(find . -type f -size +10M -not -path "./.git/*" | wc -l)
        if [ "$large_files" -gt 0 ]; then
            echo "⚠️ 发现 $large_files 个大文件 (>10MB)"
            git_report=$(echo "$git_report" | jq ".large_files = $large_files")
        else
            git_report=$(echo "$git_report" | jq ".large_files = 0")
        fi
        
        # 检查 .gitignore
        if [ -f ".gitignore" ]; then
            echo "✅ 找到 .gitignore"
            git_report=$(echo "$git_report" | jq ".has_gitignore = true")
        else
            echo "⚠️ 缺少 .gitignore 文件"
            git_report=$(echo "$git_report" | jq ".has_gitignore = false")
        fi
        
        # 检查敏感文件
        sensitive_patterns=("*.key" "*.pem" "*.p12" "*.env" "config.json" "secrets.json")
        sensitive_files=0
        for pattern in "${sensitive_patterns[@]}"; do
            count=$(find . -name "$pattern" -not -path "./.git/*" | wc -l)
            sensitive_files=$((sensitive_files + count))
        done
        
        if [ "$sensitive_files" -gt 0 ]; then
            echo "🚨 发现 $sensitive_files 个可能的敏感文件"
            git_report=$(echo "$git_report" | jq ".sensitive_files = $sensitive_files")
        else
            git_report=$(echo "$git_report" | jq ".sensitive_files = 0")
        fi
    fi
    
    REPORT_DATA=$(echo "$REPORT_DATA" | jq ".checks.git = $git_report")
}

check_docker() {
    echo "🐳 检查 Docker 配置..."
    
    local docker_report="{}"
    
    if [ -f "Dockerfile" ]; then
        echo "✅ 找到 Dockerfile"
        docker_report=$(echo "$docker_report" | jq ".has_dockerfile = true")
        
        # 检查 Dockerfile 最佳实践
        dockerfile_issues=0
        
        # 检查是否使用了 latest 标签
        if grep -q "FROM.*:latest" Dockerfile; then
            echo "⚠️ Dockerfile 使用了 latest 标签"
            dockerfile_issues=$((dockerfile_issues + 1))
        fi
        
        # 检查是否以 root 用户运行
        if ! grep -q "USER " Dockerfile; then
            echo "⚠️ Dockerfile 可能以 root 用户运行"
            dockerfile_issues=$((dockerfile_issues + 1))
        fi
        
        # 检查是否有 .dockerignore
        if [ -f ".dockerignore" ]; then
            echo "✅ 找到 .dockerignore"
            docker_report=$(echo "$docker_report" | jq ".has_dockerignore = true")
        else
            echo "⚠️ 缺少 .dockerignore 文件"
            docker_report=$(echo "$docker_report" | jq ".has_dockerignore = false")
            dockerfile_issues=$((dockerfile_issues + 1))
        fi
        
        docker_report=$(echo "$docker_report" | jq ".dockerfile_issues = $dockerfile_issues")
    else
        docker_report=$(echo "$docker_report" | jq ".has_dockerfile = false")
    fi
    
    # 检查 docker-compose.yml
    if [ -f "docker-compose.yml" ] || [ -f "docker-compose.yaml" ]; then
        echo "✅ 找到 docker-compose 文件"
        docker_report=$(echo "$docker_report" | jq ".has_compose = true")
    else
        docker_report=$(echo "$docker_report" | jq ".has_compose = false")
    fi
    
    REPORT_DATA=$(echo "$REPORT_DATA" | jq ".checks.docker = $docker_report")
}

check_security() {
    echo "🔒 安全检查..."
    
    local security_report="{}"
    
    # 检查硬编码密钥
    secret_patterns=("password\s*=" "api_key\s*=" "secret\s*=" "token\s*=" "private_key")
    secrets_found=0
    
    for pattern in "${secret_patterns[@]}"; do
        count=$(grep -r -i "$pattern" . --exclude-dir=.git --exclude-dir=node_modules 2>/dev/null | wc -l || echo "0")
        secrets_found=$((secrets_found + count))
    done
    
    if [ "$secrets_found" -gt 0 ]; then
        echo "🚨 发现 $secrets_found 个可能的硬编码密钥"
        security_report=$(echo "$security_report" | jq ".hardcoded_secrets = $secrets_found")
    else
        security_report=$(echo "$security_report" | jq ".hardcoded_secrets = 0")
    fi
    
    # 检查 TODO 和 FIXME
    todo_count=$(grep -r -i "TODO\|FIXME\|XXX" . --exclude-dir=.git --exclude-dir=node_modules 2>/dev/null | wc -l || echo "0")
    echo "📝 发现 $todo_count 个 TODO/FIXME 注释"
    security_report=$(echo "$security_report" | jq ".todo_comments = $todo_count")
    
    REPORT_DATA=$(echo "$REPORT_DATA" | jq ".checks.security = $security_report")
}

# 执行检查
echo "🚀 开始代码质量检查..."

# 检查项目类型并执行相应检查
if [ -f "package.json" ]; then
    check_nodejs_project
fi

if [ -f "requirements.txt" ] || [ -f "pyproject.toml" ] || [ -f "Pipfile" ]; then
    check_python_project
fi

check_git_repository
check_docker
check_security

# 生成总结
echo ""
echo "📊 检查完成！"

# 保存报告
if [ -n "$REPORT_FILE" ]; then
    echo "$REPORT_DATA" | jq '.' > "$REPORT_FILE"
    echo "📄 详细报告已保存到: $REPORT_FILE"
fi

# 显示总结
echo ""
echo "📋 检查总结:"
if echo "$REPORT_DATA" | jq -e '.checks.nodejs.vulnerabilities > 0' >/dev/null 2>&1; then
    vulnerabilities=$(echo "$REPORT_DATA" | jq -r '.checks.nodejs.vulnerabilities')
    echo "🚨 发现 $vulnerabilities 个安全漏洞"
fi

if echo "$REPORT_DATA" | jq -e '.checks.security.hardcoded_secrets > 0' >/dev/null 2>&1; then
    secrets=$(echo "$REPORT_DATA" | jq -r '.checks.security.hardcoded_secrets')
    echo "🔑 发现 $secrets 个可能的硬编码密钥"
fi

if echo "$REPORT_DATA" | jq -e '.checks.git.uncommitted_changes == true' >/dev/null 2>&1; then
    echo "📝 有未提交的更改"
fi

echo "✅ 代码质量检查完成！"
