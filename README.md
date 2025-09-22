# 鹿鹿论坛 - 微信小程序后端服务

基于 Docker 的 HTTPS 发帖服务，支持微信小程序访问。

## 🚀 快速开始

### 1. 准备 SSL 证书

将您的 SSL 证书文件放置在 `ssl/` 目录中：
- `ssl/deerlulu1008.cn.crt` - 证书文件
- `ssl/deerlulu1008.cn.key` - 私钥文件

### 2. 启动服务

```bash
# 使用启动脚本（推荐）
./start.sh

# 或者手动启动
docker-compose up --build -d
```

### 3. 访问服务

- **HTTPS 地址**: https://deerlulu1008.cn
- **API 基础路径**: https://deerlulu1008.cn/api
- **健康检查**: https://deerlulu1008.cn/health

## 📋 服务架构

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Nginx (443)   │────│ Node.js (3000)  │────│ MySQL (3306)    │
│   HTTPS/SSL     │    │   Express API   │    │   数据存储      │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## 🔌 API 接口

### 用户认证
- `POST /api/register` - 用户注册
- `POST /api/login` - 用户登录

### 帖子管理
- `GET /api/posts` - 获取帖子列表（支持分页）
- `POST /api/posts` - 发布帖子（需要登录）
- `GET /api/posts/:id` - 获取帖子详情和评论

### 评论系统
- `POST /api/posts/:id/comments` - 发表评论（需要登录）

### 系统接口
- `GET /api/health` - 健康检查

## 📊 数据库结构

### 用户表 (users)
- `id` - 用户ID
- `username` - 用户名（唯一）
- `password` - 加密密码
- `email` - 邮箱（唯一）
- `nickname` - 昵称
- `created_at` - 创建时间

### 帖子表 (posts)
- `id` - 帖子ID
- `user_id` - 发帖用户ID
- `title` - 帖子标题
- `content` - 帖子内容
- `view_count` - 浏览次数
- `created_at` - 创建时间

### 评论表 (comments)
- `id` - 评论ID
- `post_id` - 帖子ID
- `user_id` - 评论用户ID
- `content` - 评论内容
- `reply_to_comment_id` - 回复的评论ID（支持嵌套评论）
- `reply_to_user_id` - 回复的用户ID
- `created_at` - 创建时间

## 🔒 安全特性

- **HTTPS 强制重定向**：所有 HTTP 请求自动重定向到 HTTPS
- **JWT 认证**：使用 JSON Web Token 进行用户认证
- **密码加密**：使用 bcrypt 对密码进行加密存储
- **请求限流**：防止恶意请求和暴力破解
- **CORS 配置**：支持微信小程序跨域访问
- **SQL 注入防护**：使用参数化查询防止 SQL 注入
- **安全头设置**：包含 HSTS、XSS 防护等安全头

## 🛠️ 开发和维护

### 查看日志
```bash
# 查看所有服务日志
docker-compose logs -f

# 查看特定服务日志
docker-compose logs -f backend
docker-compose logs -f mysql
docker-compose logs -f nginx
```

### 管理服务
```bash
# 停止服务
docker-compose down

# 重启服务
docker-compose restart

# 重新构建并启动
docker-compose up --build -d

# 查看服务状态
docker-compose ps
```

### 数据库管理
```bash
# 连接到 MySQL
docker-compose exec mysql mysql -u deeruser -p deer_forum

# 备份数据库
docker-compose exec mysql mysqldump -u root -p deer_forum > backup.sql

# 恢复数据库
docker-compose exec -T mysql mysql -u root -p deer_forum < backup.sql
```

## 📱 微信小程序集成

### 请求域名配置
在微信小程序管理后台配置以下域名：
- **request 合法域名**: `https://deerlulu1008.cn`

### 示例代码
```javascript
// 用户登录
wx.request({
  url: 'https://deerlulu1008.cn/api/login',
  method: 'POST',
  data: {
    username: 'your_username',
    password: 'your_password'
  },
  success: (res) => {
    if (res.data.token) {
      wx.setStorageSync('token', res.data.token);
    }
  }
});

// 获取帖子列表
wx.request({
  url: 'https://deerlulu1008.cn/api/posts',
  method: 'GET',
  success: (res) => {
    console.log(res.data.posts);
  }
});

// 发布帖子（需要登录）
wx.request({
  url: 'https://deerlulu1008.cn/api/posts',
  method: 'POST',
  header: {
    'Authorization': 'Bearer ' + wx.getStorageSync('token')
  },
  data: {
    title: '帖子标题',
    content: '帖子内容'
  },
  success: (res) => {
    console.log('发帖成功');
  }
});
```

## 🔧 配置说明

### 环境变量
- `NODE_ENV` - 运行环境（production/development）
- `DB_HOST` - 数据库主机
- `DB_PORT` - 数据库端口
- `DB_NAME` - 数据库名称
- `DB_USER` - 数据库用户名
- `DB_PASSWORD` - 数据库密码
- `JWT_SECRET` - JWT 签名密钥

### 端口映射
- `80` - HTTP 端口（重定向到 HTTPS）
- `443` - HTTPS 端口
- `3000` - 后端 API 端口
- `3306` - MySQL 数据库端口

## 📞 技术支持

如遇到问题，请检查：
1. SSL 证书是否正确配置
2. 域名 DNS 解析是否正确
3. 防火墙是否开放相应端口
4. Docker 服务是否正常运行

---

**版本**: 1.0.0  
**更新时间**: 2024年9月
