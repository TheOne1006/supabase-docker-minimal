#!/bin/bash
#
# Supabase 停止脚本
# 按顺序停止所有服务：Studio -> 核心服务 -> 数据库
#

set -e

echo "🛑 停止 Supabase 服务..."
echo ""

# 1. 停止 Studio 管理面板
echo "🎨 停止 Studio 管理面板..."
docker compose -f docker-compose.studio.yml down

# 2. 停止核心服务
echo ""
echo "🔧 停止核心服务..."
docker compose -f docker-compose.yml down

# 3. 停止数据库
echo ""
echo "📦 停止数据库服务..."
docker compose -f docker-compose.db.yml down

echo ""
echo "✅ 所有服务已停止！"
echo ""
echo "💡 提示："
echo "   - 重新启动: ./start-all.sh"
echo "   - 完全清理 (删除数据): ./stop-all.sh --clean"
echo ""

# 可选：完全清理（删除卷和网络）
if [ "$1" = "--clean" ]; then
    echo "🧹 清理数据卷和网络..."
    docker compose -f docker-compose.studio.yml down -v
    docker compose -f docker-compose.yml down -v
    docker compose -f docker-compose.db.yml down -v
    docker network rm supabase_network 2>/dev/null || true
    echo "✅ 清理完成！所有数据已删除。"
fi
