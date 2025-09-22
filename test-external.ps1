# Windows PowerShell 外网测试脚本
# 使用方法: 在 PowerShell 中运行 .\test-external.ps1

$Domain = "deerlulu1008.cn"
$BaseUrl = "https://$Domain/api"

Write-Host "=== 鹿鹿论坛外网 HTTPS 测试 (Windows) ===" -ForegroundColor Cyan
Write-Host "测试域名: $Domain" -ForegroundColor Yellow
Write-Host "测试时间: $(Get-Date)" -ForegroundColor Yellow
Write-Host ""

$TotalTests = 0
$PassedTests = 0
$FailedTests = 0

# 测试函数
function Test-Endpoint {
    param(
        [string]$Name,
        [string]$Url,
        [string]$Method = "GET",
        [hashtable]$Headers = @{},
        [string]$Body = "",
        [int]$ExpectedStatus = 200
    )
    
    $global:TotalTests++
    Write-Host "测试 $global:TotalTests : $Name" -ForegroundColor Blue
    
    try {
        $params = @{
            Uri = $Url
            Method = $Method
            UseBasicParsing = $true
        }
        
        if ($Headers.Count -gt 0) {
            $params.Headers = $Headers
        }
        
        if ($Body -ne "") {
            $params.Body = $Body
            if (-not $Headers.ContainsKey("Content-Type")) {
                $params.Headers = @{"Content-Type" = "application/json"}
            }
        }
        
        $response = Invoke-WebRequest @params
        $statusCode = $response.StatusCode
        
        if ($statusCode -eq $ExpectedStatus) {
            Write-Host "  ✅ 成功 - HTTP $statusCode" -ForegroundColor Green
            $global:PassedTests++
            
            # 尝试格式化 JSON 响应
            try {
                $json = $response.Content | ConvertFrom-Json
                $json | ConvertTo-Json -Depth 3 | Select-Object -First 10
            } catch {
                $response.Content | Select-Object -First 5
            }
        } else {
            Write-Host "  ❌ 失败 - 期望 HTTP $ExpectedStatus, 实际 HTTP $statusCode" -ForegroundColor Red
            Write-Host "  响应内容: $($response.Content)" -ForegroundColor Red
            $global:FailedTests++
        }
    } catch {
        Write-Host "  ❌ 请求失败: $($_.Exception.Message)" -ForegroundColor Red
        $global:FailedTests++
    }
    Write-Host ""
}

# 1. 网络连接测试
Write-Host "=== 1. 网络连接测试 ===" -ForegroundColor Yellow

Write-Host "测试域名解析..."
try {
    $ip = [System.Net.Dns]::GetHostAddresses($Domain)[0].IPAddressToString
    Write-Host "✅ 域名解析成功 - $Domain → $ip" -ForegroundColor Green
} catch {
    Write-Host "❌ 域名解析失败" -ForegroundColor Red
    Write-Host "请检查网络连接和 DNS 配置" -ForegroundColor Red
    exit 1
}

Write-Host "测试 HTTPS 端口连通性..."
try {
    $tcpClient = New-Object System.Net.Sockets.TcpClient
    $tcpClient.Connect($Domain, 443)
    $tcpClient.Close()
    Write-Host "✅ HTTPS 端口 (443) 连通" -ForegroundColor Green
} catch {
    Write-Host "❌ HTTPS 端口 (443) 不通" -ForegroundColor Red
    Write-Host "请检查防火墙和服务器配置" -ForegroundColor Red
    exit 1
}
Write-Host ""

# 2. 基础服务测试
Write-Host "=== 2. 基础服务测试 ===" -ForegroundColor Yellow

Test-Endpoint "主页访问" "https://$Domain" "GET" @{} "" 200
Test-Endpoint "健康检查接口" "https://$Domain/health" "GET" @{} "" 200

# 3. API 接口测试
Write-Host "=== 3. API 接口测试 ===" -ForegroundColor Yellow

Test-Endpoint "获取帖子列表" "$BaseUrl/posts" "GET" @{} "" 200

# 用户注册测试
$randomUser = "testuser_$(Get-Date -Format 'yyyyMMddHHmmss')"
$registerData = @{
    username = $randomUser
    password = "password123"
    email = "$randomUser@test.com"
    nickname = "外网测试用户"
} | ConvertTo-Json

Write-Host "测试用户注册..." -ForegroundColor Blue
try {
    $registerResponse = Invoke-RestMethod -Uri "$BaseUrl/register" -Method POST -Body $registerData -ContentType "application/json"
    Write-Host "✅ 用户注册成功" -ForegroundColor Green
    $token = $registerResponse.token
    Write-Host "获取到认证令牌: $($token.Substring(0, 20))..." -ForegroundColor Green
    
    # 测试发布帖子
    $postData = @{
        title = "外网测试帖子"
        content = "这是通过外网 HTTPS 发布的测试帖子，验证服务正常工作。发布时间：$(Get-Date)"
    } | ConvertTo-Json
    
    $headers = @{
        "Authorization" = "Bearer $token"
        "Content-Type" = "application/json"
    }
    
    Test-Endpoint "发布帖子" "$BaseUrl/posts" "POST" $headers $postData 201
    
    # 测试用户登录
    $loginData = @{
        username = $randomUser
        password = "password123"
    } | ConvertTo-Json
    
    Test-Endpoint "用户登录" "$BaseUrl/login" "POST" @{"Content-Type" = "application/json"} $loginData 200
    
} catch {
    Write-Host "❌ 用户注册失败: $($_.Exception.Message)" -ForegroundColor Red
    $global:FailedTests++
}
Write-Host ""

# 4. 性能测试
Write-Host "=== 4. 性能测试 ===" -ForegroundColor Yellow
Write-Host "测试响应时间..."

for ($i = 1; $i -le 5; $i++) {
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    try {
        Invoke-WebRequest -Uri "https://$Domain/health" -UseBasicParsing | Out-Null
        $stopwatch.Stop()
        Write-Host "第 $i 次请求: $($stopwatch.ElapsedMilliseconds)ms"
    } catch {
        Write-Host "第 $i 次请求失败"
    }
}
Write-Host ""

# 5. 微信小程序兼容性测试
Write-Host "=== 5. 微信小程序兼容性测试 ===" -ForegroundColor Yellow

# 测试 CORS
$corsHeaders = @{
    "Origin" = "https://servicewechat.com"
}
Test-Endpoint "带微信 Origin 的请求" "$BaseUrl/posts" "GET" $corsHeaders "" 200

# 6. 错误处理测试
Write-Host "=== 6. 错误处理测试 ===" -ForegroundColor Yellow

Test-Endpoint "404 错误处理" "$BaseUrl/nonexistent" "GET" @{} "" 404

# 测试结果统计
Write-Host "=== 测试结果统计 ===" -ForegroundColor Yellow
Write-Host "总测试数: $TotalTests"
Write-Host "通过: $PassedTests" -ForegroundColor Green
Write-Host "失败: $FailedTests" -ForegroundColor Red

if ($FailedTests -eq 0) {
    Write-Host "`n🎉 所有测试通过！您的服务可以正常通过外网 HTTPS 访问！" -ForegroundColor Green
    Write-Host ""
    Write-Host "📱 微信小程序配置信息：" -ForegroundColor Blue
    Write-Host "合法域名配置: https://$Domain"
    Write-Host "API 基础地址: $BaseUrl"
    Write-Host ""
    Write-Host "📋 可用的 API 接口：" -ForegroundColor Blue
    Write-Host "- POST $BaseUrl/register (用户注册)"
    Write-Host "- POST $BaseUrl/login (用户登录)"
    Write-Host "- GET  $BaseUrl/posts (获取帖子列表)"
    Write-Host "- POST $BaseUrl/posts (发布帖子，需要登录)"
    Write-Host "- GET  $BaseUrl/posts/:id (获取帖子详情)"
    Write-Host "- POST $BaseUrl/posts/:id/comments (发表评论，需要登录)"
} else {
    Write-Host "`n❌ 有 $FailedTests 个测试失败，请检查服务配置" -ForegroundColor Red
    Write-Host ""
    Write-Host "🔍 故障排查建议：" -ForegroundColor Blue
    Write-Host "1. 检查域名 DNS 解析是否指向正确的服务器 IP"
    Write-Host "2. 确认服务器防火墙已开放 80 和 443 端口"
    Write-Host "3. 验证 SSL 证书是否正确安装和配置"
    Write-Host "4. 检查服务是否正常运行"
}

Write-Host ""
Write-Host "测试完成时间: $(Get-Date)"
