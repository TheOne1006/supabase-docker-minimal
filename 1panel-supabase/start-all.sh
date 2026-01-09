#!/bin/bash
#
# Supabase 启动脚本
# 按顺序启动所有服务：数据库 -> 核心服务 -> Studio 管理面板
#

set -e

echo "🚀 启动 Supabase 服务..."
echo ""

# 检查 .env 文件是否存在
if [ ! -f .env ]; then
    echo "❌ 错误：.env 文件不存在"
    echo "请先复制 .env.example 到 .env 并配置相关参数"
    exit 1
fi

# 创建 Docker 网络（如果不存在）
echo "📡 创建 Docker 网络..."
docker network inspect supabase_network >/dev/null 2>&1 || \
    docker network create supabase_network

# 1. 启动数据库
echo ""
echo "📦 启动数据库服务..."
docker compose -f docker-compose.db.yml up -d

# 等待数据库就绪
echo "⏳ 等待数据库启动..."
sleep 5

# 2. 启动核心服务
echo ""
echo "🔧 启动核心服务 (API, Auth, Functions, Analytics, Pooler)..."
docker compose -f docker-compose.yml up -d

# 等待核心服务就绪
echo "⏳ 等待核心服务启动..."
sleep 3

# 3. 启动 Studio 管理面板
echo ""
echo "🎨 启动 Studio 管理面板..."
docker compose -f docker-compose.studio.yml up -d

echo ""
echo "✅ 所有服务启动完成！"
echo ""
echo "📊 服务访问地址："
echo "   - API Gateway:    http://localhost:8000"
echo "   - Studio 面板:    http://localhost:3000"
echo "   - Analytics:      http://localhost:4000"
echo "   - PostgreSQL:     localhost:5432"
echo "   - Pooler (事务):  localhost:6543"
echo ""
echo "💡 提示："
echo "   - 查看日志: docker compose -f docker-compose.yml logs -f"
echo "   - 查看状态: docker compose -f docker-compose.yml ps"
echo "   - 停止服务: ./stop-all.sh"
echo ""