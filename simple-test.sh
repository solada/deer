#!/bin/bash

# 简化版外网测试脚本 - 可在任何机器上运行
DOMAIN="deerlulu1008.cn"
BASE_URL="https://$DOMAIN/api"

echo "=== 鹿鹿论坛外网简单测试 ==="
echo "域名: $DOMAIN"
echo "时间: $(date)"
echo ""

# 1. 基础连通性测试
echo "1. 测试域名解析..."
if ping -c 1 $DOMAIN >/dev/null 2>&1; then
    echo "✅ 域名可以访问"
else
    echo "❌ 域名无法访问"
    exit 1
fi

# 2. HTTPS 服务测试
echo ""
echo "2. 测试 HTTPS 服务..."
HTTP_CODE=$(curl -k -s -o /dev/null -w "%{http_code}" https://$DOMAIN 2>/dev/null)
if [ "$HTTP_CODE" = "200" ]; then
    echo "✅ HTTPS 主页正常 (HTTP $HTTP_CODE)"
else
    echo "❌ HTTPS 主页异常 (HTTP $HTTP_CODE)"
fi

# 3. API 健康检查
echo ""
echo "3. 测试 API 健康检查..."
HEALTH_RESPONSE=$(curl -k -s https://$DOMAIN/health 2>/dev/null)
if echo "$HEALTH_RESPONSE" | grep -q "正常运行"; then
    echo "✅ API 健康检查通过"
    echo "响应: $HEALTH_RESPONSE"
else
    echo "❌ API 健康检查失败"
    echo "响应: $HEALTH_RESPONSE"
fi

# 4. 获取帖子列表
echo ""
echo "4. 测试获取帖子列表..."
POSTS_RESPONSE=$(curl -k -s $BASE_URL/posts 2>/dev/null)
if echo "$POSTS_RESPONSE" | grep -q "posts"; then
    echo "✅ 获取帖子列表成功"
    POST_COUNT=$(echo "$POSTS_RESPONSE" | grep -o '"id":[0-9]*' | wc -l)
    echo "当前帖子数量: $POST_COUNT"
else
    echo "❌ 获取帖子列表失败"
    echo "响应: $POSTS_RESPONSE"
fi

# 5. 用户注册测试
echo ""
echo "5. 测试用户注册..."
RANDOM_USER="test_$(date +%s)"
REGISTER_DATA="{\"username\":\"$RANDOM_USER\",\"password\":\"password123\",\"email\":\"$RANDOM_USER@test.com\",\"nickname\":\"测试用户\"}"

REGISTER_RESPONSE=$(curl -k -s -X POST $BASE_URL/register \
    -H "Content-Type: application/json" \
    -d "$REGISTER_DATA" 2>/dev/null)

if echo "$REGISTER_RESPONSE" | grep -q "token"; then
    echo "✅ 用户注册成功"
    TOKEN=$(echo "$REGISTER_RESPONSE" | grep -o '"token":"[^"]*' | cut -d'"' -f4)
    echo "获取到认证令牌: ${TOKEN:0:20}..."
    
    # 6. 发帖测试
    echo ""
    echo "6. 测试发布帖子..."
    POST_DATA="{\"title\":\"外网测试帖子\",\"content\":\"这是外网测试发布的帖子 - $(date)\"}"
    
    POST_RESPONSE=$(curl -k -s -X POST $BASE_URL/posts \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $TOKEN" \
        -d "$POST_DATA" 2>/dev/null)
    
    if echo "$POST_RESPONSE" | grep -q "发帖成功"; then
        echo "✅ 发布帖子成功"
        POST_ID=$(echo "$POST_RESPONSE" | grep -o '"id":[0-9]*' | cut -d':' -f2)
        echo "帖子ID: $POST_ID"
        
        # 7. 评论测试
        echo ""
        echo "7. 测试发表评论..."
        COMMENT_DATA="{\"content\":\"这是外网测试评论 - $(date)\"}"
        
        COMMENT_RESPONSE=$(curl -k -s -X POST $BASE_URL/posts/$POST_ID/comments \
            -H "Content-Type: application/json" \
            -H "Authorization: Bearer $TOKEN" \
            -d "$COMMENT_DATA" 2>/dev/null)
        
        if echo "$COMMENT_RESPONSE" | grep -q "评论成功"; then
            echo "✅ 发表评论成功"
        else
            echo "❌ 发表评论失败"
            echo "响应: $COMMENT_RESPONSE"
        fi
    else
        echo "❌ 发布帖子失败"
        echo "响应: $POST_RESPONSE"
    fi
else
    echo "❌ 用户注册失败"
    echo "响应: $REGISTER_RESPONSE"
fi

# 8. HTTP 重定向测试
echo ""
echo "8. 测试 HTTP 重定向..."
HTTP_REDIRECT=$(curl -s -I http://$DOMAIN 2>/dev/null | head -1)
if echo "$HTTP_REDIRECT" | grep -q "301"; then
    echo "✅ HTTP 自动重定向到 HTTPS 正常"
else
    echo "⚠️  HTTP 重定向可能有问题"
    echo "响应: $HTTP_REDIRECT"
fi

echo ""
echo "=== 测试完成 ==="
echo ""
echo "📱 微信小程序配置："
echo "request 合法域名: https://$DOMAIN"
echo ""
echo "🔗 API 接口地址："
echo "基础路径: $BASE_URL"
echo "健康检查: https://$DOMAIN/health"
echo ""
echo "✨ 如果所有测试都通过，您的服务就可以在微信小程序中正常使用了！"
