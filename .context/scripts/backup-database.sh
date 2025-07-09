#!/bin/bash

# 数据库备份脚本
# 用法: ./backup-database.sh <database-type> <database-name> [backup-dir]
# 支持的数据库类型: mysql, postgresql, mongodb

set -e

DB_TYPE=${1:-""}
DB_NAME=${2:-""}
BACKUP_DIR=${3:-"./backups"}
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

if [ -z "$DB_TYPE" ] || [ -z "$DB_NAME" ]; then
    echo "用法: $0 <database-type> <database-name> [backup-dir]"
    echo "支持的数据库类型: mysql, postgresql, mongodb"
    exit 1
fi

echo "🗄️ 开始备份数据库: $DB_NAME (类型: $DB_TYPE)"

# 创建备份目录
mkdir -p $BACKUP_DIR

# 设置备份文件名
BACKUP_FILE="$BACKUP_DIR/${DB_NAME}_${TIMESTAMP}"

case $DB_TYPE in
    "mysql")
        echo "📦 备份 MySQL 数据库..."
        
        # 检查 mysqldump 是否可用
        command -v mysqldump >/dev/null 2>&1 || { echo "❌ mysqldump 未安装"; exit 1; }
        
        # 从环境变量或提示获取连接信息
        MYSQL_HOST=${MYSQL_HOST:-"localhost"}
        MYSQL_PORT=${MYSQL_PORT:-"3306"}
        MYSQL_USER=${MYSQL_USER:-"root"}
        
        if [ -z "$MYSQL_PASSWORD" ]; then
            read -s -p "请输入 MySQL 密码: " MYSQL_PASSWORD
            echo
        fi
        
        # 执行备份
        mysqldump -h$MYSQL_HOST -P$MYSQL_PORT -u$MYSQL_USER -p$MYSQL_PASSWORD \
            --single-transaction --routines --triggers \
            $DB_NAME > ${BACKUP_FILE}.sql
        
        # 压缩备份文件
        gzip ${BACKUP_FILE}.sql
        BACKUP_FILE="${BACKUP_FILE}.sql.gz"
        ;;
        
    "postgresql")
        echo "📦 备份 PostgreSQL 数据库..."
        
        # 检查 pg_dump 是否可用
        command -v pg_dump >/dev/null 2>&1 || { echo "❌ pg_dump 未安装"; exit 1; }
        
        # 从环境变量获取连接信息
        PGHOST=${PGHOST:-"localhost"}
        PGPORT=${PGPORT:-"5432"}
        PGUSER=${PGUSER:-"postgres"}
        
        if [ -z "$PGPASSWORD" ]; then
            read -s -p "请输入 PostgreSQL 密码: " PGPASSWORD
            echo
            export PGPASSWORD
        fi
        
        # 执行备份
        pg_dump -h $PGHOST -p $PGPORT -U $PGUSER \
            --verbose --clean --no-owner --no-privileges \
            --format=custom \
            $DB_NAME > ${BACKUP_FILE}.dump
        
        BACKUP_FILE="${BACKUP_FILE}.dump"
        ;;
        
    "mongodb")
        echo "📦 备份 MongoDB 数据库..."
        
        # 检查 mongodump 是否可用
        command -v mongodump >/dev/null 2>&1 || { echo "❌ mongodump 未安装"; exit 1; }
        
        # 从环境变量获取连接信息
        MONGO_HOST=${MONGO_HOST:-"localhost"}
        MONGO_PORT=${MONGO_PORT:-"27017"}
        MONGO_USER=${MONGO_USER:-""}
        
        # 构建连接字符串
        if [ -n "$MONGO_USER" ]; then
            if [ -z "$MONGO_PASSWORD" ]; then
                read -s -p "请输入 MongoDB 密码: " MONGO_PASSWORD
                echo
            fi
            MONGO_URI="mongodb://$MONGO_USER:$MONGO_PASSWORD@$MONGO_HOST:$MONGO_PORT/$DB_NAME"
        else
            MONGO_URI="mongodb://$MONGO_HOST:$MONGO_PORT/$DB_NAME"
        fi
        
        # 执行备份
        mongodump --uri="$MONGO_URI" --out=${BACKUP_FILE}_dump
        
        # 压缩备份目录
        tar -czf ${BACKUP_FILE}.tar.gz -C $BACKUP_DIR ${DB_NAME}_${TIMESTAMP}_dump
        rm -rf ${BACKUP_FILE}_dump
        
        BACKUP_FILE="${BACKUP_FILE}.tar.gz"
        ;;
        
    *)
        echo "❌ 不支持的数据库类型: $DB_TYPE"
        echo "支持的类型: mysql, postgresql, mongodb"
        exit 1
        ;;
esac

# 检查备份文件是否创建成功
if [ -f "$BACKUP_FILE" ]; then
    BACKUP_SIZE=$(du -h "$BACKUP_FILE" | cut -f1)
    echo "✅ 备份完成!"
    echo "📁 备份文件: $BACKUP_FILE"
    echo "📊 文件大小: $BACKUP_SIZE"
    
    # 验证备份文件
    case $DB_TYPE in
        "mysql")
            if gzip -t "$BACKUP_FILE"; then
                echo "✅ 备份文件验证通过"
            else
                echo "❌ 备份文件验证失败"
                exit 1
            fi
            ;;
        "postgresql")
            if pg_restore --list "$BACKUP_FILE" >/dev/null 2>&1; then
                echo "✅ 备份文件验证通过"
            else
                echo "❌ 备份文件验证失败"
                exit 1
            fi
            ;;
        "mongodb")
            if tar -tzf "$BACKUP_FILE" >/dev/null 2>&1; then
                echo "✅ 备份文件验证通过"
            else
                echo "❌ 备份文件验证失败"
                exit 1
            fi
            ;;
    esac
    
    # 清理旧备份（保留最近7天）
    echo "🧹 清理旧备份文件..."
    find $BACKUP_DIR -name "${DB_NAME}_*" -type f -mtime +7 -delete
    
    # 显示剩余备份文件
    echo "📋 当前备份文件:"
    ls -lh $BACKUP_DIR/${DB_NAME}_* 2>/dev/null || echo "无其他备份文件"
    
else
    echo "❌ 备份失败，文件未创建"
    exit 1
fi

echo "🎉 数据库备份任务完成！"
