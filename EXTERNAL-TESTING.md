# 外网测试指南

本文档说明如何从外网测试您的 `deerlulu1008.cn` HTTPS 服务。

## 🚀 快速测试

### 方法一：使用浏览器（最简单）

直接在浏览器中访问以下地址：

1. **主页**: https://deerlulu1008.cn
2. **健康检查**: https://deerlulu1008.cn/health
3. **API 测试**: https://deerlulu1008.cn/api/posts

如果能正常访问并返回 JSON 数据，说明服务运行正常。

### 方法二：使用 curl 命令（推荐）

在任何有网络连接的 Linux/macOS 终端中运行：

```bash
# 测试主页
curl -I https://deerlulu1008.cn

# 测试 API 健康检查
curl https://deerlulu1008.cn/health

# 测试获取帖子列表
curl https://deerlulu1008.cn/api/posts
```

## 📋 完整测试脚本

我为您准备了三个不同平台的测试脚本：

### 1. Linux/macOS 完整测试脚本

```bash
# 在服务器上运行
./test-external.sh
```

**功能特性**：
- ✅ 域名解析检查
- ✅ SSL 证书验证
- ✅ 端口连通性测试
- ✅ 完整的 API 功能测试
- ✅ 性能测试
- ✅ 微信小程序兼容性测试
- ✅ 错误处理测试

### 2. 简化版测试脚本

```bash
# 可在任何 Linux/macOS 机器上运行
./simple-test.sh
```

**功能特性**：
- ✅ 基础连通性测试
- ✅ 主要 API 功能验证
- ✅ 用户注册和发帖测试

### 3. Windows PowerShell 测试脚本

```powershell
# 在 Windows PowerShell 中运行
.\test-external.ps1
```

**功能特性**：
- ✅ Windows 系统兼容
- ✅ 完整的 API 测试
- ✅ 彩色输出和详细报告

## 🔧 手动测试步骤

如果您想手动测试，可以按以下步骤进行：

### 1. 基础连通性测试

```bash
# 测试域名解析
nslookup deerlulu1008.cn

# 测试端口连通
telnet deerlulu1008.cn 443
```

### 2. HTTPS 服务测试

```bash
# 测试主页
curl -v https://deerlulu1008.cn

# 测试 HTTP 重定向
curl -I http://deerlulu1008.cn
```

### 3. API 接口测试

```bash
# 获取帖子列表
curl https://deerlulu1008.cn/api/posts

# 用户注册
curl -X POST https://deerlulu1008.cn/api/register \
  -H "Content-Type: application/json" \
  -d '{"username":"testuser","password":"password123","email":"test@example.com","nickname":"测试用户"}'

# 用户登录
curl -X POST https://deerlulu1008.cn/api/login \
  -H "Content-Type: application/json" \
  -d '{"username":"testuser","password":"password123"}'
```

### 4. 认证测试

```bash
# 获取 token 后发帖（需要替换 YOUR_TOKEN）
curl -X POST https://deerlulu1008.cn/api/posts \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{"title":"测试帖子","content":"这是一个测试帖子"}'
```

## 📱 微信小程序测试

### 域名配置

在微信小程序管理后台配置：
- **request 合法域名**: `https://deerlulu1008.cn`

### 小程序代码示例

```javascript
// 测试 API 连通性
wx.request({
  url: 'https://deerlulu1008.cn/api/posts',
  method: 'GET',
  success: (res) => {
    console.log('API 测试成功:', res.data);
  },
  fail: (err) => {
    console.error('API 测试失败:', err);
  }
});

// 用户注册
wx.request({
  url: 'https://deerlulu1008.cn/api/register',
  method: 'POST',
  data: {
    username: 'miniprogram_user',
    password: 'password123',
    email: 'user@example.com',
    nickname: '小程序用户'
  },
  success: (res) => {
    if (res.data.token) {
      wx.setStorageSync('token', res.data.token);
      console.log('注册成功');
    }
  }
});

// 发布帖子
wx.request({
  url: 'https://deerlulu1008.cn/api/posts',
  method: 'POST',
  header: {
    'Authorization': 'Bearer ' + wx.getStorageSync('token')
  },
  data: {
    title: '小程序测试帖子',
    content: '这是从微信小程序发布的测试帖子'
  },
  success: (res) => {
    console.log('发帖成功:', res.data);
  }
});
```

## 🔍 故障排查

### 常见问题和解决方案

#### 1. 域名无法访问
- **检查项**：DNS 解析是否正确
- **解决方案**：确认域名指向正确的服务器 IP

#### 2. HTTPS 连接失败
- **检查项**：SSL 证书是否有效
- **解决方案**：检查证书配置，确保证书未过期

#### 3. 端口不通
- **检查项**：防火墙设置
- **解决方案**：开放 80 和 443 端口

#### 4. API 返回 500 错误
- **检查项**：后端服务状态
- **解决方案**：检查 Docker 服务和日志

#### 5. 数据库连接失败
- **检查项**：MySQL 服务状态
- **解决方案**：重启 MySQL 容器

### 日志查看

```bash
# 查看所有服务状态
docker-compose ps

# 查看服务日志
docker-compose logs nginx
docker-compose logs backend
docker-compose logs mysql

# 实时查看日志
docker-compose logs -f
```

## 📊 测试报告示例

成功的测试应该显示类似以下结果：

```
=== 测试结果统计 ===
总测试数: 15
通过: 15
失败: 0

🎉 所有测试通过！您的服务可以正常通过外网 HTTPS 访问！

📱 微信小程序配置信息：
合法域名配置: https://deerlulu1008.cn
API 基础地址: https://deerlulu1008.cn/api
```

## 🎯 性能基准

正常情况下的性能指标：

- **响应时间**: < 500ms
- **SSL 握手**: < 200ms
- **API 响应**: < 1s
- **数据库查询**: < 100ms

如果性能指标超出这些范围，可能需要优化服务器配置或网络环境。

---

通过以上测试方法，您可以全面验证 `deerlulu1008.cn` 服务的外网可用性和微信小程序兼容性。
