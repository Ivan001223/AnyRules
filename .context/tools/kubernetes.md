# Kubernetes 工具规则文档

## 工具概述
Kubernetes是一个开源的容器编排平台，用于自动化部署、扩展和管理容器化应用程序。

### 适用场景
- 容器化应用程序编排
- 微服务架构部署
- 自动扩缩容管理
- 服务发现和负载均衡
- 滚动更新和回滚
- 配置和密钥管理

### 核心概念
- **Pod**: 最小部署单元，包含一个或多个容器
- **Service**: 服务发现和负载均衡
- **Deployment**: 声明式应用部署和更新
- **ConfigMap/Secret**: 配置和敏感信息管理
- **Ingress**: HTTP/HTTPS路由规则
- **Namespace**: 资源隔离和多租户

## 最佳实践

### 应用部署配置
```yaml
# deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: user-service
  namespace: production
  labels:
    app: user-service
    version: v1.2.3
    component: backend
spec:
  replicas: 3
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 1
      maxSurge: 1
  selector:
    matchLabels:
      app: user-service
  template:
    metadata:
      labels:
        app: user-service
        version: v1.2.3
        component: backend
      annotations:
        prometheus.io/scrape: "true"
        prometheus.io/port: "8080"
        prometheus.io/path: "/metrics"
    spec:
      serviceAccountName: user-service
      securityContext:
        runAsNonRoot: true
        runAsUser: 1000
        fsGroup: 2000
      containers:
      - name: user-service
        image: myregistry/user-service:v1.2.3
        imagePullPolicy: IfNotPresent
        ports:
        - name: http
          containerPort: 8080
          protocol: TCP
        - name: grpc
          containerPort: 9090
          protocol: TCP
        env:
        - name: NODE_ENV
          value: "production"
        - name: DATABASE_URL
          valueFrom:
            secretKeyRef:
              name: user-service-secrets
              key: database-url
        - name: REDIS_URL
          valueFrom:
            configMapKeyRef:
              name: user-service-config
              key: redis-url
        - name: POD_NAME
          valueFrom:
            fieldRef:
              fieldPath: metadata.name
        - name: POD_NAMESPACE
          valueFrom:
            fieldRef:
              fieldPath: metadata.namespace
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
            port: http
          initialDelaySeconds: 30
          periodSeconds: 10
          timeoutSeconds: 5
          failureThreshold: 3
        readinessProbe:
          httpGet:
            path: /ready
            port: http
          initialDelaySeconds: 5
          periodSeconds: 5
          timeoutSeconds: 3
          failureThreshold: 3
        startupProbe:
          httpGet:
            path: /health
            port: http
          initialDelaySeconds: 10
          periodSeconds: 10
          timeoutSeconds: 5
          failureThreshold: 30
        volumeMounts:
        - name: config-volume
          mountPath: /app/config
          readOnly: true
        - name: logs-volume
          mountPath: /app/logs
        securityContext:
          allowPrivilegeEscalation: false
          readOnlyRootFilesystem: true
          capabilities:
            drop:
            - ALL
      volumes:
      - name: config-volume
        configMap:
          name: user-service-config
      - name: logs-volume
        emptyDir: {}
      imagePullSecrets:
      - name: registry-secret
      nodeSelector:
        kubernetes.io/arch: amd64
      tolerations:
      - key: "app"
        operator: "Equal"
        value: "user-service"
        effect: "NoSchedule"
      affinity:
        podAntiAffinity:
          preferredDuringSchedulingIgnoredDuringExecution:
          - weight: 100
            podAffinityTerm:
              labelSelector:
                matchExpressions:
                - key: app
                  operator: In
                  values:
                  - user-service
              topologyKey: kubernetes.io/hostname

---
# service.yaml
apiVersion: v1
kind: Service
metadata:
  name: user-service
  namespace: production
  labels:
    app: user-service
  annotations:
    service.beta.kubernetes.io/aws-load-balancer-type: nlb
spec:
  type: ClusterIP
  ports:
  - name: http
    port: 80
    targetPort: http
    protocol: TCP
  - name: grpc
    port: 9090
    targetPort: grpc
    protocol: TCP
  selector:
    app: user-service

---
# configmap.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: user-service-config
  namespace: production
data:
  redis-url: "redis://redis-service:6379"
  log-level: "info"
  max-connections: "100"
  timeout: "30s"
  app.properties: |
    server.port=8080
    logging.level.root=INFO
    spring.datasource.hikari.maximum-pool-size=20

---
# secret.yaml
apiVersion: v1
kind: Secret
metadata:
  name: user-service-secrets
  namespace: production
type: Opaque
data:
  database-url: cG9zdGdyZXNxbDovL3VzZXI6cGFzc3dvcmRAZGI6NTQzMi9teWRi  # base64编码
  api-key: YWJjZGVmZ2hpams=  # base64编码
  jwt-secret: c3VwZXJzZWNyZXRrZXk=  # base64编码

---
# ingress.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: user-service-ingress
  namespace: production
  annotations:
    kubernetes.io/ingress.class: nginx
    nginx.ingress.kubernetes.io/rewrite-target: /
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
    nginx.ingress.kubernetes.io/rate-limit: "100"
    nginx.ingress.kubernetes.io/rate-limit-window: "1m"
    cert-manager.io/cluster-issuer: letsencrypt-prod
spec:
  tls:
  - hosts:
    - api.example.com
    secretName: user-service-tls
  rules:
  - host: api.example.com
    http:
      paths:
      - path: /users
        pathType: Prefix
        backend:
          service:
            name: user-service
            port:
              number: 80

---
# hpa.yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: user-service-hpa
  namespace: production
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: user-service
  minReplicas: 3
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 80
  behavior:
    scaleDown:
      stabilizationWindowSeconds: 300
      policies:
      - type: Percent
        value: 10
        periodSeconds: 60
    scaleUp:
      stabilizationWindowSeconds: 60
      policies:
      - type: Percent
        value: 50
        periodSeconds: 60
```

### 网络策略和安全
```yaml
# network-policy.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: user-service-network-policy
  namespace: production
spec:
  podSelector:
    matchLabels:
      app: user-service
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          name: frontend
    - podSelector:
        matchLabels:
          app: api-gateway
    ports:
    - protocol: TCP
      port: 8080
  egress:
  - to:
    - namespaceSelector:
        matchLabels:
          name: database
    ports:
    - protocol: TCP
      port: 5432
  - to:
    - namespaceSelector:
        matchLabels:
          name: cache
    ports:
    - protocol: TCP
      port: 6379
  - to: []  # 允许DNS查询
    ports:
    - protocol: UDP
      port: 53

---
# pod-security-policy.yaml
apiVersion: policy/v1beta1
kind: PodSecurityPolicy
metadata:
  name: user-service-psp
spec:
  privileged: false
  allowPrivilegeEscalation: false
  requiredDropCapabilities:
    - ALL
  volumes:
    - 'configMap'
    - 'emptyDir'
    - 'projected'
    - 'secret'
    - 'downwardAPI'
    - 'persistentVolumeClaim'
  runAsUser:
    rule: 'MustRunAsNonRoot'
  seLinux:
    rule: 'RunAsAny'
  fsGroup:
    rule: 'RunAsAny'

---
# rbac.yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: user-service
  namespace: production

---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: production
  name: user-service-role
rules:
- apiGroups: [""]
  resources: ["configmaps", "secrets"]
  verbs: ["get", "list", "watch"]
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "list"]

---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: user-service-rolebinding
  namespace: production
subjects:
- kind: ServiceAccount
  name: user-service
  namespace: production
roleRef:
  kind: Role
  name: user-service-role
  apiGroup: rbac.authorization.k8s.io
```

### 监控和日志
```yaml
# servicemonitor.yaml (Prometheus Operator)
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: user-service-metrics
  namespace: production
  labels:
    app: user-service
spec:
  selector:
    matchLabels:
      app: user-service
  endpoints:
  - port: http
    path: /metrics
    interval: 30s
    scrapeTimeout: 10s

---
# prometheusrule.yaml
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: user-service-alerts
  namespace: production
spec:
  groups:
  - name: user-service
    rules:
    - alert: UserServiceDown
      expr: up{job="user-service"} == 0
      for: 1m
      labels:
        severity: critical
      annotations:
        summary: "User service is down"
        description: "User service has been down for more than 1 minute"
    
    - alert: UserServiceHighErrorRate
      expr: rate(http_requests_total{job="user-service",status=~"5.."}[5m]) > 0.1
      for: 2m
      labels:
        severity: warning
      annotations:
        summary: "High error rate in user service"
        description: "Error rate is {{ $value }} errors per second"
    
    - alert: UserServiceHighLatency
      expr: histogram_quantile(0.95, rate(http_request_duration_seconds_bucket{job="user-service"}[5m])) > 1
      for: 5m
      labels:
        severity: warning
      annotations:
        summary: "High latency in user service"
        description: "95th percentile latency is {{ $value }}s"

---
# fluentd-configmap.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: fluentd-config
  namespace: kube-system
data:
  fluent.conf: |
    <source>
      @type tail
      path /var/log/containers/user-service-*.log
      pos_file /var/log/fluentd-user-service.log.pos
      tag kubernetes.user-service
      format json
      time_key time
      time_format %Y-%m-%dT%H:%M:%S.%NZ
    </source>
    
    <filter kubernetes.user-service>
      @type kubernetes_metadata
      @id filter_kube_metadata
    </filter>
    
    <match kubernetes.user-service>
      @type elasticsearch
      host elasticsearch.logging.svc.cluster.local
      port 9200
      index_name user-service-logs
      type_name _doc
      include_tag_key true
      tag_key @log_name
      flush_interval 1s
    </match>
```

## 配置规范

### Helm Chart结构
```yaml
# Chart.yaml
apiVersion: v2
name: user-service
description: User management service Helm chart
type: application
version: 1.2.3
appVersion: "v1.2.3"
keywords:
  - user
  - microservice
  - api
maintainers:
  - name: DevOps Team
    email: devops@example.com

# values.yaml
replicaCount: 3

image:
  repository: myregistry/user-service
  pullPolicy: IfNotPresent
  tag: "v1.2.3"

imagePullSecrets:
  - name: registry-secret

nameOverride: ""
fullnameOverride: ""

serviceAccount:
  create: true
  annotations: {}
  name: ""

podAnnotations:
  prometheus.io/scrape: "true"
  prometheus.io/port: "8080"
  prometheus.io/path: "/metrics"

podSecurityContext:
  runAsNonRoot: true
  runAsUser: 1000
  fsGroup: 2000

securityContext:
  allowPrivilegeEscalation: false
  readOnlyRootFilesystem: true
  capabilities:
    drop:
    - ALL

service:
  type: ClusterIP
  port: 80
  targetPort: 8080

ingress:
  enabled: true
  className: "nginx"
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
    cert-manager.io/cluster-issuer: letsencrypt-prod
  hosts:
    - host: api.example.com
      paths:
        - path: /users
          pathType: Prefix
  tls:
    - secretName: user-service-tls
      hosts:
        - api.example.com

resources:
  limits:
    cpu: 500m
    memory: 512Mi
  requests:
    cpu: 250m
    memory: 256Mi

autoscaling:
  enabled: true
  minReplicas: 3
  maxReplicas: 10
  targetCPUUtilizationPercentage: 70
  targetMemoryUtilizationPercentage: 80

nodeSelector: {}

tolerations: []

affinity:
  podAntiAffinity:
    preferredDuringSchedulingIgnoredDuringExecution:
    - weight: 100
      podAffinityTerm:
        labelSelector:
          matchExpressions:
          - key: app.kubernetes.io/name
            operator: In
            values:
            - user-service
        topologyKey: kubernetes.io/hostname

config:
  logLevel: "info"
  maxConnections: 100
  timeout: "30s"

secrets:
  databaseUrl: ""
  apiKey: ""
  jwtSecret: ""
```

### Kustomize配置
```yaml
# kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

namespace: production

resources:
- deployment.yaml
- service.yaml
- configmap.yaml
- secret.yaml
- ingress.yaml
- hpa.yaml

images:
- name: myregistry/user-service
  newTag: v1.2.3

replicas:
- name: user-service
  count: 3

patchesStrategicMerge:
- production-patches.yaml

configMapGenerator:
- name: user-service-config
  files:
  - config/app.properties
  - config/logging.conf

secretGenerator:
- name: user-service-secrets
  env: secrets/.env

commonLabels:
  app: user-service
  version: v1.2.3
  environment: production

commonAnnotations:
  managed-by: kustomize
  contact: devops@example.com
```

## 常见问题与解决方案

### 故障排查
```bash
# 查看Pod状态和事件
kubectl get pods -n production
kubectl describe pod user-service-xxx -n production
kubectl logs user-service-xxx -n production --previous

# 查看资源使用情况
kubectl top pods -n production
kubectl top nodes

# 检查网络连接
kubectl exec -it user-service-xxx -n production -- nslookup database-service
kubectl exec -it user-service-xxx -n production -- curl -v http://api-gateway/health

# 查看集群事件
kubectl get events -n production --sort-by='.lastTimestamp'

# 检查资源配额
kubectl describe resourcequota -n production
kubectl describe limitrange -n production
```

### 性能优化
```yaml
# 资源请求和限制优化
resources:
  requests:
    memory: "256Mi"  # 根据实际使用情况设置
    cpu: "250m"      # 避免设置过高导致调度困难
  limits:
    memory: "512Mi"  # 防止OOM，但不要设置过低
    cpu: "1000m"     # 允许突发使用

# 就绪性和存活性探针优化
readinessProbe:
  httpGet:
    path: /ready
    port: 8080
  initialDelaySeconds: 5   # 应用启动时间
  periodSeconds: 5         # 检查频率
  timeoutSeconds: 3        # 超时时间
  failureThreshold: 3      # 失败次数

livenessProbe:
  httpGet:
    path: /health
    port: 8080
  initialDelaySeconds: 30  # 给应用足够启动时间
  periodSeconds: 10        # 不要太频繁
  timeoutSeconds: 5
  failureThreshold: 3

# 启动探针（避免慢启动应用被杀死）
startupProbe:
  httpGet:
    path: /health
    port: 8080
  initialDelaySeconds: 10
  periodSeconds: 10
  timeoutSeconds: 5
  failureThreshold: 30     # 给应用5分钟启动时间
```

### 安全加固
```yaml
# Pod安全上下文
securityContext:
  runAsNonRoot: true
  runAsUser: 1000
  runAsGroup: 3000
  fsGroup: 2000
  seccompProfile:
    type: RuntimeDefault

# 容器安全上下文
securityContext:
  allowPrivilegeEscalation: false
  readOnlyRootFilesystem: true
  capabilities:
    drop:
    - ALL
    add:
    - NET_BIND_SERVICE  # 仅在需要时添加

# 网络策略（默认拒绝）
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-all
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
```

## 输出模板

### Kubernetes部署清单
```markdown
# Kubernetes部署清单

## 部署前检查
- [ ] 镜像已构建并推送到仓库
- [ ] 配置文件已更新
- [ ] 密钥已创建
- [ ] 资源配额充足
- [ ] 网络策略已配置

## 部署配置
- [ ] Deployment配置正确
- [ ] Service配置正确
- [ ] Ingress配置正确
- [ ] ConfigMap和Secret配置
- [ ] RBAC权限配置

## 监控配置
- [ ] 健康检查配置
- [ ] 指标收集配置
- [ ] 日志收集配置
- [ ] 告警规则配置

## 安全配置
- [ ] 安全上下文配置
- [ ] 网络策略配置
- [ ] RBAC权限最小化
- [ ] 镜像安全扫描

## 部署后验证
- [ ] Pod状态正常
- [ ] 服务可访问
- [ ] 健康检查通过
- [ ] 监控数据正常
- [ ] 日志输出正常
```
