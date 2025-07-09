# PostgreSQL 数据库规则文档

## 工具概述
PostgreSQL是一个功能强大的开源关系型数据库管理系统，支持高级数据类型和复杂查询。

### 适用场景
- 企业级应用数据存储
- 复杂查询和数据分析
- 地理信息系统(GIS)
- 时间序列数据处理
- 全文搜索应用

### 核心特性
- **ACID事务**: 完整的事务支持
- **高级数据类型**: JSON、数组、自定义类型
- **扩展性**: 丰富的扩展生态
- **并发控制**: MVCC多版本并发控制
- **全文搜索**: 内置全文搜索功能

## 最佳实践

### 数据库设计
```sql
-- 用户表设计
CREATE TABLE users (
    id BIGSERIAL PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    username VARCHAR(50) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    phone VARCHAR(20),
    avatar_url TEXT,
    is_active BOOLEAN DEFAULT true,
    is_verified BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    last_login_at TIMESTAMP WITH TIME ZONE,
    
    -- 约束
    CONSTRAINT users_email_check CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'),
    CONSTRAINT users_username_check CHECK (username ~* '^[a-zA-Z0-9_]{3,50}$'),
    CONSTRAINT users_phone_check CHECK (phone IS NULL OR phone ~* '^\+?[1-9]\d{1,14}$')
);

-- 创建索引
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_username ON users(username);
CREATE INDEX idx_users_created_at ON users(created_at);
CREATE INDEX idx_users_active_verified ON users(is_active, is_verified) WHERE is_active = true;

-- 文章表设计
CREATE TABLE articles (
    id BIGSERIAL PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    slug VARCHAR(255) UNIQUE NOT NULL,
    content TEXT NOT NULL,
    excerpt TEXT,
    author_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    category_id INTEGER REFERENCES categories(id) ON DELETE SET NULL,
    status VARCHAR(20) DEFAULT 'draft' CHECK (status IN ('draft', 'published', 'archived')),
    featured_image_url TEXT,
    tags TEXT[] DEFAULT '{}',
    metadata JSONB DEFAULT '{}',
    view_count INTEGER DEFAULT 0,
    like_count INTEGER DEFAULT 0,
    published_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 创建复合索引
CREATE INDEX idx_articles_author_status ON articles(author_id, status);
CREATE INDEX idx_articles_published_at ON articles(published_at) WHERE status = 'published';
CREATE INDEX idx_articles_slug ON articles(slug);

-- GIN索引用于数组和JSONB
CREATE INDEX idx_articles_tags ON articles USING GIN(tags);
CREATE INDEX idx_articles_metadata ON articles USING GIN(metadata);

-- 全文搜索索引
CREATE INDEX idx_articles_search ON articles USING GIN(to_tsvector('chinese', title || ' ' || content));

-- 评论表设计（支持嵌套评论）
CREATE TABLE comments (
    id BIGSERIAL PRIMARY KEY,
    article_id BIGINT NOT NULL REFERENCES articles(id) ON DELETE CASCADE,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    parent_id BIGINT REFERENCES comments(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    is_approved BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    -- 防止过深嵌套
    CONSTRAINT comments_depth_check CHECK (
        parent_id IS NULL OR 
        (SELECT COUNT(*) FROM comments c WHERE c.id = parent_id AND c.parent_id IS NOT NULL) < 3
    )
);

CREATE INDEX idx_comments_article_approved ON comments(article_id, is_approved);
CREATE INDEX idx_comments_user ON comments(user_id);
CREATE INDEX idx_comments_parent ON comments(parent_id);
```

### 高级查询技巧
```sql
-- 1. 窗口函数应用
-- 获取每个用户最新的3篇文章
WITH ranked_articles AS (
    SELECT 
        a.*,
        ROW_NUMBER() OVER (PARTITION BY author_id ORDER BY published_at DESC) as rn
    FROM articles a
    WHERE status = 'published'
)
SELECT * FROM ranked_articles WHERE rn <= 3;

-- 计算累计统计
SELECT 
    date_trunc('month', created_at) as month,
    COUNT(*) as monthly_users,
    SUM(COUNT(*)) OVER (ORDER BY date_trunc('month', created_at)) as cumulative_users
FROM users
GROUP BY date_trunc('month', created_at)
ORDER BY month;

-- 2. 递归查询（评论树）
WITH RECURSIVE comment_tree AS (
    -- 根评论
    SELECT 
        id, article_id, user_id, parent_id, content, 
        created_at, 0 as level, ARRAY[id] as path
    FROM comments 
    WHERE parent_id IS NULL AND article_id = $1
    
    UNION ALL
    
    -- 子评论
    SELECT 
        c.id, c.article_id, c.user_id, c.parent_id, c.content,
        c.created_at, ct.level + 1, ct.path || c.id
    FROM comments c
    JOIN comment_tree ct ON c.parent_id = ct.id
    WHERE ct.level < 5  -- 限制递归深度
)
SELECT 
    ct.*,
    u.username,
    u.avatar_url
FROM comment_tree ct
JOIN users u ON ct.user_id = u.id
ORDER BY path;

-- 3. JSON查询
-- 查询包含特定标签的文章
SELECT title, tags
FROM articles
WHERE tags @> ARRAY['技术', 'PostgreSQL'];

-- 查询元数据中的特定字段
SELECT title, metadata->'seo'->>'description' as seo_description
FROM articles
WHERE metadata->'seo'->>'keywords' LIKE '%数据库%';

-- 更新JSON字段
UPDATE articles 
SET metadata = jsonb_set(
    metadata, 
    '{seo,updated_at}', 
    to_jsonb(CURRENT_TIMESTAMP)
)
WHERE id = $1;

-- 4. 全文搜索
-- 基本全文搜索
SELECT 
    title,
    ts_headline('chinese', content, plainto_tsquery('chinese', $1)) as highlighted_content,
    ts_rank(to_tsvector('chinese', title || ' ' || content), plainto_tsquery('chinese', $1)) as rank
FROM articles
WHERE to_tsvector('chinese', title || ' ' || content) @@ plainto_tsquery('chinese', $1)
ORDER BY rank DESC;

-- 5. 地理查询（需要PostGIS扩展）
-- 创建地理位置表
CREATE EXTENSION IF NOT EXISTS postgis;

CREATE TABLE locations (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    address TEXT,
    coordinates GEOMETRY(POINT, 4326),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 创建空间索引
CREATE INDEX idx_locations_coordinates ON locations USING GIST(coordinates);

-- 查找附近的位置
SELECT 
    name,
    address,
    ST_Distance(coordinates, ST_SetSRID(ST_MakePoint($1, $2), 4326)) as distance
FROM locations
WHERE ST_DWithin(coordinates, ST_SetSRID(ST_MakePoint($1, $2), 4326), 0.01)  -- 约1km
ORDER BY distance;
```

### 性能优化
```sql
-- 1. 查询优化
-- 使用EXPLAIN ANALYZE分析查询
EXPLAIN (ANALYZE, BUFFERS, FORMAT JSON) 
SELECT a.title, u.username, COUNT(c.id) as comment_count
FROM articles a
JOIN users u ON a.author_id = u.id
LEFT JOIN comments c ON a.id = c.article_id
WHERE a.status = 'published'
GROUP BY a.id, a.title, u.username
ORDER BY a.published_at DESC
LIMIT 20;

-- 2. 索引优化
-- 部分索引（只为特定条件创建索引）
CREATE INDEX idx_articles_published_recent 
ON articles(published_at) 
WHERE status = 'published' AND published_at > CURRENT_DATE - INTERVAL '1 year';

-- 表达式索引
CREATE INDEX idx_users_lower_email ON users(lower(email));
CREATE INDEX idx_articles_title_length ON articles(length(title));

-- 3. 分区表
-- 按时间分区的日志表
CREATE TABLE access_logs (
    id BIGSERIAL,
    user_id BIGINT,
    url TEXT NOT NULL,
    method VARCHAR(10) NOT NULL,
    status_code INTEGER NOT NULL,
    response_time INTEGER,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
) PARTITION BY RANGE (created_at);

-- 创建分区
CREATE TABLE access_logs_2024_01 PARTITION OF access_logs
FOR VALUES FROM ('2024-01-01') TO ('2024-02-01');

CREATE TABLE access_logs_2024_02 PARTITION OF access_logs
FOR VALUES FROM ('2024-02-01') TO ('2024-03-01');

-- 4. 物化视图
-- 创建文章统计的物化视图
CREATE MATERIALIZED VIEW article_stats AS
SELECT 
    a.id,
    a.title,
    a.author_id,
    u.username,
    COUNT(DISTINCT c.id) as comment_count,
    COUNT(DISTINCT l.id) as like_count,
    a.view_count,
    a.published_at
FROM articles a
JOIN users u ON a.author_id = u.id
LEFT JOIN comments c ON a.id = c.article_id AND c.is_approved = true
LEFT JOIN likes l ON a.id = l.article_id
WHERE a.status = 'published'
GROUP BY a.id, a.title, a.author_id, u.username, a.view_count, a.published_at;

-- 创建唯一索引
CREATE UNIQUE INDEX idx_article_stats_id ON article_stats(id);

-- 定期刷新物化视图
REFRESH MATERIALIZED VIEW CONCURRENTLY article_stats;
```

### 事务和并发控制
```sql
-- 1. 事务隔离级别
-- 读已提交（默认）
BEGIN TRANSACTION ISOLATION LEVEL READ COMMITTED;
-- 业务逻辑
COMMIT;

-- 可重复读
BEGIN TRANSACTION ISOLATION LEVEL REPEATABLE READ;
-- 业务逻辑
COMMIT;

-- 序列化
BEGIN TRANSACTION ISOLATION LEVEL SERIALIZABLE;
-- 业务逻辑
COMMIT;

-- 2. 行级锁
-- 悲观锁：防止并发修改
BEGIN;
SELECT * FROM accounts WHERE id = $1 FOR UPDATE;
UPDATE accounts SET balance = balance - $2 WHERE id = $1;
UPDATE accounts SET balance = balance + $2 WHERE id = $3;
COMMIT;

-- 乐观锁：使用版本号
UPDATE articles 
SET 
    title = $2,
    content = $3,
    version = version + 1,
    updated_at = CURRENT_TIMESTAMP
WHERE id = $1 AND version = $4;

-- 3. 死锁预防
-- 按固定顺序获取锁
BEGIN;
SELECT * FROM table1 WHERE id = LEAST($1, $2) FOR UPDATE;
SELECT * FROM table1 WHERE id = GREATEST($1, $2) FOR UPDATE;
-- 业务逻辑
COMMIT;

-- 4. 批量操作优化
-- 使用COPY进行批量插入
COPY users(email, username, first_name, last_name) 
FROM '/path/to/users.csv' 
WITH (FORMAT csv, HEADER true);

-- 批量更新
UPDATE articles 
SET view_count = view_count + data.increment
FROM (VALUES 
    (1, 5),
    (2, 3),
    (3, 8)
) AS data(id, increment)
WHERE articles.id = data.id;

-- 使用ON CONFLICT处理重复
INSERT INTO user_preferences (user_id, preference_key, preference_value)
VALUES ($1, $2, $3)
ON CONFLICT (user_id, preference_key)
DO UPDATE SET 
    preference_value = EXCLUDED.preference_value,
    updated_at = CURRENT_TIMESTAMP;

## 监控和维护

### 性能监控
```sql
-- 1. 查看当前活动连接
SELECT
    pid,
    usename,
    application_name,
    client_addr,
    state,
    query_start,
    state_change,
    query
FROM pg_stat_activity
WHERE state != 'idle'
ORDER BY query_start;

-- 2. 查看慢查询
SELECT
    query,
    calls,
    total_time,
    mean_time,
    rows,
    100.0 * shared_blks_hit / nullif(shared_blks_hit + shared_blks_read, 0) AS hit_percent
FROM pg_stat_statements
ORDER BY total_time DESC
LIMIT 10;

-- 3. 表和索引使用统计
SELECT
    schemaname,
    tablename,
    seq_scan,
    seq_tup_read,
    idx_scan,
    idx_tup_fetch,
    n_tup_ins,
    n_tup_upd,
    n_tup_del
FROM pg_stat_user_tables
ORDER BY seq_scan DESC;

-- 4. 索引使用情况
SELECT
    schemaname,
    tablename,
    indexname,
    idx_scan,
    idx_tup_read,
    idx_tup_fetch
FROM pg_stat_user_indexes
ORDER BY idx_scan ASC;

-- 5. 数据库大小统计
SELECT
    datname,
    pg_size_pretty(pg_database_size(datname)) as size
FROM pg_database
ORDER BY pg_database_size(datname) DESC;

-- 6. 表大小统计
SELECT
    schemaname,
    tablename,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) as size,
    pg_size_pretty(pg_relation_size(schemaname||'.'||tablename)) as table_size,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename) - pg_relation_size(schemaname||'.'||tablename)) as index_size
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;
```

### 备份和恢复
```bash
# 1. 逻辑备份
# 备份单个数据库
pg_dump -h localhost -U postgres -d myapp > myapp_backup.sql

# 备份所有数据库
pg_dumpall -h localhost -U postgres > all_databases_backup.sql

# 压缩备份
pg_dump -h localhost -U postgres -d myapp | gzip > myapp_backup.sql.gz

# 自定义格式备份（推荐）
pg_dump -h localhost -U postgres -d myapp -Fc > myapp_backup.dump

# 并行备份（提高速度）
pg_dump -h localhost -U postgres -d myapp -Fd -j 4 -f myapp_backup_dir

# 2. 物理备份
# 基础备份
pg_basebackup -h localhost -U postgres -D /backup/base -Ft -z -P

# 3. 恢复
# 从SQL文件恢复
psql -h localhost -U postgres -d myapp < myapp_backup.sql

# 从自定义格式恢复
pg_restore -h localhost -U postgres -d myapp myapp_backup.dump

# 并行恢复
pg_restore -h localhost -U postgres -d myapp -j 4 myapp_backup_dir

# 4. 自动化备份脚本
#!/bin/bash
# backup_script.sh

DB_NAME="myapp"
DB_USER="postgres"
DB_HOST="localhost"
BACKUP_DIR="/backups"
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="$BACKUP_DIR/${DB_NAME}_${DATE}.dump"

# 创建备份
pg_dump -h $DB_HOST -U $DB_USER -d $DB_NAME -Fc > $BACKUP_FILE

# 检查备份是否成功
if [ $? -eq 0 ]; then
    echo "备份成功: $BACKUP_FILE"

    # 删除7天前的备份
    find $BACKUP_DIR -name "${DB_NAME}_*.dump" -mtime +7 -delete
else
    echo "备份失败"
    exit 1
fi

# 5. 定时备份（crontab）
# 每天凌晨2点执行备份
# 0 2 * * * /path/to/backup_script.sh
```

### 故障排查
```sql
-- 1. 检查锁等待
SELECT
    blocked_locks.pid AS blocked_pid,
    blocked_activity.usename AS blocked_user,
    blocking_locks.pid AS blocking_pid,
    blocking_activity.usename AS blocking_user,
    blocked_activity.query AS blocked_statement,
    blocking_activity.query AS blocking_statement
FROM pg_catalog.pg_locks blocked_locks
JOIN pg_catalog.pg_stat_activity blocked_activity ON blocked_activity.pid = blocked_locks.pid
JOIN pg_catalog.pg_locks blocking_locks ON blocking_locks.locktype = blocked_locks.locktype
    AND blocking_locks.DATABASE IS NOT DISTINCT FROM blocked_locks.DATABASE
    AND blocking_locks.relation IS NOT DISTINCT FROM blocked_locks.relation
    AND blocking_locks.page IS NOT DISTINCT FROM blocked_locks.page
    AND blocking_locks.tuple IS NOT DISTINCT FROM blocked_locks.tuple
    AND blocking_locks.virtualxid IS NOT DISTINCT FROM blocked_locks.virtualxid
    AND blocking_locks.transactionid IS NOT DISTINCT FROM blocked_locks.transactionid
    AND blocking_locks.classid IS NOT DISTINCT FROM blocked_locks.classid
    AND blocking_locks.objid IS NOT DISTINCT FROM blocked_locks.objid
    AND blocking_locks.objsubid IS NOT DISTINCT FROM blocked_locks.objsubid
    AND blocking_locks.pid != blocked_locks.pid
JOIN pg_catalog.pg_stat_activity blocking_activity ON blocking_activity.pid = blocking_locks.pid
WHERE NOT blocked_locks.GRANTED;

-- 2. 检查表膨胀
SELECT
    schemaname,
    tablename,
    n_dead_tup,
    n_live_tup,
    ROUND(n_dead_tup * 100.0 / GREATEST(n_live_tup + n_dead_tup, 1), 2) AS dead_tuple_percent
FROM pg_stat_user_tables
WHERE n_dead_tup > 0
ORDER BY dead_tuple_percent DESC;

-- 3. 检查需要VACUUM的表
SELECT
    schemaname,
    tablename,
    last_vacuum,
    last_autovacuum,
    vacuum_count,
    autovacuum_count
FROM pg_stat_user_tables
WHERE last_autovacuum < CURRENT_DATE - INTERVAL '1 day'
   OR last_autovacuum IS NULL;

-- 4. 检查复制延迟（主从复制）
SELECT
    client_addr,
    state,
    sent_lsn,
    write_lsn,
    flush_lsn,
    replay_lsn,
    write_lag,
    flush_lag,
    replay_lag
FROM pg_stat_replication;

-- 5. 检查连接数
SELECT
    COUNT(*) as total_connections,
    COUNT(*) FILTER (WHERE state = 'active') as active_connections,
    COUNT(*) FILTER (WHERE state = 'idle') as idle_connections,
    COUNT(*) FILTER (WHERE state = 'idle in transaction') as idle_in_transaction
FROM pg_stat_activity;

-- 6. 终止长时间运行的查询
-- 查看长时间运行的查询
SELECT
    pid,
    usename,
    query_start,
    state,
    query
FROM pg_stat_activity
WHERE state != 'idle'
  AND query_start < CURRENT_TIMESTAMP - INTERVAL '5 minutes';

-- 终止特定查询
SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE pid = 12345;

-- 7. 检查磁盘空间
SELECT
    name,
    setting,
    unit,
    context
FROM pg_settings
WHERE name IN ('data_directory', 'log_directory', 'wal_level');
```

## PostgreSQL最佳实践检查清单

### 数据库设计
```markdown
- [ ] 合理的表结构设计和规范化
- [ ] 适当的数据类型选择
- [ ] 完整的约束和索引设计
- [ ] 外键关系正确设置
- [ ] 分区策略合理规划
```

### 性能优化
```markdown
- [ ] 查询性能分析和优化
- [ ] 索引策略合理配置
- [ ] 统计信息及时更新
- [ ] 连接池正确配置
- [ ] 缓存策略有效实施
```

### 安全性
```markdown
- [ ] 用户权限最小化原则
- [ ] 数据加密传输和存储
- [ ] SQL注入防护措施
- [ ] 审计日志完整记录
- [ ] 定期安全更新
```

### 备份和恢复
```markdown
- [ ] 自动化备份策略
- [ ] 备份完整性验证
- [ ] 恢复流程测试
- [ ] 灾难恢复计划
- [ ] 备份数据异地存储
```

### 监控和维护
```markdown
- [ ] 性能监控指标配置
- [ ] 慢查询日志分析
- [ ] 磁盘空间监控
- [ ] 连接数监控
- [ ] 定期维护任务执行
```
```
