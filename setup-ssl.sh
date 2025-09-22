#!/bin/bash

# 微信小程序 SSL 证书自动配置脚本
# 使用 Let's Encrypt 免费证书

DOMAIN="deerlulu1008.cn"
EMAIL="819281490@qq.com"  # 请替换为您的真实邮箱

echo "=== 微信小程序 SSL 证书配置 ==="
echo "域名: $DOMAIN"
echo "邮箱: $EMAIL"
echo ""

# 检查是否为 root 用户
if [ "$EUID" -ne 0 ]; then
    echo "❌ 请使用 root 用户运行此脚本"
    echo "使用命令: sudo $0"
    exit 1
fi

# 检查域名解析
echo "1. 检查域名解析..."
DOMAIN_IP=$(nslookup $DOMAIN | grep "Address" | tail -1 | cut -d' ' -f2)
SERVER_IP=$(curl -s ifconfig.me)

if [ "$DOMAIN_IP" = "$SERVER_IP" ]; then
    echo "✅ 域名解析正确: $DOMAIN → $DOMAIN_IP"
else
    echo "❌ 域名解析错误"
    echo "域名解析到: $DOMAIN_IP"
    echo "服务器 IP: $SERVER_IP"
    echo "请确保域名正确解析到当前服务器"
    exit 1
fi

# 安装 Certbot
echo ""
echo "2. 安装 Certbot..."
if ! command -v certbot &> /dev/null; then
    echo "安装 Certbot..."
    
    # 检测系统类型
    if [ -f /etc/debian_version ]; then
        # Debian/Ubuntu
        apt update
        apt install -y certbot python3-certbot-nginx
    elif [ -f /etc/redhat-release ]; then
        # CentOS/RHEL
        yum install -y certbot python3-certbot-nginx
    else
        echo "❌ 不支持的操作系统，请手动安装 Certbot"
        exit 1
    fi
else
    echo "✅ Certbot 已安装"
fi

# 停止当前服务
echo ""
echo "3. 停止当前服务..."
docker-compose down

# 配置 Nginx 用于证书验证
echo ""
echo "4. 配置临时 Nginx 用于证书验证..."

# 创建临时 Nginx 配置
cat > /tmp/nginx-temp.conf << EOF
events {
    worker_connections 1024;
}

http {
    server {
        listen 80;
        server_name $DOMAIN www.$DOMAIN;
        
        location /.well-known/acme-challenge/ {
            root /var/www/html;
        }
        
        location / {
            return 200 'SSL Certificate Setup in Progress';
            add_header Content-Type text/plain;
        }
    }
}
EOF

# 启动临时 Nginx 容器
docker run -d --name temp-nginx \
    -p 80:80 \
    -v /tmp/nginx-temp.conf:/etc/nginx/nginx.conf \
    -v /var/www/html:/var/www/html \
    nginx:alpine

# 等待 Nginx 启动
sleep 5

# 申请 SSL 证书
echo ""
echo "5. 申请 SSL 证书..."
echo "这可能需要几分钟时间..."

certbot certonly \
    --webroot \
    --webroot-path=/var/www/html \
    --email $EMAIL \
    --agree-tos \
    --no-eff-email \
    --domains $DOMAIN,www.$DOMAIN \
    --non-interactive

# 检查证书是否申请成功
if [ -f "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" ]; then
    echo "✅ SSL 证书申请成功！"
    
    # 停止临时 Nginx
    docker stop temp-nginx
    docker rm temp-nginx
    
    # 复制证书到项目目录
    echo ""
    echo "6. 复制证书到项目目录..."
    cp /etc/letsencrypt/live/$DOMAIN/fullchain.pem ./ssl/deerlulu1008.cn.crt
    cp /etc/letsencrypt/live/$DOMAIN/privkey.pem ./ssl/deerlulu1008.cn.key
    
    # 设置正确的权限
    chmod 644 ./ssl/deerlulu1008.cn.crt
    chmod 600 ./ssl/deerlulu1008.cn.key
    
    echo "✅ 证书文件已复制到 ssl/ 目录"
    
    # 显示证书信息
    echo ""
    echo "7. 证书信息："
    openssl x509 -in ./ssl/deerlulu1008.cn.crt -text -noout | grep -E "(Subject:|Not Before|Not After|Issuer:)"
    
    # 重启服务
    echo ""
    echo "8. 重启服务..."
    docker-compose up -d
    
    # 等待服务启动
    sleep 10
    
    # 测试 HTTPS
    echo ""
    echo "9. 测试 HTTPS 服务..."
    if curl -s https://$DOMAIN/health | grep -q "正常运行"; then
        echo "✅ HTTPS 服务正常"
    else
        echo "❌ HTTPS 服务异常"
    fi
    
    # 设置自动续期
    echo ""
    echo "10. 设置证书自动续期..."
    
    # 创建续期脚本
    cat > /etc/cron.d/certbot-renew << EOF
# 每天检查证书是否需要续期
0 12 * * * root certbot renew --quiet --deploy-hook "cd /data/deerserver && cp /etc/letsencrypt/live/$DOMAIN/fullchain.pem ./ssl/deerlulu1008.cn.crt && cp /etc/letsencrypt/live/$DOMAIN/privkey.pem ./ssl/deerlulu1008.cn.key && chmod 644 ./ssl/deerlulu1008.cn.crt && chmod 600 ./ssl/deerlulu1008.cn.key && docker-compose restart nginx"
EOF
    
    echo "✅ 自动续期已设置"
    
    echo ""
    echo "🎉 SSL 证书配置完成！"
    echo ""
    echo "📋 配置信息："
    echo "域名: $DOMAIN"
    echo "证书类型: Let's Encrypt (受微信小程序信任)"
    echo "有效期: 90 天 (自动续期)"
    echo "证书文件: ./ssl/deerlulu1008.cn.crt"
    echo "私钥文件: ./ssl/deerlulu1008.cn.key"
    echo ""
    echo "📱 微信小程序配置："
    echo "request 合法域名: https://$DOMAIN"
    echo ""
    echo "🔧 管理命令："
    echo "查看证书状态: certbot certificates"
    echo "手动续期: certbot renew"
    echo "测试续期: certbot renew --dry-run"
    
else
    echo "❌ SSL 证书申请失败"
    echo "请检查："
    echo "1. 域名是否正确解析到当前服务器"
    echo "2. 80 端口是否开放"
    echo "3. 防火墙设置是否正确"
    
    # 清理临时容器
    docker stop temp-nginx 2>/dev/null
    docker rm temp-nginx 2>/dev/null
    
    exit 1
fi
