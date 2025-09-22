# 🚀 快速配置微信小程序支持的 SSL 证书

## 📊 当前状态

根据检查结果，您当前使用的是**自签名证书**，**微信小程序不支持**。

## ⚡ 快速解决方案

### 方案一：使用 Let's Encrypt 免费证书（推荐）

#### 1. 自动配置（最简单）
```bash
# 编辑邮箱地址
nano setup-ssl.sh
# 将 EMAIL="your-email@example.com" 改为您的真实邮箱

# 运行自动配置
sudo ./setup-ssl.sh
```

#### 2. 手动配置
```bash
# 1. 安装 Certbot
sudo apt update
sudo apt install certbot python3-certbot-nginx

# 2. 停止当前服务
docker-compose down

# 3. 申请证书
sudo certbot certonly \
    --standalone \
    --email your-email@example.com \
    --agree-tos \
    --no-eff-email \
    --domains deerlulu1008.cn,www.deerlulu1008.cn

# 4. 复制证书
sudo cp /etc/letsencrypt/live/deerlulu1008.cn/fullchain.pem ./ssl/deerlulu1008.cn.crt
sudo cp /etc/letsencrypt/live/deerlulu1008.cn/privkey.pem ./ssl/deerlulu1008.cn.key
sudo chmod 644 ./ssl/deerlulu1008.cn.crt
sudo chmod 600 ./ssl/deerlulu1008.cn.key

# 5. 重启服务
docker-compose up -d
```

### 方案二：使用云服务商免费证书

#### 阿里云 SSL 证书
1. 登录阿里云控制台
2. 搜索 "SSL 证书"
3. 购买免费版 DV 证书
4. 申请证书，验证域名
5. 下载证书文件
6. 配置到服务器

#### 腾讯云 SSL 证书
1. 登录腾讯云控制台
2. 搜索 "SSL 证书"
3. 申请免费版证书
4. 验证域名所有权
5. 下载并配置证书

## 🔧 配置步骤详解

### 前置条件检查

#### 1. 域名解析检查
```bash
# 检查域名是否解析到当前服务器
nslookup deerlulu1008.cn
dig deerlulu1008.cn

# 确保解析到正确的服务器 IP
curl ifconfig.me  # 获取服务器公网 IP
```

#### 2. 端口检查
```bash
# 检查端口是否开放
netstat -tlnp | grep :80
netstat -tlnp | grep :443

# 检查防火墙
sudo ufw status
```

### Let's Encrypt 详细配置

#### 1. 安装依赖
```bash
# Ubuntu/Debian
sudo apt update
sudo apt install certbot python3-certbot-nginx

# CentOS/RHEL
sudo yum install certbot python3-certbot-nginx
```

#### 2. 申请证书
```bash
# 方法 1: 使用 standalone 模式（需要停止服务）
sudo certbot certonly --standalone \
    --email your-email@example.com \
    --agree-tos \
    --no-eff-email \
    --domains deerlulu1008.cn,www.deerlulu1008.cn

# 方法 2: 使用 webroot 模式（不需要停止服务）
sudo mkdir -p /var/www/html
sudo certbot certonly --webroot \
    --webroot-path=/var/www/html \
    --email your-email@example.com \
    --agree-tos \
    --no-eff-email \
    --domains deerlulu1008.cn,www.deerlulu1008.cn
```

#### 3. 配置证书
```bash
# 复制证书到项目目录
sudo cp /etc/letsencrypt/live/deerlulu1008.cn/fullchain.pem ./ssl/deerlulu1008.cn.crt
sudo cp /etc/letsencrypt/live/deerlulu1008.cn/privkey.pem ./ssl/deerlulu1008.cn.key

# 设置正确权限
sudo chmod 644 ./ssl/deerlulu1008.cn.crt
sudo chmod 600 ./ssl/deerlulu1008.cn.key

# 重启服务
docker-compose restart nginx
```

#### 4. 设置自动续期
```bash
# 测试续期
sudo certbot renew --dry-run

# 设置定时任务
sudo crontab -e
# 添加以下行：
0 12 * * * /usr/bin/certbot renew --quiet --deploy-hook "cd /data/deerserver && cp /etc/letsencrypt/live/deerlulu1008.cn/fullchain.pem ./ssl/deerlulu1008.cn.crt && cp /etc/letsencrypt/live/deerlulu1008.cn/privkey.pem ./ssl/deerlulu1008.cn.key && chmod 644 ./ssl/deerlulu1008.cn.crt && chmod 600 ./ssl/deerlulu1008.cn.key && docker-compose restart nginx"
```

## ✅ 验证配置

### 1. 检查证书状态
```bash
./check-ssl.sh
```

### 2. 测试 HTTPS 访问
```bash
# 测试主页
curl -I https://deerlulu1008.cn

# 测试 API
curl https://deerlulu1008.cn/health

# 运行完整测试
./simple-test.sh
```

### 3. 微信小程序测试
```javascript
// 在小程序中测试
wx.request({
  url: 'https://deerlulu1008.cn/health',
  method: 'GET',
  success: (res) => {
    console.log('HTTPS 连接成功');
  },
  fail: (err) => {
    console.error('HTTPS 连接失败:', err);
  }
});
```

## 🚨 常见问题解决

### 问题 1: 域名解析错误
```bash
# 检查 DNS 设置
nslookup deerlulu1008.cn
dig deerlulu1008.cn

# 确保域名解析到正确的服务器 IP
```

### 问题 2: 端口 80 被占用
```bash
# 检查端口占用
sudo netstat -tlnp | grep :80

# 临时停止占用端口的服务
sudo systemctl stop apache2  # 如果使用 Apache
sudo systemctl stop nginx    # 如果使用系统 Nginx
```

### 问题 3: 防火墙阻止
```bash
# 检查防火墙状态
sudo ufw status

# 开放必要端口
sudo ufw allow 80
sudo ufw allow 443
```

### 问题 4: 证书申请失败
```bash
# 查看详细日志
sudo tail -f /var/log/letsencrypt/letsencrypt.log

# 手动验证域名
sudo certbot certonly --manual --preferred-challenges dns -d deerlulu1008.cn
```

## 📱 微信小程序配置

### 1. 配置合法域名
在微信小程序管理后台：
- 进入「开发」→「开发设置」
- 在「服务器域名」中添加：
  - **request 合法域名**: `https://deerlulu1008.cn`

### 2. 测试 API 调用
```javascript
// 测试连接
wx.request({
  url: 'https://deerlulu1008.cn/health',
  method: 'GET',
  success: (res) => {
    console.log('连接成功:', res.data);
  }
});

// 用户注册
wx.request({
  url: 'https://deerlulu1008.cn/api/register',
  method: 'POST',
  data: {
    username: 'testuser',
    password: 'password123',
    email: 'test@example.com',
    nickname: '测试用户'
  },
  success: (res) => {
    console.log('注册成功:', res.data);
  }
});
```

## 🎯 推荐操作流程

### 立即执行（推荐）
```bash
# 1. 编辑邮箱地址
nano setup-ssl.sh

# 2. 运行自动配置
sudo ./setup-ssl.sh

# 3. 验证配置
./check-ssl.sh

# 4. 测试服务
./simple-test.sh
```

### 如果自动配置失败
```bash
# 1. 手动安装 Certbot
sudo apt update && sudo apt install certbot

# 2. 手动申请证书
sudo certbot certonly --standalone \
    --email your-email@example.com \
    --agree-tos \
    --domains deerlulu1008.cn

# 3. 手动配置证书
sudo cp /etc/letsencrypt/live/deerlulu1008.cn/fullchain.pem ./ssl/deerlulu1008.cn.crt
sudo cp /etc/letsencrypt/live/deerlulu1008.cn/privkey.pem ./ssl/deerlulu1008.cn.key
sudo chmod 644 ./ssl/deerlulu1008.cn.crt
sudo chmod 600 ./ssl/deerlulu1008.cn.key

# 4. 重启服务
docker-compose restart nginx
```

## 🎉 完成后的效果

配置成功后，您将获得：

✅ **受信任的 SSL 证书**（Let's Encrypt 或商业证书）  
✅ **微信小程序兼容**（可以正常配置合法域名）  
✅ **自动续期**（Let's Encrypt 证书每 90 天自动续期）  
✅ **HTTPS 安全连接**（所有通信加密）  

---

**重要提醒**：配置 SSL 证书后，您的服务就可以在微信小程序中正常使用了！
