#!/bin/bash

# SSL 证书状态检查脚本

DOMAIN="deerlulu1008.cn"
CERT_FILE="./ssl/deerlulu1008.cn.crt"
KEY_FILE="./ssl/deerlulu1008.cn.key"

echo "=== SSL 证书状态检查 ==="
echo "域名: $DOMAIN"
echo "检查时间: $(date)"
echo ""

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 1. 检查证书文件是否存在
echo -e "${BLUE}1. 检查证书文件${NC}"
if [ -f "$CERT_FILE" ] && [ -f "$KEY_FILE" ]; then
    echo -e "✅ 证书文件存在"
    echo "  证书文件: $CERT_FILE"
    echo "  私钥文件: $KEY_FILE"
else
    echo -e "${RED}❌ 证书文件缺失${NC}"
    echo "请先配置 SSL 证书"
    exit 1
fi
echo ""

# 2. 检查证书内容
echo -e "${BLUE}2. 检查证书内容${NC}"
if openssl x509 -in "$CERT_FILE" -text -noout >/dev/null 2>&1; then
    echo -e "✅ 证书格式正确"
else
    echo -e "${RED}❌ 证书格式错误${NC}"
    exit 1
fi
echo ""

# 3. 检查私钥
echo -e "${BLUE}3. 检查私钥${NC}"
if openssl pkey -in "$KEY_FILE" -check -noout >/dev/null 2>&1; then
    echo -e "✅ 私钥格式正确"
else
    echo -e "${RED}❌ 私钥格式错误${NC}"
    exit 1
fi
echo ""

# 4. 检查证书和私钥匹配
echo -e "${BLUE}4. 检查证书和私钥匹配${NC}"
# 对于 ECDSA 证书，使用不同的验证方法
CERT_PUBKEY=$(openssl x509 -noout -pubkey -in "$CERT_FILE" | openssl md5)
KEY_PUBKEY=$(openssl pkey -in "$KEY_FILE" -pubout | openssl md5)

if [ "$CERT_PUBKEY" = "$KEY_PUBKEY" ]; then
    echo -e "✅ 证书和私钥匹配"
else
    echo -e "${RED}❌ 证书和私钥不匹配${NC}"
    echo "证书公钥: $CERT_PUBKEY"
    echo "私钥公钥: $KEY_PUBKEY"
    # 不退出，继续检查其他项目
fi
echo ""

# 5. 检查证书信息
echo -e "${BLUE}5. 证书详细信息${NC}"
echo "颁发者:"
openssl x509 -in "$CERT_FILE" -noout -issuer | sed 's/issuer=//'
echo ""
echo "主题:"
openssl x509 -in "$CERT_FILE" -noout -subject | sed 's/subject=//'
echo ""
echo "有效期:"
openssl x509 -in "$CERT_FILE" -noout -dates
echo ""

# 6. 检查证书有效期
echo -e "${BLUE}6. 证书有效期检查${NC}"
CERT_EXPIRY=$(openssl x509 -in "$CERT_FILE" -noout -dates | grep notAfter | cut -d= -f2)
EXPIRY_DATE=$(date -d "$CERT_EXPIRY" +%s 2>/dev/null || date -j -f "%b %d %H:%M:%S %Y %Z" "$CERT_EXPIRY" +%s 2>/dev/null)
CURRENT_DATE=$(date +%s)
DAYS_LEFT=$(( (EXPIRY_DATE - CURRENT_DATE) / 86400 ))

if [ $DAYS_LEFT -gt 30 ]; then
    echo -e "${GREEN}✅ 证书有效期正常${NC}"
    echo "  还有 $DAYS_LEFT 天过期"
elif [ $DAYS_LEFT -gt 7 ]; then
    echo -e "${YELLOW}⚠️  证书即将过期${NC}"
    echo "  还有 $DAYS_LEFT 天过期，建议准备续期"
else
    echo -e "${RED}❌ 证书即将过期${NC}"
    echo "  还有 $DAYS_LEFT 天过期，请立即续期"
fi
echo ""

# 7. 检查域名匹配
echo -e "${BLUE}7. 检查域名匹配${NC}"
CERT_DOMAINS=$(openssl x509 -in "$CERT_FILE" -text -noout | grep -E "DNS:|Subject Alternative Name" -A 10 | grep -o "DNS:[^,]*" | sed 's/DNS://g' | tr '\n' ' ')

if echo "$CERT_DOMAINS" | grep -q "$DOMAIN"; then
    echo -e "✅ 证书包含目标域名: $DOMAIN"
    echo "  证书支持的域名: $CERT_DOMAINS"
else
    echo -e "${RED}❌ 证书不包含目标域名: $DOMAIN${NC}"
    echo "  证书支持的域名: $CERT_DOMAINS"
fi
echo ""

# 8. 检查证书类型
echo -e "${BLUE}8. 检查证书类型${NC}"
ISSUER=$(openssl x509 -in "$CERT_FILE" -noout -issuer)

if echo "$ISSUER" | grep -qi "Let's Encrypt"; then
    echo -e "${GREEN}✅ Let's Encrypt 证书${NC} (微信小程序支持)"
elif echo "$ISSUER" | grep -qi "DigiCert\|GlobalSign\|Comodo\|Symantec"; then
    echo -e "${GREEN}✅ 商业证书${NC} (微信小程序支持)"
else
    echo -e "${YELLOW}⚠️  自签名证书${NC} (微信小程序不支持)"
    echo "  颁发者: $ISSUER"
fi
echo ""

# 9. 测试 HTTPS 连接
echo -e "${BLUE}9. 测试 HTTPS 连接${NC}"
if curl -s -I https://$DOMAIN | head -1 | grep -q "200"; then
    echo -e "✅ HTTPS 连接正常"
else
    echo -e "${RED}❌ HTTPS 连接失败${NC}"
fi
echo ""

# 10. 微信小程序兼容性检查
echo -e "${BLUE}10. 微信小程序兼容性检查${NC}"

# 检查是否为受信任的 CA
if echo "$ISSUER" | grep -qi "Let's Encrypt\|DigiCert\|GlobalSign\|Comodo\|Symantec\|GoDaddy\|Amazon\|Cloudflare"; then
    echo -e "${GREEN}✅ 受信任的 CA 机构${NC}"
    WECHAT_COMPATIBLE=true
else
    echo -e "${RED}❌ 不受信任的 CA 机构${NC}"
    WECHAT_COMPATIBLE=false
fi

# 检查域名匹配
if echo "$CERT_DOMAINS" | grep -q "$DOMAIN"; then
    echo -e "${GREEN}✅ 域名匹配${NC}"
    DOMAIN_MATCH=true
else
    echo -e "${RED}❌ 域名不匹配${NC}"
    DOMAIN_MATCH=false
fi

# 检查有效期
if [ $DAYS_LEFT -gt 0 ]; then
    echo -e "${GREEN}✅ 证书未过期${NC}"
    VALID_PERIOD=true
else
    echo -e "${RED}❌ 证书已过期${NC}"
    VALID_PERIOD=false
fi

echo ""
echo -e "${BLUE}=== 微信小程序兼容性总结 ===${NC}"
if [ "$WECHAT_COMPATIBLE" = true ] && [ "$DOMAIN_MATCH" = true ] && [ "$VALID_PERIOD" = true ]; then
    echo -e "${GREEN}🎉 证书完全兼容微信小程序！${NC}"
    echo ""
    echo "📱 微信小程序配置："
    echo "request 合法域名: https://$DOMAIN"
    echo ""
    echo "✅ 可以正常在微信小程序中使用此域名进行 API 调用"
else
    echo -e "${RED}❌ 证书不兼容微信小程序${NC}"
    echo ""
    echo "🔧 需要解决的问题："
    if [ "$WECHAT_COMPATIBLE" = false ]; then
        echo "- 使用受信任的 CA 机构颁发的证书"
    fi
    if [ "$DOMAIN_MATCH" = false ]; then
        echo "- 确保证书包含正确的域名"
    fi
    if [ "$VALID_PERIOD" = false ]; then
        echo "- 更新过期的证书"
    fi
    echo ""
    echo "💡 建议使用 Let's Encrypt 免费证书："
    echo "sudo ./setup-ssl.sh"
fi

echo ""
echo "=== 检查完成 ==="
