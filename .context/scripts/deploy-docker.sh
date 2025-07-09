#!/bin/bash

# Docker 部署脚本
# 用法: ./deploy-docker.sh <app-name> [environment] [registry]

set -e

APP_NAME=${1:-"myapp"}
ENVIRONMENT=${2:-"production"}
REGISTRY=${3:-""}
VERSION=${4:-"latest"}

echo "🚀 开始 Docker 部署: $APP_NAME (环境: $ENVIRONMENT)"

# 检查必要工具
command -v docker >/dev/null 2>&1 || { echo "❌ Docker 未安装"; exit 1; }

# 设置镜像名称
if [ -n "$REGISTRY" ]; then
    IMAGE_NAME="$REGISTRY/$APP_NAME:$VERSION"
else
    IMAGE_NAME="$APP_NAME:$VERSION"
fi

# 构建 Docker 镜像
echo "📦 构建 Docker 镜像: $IMAGE_NAME"
docker build -t $IMAGE_NAME .

# 如果指定了镜像仓库，推送镜像
if [ -n "$REGISTRY" ]; then
    echo "📤 推送镜像到仓库: $REGISTRY"
    docker push $IMAGE_NAME
fi

# 停止并删除旧容器
echo "🛑 停止旧容器..."
docker stop $APP_NAME-$ENVIRONMENT 2>/dev/null || true
docker rm $APP_NAME-$ENVIRONMENT 2>/dev/null || true

# 根据环境设置不同的配置
case $ENVIRONMENT in
    "development")
        PORT=3001
        ENV_FILE=".env.development"
        RESTART_POLICY="no"
        ;;
    "staging")
        PORT=3002
        ENV_FILE=".env.staging"
        RESTART_POLICY="unless-stopped"
        ;;
    "production")
        PORT=3000
        ENV_FILE=".env.production"
        RESTART_POLICY="always"
        ;;
    *)
        echo "❌ 未知环境: $ENVIRONMENT"
        exit 1
        ;;
esac

# 检查环境文件是否存在
if [ ! -f "$ENV_FILE" ]; then
    echo "⚠️ 环境文件 $ENV_FILE 不存在，使用默认 .env"
    ENV_FILE=".env"
fi

# 启动新容器
echo "🚀 启动新容器..."
docker run -d \
    --name $APP_NAME-$ENVIRONMENT \
    --restart $RESTART_POLICY \
    -p $PORT:3000 \
    --env-file $ENV_FILE \
    -v $(pwd)/logs:/app/logs \
    $IMAGE_NAME

# 等待容器启动
echo "⏳ 等待容器启动..."
sleep 5

# 检查容器状态
if docker ps | grep -q $APP_NAME-$ENVIRONMENT; then
    echo "✅ 容器启动成功"
    
    # 显示容器信息
    echo "📊 容器信息:"
    docker ps --filter "name=$APP_NAME-$ENVIRONMENT" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
    
    # 健康检查
    echo "🏥 执行健康检查..."
    sleep 10
    
    if curl -f http://localhost:$PORT/health >/dev/null 2>&1; then
        echo "✅ 健康检查通过"
        echo "🌐 应用访问地址: http://localhost:$PORT"
    else
        echo "❌ 健康检查失败"
        echo "📋 查看容器日志:"
        docker logs $APP_NAME-$ENVIRONMENT --tail 20
        exit 1
    fi
else
    echo "❌ 容器启动失败"
    echo "📋 查看容器日志:"
    docker logs $APP_NAME-$ENVIRONMENT --tail 20
    exit 1
fi

# 清理未使用的镜像
echo "🧹 清理未使用的镜像..."
docker image prune -f

echo "🎉 部署完成！"
echo "📱 管理命令:"
echo "  查看日志: docker logs $APP_NAME-$ENVIRONMENT -f"
echo "  停止容器: docker stop $APP_NAME-$ENVIRONMENT"
echo "  重启容器: docker restart $APP_NAME-$ENVIRONMENT"
echo "  进入容器: docker exec -it $APP_NAME-$ENVIRONMENT /bin/sh"
