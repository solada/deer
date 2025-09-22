# 微信小程序 SSL 证书配置指南

## 🎯 目标

为 `deerlulu1008.cn` 配置微信小程序支持的 SSL 证书。

## 📋 前置条件

1. **域名解析**：确保 `deerlulu1008.cn` 正确解析到您的服务器 IP
2. **端口开放**：确保 80 和 443 端口对外开放
3. **服务器权限**：需要 root 或 sudo 权限

## 🚀 方案一：使用 Let's Encrypt 免费证书（推荐）

### 自动配置（推荐）

```bash
# 1. 编辑脚本中的邮箱地址
nano setup-ssl.sh
# 将 EMAIL="your-email@example.com" 改为您的真实邮箱

# 2. 运行自动配置脚本
sudo ./setup-ssl.sh
```

### 手动配置步骤

#### 1. 安装 Certbot

**Ubuntu/Debian:**
```bash
sudo apt update
sudo apt install certbot python3-certbot-nginx
```

**CentOS/RHEL:**
```bash
sudo yum install certbot python3-certbot-nginx
```

#### 2. 停止当前服务
```bash
docker-compose down
```

#### 3. 申请证书

**方法 A: 使用 Nginx 插件（推荐）**
```bash
sudo certbot --nginx -d deerlulu1008.cn -d www.deerlulu1008.cn
```

**方法 B: 使用 Webroot 验证**
```bash
# 创建验证目录
sudo mkdir -p /var/www/html

# 申请证书
sudo certbot certonly \
    --webroot \
    --webroot-path=/var/www/html \
    --email your-email@example.com \
    --agree-tos \
    --no-eff-email \
    --domains deerlulu1008.cn,www.deerlulu1008.cn
```

#### 4. 复制证书到项目目录
```bash
sudo cp /etc/letsencrypt/live/deerlulu1008.cn/fullchain.pem ./ssl/deerlulu1008.cn.crt
sudo cp /etc/letsencrypt/live/deerlulu1008.cn/privkey.pem ./ssl/deerlulu1008.cn.key
sudo chmod 644 ./ssl/deerlulu1008.cn.crt
sudo chmod 600 ./ssl/deerlulu1008.cn.key
```

#### 5. 重启服务
```bash
docker-compose up -d
```

#### 6. 设置自动续期
```bash
# 测试续期
sudo certbot renew --dry-run

# 设置定时任务
sudo crontab -e
# 添加以下行：
# 0 12 * * * /usr/bin/certbot renew --quiet --deploy-hook "cd /data/deerserver && cp /etc/letsencrypt/live/deerlulu1008.cn/fullchain.pem ./ssl/deerlulu1008.cn.crt && cp /etc/letsencrypt/live/deerlulu1008.cn/privkey.pem ./ssl/deerlulu1008.cn.key && chmod 644 ./ssl/deerlulu1008.cn.crt && chmod 600 ./ssl/deerlulu1008.cn.key && docker-compose restart nginx"
```

## 💰 方案二：购买商业 SSL 证书

### 推荐的证书提供商

1. **阿里云 SSL 证书**
   - 价格：免费版和付费版
   - 支持：DV、OV、EV 证书
   - 微信小程序：✅ 支持

2. **腾讯云 SSL 证书**
   - 价格：免费版和付费版
   - 支持：DV、OV、EV 证书
   - 微信小程序：✅ 支持

3. **DigiCert**
   - 价格：较高，但质量最好
   - 支持：所有类型证书
   - 微信小程序：✅ 支持

### 购买和配置步骤

#### 1. 购买证书
- 登录云服务商控制台
- 选择 SSL 证书服务
- 购买适合的证书类型

#### 2. 申请证书
- 填写域名信息
- 验证域名所有权
- 等待证书签发

#### 3. 下载证书
- 下载证书文件（通常包含 .crt 和 .key 文件）
- 或下载 .pem 格式文件

#### 4. 配置证书
```bash
# 将下载的证书文件复制到项目目录
cp your-certificate.crt ./ssl/deerlulu1008.cn.crt
cp your-private-key.key ./ssl/deerlulu1008.cn.key

# 设置权限
chmod 644 ./ssl/deerlulu1008.cn.crt
chmod 600 ./ssl/deerlulu1008.cn.key

# 重启服务
docker-compose restart nginx
```

## 🔧 方案三：使用 Cloudflare（免费）

### 配置步骤

#### 1. 注册 Cloudflare 账户
- 访问 https://cloudflare.com
- 注册并登录账户

#### 2. 添加域名
- 在 Cloudflare 控制台添加 `deerlulu1008.cn`
- 按照提示修改 DNS 记录

#### 3. 启用 SSL
- 在 SSL/TLS 设置中选择 "Full" 或 "Full (strict)"
- 启用 "Always Use HTTPS"

#### 4. 配置源服务器
- 在源服务器上安装 Cloudflare Origin 证书
- 或使用 Cloudflare 的代理服务

## ✅ 验证证书配置

### 1. 检查证书信息
```bash
# 查看证书详情
openssl x509 -in ./ssl/deerlulu1008.cn.crt -text -noout

# 检查证书有效期
openssl x509 -in ./ssl/deerlulu1008.cn.crt -noout -dates

# 验证证书和私钥匹配
openssl x509 -noout -modulus -in ./ssl/deerlulu1008.cn.crt | openssl md5
openssl rsa -noout -modulus -in ./ssl/deerlulu1008.cn.key | openssl md5
```

### 2. 测试 HTTPS 访问
```bash
# 测试主页
curl -I https://deerlulu1008.cn

# 测试 API
curl https://deerlulu1008.cn/health

# 检查 SSL 等级
curl -I https://www.ssllabs.com/ssltest/analyze.html?d=deerlulu1008.cn
```

### 3. 微信小程序测试
```bash
# 运行外网测试脚本
./simple-test.sh
```

## 🚨 常见问题解决

### 问题 1: 域名解析错误
```bash
# 检查域名解析
nslookup deerlulu1008.cn
dig deerlulu1008.cn

# 确保解析到正确的服务器 IP
```

### 问题 2: 端口不通
```bash
# 检查端口开放
netstat -tlnp | grep :80
netstat -tlnp | grep :443

# 检查防火墙
sudo ufw status
sudo iptables -L
```

### 问题 3: 证书申请失败
```bash
# 检查 Certbot 日志
sudo tail -f /var/log/letsencrypt/letsencrypt.log

# 手动验证域名
sudo certbot certonly --manual --preferred-challenges dns -d deerlulu1008.cn
```

### 问题 4: 证书不被信任
- 确保使用受信任的 CA 机构
- 检查证书链是否完整
- 验证域名匹配

## 📱 微信小程序配置

### 1. 配置合法域名
在微信小程序管理后台：
- 进入「开发」→「开发设置」
- 在「服务器域名」中添加：
  - **request 合法域名**: `https://deerlulu1008.cn`

### 2. 测试 API 调用
```javascript
// 测试 HTTPS 连接
wx.request({
  url: 'https://deerlulu1008.cn/health',
  method: 'GET',
  success: (res) => {
    console.log('HTTPS 连接成功:', res.data);
  },
  fail: (err) => {
    console.error('HTTPS 连接失败:', err);
  }
});
```

## 🔄 证书续期

### Let's Encrypt 自动续期
```bash
# 测试续期
sudo certbot renew --dry-run

# 手动续期
sudo certbot renew

# 重启服务
docker-compose restart nginx
```

### 商业证书续期
- 在证书到期前 30 天开始续期流程
- 按照证书提供商的指引操作
- 更新证书文件后重启服务

## 📊 证书监控

### 创建监控脚本
```bash
#!/bin/bash
# 检查证书过期时间
CERT_EXPIRY=$(openssl x509 -in ./ssl/deerlulu1008.cn.crt -noout -dates | grep notAfter | cut -d= -f2)
EXPIRY_DATE=$(date -d "$CERT_EXPIRY" +%s)
CURRENT_DATE=$(date +%s)
DAYS_LEFT=$(( (EXPIRY_DATE - CURRENT_DATE) / 86400 ))

if [ $DAYS_LEFT -lt 30 ]; then
    echo "⚠️  证书将在 $DAYS_LEFT 天后过期，请及时续期"
else
    echo "✅ 证书有效期正常，还有 $DAYS_LEFT 天"
fi
```

---

## 🎯 推荐方案

**对于微信小程序项目，推荐使用 Let's Encrypt 免费证书**：

✅ **优势**：
- 完全免费
- 受微信小程序信任
- 自动续期
- 配置简单

✅ **适用场景**：
- 个人项目
- 小型企业
- 测试环境
- 生产环境（中小型）

如果您的项目对证书有特殊要求（如 EV 证书），可以考虑购买商业证书。
