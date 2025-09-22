#!/bin/bash

# 外网 HTTPS 测试脚本 - 使用真实域名 deerlulu1008.cn
DOMAIN="deerlulu1008.cn"
BASE_URL="https://$DOMAIN/api"

echo "=== 鹿鹿论坛外网 HTTPS 测试 ==="
echo "测试域名: $DOMAIN"
echo "测试时间: $(date)"
echo ""

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 测试结果统计
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# 测试函数
test_endpoint() {
    local name="$1"
    local method="$2"
    local url="$3"
    local headers="$4"
    local data="$5"
    local expected_status="$6"
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    echo -e "${BLUE}测试 $TOTAL_TESTS: $name${NC}"
    
    # 构建 curl 命令（跳过 SSL 验证，因为使用自签名证书）
    local curl_cmd="curl -k -s -w '%{http_code}|%{time_total}|%{size_download}'"
    
    if [ "$method" = "POST" ]; then
        curl_cmd="$curl_cmd -X POST"
    fi
    
    if [ ! -z "$headers" ]; then
        curl_cmd="$curl_cmd $headers"
    fi
    
    if [ ! -z "$data" ]; then
        curl_cmd="$curl_cmd -d '$data'"
    fi
    
    curl_cmd="$curl_cmd '$url'"
    
    # 执行请求
    local response=$(eval $curl_cmd)
    local status_code=$(echo "$response" | tail -c 20 | cut -d'|' -f1)
    local time_total=$(echo "$response" | tail -c 20 | cut -d'|' -f2)
    local size_download=$(echo "$response" | tail -c 20 | cut -d'|' -f3)
    local body=$(echo "$response" | sed 's/|[^|]*|[^|]*|[^|]*$//')
    
    # 检查结果
    if [ "$status_code" = "$expected_status" ]; then
        echo -e "  ${GREEN}✅ 成功${NC} - HTTP $status_code (${time_total}s, ${size_download} bytes)"
        PASSED_TESTS=$((PASSED_TESTS + 1))
        
        # 如果是 JSON 响应，尝试格式化显示
        if echo "$body" | jq . >/dev/null 2>&1; then
            echo "$body" | jq . | head -10
        else
            echo "$body" | head -5
        fi
    else
        echo -e "  ${RED}❌ 失败${NC} - 期望 HTTP $expected_status, 实际 HTTP $status_code"
        echo "  响应内容: $body"
        FAILED_TESTS=$((FAILED_TESTS + 1))
    fi
    echo ""
}

# 1. 测试域名解析
echo -e "${YELLOW}=== 1. 网络连接测试 ===${NC}"
echo "测试域名解析..."
if nslookup $DOMAIN >/dev/null 2>&1; then
    IP=$(nslookup $DOMAIN | grep "Address" | tail -1 | cut -d' ' -f2)
    echo -e "${GREEN}✅ 域名解析成功${NC} - $DOMAIN → $IP"
else
    echo -e "${RED}❌ 域名解析失败${NC}"
    echo "请检查："
    echo "1. 域名 DNS 记录是否正确配置"
    echo "2. 网络连接是否正常"
    exit 1
fi

echo "测试端口连通性..."
if timeout 5 bash -c "</dev/tcp/$DOMAIN/443" >/dev/null 2>&1; then
    echo -e "${GREEN}✅ HTTPS 端口 (443) 连通${NC}"
else
    echo -e "${RED}❌ HTTPS 端口 (443) 不通${NC}"
    echo "请检查："
    echo "1. 服务器防火墙是否开放 443 端口"
    echo "2. 云服务商安全组是否允许 443 端口"
    exit 1
fi

if timeout 5 bash -c "</dev/tcp/$DOMAIN/80" >/dev/null 2>&1; then
    echo -e "${GREEN}✅ HTTP 端口 (80) 连通${NC}"
else
    echo -e "${YELLOW}⚠️  HTTP 端口 (80) 不通${NC} - 这可能是正常的"
fi
echo ""

# 2. SSL 证书测试
echo -e "${YELLOW}=== 2. SSL 证书测试 ===${NC}"
echo "检查 SSL 证书..."
SSL_INFO=$(echo | openssl s_client -servername $DOMAIN -connect $DOMAIN:443 2>/dev/null | openssl x509 -noout -dates -subject 2>/dev/null)
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ SSL 证书有效${NC}"
    echo "$SSL_INFO"
else
    echo -e "${RED}❌ SSL 证书无效或无法连接${NC}"
    echo "请检查 SSL 证书配置"
fi
echo ""

# 3. 基础服务测试
echo -e "${YELLOW}=== 3. 基础服务测试 ===${NC}"

# 测试主页
test_endpoint "主页访问" "GET" "https://$DOMAIN" "" "" "200"

# 测试 HTTP 重定向
test_endpoint "HTTP 重定向" "GET" "http://$DOMAIN" "" "" "301"

# 测试健康检查
test_endpoint "健康检查接口" "GET" "https://$DOMAIN/health" "" "" "200"

# 4. API 接口测试
echo -e "${YELLOW}=== 4. API 接口测试 ===${NC}"

# 测试获取帖子列表
test_endpoint "获取帖子列表" "GET" "$BASE_URL/posts" "" "" "200"

# 测试用户注册
RANDOM_USER="testuser_$(date +%s)"
REGISTER_DATA="{\"username\":\"$RANDOM_USER\",\"password\":\"password123\",\"email\":\"$RANDOM_USER@test.com\",\"nickname\":\"外网测试用户\"}"
test_endpoint "用户注册" "POST" "$BASE_URL/register" "-H 'Content-Type: application/json'" "$REGISTER_DATA" "201"

# 提取注册返回的 token（如果成功）
if [ $? -eq 0 ]; then
    TOKEN=$(curl -s -X POST $BASE_URL/register -H "Content-Type: application/json" -d "$REGISTER_DATA" 2>/dev/null | jq -r '.token // empty')
    if [ ! -z "$TOKEN" ] && [ "$TOKEN" != "null" ]; then
        echo "获取到认证令牌，继续测试需要登录的接口..."
        
        # 测试发布帖子
        POST_DATA="{\"title\":\"外网测试帖子\",\"content\":\"这是通过外网 HTTPS 发布的测试帖子，验证服务正常工作。发布时间：$(date)\"}"
        test_endpoint "发布帖子" "POST" "$BASE_URL/posts" "-H 'Content-Type: application/json' -H 'Authorization: Bearer $TOKEN'" "$POST_DATA" "201"
        
        # 测试用户登录
        LOGIN_DATA="{\"username\":\"$RANDOM_USER\",\"password\":\"password123\"}"
        test_endpoint "用户登录" "POST" "$BASE_URL/login" "-H 'Content-Type: application/json'" "$LOGIN_DATA" "200"
    else
        echo -e "${YELLOW}⚠️  未能获取认证令牌，跳过需要登录的测试${NC}"
    fi
fi

# 5. 性能测试
echo -e "${YELLOW}=== 5. 性能测试 ===${NC}"
echo "测试响应时间..."

for i in {1..5}; do
    RESPONSE_TIME=$(curl -s -w '%{time_total}' -o /dev/null https://$DOMAIN/health)
    echo "第 $i 次请求: ${RESPONSE_TIME}s"
done
echo ""

# 6. 微信小程序兼容性测试
echo -e "${YELLOW}=== 6. 微信小程序兼容性测试 ===${NC}"

# 测试 CORS 预检请求
test_endpoint "CORS 预检请求" "OPTIONS" "$BASE_URL/posts" "-H 'Origin: https://servicewechat.com' -H 'Access-Control-Request-Method: POST' -H 'Access-Control-Request-Headers: Content-Type,Authorization'" "" "204"

# 测试带 Origin 的请求
test_endpoint "带微信 Origin 的请求" "GET" "$BASE_URL/posts" "-H 'Origin: https://servicewechat.com'" "" "200"

# 7. 错误处理测试
echo -e "${YELLOW}=== 7. 错误处理测试 ===${NC}"

# 测试不存在的接口
test_endpoint "404 错误处理" "GET" "$BASE_URL/nonexistent" "" "" "404"

# 测试无效的请求数据
test_endpoint "400 错误处理" "POST" "$BASE_URL/register" "-H 'Content-Type: application/json'" "{\"invalid\":\"data\"}" "400"

# 测试结果统计
echo -e "${YELLOW}=== 测试结果统计 ===${NC}"
echo "总测试数: $TOTAL_TESTS"
echo -e "通过: ${GREEN}$PASSED_TESTS${NC}"
echo -e "失败: ${RED}$FAILED_TESTS${NC}"

if [ $FAILED_TESTS -eq 0 ]; then
    echo -e "\n${GREEN}🎉 所有测试通过！您的服务可以正常通过外网 HTTPS 访问！${NC}"
    echo ""
    echo -e "${BLUE}📱 微信小程序配置信息：${NC}"
    echo "合法域名配置: https://$DOMAIN"
    echo "API 基础地址: $BASE_URL"
    echo ""
    echo -e "${BLUE}📋 可用的 API 接口：${NC}"
    echo "- POST $BASE_URL/register (用户注册)"
    echo "- POST $BASE_URL/login (用户登录)"
    echo "- GET  $BASE_URL/posts (获取帖子列表)"
    echo "- POST $BASE_URL/posts (发布帖子，需要登录)"
    echo "- GET  $BASE_URL/posts/:id (获取帖子详情)"
    echo "- POST $BASE_URL/posts/:id/comments (发表评论，需要登录)"
else
    echo -e "\n${RED}❌ 有 $FAILED_TESTS 个测试失败，请检查服务配置${NC}"
    echo ""
    echo -e "${BLUE}🔍 故障排查建议：${NC}"
    echo "1. 检查域名 DNS 解析是否指向正确的服务器 IP"
    echo "2. 确认服务器防火墙已开放 80 和 443 端口"
    echo "3. 验证 SSL 证书是否正确安装和配置"
    echo "4. 检查 Docker 服务是否正常运行: docker-compose ps"
    echo "5. 查看服务日志: docker-compose logs"
fi

echo ""
echo "测试完成时间: $(date)"
