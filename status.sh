#!/bin/bash

# 服务状态检查脚本

echo "=== 鹿鹿论坛服务状态检查 ==="
echo ""

# 检查 Docker 服务状态
echo "📦 Docker 容器状态："
docker-compose ps
echo ""

# 检查端口占用
echo "🔌 端口占用情况："
echo "HTTP (80): $(netstat -tlnp | grep :80 | wc -l) 个进程"
echo "HTTPS (443): $(netstat -tlnp | grep :443 | wc -l) 个进程"
echo "MySQL (3306): $(netstat -tlnp | grep :3306 | wc -l) 个进程"
echo "Backend (3000): $(netstat -tlnp | grep :3000 | wc -l) 个进程"
echo ""

# 检查服务健康状态
echo "🔍 服务健康检查："

# MySQL 检查
if docker-compose exec -T mysql mysqladmin ping -h localhost -u root -proot123456 >/dev/null 2>&1; then
    echo "✅ MySQL 数据库: 正常"
else
    echo "❌ MySQL 数据库: 异常"
fi

# 后端服务检查
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:3000/api/health 2>/dev/null)
if [ "$HTTP_CODE" = "200" ]; then
    echo "✅ 后端服务: 正常"
else
    echo "❌ 后端服务: 异常 (HTTP $HTTP_CODE)"
fi

# HTTP 重定向检查
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:80 2>/dev/null)
if [ "$HTTP_CODE" = "301" ]; then
    echo "✅ HTTP 重定向: 正常"
else
    echo "❌ HTTP 重定向: 异常 (HTTP $HTTP_CODE)"
fi

# HTTPS 服务检查
HTTP_CODE=$(curl -s -k -o /dev/null -w "%{http_code}" https://localhost:443 2>/dev/null)
if [ "$HTTP_CODE" = "200" ]; then
    echo "✅ HTTPS 服务: 正常"
else
    echo "❌ HTTPS 服务: 异常 (HTTP $HTTP_CODE)"
fi

# HTTPS API 检查
HTTP_CODE=$(curl -s -k -o /dev/null -w "%{http_code}" https://localhost:443/health 2>/dev/null)
if [ "$HTTP_CODE" = "200" ]; then
    echo "✅ HTTPS API: 正常"
else
    echo "❌ HTTPS API: 异常 (HTTP $HTTP_CODE)"
fi

echo ""

# 检查数据库连接和数据
echo "📊 数据库状态："
USER_COUNT=$(docker-compose exec -T mysql mysql -u deeruser -pdeer123456 deer_forum -e "SELECT COUNT(*) as count FROM users;" -s -N 2>/dev/null)
POST_COUNT=$(docker-compose exec -T mysql mysql -u deeruser -pdeer123456 deer_forum -e "SELECT COUNT(*) as count FROM posts;" -s -N 2>/dev/null)
COMMENT_COUNT=$(docker-compose exec -T mysql mysql -u deeruser -pdeer123456 deer_forum -e "SELECT COUNT(*) as count FROM comments;" -s -N 2>/dev/null)

echo "用户数量: $USER_COUNT"
echo "帖子数量: $POST_COUNT"
echo "评论数量: $COMMENT_COUNT"
echo ""

# 检查 SSL 证书
echo "🔒 SSL 证书状态："
if [ -f "./ssl/deerlulu1008.cn.crt" ] && [ -f "./ssl/deerlulu1008.cn.key" ]; then
    CERT_EXPIRY=$(openssl x509 -in ./ssl/deerlulu1008.cn.crt -noout -dates | grep notAfter | cut -d= -f2)
    echo "✅ SSL 证书文件存在"
    echo "证书过期时间: $CERT_EXPIRY"
else
    echo "❌ SSL 证书文件缺失"
fi
echo ""

# 检查日志
echo "📝 最近的错误日志："
echo "--- 后端服务错误 ---"
docker-compose logs backend 2>/dev/null | grep -i error | tail -3
echo "--- MySQL 错误 ---"
docker-compose logs mysql 2>/dev/null | grep -i error | tail -3
echo "--- Nginx 错误 ---"
docker-compose logs nginx 2>/dev/null | grep -i error | tail -3
echo ""

echo "=== 状态检查完成 ==="
echo ""
echo "💡 如果发现异常，请检查："
echo "   - Docker 服务是否正常运行"
echo "   - 端口是否被占用"
echo "   - SSL 证书是否正确配置"
echo "   - 防火墙设置是否正确"
echo ""
echo "🔧 常用管理命令："
echo "   - 查看详细日志: docker-compose logs -f [service]"
echo "   - 重启服务: docker-compose restart [service]"
echo "   - 停止服务: docker-compose down"
echo "   - 启动服务: docker-compose up -d"
