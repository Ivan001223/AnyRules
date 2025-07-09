# 部署工作流程规则文档

## 工作流程概述

### 部署策略类型
```yaml
部署策略:
  蓝绿部署 (Blue-Green):
    - 零停机部署
    - 快速回滚
    - 资源消耗大
    
  滚动部署 (Rolling):
    - 逐步替换实例
    - 资源利用率高
    - 部署时间较长
    
  金丝雀部署 (Canary):
    - 小流量验证
    - 风险可控
    - 复杂度较高
    
  A/B测试部署:
    - 功能对比测试
    - 数据驱动决策
    - 需要流量分割
```

### 部署环境
- **开发环境 (Development)**: 开发人员日常开发测试
- **测试环境 (Testing)**: QA团队功能和集成测试
- **预发布环境 (Staging)**: 生产环境的完整复制
- **生产环境 (Production)**: 用户实际使用的环境

## 部署前准备

### 代码准备
```yaml
代码检查清单:
  - [ ] 代码审查通过
  - [ ] 单元测试通过
  - [ ] 集成测试通过
  - [ ] 安全扫描通过
  - [ ] 性能测试通过
  - [ ] 文档更新完成
  - [ ] 版本标签创建
  - [ ] 变更日志更新
```

### 环境配置
```bash
#!/bin/bash
# deploy-prepare.sh - 部署准备脚本

set -e

echo "开始部署准备..."

# 1. 检查环境变量
check_env_vars() {
    local required_vars=("DATABASE_URL" "API_KEY" "REDIS_URL")
    for var in "${required_vars[@]}"; do
        if [[ -z "${!var}" ]]; then
            echo "错误: 环境变量 $var 未设置"
            exit 1
        fi
    done
    echo "✓ 环境变量检查通过"
}

# 2. 检查依赖服务
check_dependencies() {
    echo "检查依赖服务..."
    
    # 检查数据库连接
    if ! pg_isready -h $DB_HOST -p $DB_PORT -U $DB_USER; then
        echo "错误: 数据库连接失败"
        exit 1
    fi
    
    # 检查Redis连接
    if ! redis-cli -h $REDIS_HOST -p $REDIS_PORT ping; then
        echo "错误: Redis连接失败"
        exit 1
    fi
    
    echo "✓ 依赖服务检查通过"
}

# 3. 备份当前版本
backup_current_version() {
    echo "备份当前版本..."
    
    # 备份数据库
    pg_dump $DATABASE_URL > "backup_$(date +%Y%m%d_%H%M%S).sql"
    
    # 备份配置文件
    tar -czf "config_backup_$(date +%Y%m%d_%H%M%S).tar.gz" /app/config/
    
    echo "✓ 备份完成"
}

# 4. 运行数据库迁移（如果需要）
run_migrations() {
    echo "运行数据库迁移..."
    
    # 检查是否有待执行的迁移
    if npm run migrate:status | grep -q "pending"; then
        echo "发现待执行的迁移，开始执行..."
        npm run migrate:up
        echo "✓ 数据库迁移完成"
    else
        echo "✓ 无需执行数据库迁移"
    fi
}

# 执行所有检查
main() {
    check_env_vars
    check_dependencies
    backup_current_version
    run_migrations
    
    echo "✅ 部署准备完成，可以开始部署"
}

main "$@"
```

## 蓝绿部署

### 实施步骤
```yaml
# docker-compose.blue.yml
version: '3.8'
services:
  web-blue:
    image: myapp:${VERSION}
    environment:
      - NODE_ENV=production
      - PORT=3000
    networks:
      - app-network
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.app-blue.rule=Host(`app.example.com`)"
      - "traefik.http.services.app-blue.loadbalancer.server.port=3000"

# docker-compose.green.yml  
version: '3.8'
services:
  web-green:
    image: myapp:${VERSION}
    environment:
      - NODE_ENV=production
      - PORT=3001
    networks:
      - app-network
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.app-green.rule=Host(`app.example.com`)"
      - "traefik.http.services.app-green.loadbalancer.server.port=3001"
```

### 部署脚本
```bash
#!/bin/bash
# blue-green-deploy.sh

set -e

VERSION=${1:-latest}
CURRENT_ENV=${2:-blue}
TARGET_ENV=${3:-green}

echo "开始蓝绿部署: $CURRENT_ENV -> $TARGET_ENV"

# 1. 部署到目标环境
deploy_target() {
    echo "部署到 $TARGET_ENV 环境..."
    
    export VERSION=$VERSION
    docker-compose -f docker-compose.$TARGET_ENV.yml up -d
    
    # 等待服务启动
    echo "等待服务启动..."
    sleep 30
}

# 2. 健康检查
health_check() {
    echo "执行健康检查..."
    
    local max_attempts=30
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        if curl -f http://localhost:300${TARGET_ENV:0:1}/health; then
            echo "✓ 健康检查通过"
            return 0
        fi
        
        echo "健康检查失败，重试 $attempt/$max_attempts"
        sleep 10
        ((attempt++))
    done
    
    echo "❌ 健康检查失败"
    return 1
}

# 3. 切换流量
switch_traffic() {
    echo "切换流量到 $TARGET_ENV..."
    
    # 更新负载均衡器配置
    kubectl patch service app-service -p '{"spec":{"selector":{"version":"'$TARGET_ENV'"}}}'
    
    # 或者使用Traefik标签切换
    docker service update --label-add traefik.http.routers.app.service=app-$TARGET_ENV app-router
    
    echo "✓ 流量切换完成"
}

# 4. 验证部署
verify_deployment() {
    echo "验证部署..."
    
    # 运行冒烟测试
    npm run test:smoke
    
    # 检查关键指标
    if ! check_metrics; then
        echo "❌ 指标检查失败"
        return 1
    fi
    
    echo "✓ 部署验证通过"
}

# 5. 清理旧环境
cleanup_old() {
    echo "清理旧环境 $CURRENT_ENV..."
    
    # 等待一段时间确保没有活跃连接
    sleep 60
    
    docker-compose -f docker-compose.$CURRENT_ENV.yml down
    
    echo "✓ 旧环境清理完成"
}

# 6. 回滚函数
rollback() {
    echo "❌ 部署失败，开始回滚..."
    
    # 切换回原环境
    kubectl patch service app-service -p '{"spec":{"selector":{"version":"'$CURRENT_ENV'"}}}'
    
    # 清理失败的部署
    docker-compose -f docker-compose.$TARGET_ENV.yml down
    
    echo "✅ 回滚完成"
    exit 1
}

# 主流程
main() {
    # 设置错误处理
    trap rollback ERR
    
    deploy_target
    
    if health_check && verify_deployment; then
        switch_traffic
        cleanup_old
        echo "蓝绿部署成功完成"
    else
        rollback
    fi
}

main "$@"
```

## 滚动部署

### Kubernetes滚动部署
```yaml
# deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp
  labels:
    app: myapp
spec:
  replicas: 5
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 1      # 最多1个Pod不可用
      maxSurge: 1           # 最多额外创建1个Pod
  selector:
    matchLabels:
      app: myapp
  template:
    metadata:
      labels:
        app: myapp
        version: v1.2.3
    spec:
      containers:
      - name: myapp
        image: myapp:v1.2.3
        ports:
        - containerPort: 3000
        env:
        - name: NODE_ENV
          value: "production"
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
          timeoutSeconds: 5
          failureThreshold: 3
        readinessProbe:
          httpGet:
            path: /ready
            port: 3000
          initialDelaySeconds: 5
          periodSeconds: 5
          timeoutSeconds: 3
          failureThreshold: 3
```

### 滚动部署脚本
```bash
#!/bin/bash
# rolling-deploy.sh

set -e

IMAGE_TAG=${1:-latest}
NAMESPACE=${2:-default}
DEPLOYMENT_NAME=${3:-myapp}

echo "开始滚动部署: $DEPLOYMENT_NAME:$IMAGE_TAG"

# 1. 更新部署镜像
update_deployment() {
    echo "更新部署镜像..."
    
    kubectl set image deployment/$DEPLOYMENT_NAME \
        myapp=myapp:$IMAGE_TAG \
        --namespace=$NAMESPACE
    
    echo "✓ 部署镜像已更新"
}

# 2. 监控部署进度
monitor_rollout() {
    echo "监控部署进度..."
    
    # 等待部署完成
    kubectl rollout status deployment/$DEPLOYMENT_NAME \
        --namespace=$NAMESPACE \
        --timeout=600s
    
    echo "✓ 滚动部署完成"
}

# 3. 验证部署
verify_deployment() {
    echo "验证部署..."
    
    # 检查Pod状态
    local ready_pods=$(kubectl get deployment $DEPLOYMENT_NAME \
        --namespace=$NAMESPACE \
        -o jsonpath='{.status.readyReplicas}')
    
    local desired_pods=$(kubectl get deployment $DEPLOYMENT_NAME \
        --namespace=$NAMESPACE \
        -o jsonpath='{.spec.replicas}')
    
    if [ "$ready_pods" != "$desired_pods" ]; then
        echo "❌ Pod数量不匹配: $ready_pods/$desired_pods"
        return 1
    fi
    
    # 运行健康检查
    local service_ip=$(kubectl get service $DEPLOYMENT_NAME \
        --namespace=$NAMESPACE \
        -o jsonpath='{.spec.clusterIP}')
    
    if ! curl -f http://$service_ip/health; then
        echo "❌ 健康检查失败"
        return 1
    fi
    
    echo "✓ 部署验证通过"
}

# 4. 回滚函数
rollback() {
    echo "❌ 部署失败，开始回滚..."
    
    kubectl rollout undo deployment/$DEPLOYMENT_NAME \
        --namespace=$NAMESPACE
    
    kubectl rollout status deployment/$DEPLOYMENT_NAME \
        --namespace=$NAMESPACE \
        --timeout=300s
    
    echo "✅ 回滚完成"
    exit 1
}

# 主流程
main() {
    trap rollback ERR
    
    update_deployment
    monitor_rollout
    
    if verify_deployment; then
        echo "滚动部署成功完成"
    else
        rollback
    fi
}

main "$@"
```

## 金丝雀部署

### 流量分割配置
```yaml
# canary-deployment.yaml
apiVersion: argoproj.io/v1alpha1
kind: Rollout
metadata:
  name: myapp-rollout
spec:
  replicas: 10
  strategy:
    canary:
      steps:
      - setWeight: 10        # 10%流量到新版本
      - pause: {duration: 2m} # 暂停2分钟观察
      - setWeight: 25        # 25%流量
      - pause: {duration: 5m}
      - setWeight: 50        # 50%流量
      - pause: {duration: 10m}
      - setWeight: 75        # 75%流量
      - pause: {duration: 5m}
      # 自动完成100%
      
      # 分析配置
      analysis:
        templates:
        - templateName: success-rate
        args:
        - name: service-name
          value: myapp
        
      # 流量路由
      trafficRouting:
        nginx:
          stableService: myapp-stable
          canaryService: myapp-canary
          annotationPrefix: nginx.ingress.kubernetes.io
  
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
        image: myapp:stable
        ports:
        - containerPort: 3000

---
# 分析模板
apiVersion: argoproj.io/v1alpha1
kind: AnalysisTemplate
metadata:
  name: success-rate
spec:
  args:
  - name: service-name
  metrics:
  - name: success-rate
    interval: 1m
    count: 5
    successCondition: result[0] >= 0.95
    failureLimit: 3
    provider:
      prometheus:
        address: http://prometheus:9090
        query: |
          sum(rate(http_requests_total{service="{{args.service-name}}",status!~"5.."}[1m])) /
          sum(rate(http_requests_total{service="{{args.service-name}}"}[1m]))
```

### 金丝雀部署脚本
```bash
#!/bin/bash
# canary-deploy.sh

set -e

NEW_VERSION=${1:-latest}
CANARY_PERCENTAGE=${2:-10}
NAMESPACE=${3:-default}

echo "开始金丝雀部署: $NEW_VERSION (${CANARY_PERCENTAGE}%)"

# 1. 部署金丝雀版本
deploy_canary() {
    echo "部署金丝雀版本..."
    
    # 创建金丝雀部署
    kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp-canary
  namespace: $NAMESPACE
spec:
  replicas: 1
  selector:
    matchLabels:
      app: myapp
      version: canary
  template:
    metadata:
      labels:
        app: myapp
        version: canary
    spec:
      containers:
      - name: myapp
        image: myapp:$NEW_VERSION
        ports:
        - containerPort: 3000
EOF
    
    # 等待Pod就绪
    kubectl wait --for=condition=ready pod \
        -l app=myapp,version=canary \
        --namespace=$NAMESPACE \
        --timeout=300s
    
    echo "✓ 金丝雀版本部署完成"
}

# 2. 配置流量分割
configure_traffic() {
    echo "配置流量分割 (${CANARY_PERCENTAGE}%)..."
    
    # 更新Ingress配置
    kubectl apply -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: myapp-ingress
  namespace: $NAMESPACE
  annotations:
    nginx.ingress.kubernetes.io/canary: "true"
    nginx.ingress.kubernetes.io/canary-weight: "$CANARY_PERCENTAGE"
spec:
  rules:
  - host: app.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: myapp-canary
            port:
              number: 80
EOF
    
    echo "✓ 流量分割配置完成"
}

# 3. 监控指标
monitor_metrics() {
    echo "监控金丝雀指标..."
    
    local duration=${1:-300}  # 默认监控5分钟
    local start_time=$(date +%s)
    
    while [ $(($(date +%s) - start_time)) -lt $duration ]; do
        # 检查错误率
        local error_rate=$(curl -s "http://prometheus:9090/api/v1/query" \
            --data-urlencode 'query=rate(http_requests_total{status=~"5.."}[1m])/rate(http_requests_total[1m])' \
            | jq -r '.data.result[0].value[1]')
        
        # 检查响应时间
        local response_time=$(curl -s "http://prometheus:9090/api/v1/query" \
            --data-urlencode 'query=histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[1m]))' \
            | jq -r '.data.result[0].value[1]')
        
        echo "错误率: ${error_rate:-0}%, 响应时间: ${response_time:-0}s"
        
        # 检查阈值
        if (( $(echo "$error_rate > 0.05" | bc -l) )); then
            echo "❌ 错误率过高: $error_rate"
            return 1
        fi
        
        if (( $(echo "$response_time > 1.0" | bc -l) )); then
            echo "❌ 响应时间过长: $response_time"
            return 1
        fi
        
        sleep 30
    done
    
    echo "✓ 指标监控通过"
}

# 4. 推广到全量
promote_canary() {
    echo "推广金丝雀到全量..."
    
    # 更新主部署
    kubectl set image deployment/myapp \
        myapp=myapp:$NEW_VERSION \
        --namespace=$NAMESPACE
    
    # 等待滚动更新完成
    kubectl rollout status deployment/myapp \
        --namespace=$NAMESPACE \
        --timeout=600s
    
    # 清理金丝雀资源
    kubectl delete deployment myapp-canary --namespace=$NAMESPACE
    kubectl delete ingress myapp-ingress --namespace=$NAMESPACE
    
    echo "✓ 金丝雀推广完成"
}

# 5. 回滚金丝雀
rollback_canary() {
    echo "❌ 金丝雀部署失败，开始回滚..."
    
    # 删除金丝雀资源
    kubectl delete deployment myapp-canary --namespace=$NAMESPACE --ignore-not-found
    kubectl delete ingress myapp-ingress --namespace=$NAMESPACE --ignore-not-found
    
    echo "✅ 金丝雀回滚完成"
    exit 1
}

# 主流程
main() {
    trap rollback_canary ERR
    
    deploy_canary
    configure_traffic
    
    if monitor_metrics 300; then  # 监控5分钟
        promote_canary
        echo "金丝雀部署成功完成"
    else
        rollback_canary
    fi
}

main "$@"
```

## 部署后验证

### 自动化测试
```bash
#!/bin/bash
# post-deploy-tests.sh

set -e

ENVIRONMENT=${1:-production}
BASE_URL=${2:-https://app.example.com}

echo "开始部署后验证测试..."

# 1. 健康检查
health_check() {
    echo "执行健康检查..."
    
    local max_attempts=10
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        if curl -f "$BASE_URL/health"; then
            echo "✓ 健康检查通过"
            return 0
        fi
        
        echo "健康检查失败，重试 $attempt/$max_attempts"
        sleep 10
        ((attempt++))
    done
    
    echo "❌ 健康检查失败"
    return 1
}

# 2. 冒烟测试
smoke_tests() {
    echo "执行冒烟测试..."
    
    # 测试主页
    if ! curl -f "$BASE_URL/"; then
        echo "❌ 主页访问失败"
        return 1
    fi
    
    # 测试API端点
    if ! curl -f "$BASE_URL/api/status"; then
        echo "❌ API状态检查失败"
        return 1
    fi
    
    # 测试用户注册
    local test_email="test_$(date +%s)@example.com"
    local response=$(curl -s -X POST "$BASE_URL/api/users" \
        -H "Content-Type: application/json" \
        -d "{\"name\":\"Test User\",\"email\":\"$test_email\"}")
    
    if ! echo "$response" | jq -e '.id'; then
        echo "❌ 用户注册测试失败"
        return 1
    fi
    
    echo "✓ 冒烟测试通过"
}

# 3. 性能测试
performance_tests() {
    echo "执行性能测试..."
    
    # 使用Apache Bench进行简单性能测试
    local ab_result=$(ab -n 100 -c 10 "$BASE_URL/" 2>/dev/null)
    
    # 提取响应时间
    local avg_time=$(echo "$ab_result" | grep "Time per request" | head -1 | awk '{print $4}')
    
    if (( $(echo "$avg_time > 1000" | bc -l) )); then
        echo "❌ 平均响应时间过长: ${avg_time}ms"
        return 1
    fi
    
    echo "✓ 性能测试通过 (平均响应时间: ${avg_time}ms)"
}

# 4. 数据库连接测试
database_tests() {
    echo "执行数据库连接测试..."
    
    local db_status=$(curl -s "$BASE_URL/api/db/status")
    
    if ! echo "$db_status" | jq -e '.connected'; then
        echo "❌ 数据库连接测试失败"
        return 1
    fi
    
    echo "✓ 数据库连接测试通过"
}

# 5. 外部服务集成测试
integration_tests() {
    echo "执行外部服务集成测试..."
    
    # 测试Redis连接
    local redis_status=$(curl -s "$BASE_URL/api/redis/status")
    if ! echo "$redis_status" | jq -e '.connected'; then
        echo "❌ Redis连接测试失败"
        return 1
    fi
    
    # 测试邮件服务
    local email_status=$(curl -s "$BASE_URL/api/email/status")
    if ! echo "$email_status" | jq -e '.available'; then
        echo "❌ 邮件服务测试失败"
        return 1
    fi
    
    echo "✓ 外部服务集成测试通过"
}

# 主流程
main() {
    echo "开始 $ENVIRONMENT 环境部署后验证..."
    
    health_check
    smoke_tests
    performance_tests
    database_tests
    integration_tests
    
    echo "所有部署后验证测试通过"
}

main "$@"
```

## 监控和告警

### 部署监控
```yaml
# prometheus-rules.yaml
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: deployment-alerts
spec:
  groups:
  - name: deployment
    rules:
    - alert: DeploymentReplicasMismatch
      expr: kube_deployment_status_replicas != kube_deployment_spec_replicas
      for: 5m
      labels:
        severity: warning
      annotations:
        summary: "部署副本数不匹配"
        description: "{{ $labels.deployment }} 的实际副本数与期望副本数不匹配"
    
    - alert: PodCrashLooping
      expr: rate(kube_pod_container_status_restarts_total[15m]) > 0
      for: 5m
      labels:
        severity: critical
      annotations:
        summary: "Pod崩溃循环"
        description: "{{ $labels.pod }} 在过去15分钟内重启了 {{ $value }} 次"
    
    - alert: HighErrorRate
      expr: rate(http_requests_total{status=~"5.."}[5m]) / rate(http_requests_total[5m]) > 0.05
      for: 2m
      labels:
        severity: critical
      annotations:
        summary: "错误率过高"
        description: "错误率为 {{ $value | humanizePercentage }}"
    
    - alert: HighResponseTime
      expr: histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m])) > 1
      for: 5m
      labels:
        severity: warning
      annotations:
        summary: "响应时间过长"
        description: "95%响应时间为 {{ $value }}s"
```

## 输出模板

### 部署报告模板
```markdown
# 部署报告

## 部署信息
- **版本**: {version}
- **环境**: {environment}
- **部署时间**: {deploy_time}
- **部署策略**: {strategy}
- **部署人员**: {deployer}

## 部署结果
- **状态**: {status}
- **持续时间**: {duration}
- **影响范围**: {scope}

## 验证结果
- **健康检查**: {health_check}
- **冒烟测试**: {smoke_tests}
- **性能测试**: {performance_tests}
- **集成测试**: {integration_tests}

## 关键指标
- **响应时间**: {response_time}
- **错误率**: {error_rate}
- **吞吐量**: {throughput}
- **可用性**: {availability}

## 问题和风险
{issues_and_risks}

## 回滚计划
{rollback_plan}

## 下次改进
{improvements}
```
