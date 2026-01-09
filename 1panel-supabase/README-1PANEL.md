# 1Panel 使用说明 / 1Panel Usage Guide

## ⚠️ 重要提示

1Panel 不支持在 docker-compose.yml 根级别使用 `env_file`。
所有环境变量必须通过 1Panel 界面配置。

## 在 1Panel 界面配置环境变量

### 必需配置的环境变量

1. 打开 1Panel 管理界面
2. 进入应用管理 → 找到你的 Supabase 数据库应用
3. 点击"编辑" → "环境变量"
4. 添加以下环境变量：

#### 路径配置（必需）
```bash
SUPABASE_VOLUMES_BASE_PATH=/home/ubuntu/apps/supabase-docker-minimal
```
> 修改为你的实际项目路径（绝对路径）

#### 数据库配置（必需）
```bash
POSTGRES_PORT=5432
POSTGRES_DB=postgres
POSTGRES_HOST=db
```

#### 安全配置（必需）
```bash
JWT_SECRET=your-super-secret-jwt-token-with-at-least-32-characters-long
JWT_EXPIRY=3600
```

#### 1Panel 自动管理的变量（无需手动添加）
1Panel 会自动注入以下变量：
- `CONTAINER_NAME` - 容器名称
- `PANEL_APP_PORT_HTTP` - HTTP 端口
- `PANEL_DB_ROOT_USER` - 数据库用户名
- `PANEL_DB_ROOT_PASSWORD` - 数据库密码

### 完整的环境变量列表

可以参考 `1panel/.env.example` 文件，将需要的变量复制到 1Panel 界面中。

## 配置步骤

### 步骤 1：设置路径变量

在 1Panel 环境变量中添加：
```bash
SUPABASE_VOLUMES_BASE_PATH=/home/ubuntu/apps/supabase-docker-minimal
```

### 步骤 2：复制其他必需变量

从 `1panel/.env.example` 复制以下变量到 1Panel 界面：

```bash
# 数据库配置
POSTGRES_HOST=db
POSTGRES_DB=postgres
POSTGRES_PORT=5432

# JWT 配置
JWT_SECRET=your-super-secret-jwt-token-with-at-least-32-characters-long
JWT_EXPIRY=3600
```

### 步骤 3：保存并启动

1. 保存环境变量配置
2. 启动或重启应用

## 验证配置

启动容器后，验证环境变量：

```bash
docker exec <容器名称> env | grep SUPABASE_VOLUMES_BASE_PATH
```

应该输出：
```
SUPABASE_VOLUMES_BASE_PATH=/home/ubuntu/apps/supabase-docker-minimal
```

## 常见问题

### Q: 为什么不能使用 env_file？
A: 1Panel 对 Docker Compose 配置有严格的验证规则，不允许在根级别使用 `env_file`。所有环境变量必须通过 1Panel 界面管理。

### Q: 如何批量导入环境变量？
A: 
1. 复制 `1panel/.env.example` 的内容
2. 在 1Panel 界面中逐个添加，或者
3. 使用 1Panel 的批量导入功能（如果支持）

### Q: 路径必须是绝对路径吗？
A: 是的，`SUPABASE_VOLUMES_BASE_PATH` 必须是绝对路径，例如：
- `/opt/supabase`
- `/home/ubuntu/apps/supabase-docker-minimal`
- `/data/supabase`

### Q: 修改环境变量后需要重启吗？
A: 是的，修改环境变量后需要在 1Panel 中重启应用才能生效。

### Q: 可以使用 .env 文件吗？
A: 在 1Panel 中不推荐使用 .env 文件。建议直接在 1Panel 界面配置所有环境变量。

## 环境变量模板

复制以下内容到 1Panel 环境变量配置中（根据实际情况修改值）：

```bash
# ============ 路径配置 ============
SUPABASE_VOLUMES_BASE_PATH=/home/ubuntu/apps/supabase-docker-minimal

# ============ 数据库配置 ============
POSTGRES_HOST=db
POSTGRES_DB=postgres
POSTGRES_PORT=5432

# ============ 安全配置 ============
JWT_SECRET=your-super-secret-jwt-token-with-at-least-32-characters-long
JWT_EXPIRY=3600

# ============ 其他配置（可选）============
# 根据需要从 .env.example 中复制其他变量
```
