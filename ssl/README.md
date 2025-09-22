# SSL 证书配置说明

## 证书文件要求

请将您的 SSL 证书文件放置在此目录中，文件名需要按照以下规范：

1. **证书文件**: `deerlulu1008.cn.crt` 或 `deerlulu1008.cn.pem`
2. **私钥文件**: `deerlulu1008.cn.key`

## 文件结构

```
ssl/
├── deerlulu1008.cn.crt  # 证书文件
├── deerlulu1008.cn.key  # 私钥文件
└── README.md           # 说明文档
```

## 证书权限设置

为了安全起见，建议设置正确的文件权限：

```bash
chmod 644 deerlulu1008.cn.crt
chmod 600 deerlulu1008.cn.key
```

## 证书验证

可以使用以下命令验证证书：

```bash
# 检查证书内容
openssl x509 -in deerlulu1008.cn.crt -text -noout

# 检查私钥
openssl rsa -in deerlulu1008.cn.key -check

# 验证证书和私钥是否匹配
openssl x509 -noout -modulus -in deerlulu1008.cn.crt | openssl md5
openssl rsa -noout -modulus -in deerlulu1008.cn.key | openssl md5
```

## 自签名证书（仅用于测试）

如果您需要创建自签名证书用于测试，可以使用以下命令：

```bash
# 生成私钥
openssl genrsa -out deerlulu1008.cn.key 2048

# 生成证书签名请求
openssl req -new -key deerlulu1008.cn.key -out deerlulu1008.cn.csr

# 生成自签名证书
openssl x509 -req -days 365 -in deerlulu1008.cn.csr -signkey deerlulu1008.cn.key -out deerlulu1008.cn.crt
```

**注意**: 自签名证书仅适用于开发和测试环境，生产环境请使用正式的 SSL 证书。

## 证书更新

当证书即将过期时，请：

1. 替换证书文件
2. 重启 nginx 容器：`docker-compose restart nginx`

## 故障排查

如果 HTTPS 访问出现问题，请检查：

1. 证书文件是否存在且路径正确
2. 证书是否有效且未过期
3. 域名是否与证书匹配
4. 防火墙是否开放 443 端口
