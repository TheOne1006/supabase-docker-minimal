# Supabase 最小化 Docker Compose 配置

这是一个模块化的 Supabase Docker Compose 配置，专注于构建**最小可用的 Supabase 环境**，将服务分离到三个独立的文件中，便于灵活管理和按需启动。

## 🎯 项目目标

构建一个**最小可用的 Supabase 环境**，包含：
- ✅ PostgreSQL 数据库（带 Supabase 扩展）
- ✅ REST API（PostgREST）
- ✅ 身份认证（GoTrue）
- ✅ API 网关（Kong）
- ✅ 数据库管理界面（postgres-meta）
- ✅ Web 管理界面（Studio，可选）

**不包含的服务**（可根据需要添加）：
- ❌ Realtime（实时订阅）
- ❌ Storage（文件存储）
- ❌ Edge Functions（边缘函数）
- ❌ Analytics（日志分析）

## 📁 文件结构

```
.
├── docker-compose.db.yml       # 数据库层：PostgreSQL
├── docker-compose.yml          # 核心服务层：Auth + REST + Meta + Kong
├── docker-compose.studio.yml   # 管理界面层：Studio（可选）
├── .env.example                # 环境变量模板
├── volumes/
│   ├── api/
│   │   └── kong.yml           # Kong 网关配置
│   └── db/                     # 数据库初始化脚本
└── README.md
```

## 🐳 Docker 镜像说明

### 1. 数据库层（docker-compose.db.yml）

#### `supabase/postgres:15.1.0.54-rc0`
**作用**：Supabase 定制的 PostgreSQL 数据库
- 基于 PostgreSQL 15
- 预装 Supabase 所需的扩展（pg_graphql, pgjwt, pgsodium 等）
- 启用逻辑复制（用于 Realtime）
- 包含 Supabase 的角色和权限体系

**为什么单独一个文件**：
- 数据库是基础设施，需要最先启动
- 创建 `supabase_network` 网络供其他服务使用
- 数据持久化独立管理，避免误删
- 可以独立重启其他服务而不影响数据库

### 2. 核心服务层（docker-compose.yml）

#### `supabase/gotrue:v2.60.7`
**作用**：身份认证服务（Auth）
- 用户注册、登录、密码重置
- JWT Token 生成和验证
- OAuth 第三方登录集成
- 邮箱/手机号验证
- 多因素认证（MFA）

#### `postgrest/postgrest:v10.1.2`
**作用**：自动生成 REST API
- 将 PostgreSQL 表自动转换为 RESTful API
- 支持 CRUD 操作（增删改查）
- 基于 JWT 的行级安全（RLS）
- 支持复杂查询、过滤、排序、分页

#### `supabase/postgres-meta:v0.60.7`
**作用**：数据库元数据管理
- 提供数据库结构的 API（表、列、关系等）
- Studio 界面依赖此服务获取数据库信息
- 支持通过 API 修改数据库结构

#### `kong:2.8.1`
**作用**：API 网关和反向代理
- 统一入口：所有 API 请求通过 Kong 路由
- 认证鉴权：验证 API Key 和 JWT Token
- 请求转发：将请求路由到对应的后端服务
  - `/auth/v1/*` → GoTrue
  - `/rest/v1/*` → PostgREST
  - `/meta/*` → postgres-meta
- CORS 处理和请求限流

**为什么这些服务在一起**：
- 它们构成了 Supabase 的核心功能
- 相互依赖紧密（都需要数据库和网络）
- 通常一起启动和停止
- 对外只暴露 Kong 的端口（8000/8443）

### 3. 管理界面层（docker-compose.studio.yml）

#### `supabase/studio:2025.12.17-sha-43f4f7f`
**作用**：Web 管理界面
- 可视化数据库管理（表编辑器）
- SQL 编辑器
- 用户管理界面
- API 文档查看
- 实时日志查看

**为什么单独一个文件**：
- Studio 是可选的，生产环境可能不需要
- 占用资源较多，开发时按需启动
- 可以独立更新而不影响核心服务
- 便于在无需管理界面时节省资源

## 🏗️ 配置文件设计原因

### 为什么分成三个文件？

1. **分层架构**
   - 数据层 → 服务层 → 界面层
   - 清晰的依赖关系和启动顺序

2. **灵活性**
   - 开发环境：启动所有服务
   - 测试环境：只启动数据库和核心服务
   - 生产环境：不启动 Studio

3. **资源优化**
   - 按需启动，节省内存和 CPU
   - Studio 占用约 200-300MB 内存

4. **维护性**
   - 每个文件职责单一，易于理解
   - 修改某层服务不影响其他层
   - 便于添加新服务（如 Realtime、Storage）

### 为什么使用外部网络？

```yaml
networks:
  supabase_network:
    external: true
```

- Docker Compose 的 `depends_on` 不能跨文件工作
- 使用外部网络让多个 compose 文件共享同一网络
- 由 `docker-compose.db.yml` 创建网络，其他文件加入

## 🔍 镜像技术细节

### PostgreSQL 扩展

Supabase PostgreSQL 镜像包含以下扩展：

| 扩展名 | 作用 |
|--------|------|
| `pg_graphql` | GraphQL API 支持 |
| `pgjwt` | JWT token 生成和验证 |
| `pgsodium` | 加密功能（libsodium） |
| `pg_stat_statements` | SQL 性能统计 |
| `pgcrypto` | 加密函数 |
| `uuid-ossp` | UUID 生成 |
| `pg_net` | HTTP 请求（用于 webhooks） |

### 预定义角色

| 角色 | 权限 | 用途 |
|------|------|------|
| `postgres` | 超级用户 | 数据库管理 |
| `supabase_admin` | 管理员 | Supabase 内部管理 |
| `supabase_auth_admin` | Auth 管理 | GoTrue 使用 |
| `authenticator` | 连接角色 | PostgREST 连接池 |
| `anon` | 匿名用户 | 公开 API 访问 |
| `authenticated` | 认证用户 | 登录后的用户 |
| `service_role` | 服务角色 | 后端服务（绕过 RLS） |

### Kong 插件配置

当前配置启用的 Kong 插件：

| 插件 | 作用 |
|------|------|
| `request-transformer` | 修改请求头和参数 |
| `cors` | 跨域资源共享 |
| `key-auth` | API Key 认证 |
| `acl` | 访问控制列表 |
| `basic-auth` | 基础认证（Studio） |
| `request-termination` | 请求终止（错误处理） |
| `ip-restriction` | IP 白名单/黑名单 |

## 🚀 快速开始

### 1. 准备环境变量

```bash
# 复制环境变量模板
cp .env.example .env

# 编辑 .env 文件，至少修改以下内容：
# - POSTGRES_PASSWORD (数据库密码)
# - JWT_SECRET (JWT 密钥，至少 32 字符)
# - DASHBOARD_USERNAME (Studio 用户名，默认: supabase)
# - DASHBOARD_PASSWORD (Studio 密码，默认: supabase)
```

### 2. 启动服务

#### 🎯 推荐方式：使用启动脚本

```bash
# 给脚本添加执行权限
chmod +x start.sh stop.sh

# 启动所有服务（数据库 + 核心服务 + Studio）
./start.sh all

# 或者分步启动：
./start.sh db      # 仅启动数据库
./start.sh core    # 启动数据库和核心服务
./start.sh all     # 启动所有服务
```

#### 手动启动方式

如果不使用脚本，可以手动启动：

#### 方式 A：仅启动数据库

```bash
docker-compose -f docker-compose.db.yml up -d
```

#### 方式 B：启动核心服务（数据库 + Auth + REST + Kong）

```bash
# 先启动数据库
docker-compose -f docker-compose.db.yml up -d

# 等待数据库就绪（约 10 秒）
sleep 10

# 启动核心服务
docker-compose -f docker-compose.yml up -d
```

#### 方式 C：启动所有服务（包括 Studio）

```bash
# 先启动数据库
docker-compose -f docker-compose.db.yml up -d

# 等待数据库就绪
sleep 10

# 启动核心服务
docker-compose -f docker-compose.yml up -d

# 等待核心服务就绪
sleep 5

# 启动 Studio
docker-compose -f docker-compose.studio.yml up -d
```

### 4. 验证服务

```bash
# 检查所有容器状态
docker ps

# 测试 Auth API
curl http://localhost:8000/auth/v1/health

# 测试 REST API
curl http://localhost:8000/rest/v1/

# 访问 Studio（如果已启动）
# 浏览器打开: http://localhost:3001
# 用户名: supabase (在 .env 中配置)
# 密码: 在 .env 中的 DASHBOARD_PASSWORD
```

## 🛑 停止服务

#### 使用停止脚本（推荐）

```bash
./stop.sh all      # 停止所有服务
./stop.sh studio   # 仅停止 Studio
./stop.sh core     # 停止 Studio 和核心服务
./stop.sh db       # 停止所有服务（包括数据库）
```

#### 手动停止

```bash
# 停止所有服务
docker-compose -f docker-compose.studio.yml down
docker-compose -f docker-compose.yml down
docker-compose -f docker-compose.db.yml down

# 停止并删除数据卷（⚠️ 会删除所有数据）
docker-compose -f docker-compose.db.yml down -v
```

## 📊 服务端口

| 服务 | 容器名 | 端口 | 说明 |
|------|--------|------|------|
| PostgreSQL | supabase-db | 5432 | 数据库直连端口 |
| Kong Gateway | supabase-kong | 8000 | HTTP API 网关（主要入口） |
| Kong Gateway | supabase-kong | 8443 | HTTPS API 网关 |
| Studio | supabase-studio | 3000 | Web 管理界面 |
| GoTrue | supabase-auth | 9999 | 内部端口（通过 Kong 访问） |
| PostgREST | supabase-rest | 3000 | 内部端口（通过 Kong 访问） |
| postgres-meta | supabase-meta | 8080 | 内部端口（Studio 使用） |

**访问方式**：
- 所有 API 请求统一通过 Kong：`http://localhost:8000`
- Studio 管理界面：`http://localhost:3000`
- 数据库直连：`postgresql://postgres:your-password@localhost:5432/postgres`

## 🔑 默认凭证

- **Studio Dashboard**
  - URL: http://localhost:3000
  - 用户名: `supabase`
  - 密码: `supabase`
  - （可在 `.env` 文件中修改）

## 🔧 常见问题

### 问题 1: 网络不存在错误

```
ERROR: Network supabase_network declared as external, but could not be found
```

**原因**：其他服务依赖的网络还未创建

**解决方案**：
```bash
# 方案 1: 先启动数据库（会自动创建网络）
docker-compose -f docker-compose.db.yml up -d

# 方案 2: 手动创建网络
docker network create supabase_network
```

### 问题 2: 服务无法连接到数据库

**症状**：
- GoTrue 或 PostgREST 启动失败
- 日志显示 "connection refused" 或 "database not found"

**解决方案**：
1. 确保数据库已启动并健康：
   ```bash
   docker ps | grep supabase-db
   docker logs supabase-db
   ```
2. 检查 `.env` 文件中的 `POSTGRES_HOST=db`（容器名）
3. 等待数据库完全就绪（约 10-15 秒）后再启动其他服务
4. 检查网络连接：
   ```bash
   docker exec supabase-auth ping -c 2 db
   ```

### 问题 3: Kong 启动失败

**症状**：
- Kong 容器反复重启
- 日志显示 "failed to load declarative config"

**解决方案**：
1. 检查 `volumes/api/kong.yml` 是否存在且格式正确
2. 确保环境变量已正确替换：
   ```bash
   docker logs supabase-kong
   ```
3. 验证 Kong 配置：
   ```bash
   docker exec supabase-kong kong config parse /home/kong/kong.yml
   ```

### 问题 4: Studio 无法访问或登录失败

**症状**：
- Studio 页面空白或报错
- 无法查看数据库表

**解决方案**：
1. 确保 meta 服务已启动：
   ```bash
   docker ps | grep supabase-meta
   ```
2. 检查 Studio 日志：
   ```bash
   docker logs supabase-studio
   ```
3. 验证 meta 服务连接：
   ```bash
   curl http://localhost:8000/meta/health
   ```
4. 确认 `.env` 中的 `DASHBOARD_USERNAME` 和 `DASHBOARD_PASSWORD` 已设置

### 问题 5: 端口冲突

```
ERROR: port is already allocated
```

**解决方案**：修改 `.env` 文件中的端口配置：
```bash
# 示例：修改为其他端口
POSTGRES_PORT=5433
KONG_HTTP_PORT=8001
KONG_HTTPS_PORT=8444
STUDIO_PORT=3001
```

### 问题 6: 数据库初始化失败

**症状**：
- 数据库启动但无法连接
- 缺少 Supabase 角色或表

**解决方案**：
1. 检查初始化脚本是否正确挂载：
   ```bash
   docker exec supabase-db ls -la /docker-entrypoint-initdb.d/
   ```
2. 查看数据库日志：
   ```bash
   docker logs supabase-db | grep ERROR
   ```
3. 重新初始化（⚠️ 会删除所有数据）：
   ```bash
   docker-compose -f docker-compose.db.yml down -v
   docker-compose -f docker-compose.db.yml up -d
   ```

### 问题 7: JWT Token 验证失败

**症状**：
- API 返回 401 Unauthorized
- "JWT verification failed"

**解决方案**：
1. 确保所有服务使用相同的 `JWT_SECRET`
2. 验证 ANON_KEY 和 SERVICE_ROLE_KEY 是否正确：
   ```bash
   # 在 https://jwt.io 解码 token，检查 secret
   ```
3. 重新生成 JWT keys（如果修改了 JWT_SECRET）：
   ```bash
   # 使用 Supabase CLI 或在线工具生成
   ```

## ⚠️ 重要说明

### 最小可用 vs 完整版本

**当前配置包含**：
- ✅ 数据库（PostgreSQL + Supabase 扩展）
- ✅ REST API（PostgREST）
- ✅ 身份认证（GoTrue）
- ✅ API 网关（Kong）
- ✅ 数据库管理（postgres-meta）
- ✅ Web 界面（Studio）

**完整 Supabase 还包括**：
- ❌ Realtime（实时订阅，WebSocket）
- ❌ Storage（文件存储和 CDN）
- ❌ Edge Functions（Deno 边缘函数）
- ❌ Analytics（Vector 日志收集）
- ❌ Imgproxy（图片处理）

### 服务间依赖关系

```
┌─────────────────────────────────────────┐
│  Studio (Web 界面)                       │
│  - 依赖: meta, kong                      │
└─────────────────────────────────────────┘
                  ↓
┌─────────────────────────────────────────┐
│  Kong (API 网关)                         │
│  - 路由所有 API 请求                     │
│  - 依赖: auth, rest, meta                │
└─────────────────────────────────────────┘
                  ↓
┌──────────────┬──────────────┬───────────┐
│ GoTrue       │ PostgREST    │ Meta      │
│ (Auth)       │ (REST API)   │ (DB Info) │
└──────────────┴──────────────┴───────────┘
                  ↓
┌─────────────────────────────────────────┐
│  PostgreSQL (数据库)                     │
│  - 所有服务的数据存储                    │
└─────────────────────────────────────────┘
```

### 跨文件依赖说明

⚠️ **重要**：Docker Compose 的 `depends_on` 在跨文件时不生效

**解决方案**：
1. 使用外部网络（`supabase_network`）
2. 手动控制启动顺序：
   - 第一步：启动数据库（创建网络）
   - 第二步：等待数据库就绪
   - 第三步：启动核心服务
   - 第四步：启动 Studio（可选）

### 生产环境注意事项

⚠️ **此配置仅用于开发和测试环境，不适合直接用于生产环境！**

生产环境需要：
- ✅ 使用强密码和密钥（至少 32 字符）
- ✅ 配置 HTTPS/SSL 证书
- ✅ 添加数据库备份策略
- ✅ 配置监控和日志收集
- ✅ 使用 Docker Secrets 而非环境变量
- ✅ 不要暴露数据库端口到主机（移除 `ports` 配置）
- ✅ 配置防火墙和访问控制
- ✅ 定期更新镜像版本

## 📚 API 使用示例

### Kong 路由规则

所有 API 请求通过 Kong 网关（`http://localhost:8000`）：

| 路径 | 后端服务 | 说明 |
|------|---------|------|
| `/auth/v1/*` | GoTrue (9999) | 用户认证 API |
| `/rest/v1/*` | PostgREST (3000) | 数据库 REST API |
| `/meta/*` | postgres-meta (8080) | 数据库元数据 API |

### 使用 Anon Key 访问 REST API

```bash
# 从 .env 文件获取 ANON_KEY
ANON_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyAgCiAgICAicm9sZSI6ICJhbm9uIiwKICAgICJpc3MiOiAic3VwYWJhc2UtZGVtbyIsCiAgICAiaWF0IjogMTY0MTc2OTIwMCwKICAgICJleHAiOiAxNzk5NTM1NjAwCn0.dc_X5iR_VP_qT0zsiyj_I_OZ2T9FtRU2BBNWN8Bu4GE"

# 查询数据（需要先创建表）
curl http://localhost:8000/rest/v1/your_table \
  -H "apikey: $ANON_KEY" \
  -H "Authorization: Bearer $ANON_KEY"

# 插入数据
curl -X POST http://localhost:8000/rest/v1/your_table \
  -H "apikey: $ANON_KEY" \
  -H "Authorization: Bearer $ANON_KEY" \
  -H "Content-Type: application/json" \
  -d '{"column1": "value1", "column2": "value2"}'
```

### 使用 Service Role Key（后端操作）

```bash
# 从 .env 文件获取 SERVICE_ROLE_KEY（绕过 RLS）
SERVICE_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyAgCiAgICAicm9sZSI6ICJzZXJ2aWNlX3JvbGUiLAogICAgImlzcyI6ICJzdXBhYmFzZS1kZW1vIiwKICAgICJpYXQiOiAxNjQxNzY5MjAwLAogICAgImV4cCI6IDE3OTk1MzU2MDAKfQ.DaYlNEoUrrEn2Ig7tqibS-PHK5vgusbcbo7X36XVt4Q"

# 执行管理操作（绕过行级安全）
curl http://localhost:8000/rest/v1/your_table \
  -H "apikey: $SERVICE_KEY" \
  -H "Authorization: Bearer $SERVICE_KEY"
```

### 用户注册和登录

```bash
# 注册新用户
curl -X POST http://localhost:8000/auth/v1/signup \
  -H "apikey: $ANON_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "user@example.com",
    "password": "your-password"
  }'

# 登录
curl -X POST http://localhost:8000/auth/v1/token?grant_type=password \
  -H "apikey: $ANON_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "user@example.com",
    "password": "your-password"
  }'
```

## 🔗 相关链接

- [Supabase 官方文档](https://supabase.com/docs)
- [Docker Compose 文档](https://docs.docker.com/compose/)
- [PostgREST 文档](https://postgrest.org/)
- [Kong Gateway 文档](https://docs.konghq.com/)
- [GoTrue 文档](https://github.com/supabase/gotrue)

## 💾 资源使用情况

### 内存占用（参考值）

| 服务 | 内存占用 | 说明 |
|------|---------|------|
| PostgreSQL | 100-200 MB | 取决于数据量和连接数 |
| GoTrue | 20-50 MB | 轻量级 Go 服务 |
| PostgREST | 10-30 MB | 轻量级 Haskell 服务 |
| postgres-meta | 30-50 MB | Node.js 服务 |
| Kong | 50-100 MB | Nginx + Lua |
| Studio | 200-300 MB | Next.js 应用 |
| **总计（不含 Studio）** | **~300-500 MB** | 最小可用配置 |
| **总计（含 Studio）** | **~500-800 MB** | 完整开发环境 |

### 磁盘占用

| 项目 | 大小 | 说明 |
|------|------|------|
| Docker 镜像 | ~2-3 GB | 所有服务的镜像 |
| 数据库数据 | 取决于使用 | `volumes/db/data/` |
| 日志文件 | 取决于使用 | Docker 日志 |

### 性能建议

- **最低配置**：2 CPU 核心，4GB 内存
- **推荐配置**：4 CPU 核心，8GB 内存
- **生产环境**：根据负载调整，建议至少 8GB 内存

## 🚀 扩展指南

### 添加 Realtime 服务

如需实时订阅功能，可添加：

```yaml
# 在 docker-compose.yml 中添加
realtime:
  container_name: supabase-realtime
  image: supabase/realtime:v2.10.1
  environment:
    DB_HOST: ${POSTGRES_HOST}
    DB_PORT: ${POSTGRES_PORT}
    DB_NAME: ${POSTGRES_DB}
    DB_USER: supabase_admin
    DB_PASSWORD: ${POSTGRES_PASSWORD}
    JWT_SECRET: ${JWT_SECRET}
  networks:
    - supabase_network
```

### 添加 Storage 服务

如需文件存储功能，可添加：

```yaml
# 在 docker-compose.yml 中添加
storage:
  container_name: supabase-storage
  image: supabase/storage-api:v0.40.4
  environment:
    POSTGREST_URL: http://rest:3000
    PGRST_JWT_SECRET: ${JWT_SECRET}
    DATABASE_URL: postgres://supabase_storage_admin:${POSTGRES_PASSWORD}@${POSTGRES_HOST}:${POSTGRES_PORT}/${POSTGRES_DB}
  volumes:
    - ./volumes/storage:/var/lib/storage
  networks:
    - supabase_network
```

### 添加 Edge Functions

如需边缘函数功能，可添加：

```yaml
# 在 docker-compose.yml 中添加
functions:
  container_name: supabase-functions
  image: supabase/edge-runtime:v1.22.4
  environment:
    JWT_SECRET: ${JWT_SECRET}
  volumes:
    - ./volumes/functions:/home/deno/functions
  networks:
    - supabase_network
```

## 📝 许可证

此配置基于 Supabase 官方配置修改，遵循相同的开源许可证。
