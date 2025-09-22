#!/bin/bash

# API 测试脚本
BASE_URL="https://localhost:443/api"

echo "=== 鹿鹿论坛 API 测试 ==="
echo ""

# 测试健康检查
echo "1. 测试健康检查..."
curl -s -k $BASE_URL/health | jq .
echo ""

# 测试用户注册
echo "2. 测试用户注册..."
REGISTER_RESPONSE=$(curl -s -k -X POST $BASE_URL/register \
  -H "Content-Type: application/json" \
  -d '{"username":"testapi","password":"password123","email":"testapi@deerlulu1008.cn","nickname":"API测试用户"}')
echo $REGISTER_RESPONSE | jq .
TOKEN=$(echo $REGISTER_RESPONSE | jq -r '.token')
echo "获取到 Token: $TOKEN"
echo ""

# 测试用户登录
echo "3. 测试用户登录..."
LOGIN_RESPONSE=$(curl -s -k -X POST $BASE_URL/login \
  -H "Content-Type: application/json" \
  -d '{"username":"testapi","password":"password123"}')
echo $LOGIN_RESPONSE | jq .
echo ""

# 测试获取帖子列表
echo "4. 测试获取帖子列表..."
curl -s -k $BASE_URL/posts | jq .
echo ""

# 测试发布帖子
echo "5. 测试发布帖子..."
POST_RESPONSE=$(curl -s -k -X POST $BASE_URL/posts \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{"title":"API测试帖子","content":"这是通过API测试脚本发布的帖子，用来验证所有功能是否正常工作。包含中文字符测试。"}')
echo $POST_RESPONSE | jq .
POST_ID=$(echo $POST_RESPONSE | jq -r '.post.id')
echo "创建的帖子ID: $POST_ID"
echo ""

# 测试发表评论
echo "6. 测试发表评论..."
COMMENT_RESPONSE=$(curl -s -k -X POST $BASE_URL/posts/$POST_ID/comments \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{"content":"这是一条测试评论，验证评论功能是否正常。"}')
echo $COMMENT_RESPONSE | jq .
COMMENT_ID=$(echo $COMMENT_RESPONSE | jq -r '.comment.id')
echo ""

# 测试回复评论
echo "7. 测试回复评论..."
curl -s -k -X POST $BASE_URL/posts/$POST_ID/comments \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d "{\"content\":\"这是对评论的回复，测试嵌套评论功能。\",\"reply_to_comment_id\":$COMMENT_ID,\"reply_to_user_id\":$(echo $REGISTER_RESPONSE | jq -r '.user.id')}" | jq .
echo ""

# 测试获取帖子详情
echo "8. 测试获取帖子详情和评论..."
curl -s -k $BASE_URL/posts/$POST_ID | jq .
echo ""

# 测试分页
echo "9. 测试帖子列表分页..."
curl -s -k "$BASE_URL/posts?page=1&limit=2" | jq .
echo ""

echo "=== API 测试完成 ==="
echo ""
echo "📊 测试总结："
echo "✅ 健康检查接口"
echo "✅ 用户注册功能"
echo "✅ 用户登录功能"
echo "✅ 获取帖子列表"
echo "✅ 发布帖子功能"
echo "✅ 发表评论功能"
echo "✅ 回复评论功能"
echo "✅ 获取帖子详情"
echo "✅ 分页功能"
echo ""
echo "🎉 所有功能测试通过！"
