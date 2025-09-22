#!/bin/bash

# 鹿鹿论坛服务启动脚本

echo "=== 鹿鹿论坛 Docker 服务启动 ==="

# 检查 Docker 和 Docker Compose 是否安装
if ! command -v docker &> /dev/null; then
    echo "❌ Docker 未安装，请先安装 Docker"
    exit 1
fi

if ! command -v docker-compose &> /dev/null; then
    echo "❌ Docker Compose 未安装，请先安装 Docker Compose"
    exit 1
fi

# 检查 SSL 证书文件
if [ ! -f "./ssl/deerlulu1008.cn.crt" ] || [ ! -f "./ssl/deerlulu1008.cn.key" ]; then
    echo "⚠️  SSL 证书文件未找到，请确保以下文件存在："
    echo "   - ./ssl/deerlulu1008.cn.crt"
    echo "   - ./ssl/deerlulu1008.cn.key"
    echo ""
    echo "如果是测试环境，可以生成自签名证书："
    echo "   cd ssl"
    echo "   openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout deerlulu1008.cn.key -out deerlulu1008.cn.crt -subj '/CN=deerlulu1008.cn'"
    echo "   cd .."
    exit 1
fi

# 设置证书文件权限
chmod 644 ./ssl/deerlulu1008.cn.crt
chmod 600 ./ssl/deerlulu1008.cn.key

echo "✅ SSL 证书文件检查通过"

# 停止可能存在的旧容器
echo "🔄 停止旧容器..."
docker-compose down

# 构建并启动服务
echo "🚀 启动服务..."
docker-compose up --build -d

# 等待服务启动
echo "⏳ 等待服务启动..."
sleep 10

# 检查服务状态
echo "📊 服务状态检查："
docker-compose ps

# 检查服务健康状态
echo ""
echo "🔍 健康检查："
echo "- MySQL 数据库: $(docker-compose exec -T mysql mysqladmin ping -h localhost -u root -proot123456 2>/dev/null && echo '✅ 正常' || echo '❌ 异常')"
echo "- 后端服务: $(curl -s -o /dev/null -w "%{http_code}" http://localhost:3000/api/health | grep -q "200" && echo '✅ 正常' || echo '❌ 异常')"
echo "- Nginx 服务: $(curl -s -o /dev/null -w "%{http_code}" http://localhost:80 | grep -q "301" && echo '✅ 正常' || echo '❌ 异常')"

echo ""
echo "🎉 服务启动完成！"
echo ""
echo "📋 服务信息："
echo "   - HTTPS 地址: https://deerlulu1008.cn"
echo "   - HTTP 地址: http://deerlulu1008.cn (自动重定向到 HTTPS)"
echo "   - API 基础路径: https://deerlulu1008.cn/api"
echo "   - 健康检查: https://deerlulu1008.cn/health"
echo ""
echo "🔧 管理命令："
echo "   - 查看日志: docker-compose logs -f"
echo "   - 停止服务: docker-compose down"
echo "   - 重启服务: docker-compose restart"
echo ""
echo "📚 API 接口："
echo "   - POST /api/register - 用户注册"
echo "   - POST /api/login - 用户登录"
echo "   - GET /api/posts - 获取帖子列表"
echo "   - POST /api/posts - 发布帖子"
echo "   - GET /api/posts/:id - 获取帖子详情"
echo "   - POST /api/posts/:id/comments - 发表评论"
